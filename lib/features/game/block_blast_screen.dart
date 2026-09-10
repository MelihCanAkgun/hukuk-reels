import 'dart:async';
import 'dart:math';
import 'block_blast_engine.dart';
import 'block_celebration.dart';
import 'block_board_fx.dart';
import 'block_leaderboard.dart';
import '../../core/services/social_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../core/data/questions_data.dart';
import '../../core/models/quiz_question.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/sfx_service.dart';
import '../reels/widgets/music_button.dart';

/// Block Blast benzeri bulmaca: 8×8 ızgaraya 3 parçayı sürükleyip yerleştir;
/// dolan satır/sütunlar patlar. Hiçbir parça sığmazsa oyun biter.
class BlockBlastScreen extends StatefulWidget {
  const BlockBlastScreen({super.key});

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _rng = Random();
  final _gridKey = GlobalKey();
  final _stackKey = GlobalKey();

  late BlockBlastEngine _game;
  List<List<int?>> get _grid => _game.grid;
  List<BlockPiece?> get _tray => _game.tray;
  int get _score => _game.score;
  late final AnimationController _fxClock;
  final _boardFx = BlockBoardFx();
  String _feedback = '';
  BlockCelebrationData? _celebration;
  int _celebrationId = 0;
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
  static const double _lift = 64; // parmağın belirgin şekilde üstünde göster

  int? _dragIdx;
  final _dragPosition = ValueNotifier<Offset>(Offset.zero);
  int? _dragPointer;
  Offset _pointerDown = Offset.zero;
  bool _dragMoved = false;
  double _dragGain = 2.2;
  Offset _dragAnchor = Offset.zero; // sürükleme başında parmak (stack uzayı)
  Offset _anchorTL = Offset.zero; // sürükleme başında parçanın sol-üstü
  bool _dragHasAnchor = false;
  // Kaydırma hassasiyeti: parmak hareketi bu katsayıyla büyütülür (>1 = aynı
  // mesafeye daha az parmak hareketiyle ulaşılır).

  int _tr = 0, _tc = 0;
  bool _valid = false;
  Set<int> _preview = {};
  Set<int> _clearPreview = {}; // bırakınca silinecek (tam dolacak) hücreler

  @override
  void initState() {
    super.initState();
    unawaited(socialCall('init', {'url': socialApiUrl}).then((_) =>
        socialCall('score', {'score': ProgressService.instance.blockHigh})));
    SfxService.instance.init(); // efektleri önceden yükle (düşük gecikme)
    WidgetsBinding.instance.addObserver(this);
    _fxClock = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (_boardFx.retire(_fxClock.value) && mounted) setState(() {});
      });
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
    _fxClock.dispose();
    _dragPosition.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _cancelDrag();
  }

  @override
  void didChangeMetrics() {
    if (_dragIdx != null) _cancelDrag();
  }

  void _save() {
    unawaited(socialCall('score', {'score': _score}));
    unawaited(ProgressService.instance.saveBlockGame(_game.toJson()));
    final run = _run;
    unawaited(ProgressService.instance.submitBlockScore(_score).then((record) {
      if (mounted && run == _run && record) setState(() => _newRecord = true);
    }));
  }

  void _reset() {
    _run++;
    _reviveTimer?.cancel();
    _fxClock.stop();
    _boardFx.reset();
    _feedback = '';
    _celebration = null;
    _game = BlockBlastEngine(random: _rng);
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
    if (_dragIdx != null || _over || _askContinue || _reviveQ != null) {
      return;
    }
    _dragPointer = event.pointer;
    _pointerDown = event.position;
    _dragMoved = false;
    _dragGain = event.kind == PointerDeviceKind.mouse ? 1.0 : 2.2;
    _valid = false;
    _dragIdx = i;
    _dragHasAnchor = false;
    _updateDrag(event.position);
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _updateDrag(Offset global) {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || gridBox == null || _dragIdx == null) return;
    final p = _tray[_dragIdx!];
    if (p == null) return;

    final local = stackBox.globalToLocal(global);
    final gridTL = stackBox.globalToLocal(gridBox.localToGlobal(Offset.zero));
    final wpx = p.cols * _cell, hpx = p.rows * _cell;

    // Başlangıç çapasını sabitle: parça ilk anda parmağın üstünde belirir.
    if (!_dragHasAnchor) {
      _dragAnchor = local;
      _anchorTL = local - Offset(wpx / 2, hpx + _lift);
      _dragHasAnchor = true;
    }
    // Parmak hareketini büyüterek uygula (hassasiyet).
    final target = _anchorTL + (local - _dragAnchor) * _dragGain;
    // The piece always stays above the finger, including downward corrections.
    _dragPosition.value =
        Offset(target.dx, min(target.dy, local.dy - hpx - 32));

    final oldRow = _tr, oldCol = _tc;
    final wasValid = _valid;
    final rel = _dragPosition.value - gridTL;
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
    }
    _dragIdx = null;
    _dragPointer = null;
    _valid = false;
    _preview = {};
    _clearPreview = {};
    setState(() {});
  }

  void _cancelDrag() {
    _dragIdx = null;
    _dragPointer = null;
    _valid = false;
    _preview = {};
    _clearPreview = {};
    if (mounted) setState(() {});
  }

  void _place(BlockPiece p, int tr, int tc, int idx) {
    final move = _game.place(idx, tr, tc);
    if (move == null) return;
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
    if (!_game.hasMove) _gameOver();
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
      _reviveQ = null;
      _reviveSelected = null;
    });
    _save();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final best = ProgressService.instance.blockHigh;
    return Scaffold(
      backgroundColor: const Color(0xFF182B50),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF294879), Color(0xFF172849)],
        )),
        child: SafeArea(
          child: Stack(
            key: _stackKey,
            children: [
              Column(
                children: [
                  _topBar(best),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final gridSize = min(min(c.maxWidth - 28, 440),
                                max(80, (c.maxHeight - 134) / 1.37))
                            .toDouble();
                        _cell = gridSize / _n;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _scoreText(),
                            _gridWidget(gridSize),
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
                ValueListenableBuilder<Offset>(
                  valueListenable: _dragPosition,
                  child: IgnorePointer(
                      child: RepaintBoundary(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.72, end: 1.0),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 80),
                      curve: Curves.easeOutCubic,
                      child: _pieceGrid(_tray[_dragIdx!]!, _cell),
                      builder: (context, scale, child) => Transform.scale(
                          key: const ValueKey('block-drag-feedback'),
                          scale: scale,
                          alignment: Alignment.bottomCenter,
                          child: child),
                    ),
                  )),
                  builder: (context, position, child) => Positioned(
                      left: position.dx, top: position.dy, child: child!),
                ),

              if (_askContinue) _continueOverlay(),
              if (_reviveQ != null) _quizOverlay(),
              if (_over) _overOverlay(best),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(int best) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 14, 4),
      child: Row(
        children: [
          _circleBtn(
              Icons.arrow_back_rounded, () => Navigator.of(context).maybePop()),
          const SizedBox(width: 6),
          const Text('🧩', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Expanded(
              child: Text(
            'Block Blast',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          )),
          IconButton(
            tooltip: 'İkimizin sıralaması',
            icon:
                const Icon(Icons.leaderboard_rounded, color: Color(0xFFFFD76A)),
            onPressed: () {
              _cancelDrag();
              Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const BlockLeaderboard()));
            },
          ),
          const MusicButton(),
          const SizedBox(width: 8),
          _circleBtn(Icons.refresh_rounded, _reset),
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
              Text('🏆 ${ProgressService.instance.blockHigh}',
                  style: const TextStyle(
                      color: Color(0xFFFFD36A), fontWeight: FontWeight.w700)),
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
              Text(
                  _game.combo > 0
                      ? 'KOMBO ×${_game.combo} · ${BlockBlastEngine.comboGrace - _game.misses} hamle'
                      : 'Bir satır veya sütun doldur',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFFFFD36A))),
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
          decoration: BoxDecoration(
            color: const Color(0xFF101F3B),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(children: [
            Positioned.fill(
                child: RepaintBoundary(
                    child: CustomPaint(
              painter: _GridPainter(
                  _grid,
                  _preview,
                  _dragIdx != null && _tray[_dragIdx!] != null
                      ? _palette[_tray[_dragIdx!]!.color]
                      : null,
                  _clearPreview,
                  _fxClock,
                  _boardFx),
            ))),
            Positioned.fill(
                child: IgnorePointer(
                    child: RepaintBoundary(
                        child: CustomPaint(
              painter: BlockBoardFxPainter(
                  _fxClock, _boardFx, _grid, _palette, _preview),
            )))),
            if (_celebration != null)
              Positioned.fill(
                  child: BlockCelebration(
                      key: ValueKey(_celebrationId),
                      data: _celebration!,
                      compact: true)),
          ]),
        ));
  }

  Widget _cellBox(Color? color, {double alpha = 1}) {
    if (color == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.25)!.withValues(alpha: alpha),
            color.withValues(alpha: alpha),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18 * alpha),
          width: 1,
        ),
      ),
    );
  }

  Widget _trayWidget() {
    final tc =
        min(_cell * 0.58, (MediaQuery.sizeOf(context).width / 3 - 12) / 5);
    return SizedBox(
      height: tc * 5 + 16,
      child: Row(
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
                            child: _pieceGrid(_tray[i]!, tc),
                          ),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _pieceGrid(BlockPiece p, double cell) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < p.rows; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < p.cols; c++)
                SizedBox(
                  width: cell,
                  height: cell,
                  child: p.has(r, c)
                      ? Padding(
                          padding: const EdgeInsets.all(1.5),
                          child: _cellBox(_palette[p.color]),
                        )
                      : null,
                ),
            ],
          ),
      ],
    );
  }

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
      child: GestureDetector(
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
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: SingleChildScrollView(
          child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_newRecord ? '🎉' : '🧱',
                style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text(
              _newRecord ? 'Yeni Rekor!' : 'Oyun Bitti',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text('Sığacak yer kalmadı.',
                style:
                    TextStyle(fontSize: 13.5, color: AppTheme.textSecondary)),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _scoreBox('Skor', '$_score', AppTheme.accent),
                const SizedBox(width: 14),
                _scoreBox('Rekor', '$best', AppTheme.success),
              ],
            ),
            const SizedBox(height: 22),
            _bigBtn('Tekrar Oyna', primary: true, onTap: _reset),
            const SizedBox(height: 10),
            _bigBtn('Oyunlara Dön',
                primary: false, onTap: () => Navigator.of(context).maybePop()),
          ],
        ),
      )),
    );
  }

  Widget _bigBtn(String label,
      {required bool primary, required VoidCallback onTap}) {
    return GestureDetector(
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

  Widget _scoreBox(String label, String value, Color color) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
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
  final Animation<double> clock;
  final BlockBoardFx fx;
  _GridPainter(this.grid, this.preview, this.previewColor, this.clearCells,
      this.clock, this.fx)
      : super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _n;
    const gap = 3.0;
    final empty = Paint()..color = const Color(0xFF1C3153);
    final radius = Radius.circular(cell * 0.16);

    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
              c * cell + gap / 2, r * cell + gap / 2, cell - gap, cell - gap),
          radius,
        );
        Color? col = grid[r][c] == null ? null : _palette[grid[r][c]!];
        var alpha = 1.0;
        if (previewColor != null && preview.contains(r * _n + c)) {
          col = previewColor;
          alpha = 0.5;
        }
        if (col == null) {
          canvas.drawRRect(rect, empty);
          continue;
        }
        canvas.drawRRect(rect, empty);
        canvas.save();
        if (grid[r][c] != null) {
          fx
              .impactAt(r * _n + c, clock.value)
              ?.transform(canvas, cell, clock.value);
        }
        paintBlockCell(canvas, rect, col, alpha: alpha);
        canvas.restore();
      }
    }

    // ── Silme önizlemesi: bırakınca tam dolacak satır/sütunlar parlasın ──
    if (clearCells.isNotEmpty) {
      final glow = Paint()
        ..color = const Color(0xFFFFE26A).withValues(alpha: .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      final lit = Paint()
        ..color = const Color(0xFFFFF4C2).withValues(alpha: 0.18);
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFFFF7D6).withValues(alpha: .55);
      for (final key in clearCells) {
        final r = key ~/ _n, c = key % _n;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
              c * cell + gap / 2, r * cell + gap / 2, cell - gap, cell - gap),
          radius,
        );
        canvas.drawRRect(rect, glow); // hale
        canvas.drawRRect(rect, lit); // parlak dolgu
        canvas.drawRRect(rect, edge); // parlak kenar
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => true;
}
