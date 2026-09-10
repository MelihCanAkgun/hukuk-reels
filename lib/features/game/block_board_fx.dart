import 'dart:math';
import 'package:flutter/material.dart';

/// Visual snapshots only. The engine commits placements/_clears immediately.
/// One screen-owned clock drives all events; nothing allocates a ticker per cell.
class BlockBoardFx {
  final impacts = <BlockImpact>[];
  final _clears = <_ClearWave>[];
  int _seed = 0;
  int get particleCount => _clears.fold(0, (n, e) => n + e.particles.length);
  bool get isEmpty => impacts.isEmpty && _clears.isEmpty;
  double get end => [
        ...impacts.map((e) => e.start + 170),
        ..._clears.map((e) => e.start + e.duration),
      ].fold(0.0, max);

  void add(double now, Set<int> placed, Map<int, int> cleared, int lines) {
    impacts.add(BlockImpact(now, placed));
    if (impacts.length > 3) impacts.removeAt(0);
    if (cleared.isEmpty) return;
    final wave = _ClearWave(now, cleared, lines, ++_seed);
    // Budget all concurrent _clears together, including rapid consecutive moves.
    while (_clears.isNotEmpty &&
        (_clears.length >= 2 ||
            _clears.fold(0, (n, e) => n + e.particles.length) +
                    wave.particles.length >
                160)) {
      _clears.removeAt(0);
    }
    _clears.add(wave);
  }

  bool retire(double now) {
    final count = impacts.length + _clears.length;
    impacts.removeWhere((e) => now >= e.start + 170);
    _clears.removeWhere((e) => now >= e.start + e.duration);
    return count != impacts.length + _clears.length;
  }

  void reset() {
    impacts.clear();
    _clears.clear();
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
    final perCell =
        min(lines >= 4 ? 4 : (lines >= 2 ? 3 : 2), 128 ~/ cells.length);
    for (final entry in cells.entries) {
      for (var i = 0; i < perCell; i++) {
        final angle = (i + random.nextDouble() * .6) * pi * 2 / perCell;
        particles.add(_CellParticle(
            entry.key,
            entry.value,
            Offset(cos(angle), sin(angle)) *
                (.24 + random.nextDouble() * (.23 + intensity * .15)),
            .035 + random.nextDouble() * .025,
            random.nextDouble() * pi,
            (random.nextDouble() - .5) * 2.2));
      }
    }
  }
}

class _CellParticle {
  final int key, color;
  final Offset velocity;
  final double radius, rotation, spin;
  const _CellParticle(this.key, this.color, this.velocity, this.radius,
      this.rotation, this.spin);
}

/// Shared block finish prevents an initial flash when a cell becomes an FX ghost.
void paintBlockCell(Canvas canvas, RRect rect, Color color,
    {double alpha = 1}) {
  canvas.drawRRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, .25)!.withValues(alpha: alpha),
            color.withValues(alpha: alpha),
          ],
        ).createShader(rect.outerRect));
  canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .18 * alpha));
}

class BlockBoardFxPainter extends CustomPainter {
  final Animation<double> clock;
  final BlockBoardFx fx;
  final List<List<int?>> grid;
  final List<Color> palette;
  final Set<int> preview;
  BlockBoardFxPainter(
      this.clock, this.fx, this.grid, this.palette, this.preview)
      : super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    final now = clock.value;
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)));
    for (final wave in fx._clears) {
      final age = now - wave.start;
      if (wave.intensity == 1) {
        final t = (age / 380).clamp(0.0, 1.0);
        final fade = sin(pi * t) * (1 - t);
        // A single fine ring and quiet board tint, reserved for 4+ lines.
        canvas.drawRect(
            Offset.zero & size,
            Paint()
              ..color = const Color(0xFFD7E9FF).withValues(alpha: fade * .045));
        canvas.drawCircle(
            wave.center * cell,
            size.width * (.05 + .65 * Curves.easeOutCubic.transform(t)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = cell * .035 * (1 - t)
              ..color = const Color(0xFFC9E2FF).withValues(alpha: fade * .34));
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
        final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: center,
                width: (cell - 3) * scale,
                height: (cell - 3) * scale),
            Radius.circular(cell * .16 * scale));
        final glow = sin(pi * t) * (.12 + wave.intensity * .10);
        if (glow > 0) {
          canvas.drawRRect(
              rect.inflate(cell * .035),
              Paint()
                ..color = color.withValues(alpha: glow)
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * .065));
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
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(p.rotation + p.spin * t);
        final radius = p.radius * cell * (1 - .45 * t);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset.zero,
                    width: radius * 1.5,
                    height: radius * 2),
                Radius.circular(radius * .35)),
            Paint()
              ..color = palette[p.color]
                  .withValues(alpha: .65 * min(1, t * 8) * (1 - t)));
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BlockBoardFxPainter old) => true;
}
