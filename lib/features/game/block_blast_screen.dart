import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
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
const List<List<List<int>>> _shapes = [
  [[0, 0]],
  [[0, 0], [0, 1]],
  [[0, 0], [1, 0]],
  [[0, 0], [0, 1], [0, 2]],
  [[0, 0], [1, 0], [2, 0]],
  [[0, 0], [0, 1], [0, 2], [0, 3]],
  [[0, 0], [1, 0], [2, 0], [3, 0]],
  [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
  [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]],
  [[0, 0], [0, 1], [1, 0], [1, 1]], // kare
  [[0, 0], [1, 0], [1, 1]], // L köşeler
  [[0, 1], [1, 0], [1, 1]],
  [[0, 0], [0, 1], [1, 0]],
  [[0, 0], [0, 1], [1, 1]],
  [[0, 0], [1, 0], [2, 0], [2, 1]], // J/L
  [[0, 1], [1, 1], [2, 0], [2, 1]],
  [[0, 0], [0, 1], [0, 2], [1, 0]],
  [[0, 0], [0, 1], [0, 2], [1, 2]],
  [[0, 0], [0, 1], [0, 2], [1, 1]], // T
  [[0, 1], [1, 0], [1, 1], [1, 2]],
  [[0, 1], [0, 2], [1, 0], [1, 1]], // S/Z
  [[0, 0], [0, 1], [1, 1], [1, 2]],
  [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2]], // 2x3
  [[0, 0], [0, 1], [1, 0], [1, 1], [2, 0], [2, 1]], // 3x2
  [[0, 1], [1, 0], [1, 1], [1, 2], [2, 1]], // artı
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
    _tray[0] = _newPiece();
    _tray[1] = _newPiece();
    _tray[2] = _newPiece();
    _score = 0;
    _over = false;
    _newRecord = false;
    _dragIdx = null;
    _preview = {};
    if (mounted) setState(() {});
  }

  _Piece _newPiece() => _Piece(
        _shapes[_rng.nextInt(_shapes.length)],
        _palette[_rng.nextInt(_palette.length)],
      );

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

  void _place(_Piece p, int tr, int tc, int idx) {
    for (final cell in p.cells) {
      _grid[tr + cell[0]][tc + cell[1]] = p.color;
    }
    _score += p.cells.length;
    _tray[idx] = null;
    HapticFeedback.lightImpact();
    _clearLines();
    if (_tray.every((e) => e == null)) {
      _tray[0] = _newPiece();
      _tray[1] = _newPiece();
      _tray[2] = _newPiece();
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
    _over = true;
    HapticFeedback.heavyImpact();
    ProgressService.instance.submitBlockScore(_score).then((rec) {
      if (mounted && rec) setState(() => _newRecord = true);
    });
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
    return Container(
      key: _gridKey,
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          for (var r = 0; r < _n; r++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < _n; c++)
                    Expanded(child: _gridCell(r, c)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _gridCell(int r, int c) {
    final filled = _grid[r][c];
    final isPreview = _preview.contains(r * _n + c);
    Color? color = filled;
    double alpha = 1;
    if (isPreview && _dragIdx != null) {
      color = _tray[_dragIdx!]!.color;
      alpha = 0.55;
    }
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: _cellBox(color, alpha: alpha),
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
                child: (_tray[i] == null || _dragIdx == i)
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        onPanStart: (d) => _startDrag(i, d.globalPosition),
                        onPanUpdate: (d) => _updateDrag(d.globalPosition),
                        onPanEnd: (_) => _endDrag(),
                        child: _pieceGrid(_tray[i]!, tc),
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
