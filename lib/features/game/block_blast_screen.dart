import 'dart:async';
import 'dart:math';
import 'block_blast_engine.dart';
import 'block_celebration.dart';
import 'block_board_fx.dart';
import 'game_leaderboard.dart';
import 'block_battle_lobby.dart';
import 'block_battle_session.dart';
import 'block_battle_widgets.dart';
import 'combo_hud.dart';
import 'block_battle_life_fx.dart';
import '../../core/services/social_bridge.dart';
import 'package:flutter/material.dart';
import 'package:hukuk_reels/core/widgets/pixel_logo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../core/data/questions_data.dart';
import '../../core/models/quiz_question.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/sfx_service.dart';
import '../reels/widgets/music_button.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/fit_panel.dart';
import '../../core/services/activity_area.dart';

/// Block Blast benzeri bulmaca: 8×8 ızgaraya 3 parçayı sürükleyip yerleştir;
/// dolan satır/sütunlar patlar. Hiçbir parça sığmazsa oyun biter.
class BlockBlastScreen extends StatefulWidget {
  final BlockBattleSession? battle;
  const BlockBlastScreen({super.key, this.battle});

  @override
  State<BlockBlastScreen> createState() => _BlockBlastScreenState();
}

const int _n = 8; // ızgara boyutu

const List<Color> _palette = [
  Color(0xFFFF5C8A),
  Color(0xFFB06CFF),
  Color(0xFF5C9BFF),
  Color(0xFF35D0C0),
  Color(0xFFFFB14E),
  Color(0xFF6BD46B),
  Color(0xFFFF6B6B),
  Color(0xFFFFD93D),
];

class _BlockBlastScreenState extends State<BlockBlastScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _rng = Random();
  BlockBattleSession? get _battle => widget.battle;
  Timer? _battleTimer, _battleNoticeTimer;
  bool _predicted = false;
  int _battleMove = -1,
      _battleOut = -1,
      _battleEventRevision = -1,
      _battleRound = 1;
  String _battleFeedback = '';

  final _gridKey = GlobalKey();
  final _stackKey = GlobalKey();

  late BlockBlastEngine _game;
  List<List<int?>> get _grid => _game.grid;
  List<BlockPiece?> get _tray => _game.tray;
  int get _score => _game.score;
  late final AnimationController _fxClock;
  // Ekran sarsıntısı (yalnız görsel): kombo büyüdükçe sertleşir ve uzar.
  late final AnimationController _shake;
  // Sarsıntı adımı (~30 kare/sn; -1 = durgun). Yalnız adım değişince
  // ekran yeniden konumlanır.
  final _shakeStep = ValueNotifier<int>(-1);
  double _shakePower = 0;
  final _boardFx = BlockBoardFx();
  String _feedback = '';
  BlockCelebrationData? _celebration;
  int _celebrationId = 0;
  int _boardRevision = 0;
  Timer? _reviveTimer;
  int _run = 0;
  bool _over = false;
  bool _newRecord = false;

  // Devam etme (revive): oyun başına yalnızca 1 kez bir soruyla hak kazanılır.
  bool get _reviveUsed => _game.reviveUsed;
  bool _askContinue = false;
  QuizQuestion? _reviveQ;
  int? _reviveSelected;

  double _cell = 40; // build'de hesaplanır
  bool _sideTray = false; // yatay ekran: tepsi tahtanın sağında
  static const double _lift = 64; // parmağın belirgin şekilde üstünde göster

  int? _dragIdx;
  final _dragPosition = ValueNotifier<Offset>(Offset.zero);
  int? _dragPointer;
  Offset _pointerDown = Offset.zero;
  bool _dragMoved = false;
  // Kaydırma hassasiyeti: parmak hareketi bu katsayıyla büyütülür (>1 = aynı
  // mesafeye daha az parmak hareketiyle ulaşılır).
  double _dragGain = 2.0;
  Offset _dragAnchor = Offset.zero; // sürükleme başında parmak (stack uzayı)
  Offset _anchorTL = Offset.zero; // sürükleme başında parçanın sol-üstü
  bool _dragHasAnchor = false;
  // Parça tepsiden parmağın üstüne süzülür, geçersiz bırakılınca geri döner:
  // 0 = tepsideki yeri ve boyu, 1 = parmağı izleyen tam boy.
  late final AnimationController _float;
  final _trayKeys = List.generate(3, (_) => GlobalKey());
  Offset _trayTL = Offset.zero;
  double _trayScale = 1;
  Offset _fingerTL = Offset.zero; // parmağı izleyen konum (önizleme buna göre)

  int _tr = 0, _tc = 0;
  bool _valid = false;
  Set<int> _preview = {};
  Set<int> _clearPreview = {}; // bırakınca silinecek (tam dolacak) hücreler

  @override
  void initState() {
    super.initState();
    if (_battle == null) {
      unawaited(socialCall('init', {'url': socialApiUrl}).then((_) =>
          socialCall('score', {'score': ProgressService.instance.blockHigh})));
    }
    SfxService.instance.init(); // efektleri önceden yükle (düşük gecikme)
    WidgetsBinding.instance.addObserver(this);
    _shake = AnimationController(vsync: this)
      ..addListener(() => _shakeStep.value = _shake.isAnimating
          ? (_shake.value * _shake.duration!.inMilliseconds / 33).floor()
          : -1)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _shakeStep.value = -1;
      });
    _float = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120))
      ..addListener(_floatChanged)
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed && _dragIdx != null) {
          _finishDrag();
        }
      });
    _fxClock = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (_boardFx.retire(_fxClock.value) && mounted) setState(() {});
      });
    if (_battle != null) {
      _game = _battle!.engine()!;
      _battleMove = _battle!.mine!['lastMove'];
      _battleOut = _battle!.mine!['boardOuts'];
      _battleRound = _battle!.round;
      _battle!.addListener(_battleChanged);
      _battleTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted && _battle!.status == 'countdown') setState(() {});
      });
      return;
    }
    _game = BlockBlastEngine.restore(ProgressService.instance.loadBlockGame(),
            random: _rng) ??
        BlockBlastEngine(random: _rng);
    if (!_game.hasMove) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _gameOver();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _fxClock.stop();
      _boardFx.reset();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reviveTimer?.cancel();
    _battleTimer?.cancel();
    _battleNoticeTimer?.cancel();
    _battle?.removeListener(_battleChanged);
    _fxClock.dispose();
    _float.dispose();
    _shake.dispose();
    _shakeStep.dispose();
    _dragPosition.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _dragIdx != null) _finishDrag();
  }

  @override
  void didChangeMetrics() {
    if (_dragIdx != null) _finishDrag();
  }

  void _save() {
    if (_battle != null) return;
    unawaited(socialCall('score', {'score': _score}));
    unawaited(ProgressService.instance
        .saveBlockGame(_game.toJson(includeRunSummary: true)));
    final run = _run;
    unawaited(ProgressService.instance.submitBlockScore(_score).then((record) {
      if (mounted && run == _run && record) setState(() => _newRecord = true);
    }));
  }

  void _reset() {
    if (_battle != null) return;
    _run++;
    _reviveTimer?.cancel();
    _fxClock.stop();
    _boardFx.reset();
    _feedback = '';
    _celebration = null;
    _game = BlockBlastEngine(random: _rng);
    _boardRevision++;
    _over = false;
    _newRecord = false;
    _askContinue = false;
    _reviveQ = null;
    _reviveSelected = null;
    _dragIdx = null;
    _dragPointer = null;
    _valid = false;
    _preview = {};
    _clearPreview = {};
    _save();
    if (mounted) setState(() {});
  }

  bool _fits(BlockPiece p, int r, int c) => _game.fits(p, r, c);

  // ── Sürükleme ──
  void _startDrag(int i, PointerDownEvent event) {
    // Tepsiye dönmekte olan parça yeni dokunuşu bekletmez.
    if (_dragIdx != null && _dragPointer == null) _finishDrag();
    if ((_battle != null && !_battle!.canPlay) ||
        _dragIdx != null ||
        _over ||
        _askContinue ||
        _reviveQ != null) {
      return;
    }
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final pieceBox =
        _trayKeys[i].currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || pieceBox == null) return;
    _dragPointer = event.pointer;
    _pointerDown = event.position;
    _dragMoved = false;
    _dragGain = event.kind == PointerDeviceKind.mouse ? 1.0 : 2.0;
    _valid = false;
    _dragIdx = i;
    _dragHasAnchor = false;
    _trayTL = stackBox.globalToLocal(pieceBox.localToGlobal(Offset.zero));
    _trayScale = pieceBox.size.width / (_tray[i]!.cols * _cell);
    _updateDrag(event.position);
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.value = 1;
    } else {
      _float.forward(from: 0);
    }
    HapticFeedback.selectionClick();
    setState(() {});
  }

  /// Gösterilen konum: tepsideki yerden parmağın üstüne (ve geri) geçiş.
  void _floatChanged() {
    final t = Curves.easeOutCubic.transform(_float.value);
    _dragPosition.value = Offset.lerp(_trayTL, _fingerTL, t)!;
  }

  double get _dragScale =>
      _trayScale +
      (1 - _trayScale) * Curves.easeOutCubic.transform(_float.value);

  void _updateDrag(Offset global) {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || gridBox == null || _dragIdx == null) return;
    final p = _tray[_dragIdx!];
    if (p == null) return;

    final local = stackBox.globalToLocal(global);
    final gridTL = stackBox.globalToLocal(gridBox.localToGlobal(Offset.zero));
    final wpx = p.cols * _cell, hpx = p.rows * _cell;

    // Başlangıç çapasını sabitle: parça parmağın üstüne yerleşir
    // (tepsi tahtanın yanındaysa parmağın solunda).
    if (!_dragHasAnchor) {
      _dragAnchor = local;
      _anchorTL = _sideTray
          ? local - Offset(wpx + _lift, hpx / 2)
          : local - Offset(wpx / 2, hpx + _lift);
      _dragHasAnchor = true;
    }
    // Parmak hareketini büyüterek uygula (hassasiyet).
    final target = _anchorTL + (local - _dragAnchor) * _dragGain;
    // Parça parmağın altında kalmaz: dikeyde hep üstünde, yanda hep solunda.
    _fingerTL = _sideTray
        ? Offset(min(target.dx, local.dx - wpx - 32), target.dy)
        : Offset(target.dx, min(target.dy, local.dy - hpx - 32));
    _floatChanged();

    final oldRow = _tr, oldCol = _tc;
    final wasValid = _valid;
    final rel = _fingerTL - gridTL;
    _tc = (rel.dx / _cell).round();
    _tr = (rel.dy / _cell).round();
    _valid = _fits(p, _tr, _tc);
    if (oldRow == _tr && oldCol == _tc && wasValid == _valid) return;
    if (_valid) {
      _preview = {
        for (final cell in p.cells) (_tr + cell[0]) * _n + (_tc + cell[1])
      };
      // O konuma konunca tamamen dolacak (silinecek) satır/sütunları parlat.
      _clearPreview = _clearCellsIfPlaced(p, _tr, _tc);
    } else {
      _preview = {};
      _clearPreview = {};
    }
    setState(() {});
  }

  /// Parça (tr,tc)'ye konursa tamamen dolacak satır/sütunların TÜM hücreleri
  /// (silme önizlemesi için parlatılacak).
  Set<int> _clearCellsIfPlaced(BlockPiece p, int tr, int tc) {
    return _game.preview(p, tr, tc);
  }

  void _endDrag() {
    if (_dragIdx != null && _valid) {
      _place(_tray[_dragIdx!]!, _tr, _tc, _dragIdx!);
      _finishDrag();
    } else {
      _cancelDrag();
    }
  }

  /// Geçersiz bırakma ya da sürüklemeden dokunma: parça tepsiye süzülür.
  void _cancelDrag() {
    _dragPointer = null;
    _valid = false;
    _preview = {};
    _clearPreview = {};
    if (_float.value == 0 || MediaQuery.disableAnimationsOf(context)) {
      _finishDrag();
      return;
    }
    _float.reverse();
    setState(() {});
  }

  void _finishDrag() {
    _float.stop();
    _float.value = 0;
    _dragIdx = null;
    _dragPointer = null;
    _valid = false;
    _preview = {};
    _clearPreview = {};
    if (mounted) setState(() {});
  }

  void _place(BlockPiece p, int tr, int tc, int idx) {
    if (_battle != null && !_battle!.canPlay) return;
    final move = _game.place(idx, tr, tc);
    if (move == null) return;
    _boardRevision++;
    if (_battle != null) {
      _predicted = true;
      _battle!.place(idx, tr, tc);
    }
    _feedback = move.allClear
        ? 'TERTEMİZ! +${move.points}'
        : move.lines > 0
            ? '${move.lines > 1 ? "${move.lines} ÇİZGİ · " : ""}+${move.points}'
            : '';
    _save();
    if (!MediaQuery.disableAnimationsOf(context)) {
      if (_boardFx.isEmpty) _fxClock.value = 0;
      final now = _fxClock.value;
      _boardFx.add(
          now,
          {for (final cell in p.cells) (tr + cell[0]) * _n + tc + cell[1]},
          move.clearedCells,
          move.lines);
      _fxClock.animateTo(_boardFx.end,
          duration: Duration(milliseconds: (_boardFx.end - now).ceil()));
    }
    if (move.lines > 0) {
      if (_game.combo > 1 || move.lines > 1 || move.allClear) {
        _celebration = BlockCelebrationData.forClear(
            combo: _game.combo,
            lines: move.lines,
            points: move.points,
            allClear: move.allClear);
        _celebrationId++;
      }
      _kickShake(move);
      HapticFeedback.mediumImpact();
      if (_game.combo > 1 || move.lines > 1) {
        SfxService.instance.combo(_game.combo);
      } else {
        SfxService.instance.clear();
      }
    } else {
      HapticFeedback.lightImpact();
      SfxService.instance.place();
    }
    if (_battle == null && !_game.hasMove) _gameOver();
  }

  /// Kombo ve aynı anda silinen çizgi arttıkça ekran daha sert ve uzun
  /// sarsılır; tek çizgilik ilk silme sarsmaz. Puanı etkilemez.
  void _kickShake(BlockMove move) {
    final power =
        (_game.combo - 1) + (move.lines - 1) * 1.5 + (move.allClear ? 3 : 0);
    if (power <= 0 || MediaQuery.disableAnimationsOf(context)) return;
    _shakePower = min(power, 10.0);
    _shake.duration = Duration(milliseconds: (180 + _shakePower * 30).round());
    _shake.forward(from: 0);
    if (_shakePower >= 4) HapticFeedback.heavyImpact();
  }

  /// Ağaç yapısı hep aynı kalır (durağanken sıfır kayma), böylece sarsıntı
  /// başlayıp bitince alt ağaç yeniden kurulmaz. Ekran kendi katmanında
  /// (RepaintBoundary) bir kez çizilir; sarsıntı yalnız o katmanı kaydırır,
  /// her karede tüm ekranı yeniden çizmez.
  Widget _shaking(Widget child) => ValueListenableBuilder<int>(
        valueListenable: _shakeStep,
        child: RepaintBoundary(child: child),
        builder: (context, step, child) {
          var offset = Offset.zero, turn = 0.0;
          if (step >= 0) {
            // Piksel hissi: ~30 kare/sn adımlar, tam piksele yuvarlanmış kayma.
            final t = min(1.0, step * 33 / _shake.duration!.inMilliseconds);
            final decay = (1 - t) * (1 - t);
            final amp = (1.5 + _shakePower * 1.3) * decay;
            offset = Offset((sin(step * 2.7) * amp).roundToDouble(),
                (cos(step * 3.9) * amp * .7).roundToDouble());
            // Çok büyük kombolarda hafif yalpalama da eklenir.
            if (_shakePower > 5) {
              turn = sin(step * 1.9) * .006 * (_shakePower - 5) / 5 * decay;
            }
          }
          return Transform.translate(
              offset: offset,
              child: Transform.rotate(angle: turn, child: child));
        },
      );

  void _battleChanged() {
    if (!mounted || _battle?.mine == null) return;
    final session = _battle!;
    final mine = session.mine!;
    final reset = _battleOut != mine['boardOuts'];
    final round = session.round;
    final roundChanged = round != _battleRound;
    if (!session.pending &&
        (_predicted ||
            _battleMove != mine['lastMove'] ||
            reset ||
            roundChanged)) {
      _game = session.engine()!;
      _boardRevision++;
      _predicted = false;
      _battleMove = mine['lastMove'];
      _battleOut = mine['boardOuts'];
      _battleRound = round;
      _finishDrag();
      if (reset || roundChanged) {
        _fxClock.stop();
        _boardFx.reset();
        _celebration = null;
        if (roundChanged) {
          _feedback = '';
          _battleFeedback = '';
        }
      }
    }
    final revision = session.state!['revision'] as int;
    if (session.events.isNotEmpty && revision != _battleEventRevision) {
      _battleEventRevision = revision;
      for (final event in session.events) {
        if (event['type'] == 'BOARD_RESET' && event['player'] == session.me) {
          _battleFeedback = 'HAMLE KALMADI · −1 CAN · Tahta yenilendi';
        } else if (event['type'] == 'DAMAGE') {
          _battleFeedback = event['player'] == session.me
              ? '−${event['amount']} CAN · Rakip 500 puan eşiğini geçti'
              : 'RAKİP −${event['amount']} CAN';
        } else if (event['type'] == 'REMATCH_STARTED') {
          _battleFeedback = 'YENİ ROUND BAŞLADI!';
        }
      }
      _battleNoticeTimer?.cancel();
      _battleNoticeTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _battleFeedback = '');
      });
    }
    if (!session.canPlay && !session.pending) _finishDrag();
    setState(() {});
  }

  Future<void> _exitBattle() async {
    final session = _battle!;
    if (session.status != 'finished') {
      final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Maçtan ayrıl?'),
                content: const Text('Ayrılırsan bu maçı kaybedersin.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Devam et')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ayrıl')),
                ],
              ));
      if (leave != true || !mounted) return;
      if (session.connected) await session.action('resign');
    }
    await session.action('leave');
    if (mounted) Navigator.of(context).pop();
  }

  void _gameOver() {
    // Bu oyunda revive hakkı henüz kullanılmadıysa önce "devam et?" sor.
    if (!_reviveUsed) {
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _askContinue = true);
      return;
    }
    _finishGame();
  }

  void _finishGame() {
    _over = true;
    unawaited(ProgressService.instance.clearBlockGame());
    HapticFeedback.heavyImpact();
    SfxService.instance.gameOver();
    ProgressService.instance.submitBlockScore(_score).then((rec) {
      if (mounted && rec) setState(() => _newRecord = true);
    });
    if (mounted) setState(() {});
  }

  // ── Devam etme (revive) ──
  void _declineContinue() {
    setState(() => _askContinue = false);
    _finishGame();
  }

  void _acceptContinue() {
    // Consume the attempt before showing the question; reopening cannot retry it.
    _game.reviveUsed = true;
    _save();
    setState(() {
      _askContinue = false;
      _reviveSelected = null;
      _reviveQ =
          kQuestions[_rng.nextInt(kQuestions.length)].withShuffledOptions(_rng);
    });
  }

  void _answerRevive(int i) {
    if (_reviveSelected != null) return; // tek seçim hakkı
    setState(() => _reviveSelected = i);
    final correct = i == _reviveQ!.correctIndex;
    HapticFeedback.lightImpact();
    _reviveTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (correct) {
        _revive();
      } else {
        setState(() {
          _reviveQ = null;
          _reviveSelected = null;
        });
        _finishGame();
      }
    });
  }

  /// Doğru cevap: revive hakkı yakıldı, tahta temizlendi, oyun devam.
  void _revive() {
    setState(() {
      _game.revive();
      _boardRevision++;
      _reviveQ = null;
      _reviveSelected = null;
    });
    _save();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) =>
      ActivityAreaScope(area: 'block', child: _areaBody(context));

  Widget _areaBody(BuildContext context) {
    final best = ProgressService.instance.blockHigh;
    return PopScope(
        canPop: _battle == null,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _battle != null) unawaited(_exitBattle());
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF182B50),
          body: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF294879), Color(0xFF172849)],
            )),
            child: SafeArea(
              child: _shaking(BattleLifeFeedback(
                  session: _battle,
                  child: Stack(
                    key: _stackKey,
                    children: [
                      Column(
                        children: [
                          _topBar(best),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, c) {
                                // Skor sayacı ve kombo çipi canlanırken
                                // ekranın geri kalanı yeniden çizilmesin.
                                final hud = RepaintBoundary(
                                    child: _battle == null
                                        ? _scoreText()
                                        : BattleHud(
                                            session: _battle!,
                                            palette: _palette,
                                            feedback: _battleFeedback));
                                // Dikey: skor, tahta, tepsi alt alta. Ekran
                                // yataysa ve tahta yükseklikten kısılıyorsa
                                // skor solda, tahta ortada, tepsi sağda.
                                final tall = min(min(c.maxWidth - 28, 600),
                                        max(80, (c.maxHeight - 134) / 1.37))
                                    .toDouble();
                                final side = min(min(c.maxHeight - 24, 680),
                                        max(80, c.maxWidth - 2 * 150))
                                    .toDouble();
                                if (c.maxWidth > c.maxHeight * 1.1 &&
                                    side > tall * 1.12) {
                                  _cell = side / _n;
                                  _sideTray = true;
                                  return Row(
                                    children: [
                                      Expanded(
                                          child: Center(
                                              child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: hud,
                                      ))),
                                      _gridWidget(side),
                                      Expanded(
                                          child: _trayWidget(
                                              vertical: true,
                                              extent: side,
                                              cross: (c.maxWidth - side) / 2)),
                                    ],
                                  );
                                }
                                _cell = tall / _n;
                                _sideTray = false;
                                return Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    hud,
                                    _gridWidget(tall),
                                    _trayWidget(),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      // Sürüklenen parça (parmağın üstünde, tıklamayı engellemez)
                      if (_dragIdx != null && _tray[_dragIdx!] != null)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _dragPosition,
                              // Yalnız boyanır (yerleşim değişmez): akıcı.
                              builder: (context, child) => Transform(
                                  transform: Matrix4.identity()
                                    ..translateByDouble(_dragPosition.value.dx,
                                        _dragPosition.value.dy, 0, 1)
                                    ..scaleByDouble(
                                        _dragScale, _dragScale, 1, 1),
                                  child: child),
                              // Anahtar boyanan parçada: ölçülen yer ekrandaki.
                              child: RepaintBoundary(
                                  key: const ValueKey('block-drag-feedback'),
                                  child: _pieceGrid(_tray[_dragIdx!]!, _cell)),
                            ),
                          ),
                        ),

                      if (_askContinue) _continueOverlay(),
                      if (_reviveQ != null) _quizOverlay(),
                      if (_over) _overOverlay(best),
                      if (_battle != null && _battle!.status == 'finished')
                        BattleResult(
                            session: _battle!,
                            onClose: () => unawaited(_exitBattle())),
                    ],
                  ))),
            ),
          ),
        ));
  }

  Widget _topBar(int best) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 14, 4),
      child: Row(
        children: [
          _circleBtn(Icons.arrow_back_rounded, () {
            if (_battle != null) {
              unawaited(_exitBattle());
            } else {
              Navigator.of(context).maybePop();
            }
          }),
          const SizedBox(width: 6),
          PixelLogo(_battle == null ? kLogoBlockBlast : kLogoBattle, size: 22),
          const SizedBox(width: 6),
          Expanded(
              child: Text(
            _battle == null ? 'Block Blast' : '1v1 · ${_battle!.room}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          )),
          if (_battle == null)
            IconButton(
              tooltip: 'İkimizin sıralaması',
              icon: const Icon(Icons.leaderboard_rounded,
                  color: Color(0xFFFFD76A)),
              onPressed: () {
                _cancelDrag();
                Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const GameLeaderboard()));
              },
            ),
          const MusicButton(),
          const SizedBox(width: 8),
          if (_battle == null) _circleBtn(Icons.refresh_rounded, _reset),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _scoreText() => SizedBox(
        height: 112,
        child: FittedBox(
            fit: BoxFit.scaleDown,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('🏆 ${ProgressService.instance.blockHigh}',
                    style: const TextStyle(
                        color: Color(0xFFFFD36A), fontWeight: FontWeight.w700)),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    _cancelDrag();
                    Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const BlockBattleLobby()));
                  },
                  icon: const PixelLogo(kLogoBattle, size: 18),
                  label: const Text('1v1 Battle'),
                ),
              ]),
              TweenAnimationBuilder<double>(
                tween: Tween(end: _score.toDouble()),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                builder: (context, value, child) => Text('${value.round()}',
                    style: const TextStyle(
                        fontSize: 36,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
              ComboHud(
                combo: _game.combo,
                misses: _game.misses,
                comboBonus: _game.comboBonus,
                comboGrace: BlockBlastEngine.comboGrace,
              ),
              if (_game.combo == 0)
                Text(
                    _feedback.isNotEmpty
                        ? _feedback
                        : 'Bir satır veya sütun doldur',
                    style: TextStyle(
                        fontSize: 12,
                        color: _feedback.isNotEmpty
                            ? Colors.white
                            : const Color(0xFFFFD36A),
                        fontWeight: _feedback.isNotEmpty
                            ? FontWeight.w700
                            : FontWeight.w400)),
              if (_game.combo > 0 && _feedback.isNotEmpty)
                Text(_feedback,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
            ])),
      );

  Widget _gridWidget(double size) {
    // 64 ayrı widget yerine tek CustomPaint — sürükleme akıcı olsun.
    return Semantics(
        key: const ValueKey('block-board'),
        label: '8 × 8 oyun tahtası',
        child: Container(
          key: _gridKey,
          width: size,
          height: size,
          // Piksel çerçeve: sert (bulanıksız) gölgeler kutunun dışına çizilir,
          // hücre ölçülerini değiştirmez.
          decoration: const BoxDecoration(
            color: Color(0xFF101F3B),
            boxShadow: [
              BoxShadow(
                  color: Color(0xFF070F1E),
                  offset: Offset(0, 7),
                  spreadRadius: 4),
              BoxShadow(color: Color(0xFF3A5C92), spreadRadius: 4),
              BoxShadow(color: Color(0xFF070F1E), spreadRadius: 1),
            ],
          ),
          child: Stack(children: [
            Positioned.fill(
                child: RepaintBoundary(
                    key: const ValueKey('block-static-grid'),
                    child: CustomPaint(
                      painter: _GridPainter(
                          _grid,
                          _preview,
                          _dragIdx != null && _tray[_dragIdx!] != null
                              ? _palette[_tray[_dragIdx!]!.color]
                              : null,
                          _clearPreview,
                          {
                            for (final impact in _boardFx.impacts)
                              ...impact.cells
                          },
                          _boardRevision),
                    ))),
            Positioned.fill(
                child: IgnorePointer(
                    child: RepaintBoundary(
                        key: const ValueKey('block-board-fx'),
                        child: CustomPaint(
                          painter: BlockBoardFxPainter(
                              _fxClock, _boardFx, _grid, _palette, _preview),
                        )))),
            if (_battle != null && _battle!.status == 'countdown')
              Positioned.fill(
                  child: IgnorePointer(
                      child: ColoredBox(
                color: const Color(0xCC101F3B),
                child: Center(
                    child: Text(
                  '${max(1, (((_battle!.state!['startAt'] as int) - _battle!.now) / 1000).ceil())}',
                  key: const ValueKey('battle-countdown'),
                  style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD36A)),
                )),
              ))),
            if (_celebration != null)
              Positioned.fill(
                  child: BlockCelebration(
                      key: ValueKey(_celebrationId),
                      data: _celebration!,
                      compact: true)),
          ]),
        ));
  }

  /// Üç parçalık tepsi. [vertical]: yatay ekranda tahtanın yanında, [extent]
  /// yüksekliğinde üst üste üç bölme.
  /// iOS geri kaydırma şeridinin genişliği (Flutter: kBackGestureWidth).
  static const double _edge = 20;

  Widget _trayWidget(
      {bool vertical = false, double extent = 0, double cross = 0}) {
    // Dikey tepside 5 hücrelik parça hem 1/3 yüksekliğe hem sütun genişliğine
    // sığmalı.
    final tc = vertical
        ? min(_cell * 0.58, min(extent / 3 - 12, cross - 16) / 5)
        : min(_cell * 0.58,
            ((MediaQuery.sizeOf(context).width - 2 * _edge) / 3 - 12) / 5);
    return Container(
      height: vertical ? extent : tc * 5 + 16,
      // Kenardaki 20 px iOS'ta geri kaydırmaya ayrılır; parça sürüklemesi
      // oradan başlamaz.
      padding: vertical
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: _edge),
      child: Flex(
        direction: vertical ? Axis.vertical : Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < 3; i++)
            // Her parçanın seçim alanı, tepsinin 1/3'lük bölgesinin TAMAMIDIR;
            // parçanın tam üstüne basmaya gerek yok, o bölgeye dokunmak yeter.
            // Pointer dinleyicisi basıldığı anda kaldırır; jest eşiğini beklemez.
            // Tek aktif parmak izlenir; ikinci dokunuş sürüklemeyi devralamaz.
            Expanded(
              child: _tray[i] == null
                  ? const SizedBox.expand()
                  : Listener(
                      key: ValueKey('block-tray-$i'),
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) => _startDrag(i, event),
                      onPointerMove: (event) {
                        if (_dragPointer != event.pointer) return;
                        if ((event.position - _pointerDown).distance > 6) {
                          _dragMoved = true;
                        }
                        _updateDrag(event.position);
                      },
                      onPointerUp: (event) {
                        if (_dragPointer != event.pointer) return;
                        if (_dragMoved) {
                          _updateDrag(event.position);
                          _endDrag();
                        } else {
                          _cancelDrag();
                        }
                      },
                      onPointerCancel: (event) {
                        if (_dragPointer == event.pointer) _cancelDrag();
                      },
                      child: SizedBox.expand(
                        child: Center(
                          child: Opacity(
                            opacity: _dragIdx == i
                                ? 0.18
                                : (_game.canPlace(_tray[i]!) ? 1.0 : 0.35),
                            child: KeyedSubtree(
                                key: _trayKeys[i],
                                child: _pieceGrid(_tray[i]!, tc)),
                          ),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _pieceGrid(BlockPiece p, double cell) => SizedBox(
        width: p.cols * cell,
        height: p.rows * cell,
        child: CustomPaint(painter: _PiecePainter(p, _palette[p.color])),
      );

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      tooltip: icon == Icons.refresh_rounded ? 'Yeni oyun' : 'Oyunlara dön',
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _continueOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: SingleChildScrollView(
          child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 36),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 46)),
            const SizedBox(height: 8),
            const Text(
              'Sığacak yer kalmadı!',
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bir soruyu doğru bilirsen tahta temizlenir ve devam edersin.\n(Oyun başına yalnızca 1 hak)',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, height: 1.35, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            _bigBtn('Evet, soruyu göster 🧠',
                primary: true, onTap: _acceptContinue),
            const SizedBox(height: 10),
            _bigBtn('Hayır, bitir', primary: false, onTap: _declineContinue),
          ],
        ),
      )),
    );
  }

  Widget _quizOverlay() {
    final q = _reviveQ!;
    final answered = _reviveSelected != null;
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: AppTheme.bgElevated,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: q.category.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: q.category.color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'DEVAM SORUSU · ${q.category.label.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: q.category.color,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                q.question,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < q.options.length; i++) _reviveOption(i, q),
              const SizedBox(height: 4),
              Text(
                answered
                    ? (_reviveSelected == q.correctIndex
                        ? 'Doğru! Devam ediyorsun… 🎉'
                        : 'Yanlış… oyun bitiyor.')
                    : 'Doğru bilirsen oyun devam eder.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: answered
                      ? (_reviveSelected == q.correctIndex
                          ? AppTheme.success
                          : AppTheme.danger)
                      : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviveOption(int i, QuizQuestion q) {
    final sel = _reviveSelected;
    Color bg = AppTheme.surface;
    Color border = AppTheme.border;
    Color fg = AppTheme.textPrimary;
    if (sel != null) {
      final isCorrect = i == q.correctIndex;
      final isChosen = i == sel;
      if (isCorrect) {
        bg = AppTheme.success.withValues(alpha: 0.18);
        border = AppTheme.success;
      } else if (isChosen) {
        bg = AppTheme.danger.withValues(alpha: 0.18);
        border = AppTheme.danger;
      } else {
        fg = AppTheme.textMuted;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        behavior: HitTestBehavior.opaque,
        onTap: sel == null ? () => _answerRevive(i) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  String.fromCharCode(65 + i),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  q.options[i],
                  style: TextStyle(
                      fontSize: 14.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overOverlay(int best) {
    final screen = MediaQuery.sizeOf(context);
    // Kısa (yatay telefon) ekranda kart genişler, istatistikler tek satıra iner.
    final short = screen.height < 520 && screen.width > screen.height;
    final cardWidth = min(screen.width - 36, short ? 600.0 : 420.0);
    final cols = short ? 4 : 2;
    // 40 iç boşluk + 2 kenarlık; aşağı yuvarlanır ki karolar yan yana sığsın.
    final statWidth =
        ((cardWidth - 42 - 10 * (cols - 1)) / cols).floorToDouble();
    final summaryAvailable = _game.runSummaryAvailable;
    final recordColor = _newRecord ? const Color(0xFFFFD36A) : AppTheme.accent;
    return Container(
      color: const Color(0xD8091428),
      alignment: Alignment.center,
      child: SafeArea(
        child: FitPanel(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Container(
              key: const ValueKey('block-run-summary'),
              width: cardWidth,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF233B61), Color(0xFF14243F)],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                    color:
                        recordColor.withValues(alpha: _newRecord ? .62 : .28)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66050B16),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!short) ...[
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: recordColor.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                            color: recordColor.withValues(alpha: .34)),
                      ),
                      child: Icon(
                        _newRecord
                            ? Icons.emoji_events_rounded
                            : Icons.grid_view_rounded,
                        color: recordColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _newRecord ? 'YENİ REKOR!' : 'OYUN TAMAMLANDI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: recordColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _newRecord
                        ? 'Kendi rekorunu geçtin.'
                        : 'Sığacak yer kalmadı.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E1B30).withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'SKOR',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$_score',
                            key: const ValueKey('block-run-score'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.2,
                              shadows: [
                                Shadow(
                                  color: recordColor.withValues(alpha: .25),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'REKOR  ${max(best, _score)}',
                          style: const TextStyle(
                            color: Color(0xFFFFD36A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: statWidth,
                        child: _runStat(
                          'TEMİZLENEN ÇİZGİ',
                          summaryAvailable ? '${_game.linesCleared}' : '—',
                          Icons.view_week_rounded,
                          const Color(0xFF80E7DC),
                        ),
                      ),
                      SizedBox(
                        width: statWidth,
                        child: _runStat(
                          'EN İYİ KOMBO',
                          summaryAvailable ? '×${_game.bestCombo}' : '—',
                          Icons.bolt_rounded,
                          const Color(0xFFFFD36A),
                        ),
                      ),
                      SizedBox(
                        width: statWidth,
                        child: _runStat(
                          'ALL CLEAR',
                          summaryAvailable ? '${_game.allClears}' : '—',
                          Icons.auto_awesome_rounded,
                          const Color(0xFFC9A6FF),
                        ),
                      ),
                      SizedBox(
                        width: statWidth,
                        child: _runStat(
                          'YERLEŞTİRİLEN PARÇA',
                          summaryAvailable ? '${_game.placementsMade}' : '—',
                          Icons.extension_rounded,
                          const Color(0xFF8CB8FF),
                        ),
                      ),
                    ],
                  ),
                  if (!summaryAvailable) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Bu kayıt eski sürümden; bazı istatistikler tutulmamış.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _bigBtn('Tekrar Oyna', primary: true, onTap: _reset),
                  const SizedBox(height: 9),
                  _bigBtn('Oyunlara Dön',
                      primary: false,
                      onTap: () => Navigator.of(context).maybePop()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _runStat(String label, String value, IconData icon, Color color) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B30).withValues(alpha: .52),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: .065)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .45,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  key: ValueKey('block-stat-${label.toLowerCase()}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigBtn(String label,
      {required bool primary, required VoidCallback onTap}) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: primary ? AppTheme.pinkGradient : null,
          color: primary ? null : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(15),
          border: primary ? null : Border.all(color: AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: primary ? Colors.white : AppTheme.textSecondary,
            fontSize: primary ? 16 : 15,
            fontWeight: primary ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Izgarayı tek seferde çizer (64 widget yerine). Sürükleme sırasında yalnızca
/// bu boyanır; performans için hafiftir.
class _GridPainter extends CustomPainter {
  final List<List<int?>> grid;
  final Set<int> preview;
  final Color? previewColor;
  final Set<int> clearCells; // bırakınca silinecek hücreler (parlama)
  final Set<int> movingCells;
  final int boardRevision;
  _GridPainter(this.grid, this.preview, this.previewColor, this.clearCells,
      this.movingCells, this.boardRevision);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _n;
    const gap = 3.0;

    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        final rect = Rect.fromLTWH(
            c * cell + gap / 2, r * cell + gap / 2, cell - gap, cell - gap);
        Color? col = grid[r][c] == null || movingCells.contains(r * _n + c)
            ? null
            : _palette[grid[r][c]!];
        var alpha = 1.0;
        if (previewColor != null && preview.contains(r * _n + c)) {
          col = previewColor;
          alpha = 0.5;
        }
        paintEmptyCell(canvas, rect);
        if (col == null) continue;
        paintBlockCell(canvas, rect, col, alpha: alpha);
      }
    }

    // ── Silme önizlemesi: bırakınca tam dolacak satır/sütunlar parlasın ──
    if (clearCells.isNotEmpty) {
      final glow = Paint()
        ..color = const Color(0xFFFFE26A).withValues(alpha: .42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      final lit = Paint()
        ..color = const Color(0xFFFFF4C2).withValues(alpha: 0.48);
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFFFF7D6).withValues(alpha: .85);
      final glowPath = Path();
      for (final key in clearCells) {
        final r = key ~/ _n, c = key % _n;
        final rect = Rect.fromLTWH(
            c * cell + gap / 2, r * cell + gap / 2, cell - gap, cell - gap);
        glowPath.addRect(rect);
        canvas.drawRect(rect, lit); // parlak dolgu
        canvas.drawRect(rect.deflate(.5), edge); // parlak kenar
      }
      canvas.drawPath(
          glowPath, glow); // One cached preview halo, not 64 animated blurs.
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      boardRevision != old.boardRevision ||
      previewColor != old.previewColor ||
      !setEquals(preview, old.preview) ||
      !setEquals(clearCells, old.clearCells) ||
      !setEquals(movingCells, old.movingCells);
}

/// Tepsideki ve sürüklenen parça: hücreler tahtadakiyle aynı piksel bloklar.
class _PiecePainter extends CustomPainter {
  final BlockPiece piece;
  final Color color;
  _PiecePainter(this.piece, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / piece.cols;
    final gap = cell < 30 ? 2.0 : 3.0;
    for (final c in piece.cells) {
      paintBlockCell(
          canvas,
          Rect.fromLTWH(c[1] * cell + gap / 2, c[0] * cell + gap / 2,
              cell - gap, cell - gap),
          color);
    }
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.piece != piece || old.color != color;
}
