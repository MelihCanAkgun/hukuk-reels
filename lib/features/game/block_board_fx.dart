import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Visual snapshots only. The engine commits placements/clears immediately.
/// One screen-owned clock drives all events; nothing allocates a ticker per cell.
class BlockBoardFx {
  final impacts = <BlockImpact>[];
  final _clears = <_ClearWave>[];
  int _seed = 0;
  int revision = 0;
  int get particleCount => _clears.fold(0, (n, e) => n + e.particles.length);
  bool get isEmpty => impacts.isEmpty && _clears.isEmpty;
  double get end => [
        ...impacts.map((e) => e.start + 170),
        ..._clears.map((e) => e.start + e.duration),
      ].fold(0.0, max);

  void add(double now, Set<int> placed, Map<int, int> cleared, int lines) {
    revision++;
    impacts.add(BlockImpact(now, placed));
    if (impacts.length > 3) impacts.removeAt(0);
    if (cleared.isEmpty) return;
    final wave = _ClearWave(now, cleared, lines, ++_seed);
    // Budget all concurrent clears together, including rapid consecutive moves.
    while (_clears.isNotEmpty &&
        (_clears.length >= 2 ||
            _clears.fold(0, (n, e) => n + e.particles.length) +
                    wave.particles.length >
                96)) {
      _clears.removeAt(0);
    }
    _clears.add(wave);
  }

  bool retire(double now) {
    final count = impacts.length + _clears.length;
    impacts.removeWhere((e) => now >= e.start + 170);
    _clears.removeWhere((e) => now >= e.start + e.duration);
    final changed = count != impacts.length + _clears.length;
    if (changed) revision++;
    return changed;
  }

  void reset() {
    impacts.clear();
    _clears.clear();
    revision++;
  }

  BlockImpact? impactAt(int key, double now) {
    for (final impact in impacts.reversed) {
      if (impact.cells.contains(key) && now < impact.start + 170) return impact;
    }
    return null;
  }
}

class BlockImpact {
  final double start;
  final Set<int> cells;
  late final Offset center;
  BlockImpact(this.start, Set<int> placed) : cells = Set.of(placed) {
    final xs = cells.map((k) => k % 8);
    final ys = cells.map((k) => k ~/ 8);
    center = Offset((xs.reduce(min) + xs.reduce(max) + 1) / 2,
        (ys.reduce(min) + ys.reduce(max) + 1) / 2);
  }

  void transform(Canvas canvas, double cell, double now) {
    final t = ((now - start) / 170).clamp(0.0, 1.0);
    final amount = t < .25
        ? Curves.easeOutCubic.transform(t / .25)
        : 1 - Curves.easeOutBack.transform((t - .25) / .75);
    final pivot = center * cell;
    canvas.translate(pivot.dx, pivot.dy);
    canvas.scale(1 + .05 * amount, 1 - .065 * amount);
    canvas.translate(-pivot.dx, -pivot.dy);
  }
}

class _ClearWave {
  final double start;
  final Map<int, int> cells;
  final double intensity;
  late final Offset center;
  late final double duration;
  final delays = <int, double>{};
  final particles = <_CellParticle>[];
  final tintPaint = Paint();
  final shockwavePaint = Paint()..style = PaintingStyle.stroke;
  final cellGlowPaint = Paint();
  final cellGlowEdgePaint = Paint()..style = PaintingStyle.stroke;

  _ClearWave(this.start, Map<int, int> snapshot, int lines, int seed)
      : cells = Map.of(snapshot),
        intensity = lines >= 4 ? 1.0 : (lines >= 2 ? .45 : 0.0) {
    center = cells.keys.fold(
            Offset.zero, (sum, k) => sum + Offset(k % 8 + .5, k ~/ 8 + .5)) /
        cells.length.toDouble();
    // Diagonal wave: adjacent cells differ by 28 ms, even at row intersections.
    final first = cells.keys.map((k) => k % 8 + k ~/ 8).reduce(min);
    for (final key in cells.keys) {
      delays[key] = (key % 8 + key ~/ 8 - first) * 28.0;
    }
    duration = delays.values.reduce(max) + 300;
    final random = Random(seed);
    final perCell = min(lines >= 4 ? 3 : 2, 96 ~/ cells.length);
    for (final entry in cells.entries) {
      for (var i = 0; i < perCell; i++) {
        final angle = (i + random.nextDouble() * .6) * pi * 2 / perCell;
        particles.add(_CellParticle(
            entry.key,
            entry.value,
            Offset(cos(angle), sin(angle)) *
                (.24 + random.nextDouble() * (.23 + intensity * .15)),
            .035 + random.nextDouble() * .025));
      }
    }
  }
}

class _CellParticle {
  final int key, color;
  final Offset velocity;
  final double radius;
  final Paint paint = Paint()..isAntiAlias = false;
  _CellParticle(this.key, this.color, this.velocity, this.radius);
}

// Piksel blok: kare hücre, açık üst/sol ve koyu alt/sağ kenar, köşede parıltı.
// Tonlar renk başına bir kez hesaplanır; tek Paint bütün dikdörtgenleri çizer.
final _shades = <Color, (Color, Color, Color)>{};
final _pixel = Paint()..isAntiAlias = false;

/// Kenar kalınlığı (bir "piksel"): hücrenin ~1/9'u, tam sayıya yuvarlı.
double blockPixel(double size) => max(1.0, (size * .11).roundToDouble());

void paintBlockCell(Canvas canvas, Rect rect, Color color, {double alpha = 1}) {
  if (rect.width <= 0 || rect.height <= 0) return;
  final (light, dark, glint) = _shades.putIfAbsent(
      color,
      () => (
            Color.lerp(color, Colors.white, .38)!,
            Color.lerp(color, Colors.black, .36)!,
            Color.lerp(color, Colors.white, .8)!,
          ));
  final x = rect.left, y = rect.top, w = rect.width, h = rect.height;
  final p = min(blockPixel(min(w, h)), min(w, h) / 3);
  void fill(Color c, double l, double t, double rw, double rh) =>
      canvas.drawRect(Rect.fromLTWH(l, t, rw, rh),
          _pixel..color = c.withValues(alpha: alpha));
  fill(color, x + p, y + p, w - 2 * p, h - 2 * p);
  fill(light, x, y, w - p, p);
  fill(light, x, y + p, p, h - 2 * p);
  fill(color, x + w - p, y, p, p);
  fill(color, x, y + h - p, p, p);
  fill(dark, x + w - p, y + p, p, h - p);
  fill(dark, x + p, y + h - p, w - 2 * p, p);
  if (w >= 6 * p) {
    fill(glint, x + 2 * p, y + 2 * p, 2 * p, p);
    fill(glint, x + 2 * p, y + 3 * p, p, p);
  }
}

/// Boş tahta hücresi: üst/sol kenarı gölgeli, içe gömük kare.
void paintEmptyCell(Canvas canvas, Rect rect) {
  final p = blockPixel(rect.width);
  canvas.drawRect(rect, _pixel..color = const Color(0xFF1C3153));
  _pixel.color = const Color(0xFF13233F);
  canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, p), _pixel);
  canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top + p, p, rect.height - p), _pixel);
}

class BlockBoardFxPainter extends CustomPainter {
  final Animation<double> clock;
  final BlockBoardFx fx;
  final List<List<int?>> grid;
  final List<Color> palette;
  final Set<int> preview;
  final int _revision;
  BlockBoardFxPainter(
      this.clock, this.fx, this.grid, this.palette, this.preview)
      : _revision = fx.revision,
        super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    final now = clock.value;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // Only moving cells repaint on clock ticks; the other 64 cells stay cached.
    for (final impact in fx.impacts) {
      canvas.save();
      impact.transform(canvas, cell, now);
      for (final key in impact.cells) {
        final color = grid[key ~/ 8][key % 8];
        if (color == null || fx.impactAt(key, now) != impact) continue;
        paintBlockCell(
            canvas,
            Rect.fromLTWH((key % 8) * cell + 1.5, (key ~/ 8) * cell + 1.5,
                cell - 3, cell - 3),
            palette[color]);
      }
      canvas.restore();
    }
    for (final wave in fx._clears) {
      final age = now - wave.start;
      if (wave.intensity == 1) {
        final t = (age / 380).clamp(0.0, 1.0);
        final fade = sin(pi * t) * (1 - t);
        // A single fine ring and quiet board tint, reserved for 4+ lines.
        wave.tintPaint.color =
            const Color(0xFFD7E9FF).withValues(alpha: fade * .045);
        canvas.drawRect(Offset.zero & size, wave.tintPaint);
        wave.shockwavePaint
          ..strokeWidth = cell * .035 * (1 - t)
          ..color = const Color(0xFFC9E2FF).withValues(alpha: fade * .34);
        canvas.drawCircle(
            wave.center * cell,
            size.width * (.05 + .65 * Curves.easeOutCubic.transform(t)),
            wave.shockwavePaint);
      }
      for (final entry in wave.cells.entries) {
        final t = ((age - wave.delays[entry.key]!) / 230).clamp(0.0, 1.0);
        // Old ghosts must never hide a newly placed block at the same location.
        if (t >= 1 ||
            preview.contains(entry.key) ||
            grid[entry.key ~/ 8][entry.key % 8] != null) {
          continue;
        }
        final color = palette[entry.value];
        final center = Offset(entry.key % 8 + .5, entry.key ~/ 8 + .5) * cell;
        final shrink = ((t - .24) / .76).clamp(0.0, 1.0);
        final scale = t < .24
            ? 1 + .1 * Curves.easeOutCubic.transform(t / .24)
            : 1.1 * (1 - Curves.easeInCubic.transform(shrink));
        final alpha = 1 - Curves.easeInQuad.transform(shrink);
        canvas.save();
        fx.impactAt(entry.key, now)?.transform(canvas, cell, now);
        final rect = Rect.fromCenter(
            center: center,
            width: (cell - 3) * scale,
            height: (cell - 3) * scale);
        final glow = sin(pi * t) * (.22 + wave.intensity * .10);
        if (glow > 0) {
          wave.cellGlowPaint.color =
              const Color(0xFFFFE5A0).withValues(alpha: glow);
          wave.cellGlowEdgePaint
            ..strokeWidth = cell * .045
            ..color = color.withValues(alpha: glow * .55);
          canvas.drawRect(rect.inflate(cell * .035), wave.cellGlowPaint);
          canvas.drawRect(rect.inflate(cell * .075), wave.cellGlowEdgePaint);
        }
        paintBlockCell(canvas, rect, color, alpha: alpha);
        canvas.restore();
      }
      for (final p in wave.particles) {
        final t = (age - wave.delays[p.key]! - 45) / 255;
        if (t <= 0 || t >= 1) continue;
        final origin = Offset(p.key % 8 + .5, p.key ~/ 8 + .5) * cell;
        final position = origin +
            p.velocity * cell * Curves.easeOutCubic.transform(t) +
            Offset(0, cell * .13 * t * t);
        // Piksel kırıntı: döndürülmeyen kare.
        final side = (p.radius * cell * 1.8 * (1 - .45 * t)).roundToDouble();
        p.paint.color =
            palette[p.color].withValues(alpha: .65 * min(1, t * 8) * (1 - t));
        canvas.drawRect(
            Rect.fromCenter(center: position, width: side, height: side),
            p.paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BlockBoardFxPainter old) =>
      old._revision != _revision ||
      old.clock != clock ||
      old.fx != fx ||
      old.grid != grid ||
      old.palette != palette ||
      !setEquals(old.preview, preview);
}
