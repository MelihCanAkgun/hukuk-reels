import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../core/data/questions_data.dart';
import '../../core/models/quiz_question.dart';
import '../../core/services/progress_service.dart';

/// Block Blast benzeri bulmaca: 8×8 ızgaraya 3 parçayı sürükleyip yerleştir;
/// dolan satır/sütunlar patlar. Hiçbir parça sığmazsa oyun biter.
class BlockBlastScreen extends StatefulWidget {
  const BlockBlastScreen({super.key});

  @override
  State<BlockBlastScreen> createState() => _BlockBlastScreenState();
}

const int _n = 8; // ızgara boyutu

// Parça şekilleri (normalize: min r=0, min c=0). [r,c] hücreleri.
// Tanıdık Block Blast / Tetris parçaları; her birinin dönüşleri dahil.
const List<List<List<int>>> _shapes = [
  // Tekli
  [[0, 0]],

  // İkili (yatay / dikey)
  [[0, 0], [0, 1]],
  [[0, 0], [1, 0]],

  // Üçlü çizgi
  [[0, 0], [0, 1], [0, 2]],
  [[0, 0], [1, 0], [2, 0]],

  // Dörtlü çizgi
  [[0, 0], [0, 1], [0, 2], [0, 3]],
  [[0, 0], [1, 0], [2, 0], [3, 0]],

  // Beşli çizgi
  [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
  [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]],

  // 2x2 kare
  [[0, 0], [0, 1], [1, 0], [1, 1]],

  // 3x3 kare
  [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2], [2, 0], [2, 1], [2, 2]],

  // Küçük L köşe (3 hücre) — 4 dönüş
  [[0, 0], [0, 1], [1, 0]],
  [[0, 0], [0, 1], [1, 1]],
  [[0, 0], [1, 0], [1, 1]],
  [[0, 1], [1, 0], [1, 1]],

  // L (4 hücre) — 4 dönüş
  [[0, 0], [1, 0], [2, 0], [2, 1]],
  [[0, 0], [0, 1], [0, 2], [1, 0]],
  [[0, 0], [0, 1], [1, 1], [2, 1]],
  [[0, 2], [1, 0], [1, 1], [1, 2]],

  // J (4 hücre) — 4 dönüş
  [[0, 1], [1, 1], [2, 0], [2, 1]],
  [[0, 0], [1, 0], [1, 1], [1, 2]],
  [[0, 0], [0, 1], [1, 0], [2, 0]],
  [[0, 0], [0, 1], [0, 2], [1, 2]],

  // T (4 hücre) — 4 dönüş
  [[0, 0], [0, 1], [0, 2], [1, 1]],
  [[0, 1], [1, 0], [1, 1], [1, 2]],
  [[0, 0], [1, 0], [1, 1], [2, 0]],
  [[0, 1], [1, 0], [1, 1], [2, 1]],

  // S / Z (4 hücre)
  [[0, 1], [0, 2], [1, 0], [1, 1]],
  [[0, 0], [1, 0], [1, 1], [2, 1]],
  [[0, 0], [0, 1], [1, 1], [1, 2]],
  [[0, 1], [1, 0], [1, 1], [2, 0]],

  // Dikdörtgenler
  [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2]], // 2x3
  [[0, 0], [0, 1], [1, 0], [1, 1], [2, 0], [2, 1]], // 3x2
];

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

// Kurtarıcı (rescue) şekiller: ≤3 hücreli küçükler — sıkışık tahtada sığması
// en olası ve rahatlatması en kolay olanlar.
final List<List<List<int>>> _smallShapes =
    _shapes.where((s) => s.length <= 3).toList();

// Kombo çubukları: tek satır/sütun, ≥3 uzunluk — çoklu silme potansiyeli.
final List<List<List<int>>> _barShapes = _shapes.where((s) {
  final mr = s.map((e) => e[0]).reduce(max);
  final mc = s.map((e) => e[1]).reduce(max);
  return (mr == 0 || mc == 0) && s.length >= 3;
}).toList();

class _Piece {
  final List<List<int>> cells;
  final Color color;
  final int rows, cols;
  _Piece(this.cells, this.color)
      : rows = cells.map((e) => e[0]).reduce(max) + 1,
        cols = cells.map((e) => e[1]).reduce(max) + 1;
  bool has(int r, int c) => cells.any((e) => e[0] == r && e[1] == c);
}

class _BlockBlastScreenState extends State<BlockBlastScreen> {
  final _rng = Random();
  final _gridKey = GlobalKey();
  final _stackKey = GlobalKey();

  late List<List<Color?>> _grid;
  final List<_Piece?> _tray = [null, null, null];
  int _score = 0;
  bool _over = false;
  bool _newRecord = false;

  // Devam etme (revive): oyun başına yalnızca 1 kez bir soruyla hak kazanılır.
  bool _reviveUsed = false;
  bool _askContinue = false;
  QuizQuestion? _reviveQ;
  int? _reviveSelected;

  double _cell = 40; // build'de hesaplanır
  static const double _lift = 16; // parmağın üstünde göstermek için

  int? _dragIdx;
  Offset _drawTL = Offset.zero; // sürüklenen parçanın sol-üstü (stack uzayı)
  int _tr = 0, _tc = 0;
  bool _valid = false;
  Set<int> _preview = {};

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _grid = List.generate(_n, (_) => List<Color?>.filled(_n, null));
    _refillTray();
    _score = 0;
    _over = false;
    _newRecord = false;
    _reviveUsed = false;
    _askContinue = false;
    _reviveQ = null;
    _reviveSelected = null;
    _dragIdx = null;
    _preview = {};
    if (mounted) setState(() {});
  }

  Color _randColor() => _palette[_rng.nextInt(_palette.length)];

  // ───────────── Akıllı taş üretimi (Shape Generation) ─────────────
  // Üç kural: (1) Dinamik kurtarma, (2) Kombo teşviki, (3) Zorluk eğrisi.
  // Tahta açıkken rastgele/zorlayıcı; doldukça kurtarıcı ve kombo şekiller
  // ağırlık kazanır. Set, her tepsi yenilemesinde tahtanın o anki formuna
  // göre üretilir.

  int _emptyCount() {
    var e = 0;
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_grid[r][c] == null) e++;
      }
    }
    return e;
  }

  /// Parçanın tahtada kaç farklı konuma sığdığı (yerleştirilebilirlik).
  int _placements(_Piece p) {
    var n = 0;
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_fits(p, r, c)) n++;
      }
    }
    return n;
  }

  /// Parça en uygun konuma konunca silinebilecek azami satır+sütun sayısı.
  int _clearPotential(_Piece p) {
    var best = 0;
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (!_fits(p, r, c)) continue;
        final l = _linesIfPlaced(p, r, c);
        if (l > best) best = l;
      }
    }
    return best;
  }

  /// Parça (tr,tc)'ye konursa kaç satır/sütun tamamen dolar.
  /// Yalnızca parçanın dokunduğu satır/sütunlar tamamlanabilir.
  int _linesIfPlaced(_Piece p, int tr, int tc) {
    final rowsT = <int>{};
    final colsT = <int>{};
    for (final cell in p.cells) {
      rowsT.add(tr + cell[0]);
      colsT.add(tc + cell[1]);
    }
    bool covered(int r, int c) => _grid[r][c] != null || p.has(r - tr, c - tc);
    var lines = 0;
    for (final r in rowsT) {
      var full = true;
      for (var c = 0; c < _n; c++) {
        if (!covered(r, c)) {
          full = false;
          break;
        }
      }
      if (full) lines++;
    }
    for (final c in colsT) {
      var full = true;
      for (var r = 0; r < _n; r++) {
        if (!covered(r, c)) {
          full = false;
          break;
        }
      }
      if (full) lines++;
    }
    return lines;
  }

  /// Tam dolmaya yalnızca 1 hücre kalan satır/sütun sayısı (kombo fırsatı).
  int _almostLineCount() {
    var n = 0;
    for (var r = 0; r < _n; r++) {
      var e = 0;
      for (var c = 0; c < _n; c++) {
        if (_grid[r][c] == null) e++;
      }
      if (e == 1) n++;
    }
    for (var c = 0; c < _n; c++) {
      var e = 0;
      for (var r = 0; r < _n; r++) {
        if (_grid[r][c] == null) e++;
      }
      if (e == 1) n++;
    }
    return n;
  }

  bool _isBar(List<List<int>> s) {
    final mr = s.map((e) => e[0]).reduce(max);
    final mc = s.map((e) => e[1]).reduce(max);
    return (mr == 0 || mc == 0) && s.length >= 3;
  }

  List<List<int>> _weightedPick(
      List<List<List<int>>> cands, List<double> scores) {
    var total = 0.0;
    for (final w in scores) {
      total += w < 0.1 ? 0.1 : w;
    }
    var r = _rng.nextDouble() * total;
    for (var i = 0; i < cands.length; i++) {
      final w = scores[i] < 0.1 ? 0.1 : scores[i];
      if ((r -= w) <= 0) return cands[i];
    }
    return cands.last;
  }

  /// Kural 1: tahtayı rahatlatacak şekil. Sığan küçükler arasından; bir
  /// satır/sütun silebilecek olanlar ve çok yerleşim noktası olanlar öncelikli.
  List<List<int>> _rescueShape() {
    final cands = <List<List<int>>>[];
    final scores = <double>[];
    for (final s in _smallShapes) {
      final p = _Piece(s, _palette[0]);
      final pc = _placements(p);
      if (pc == 0) continue;
      final clears = _clearPotential(p);
      cands.add(s);
      scores.add(pc + (clears > 0 ? 40.0 : 0.0) - s.length * 3.0);
    }
    if (cands.isEmpty) {
      // Hiç küçük şekil sığmıyorsa sığan herhangi biri, o da yoksa 1x1.
      for (final s in _shapes) {
        if (_placements(_Piece(s, _palette[0])) > 0) return s;
      }
      return const [
        [0, 0]
      ];
    }
    return _weightedPick(cands, scores);
  }

  /// Kural 2: kombo/çoklu-silme potansiyelini büyüten şekil. Şu an bir
  /// satır/sütun silebilecek (özellikle çok sayıda) şekiller ve uzun çubuklar
  /// öne çıkar.
  List<List<int>> _comboShape() {
    final cands = <List<List<int>>>[];
    final scores = <double>[];
    for (final s in _shapes) {
      final p = _Piece(s, _palette[0]);
      if (_placements(p) == 0) continue;
      final clears = _clearPotential(p);
      if (clears <= 0) continue;
      cands.add(s);
      scores.add(1.0 + clears * 30.0 + (_isBar(s) ? 12.0 : 0.0));
    }
    if (cands.isEmpty) {
      // Şu an silen yoksa gelecekteki kombo için sığan bir uzun çubuk ver.
      final bars = _barShapes
          .where((s) => _placements(_Piece(s, _palette[0])) > 0)
          .toList();
      if (bars.isNotEmpty) return bars[_rng.nextInt(bars.length)];
      return _rescueShape();
    }
    return _weightedPick(cands, scores);
  }

  List<List<int>> _randomShape() => _shapes[_rng.nextInt(_shapes.length)];

  /// Tahtanın o anki formuna göre 3'lü taş seti üretir.
  List<_Piece> _genSet() {
    final total = _n * _n;
    final fill = (total - _emptyCount()) / total; // 0..1 doluluk
    var fitForms = 0;
    for (final s in _shapes) {
      if (_placements(_Piece(s, _palette[0])) > 0) fitForms++;
    }
    final formRatio = fitForms / _shapes.length; // 1 = her şekil sığıyor
    final almost = _almostLineCount();

    // Baskı: doluluk + sığmayan şekil oranı. Açık tahtada ~0, sıkışıkta ~1.
    final pressure = (fill * 0.6 + (1 - formRatio) * 0.8).clamp(0.0, 1.0);

    final out = <_Piece>[];
    for (var i = 0; i < 3; i++) {
      final roll = _rng.nextDouble();
      List<List<int>> shape;
      if (almost > 0 && roll < 0.22 + 0.28 * pressure) {
        shape = _comboShape(); // kural 2 — kombo fırsatı varken
      } else if (roll < 0.2 + 0.85 * pressure) {
        shape = _rescueShape(); // kural 1 — baskı arttıkça olasılık artar
      } else {
        shape = _randomShape(); // kural 3 — açıkken zorlayıcı/rastgele
      }
      out.add(_Piece(shape, _randColor()));
    }

    // Güvenlik ağı: tahta sıkışıkken hiç sığmayan parçaları kurtarıcıyla
    // değiştir; setin tamamen tıkanmasını engelle (erken game over'ı azaltır).
    if (pressure > 0.38) {
      for (var i = 0; i < 3; i++) {
        if (_placements(out[i]) == 0) {
          out[i] = _Piece(_rescueShape(), _randColor());
        }
      }
      if (!out.any((p) => _placements(p) > 0)) {
        out[0] = _Piece(_rescueShape(), _randColor());
      }
    }
    return out;
  }

  /// Tepsiyi akıllı set ile doldurur.
  void _refillTray() {
    final set = _genSet();
    _tray[0] = set[0];
    _tray[1] = set[1];
    _tray[2] = set[2];
  }

  bool _fits(_Piece p, int tr, int tc) {
    for (final cell in p.cells) {
      final r = tr + cell[0], c = tc + cell[1];
      if (r < 0 || r >= _n || c < 0 || c >= _n) return false;
      if (_grid[r][c] != null) return false;
    }
    return true;
  }

  bool _canPlaceAnywhere(_Piece p) {
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_fits(p, r, c)) return true;
      }
    }
    return false;
  }

  bool get _anyMove =>
      _tray.any((p) => p != null && _canPlaceAnywhere(p));

  // ── Sürükleme ──
  void _startDrag(int i, Offset global) {
    _dragIdx = i;
    _updateDrag(global);
  }

  void _updateDrag(Offset global) {
    final stackBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || gridBox == null || _dragIdx == null) return;
    final p = _tray[_dragIdx!];
    if (p == null) return;

    final local = stackBox.globalToLocal(global);
    final gridTL = stackBox.globalToLocal(gridBox.localToGlobal(Offset.zero));
    final wpx = p.cols * _cell, hpx = p.rows * _cell;
    _drawTL = local - Offset(wpx / 2, hpx + _lift);

    final rel = _drawTL - gridTL;
    _tc = (rel.dx / _cell).round();
    _tr = (rel.dy / _cell).round();
    _valid = _fits(p, _tr, _tc);
    _preview = _valid
        ? {for (final cell in p.cells) (_tr + cell[0]) * _n + (_tc + cell[1])}
        : {};
    setState(() {});
  }

  void _endDrag() {
    if (_dragIdx != null && _valid) {
      _place(_tray[_dragIdx!]!, _tr, _tc, _dragIdx!);
    }
    _dragIdx = null;
    _preview = {};
    setState(() {});
  }

  void _cancelDrag() {
    _dragIdx = null;
    _preview = {};
    if (mounted) setState(() {});
  }

  void _place(_Piece p, int tr, int tc, int idx) {
    for (final cell in p.cells) {
      _grid[tr + cell[0]][tc + cell[1]] = p.color;
    }
    _score += p.cells.length;
    _tray[idx] = null;
    HapticFeedback.lightImpact();
    _clearLines();
    if (_tray.every((e) => e == null)) {
      _refillTray();
    }
    if (!_anyMove) _gameOver();
  }

  void _clearLines() {
    final rows = <int>[], cols = <int>[];
    for (var r = 0; r < _n; r++) {
      if (List.generate(_n, (c) => _grid[r][c]).every((e) => e != null)) {
        rows.add(r);
      }
    }
    for (var c = 0; c < _n; c++) {
      if (List.generate(_n, (r) => _grid[r][c]).every((e) => e != null)) {
        cols.add(c);
      }
    }
    final cleared = rows.length + cols.length;
    if (cleared == 0) return;
    for (final r in rows) {
      for (var c = 0; c < _n; c++) _grid[r][c] = null;
    }
    for (final c in cols) {
      for (var r = 0; r < _n; r++) _grid[r][c] = null;
    }
    // Puan: temizlenen başına 10, çoklu temizlikte kombo bonusu.
    _score += cleared * 10 + (cleared > 1 ? (cleared - 1) * 15 : 0);
    HapticFeedback.mediumImpact();
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
    HapticFeedback.heavyImpact();
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
    setState(() {
      _askContinue = false;
      _reviveSelected = null;
      _reviveQ = kQuestions[_rng.nextInt(kQuestions.length)]
          .withShuffledOptions(_rng);
    });
  }

  void _answerRevive(int i) {
    if (_reviveSelected != null) return; // tek seçim hakkı
    setState(() => _reviveSelected = i);
    final correct = i == _reviveQ!.correctIndex;
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 1200), () {
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
      _reviveUsed = true;
      _reviveQ = null;
      _reviveSelected = null;
      _grid = List.generate(_n, (_) => List<Color?>.filled(_n, null));
      if (_tray.every((e) => e == null)) {
        _refillTray();
      }
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final best = ProgressService.instance.blockHigh;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
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
                        final gridSize =
                            min(c.maxWidth - 28, 384).toDouble();
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
                Positioned(
                  left: _drawTL.dx,
                  top: _drawTL.dy,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.95,
                      child: _pieceGrid(_tray[_dragIdx!]!, _cell),
                    ),
                  ),
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
          _circleBtn(Icons.arrow_back_rounded,
              () => Navigator.of(context).maybePop()),
          const SizedBox(width: 6),
          const Text('🧩', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Text(
            'Block Blast',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          _circleBtn(Icons.refresh_rounded, _reset),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text('$best',
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreText() => Text(
        '$_score',
        style: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary,
        ),
      );

  Widget _gridWidget(double size) {
    // 64 ayrı widget yerine tek CustomPaint — sürükleme akıcı olsun.
    return Container(
      key: _gridKey,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: _GridPainter(
            _grid,
            _preview,
            _dragIdx != null ? _tray[_dragIdx!]?.color : null,
          ),
        ),
      ),
    );
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
    final tc = _cell * 0.58;
    return SizedBox(
      height: tc * 5 + 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Center(
                child: _tray[i] == null
                    ? const SizedBox.shrink()
                    // ÖNEMLİ: sürükleme başlayınca bu GestureDetector ağaçtan
                    // kalkmamalı (yoksa onPanUpdate/End hiç tetiklenmez ve parça
                    // takılı kalır). Sürüklenen parçayı yalnızca soluklaştırıyoruz.
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (d) => _startDrag(i, d.globalPosition),
                        onPanUpdate: (d) => _updateDrag(d.globalPosition),
                        onPanEnd: (_) => _endDrag(),
                        onPanCancel: _cancelDrag,
                        child: Opacity(
                          opacity: _dragIdx == i ? 0.22 : 1.0,
                          child: _pieceGrid(_tray[i]!, tc),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pieceGrid(_Piece p, double cell) {
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
                          child: _cellBox(p.color),
                        )
                      : null,
                ),
            ],
          ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 20),
      ),
    );
  }

  Widget _continueOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      alignment: Alignment.center,
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
                  fontSize: 13.5,
                  height: 1.35,
                  color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            _bigBtn('Evet, soruyu göster 🧠',
                primary: true, onTap: _acceptContinue),
            const SizedBox(height: 10),
            _bigBtn('Hayır, bitir', primary: false, onTap: _declineContinue),
          ],
        ),
      ),
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
                  border:
                      Border.all(color: q.category.color.withValues(alpha: 0.5)),
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
              for (var i = 0; i < q.options.length; i++)
                _reviveOption(i, q),
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
            Text(_newRecord ? '🎉' : '🧱', style: const TextStyle(fontSize: 48)),
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
            _bigBtn('Profile Dön',
                primary: false,
                onTap: () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
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
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

/// Izgarayı tek seferde çizer (64 widget yerine). Sürükleme sırasında yalnızca
/// bu boyanır; performans için hafiftir.
class _GridPainter extends CustomPainter {
  final List<List<Color?>> grid;
  final Set<int> preview;
  final Color? previewColor;
  _GridPainter(this.grid, this.preview, this.previewColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _n;
    const gap = 3.0;
    final empty = Paint()..color = AppTheme.surface.withValues(alpha: 0.5);
    final radius = Radius.circular(cell * 0.16);

    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
              c * cell + gap / 2, r * cell + gap / 2, cell - gap, cell - gap),
          radius,
        );
        Color? col = grid[r][c];
        var alpha = 1.0;
        if (previewColor != null && preview.contains(r * _n + c)) {
          col = previewColor;
          alpha = 0.5;
        }
        if (col == null) {
          canvas.drawRRect(rect, empty);
          continue;
        }
        canvas.drawRRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(col, Colors.white, 0.25)!.withValues(alpha: alpha),
                col.withValues(alpha: alpha),
              ],
            ).createShader(rect.outerRect),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.white.withValues(alpha: 0.18 * alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => true;
}
