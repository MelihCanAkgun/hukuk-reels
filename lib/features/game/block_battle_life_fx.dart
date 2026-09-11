import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/services/sfx_service.dart';
import 'block_battle_session.dart';

/// Visual observer only: never sends actions or writes a match snapshot.
class BattleLifeFeedback extends StatefulWidget {
  final BlockBattleSession? session;
  final Widget child;
  const BattleLifeFeedback(
      {super.key, required this.session, required this.child});
  @override
  State<BattleLifeFeedback> createState() => _BattleLifeFeedbackState();
}

class _BattleLifeFeedbackState extends State<BattleLifeFeedback>
    with TickerProviderStateMixin {
  late final _hit = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 480));
  late final _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));
  int? _lives;
  int _lost = 0;
  bool _reduced = false;
  @override
  void initState() {
    super.initState();
    _lives = widget.session?.mine?['lives'] as int?;
    widget.session?.addListener(_observe);
  }

  @override
  void didUpdateWidget(BattleLifeFeedback old) {
    super.didUpdateWidget(old);
    if (old.session != widget.session) {
      old.session?.removeListener(_observe);
      _lives = widget.session?.mine?['lives'] as int?;
      widget.session?.addListener(_observe);
      _hit.reset();
      _syncPulse();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) _hit.reset();
    _syncPulse();
  }

  void _syncPulse() {
    final critical =
        _lives == 1 && widget.session?.status == 'playing' && !_reduced;
    if (critical && !_pulse.isAnimating) _pulse.repeat(reverse: true);
    if (!critical) _pulse.reset();
  }

  void _observe() {
    final next = widget.session?.mine?['lives'] as int?;
    if (next != null && _lives != null && next < _lives!) {
      _lost = _lives! - next;
      if (!_reduced) _hit.forward(from: 0);
      SfxService.instance.damage();
    }
    _lives = next;
    _syncPulse();
  }

  @override
  void dispose() {
    widget.session?.removeListener(_observe);
    _hit.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([_hit, _pulse]),
        child: widget.child,
        builder: (context, child) {
          final hit = _hit.isAnimating ? 1 - _hit.value : 0.0;
          final shake = math.sin(_hit.value * math.pi * 8) * hit * 2;
          final pulseEased = Curves.easeInOut.transform(_pulse.value);
          final pulseOpacity =
              _pulse.isAnimating ? 0.03 + pulseEased * 0.12 : 0.0;
          final edgeOpacity = math.min(0.22, hit * .10 + pulseOpacity);
          return Stack(fit: StackFit.expand, children: [
            Transform.translate(
                offset: Offset(shake, 0),
                transformHitTests: false,
                child: child),
            Positioned.fill(
                child: IgnorePointer(
                    child: RepaintBoundary(
                        child: CustomPaint(
              painter: _LifeEdgePainter(edgeOpacity),
            )))),
            if (hit > 0)
              Positioned(
                  top: 126 - _hit.value * 18,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                      child: Opacity(
                          opacity: math.min(1, hit * 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('−$_lost',
                                  key: const ValueKey('battle-life-loss'),
                                  style: const TextStyle(
                                      color: Color(0xFFFF8B85),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(width: 5),
                              const CustomPaint(
                                  size: Size(22, 20),
                                  painter: PixelHeartPainter(active: true)),
                            ],
                          )))),
          ]);
        },
      );
}

class _LifeEdgePainter extends CustomPainter {
  final double opacity;
  _LifeEdgePainter(this.opacity);
  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    canvas.save();
    canvas.scale(size.width, size.height);
    const unitRect = Rect.fromLTWH(0, 0, 1, 1);
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0),
        radius: 0.72,
        colors: [
          Colors.transparent,
          Colors.transparent,
          const Color(0xFFFF2535).withValues(alpha: opacity * 0.45),
          const Color(0xFFFF1624).withValues(alpha: opacity),
        ],
        stops: const [0.0, 0.58, 0.84, 1.0],
      ).createShader(unitRect);
    canvas.drawRect(unitRect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LifeEdgePainter old) => opacity != old.opacity;
}

/// Two clocks per strip, never one controller/widget per pixel or particle.
class BattleHearts extends StatefulWidget {
  final int lives;
  final bool critical;
  const BattleHearts({super.key, required this.lives, required this.critical});
  @override
  State<BattleHearts> createState() => _BattleHeartsState();
}

class _BattleHeartsState extends State<BattleHearts>
    with TickerProviderStateMixin {
  late final _hit = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 480));
  late final _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
  int _previous = 0;
  void _sync() {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) _hit.reset();
    if (widget.critical && !reduced) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.reset();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(BattleHearts old) {
    super.didUpdateWidget(old);
    if (widget.lives < old.lives && !MediaQuery.disableAnimationsOf(context)) {
      _previous = old.lives;
      _hit.forward(from: 0);
    }
    _sync();
  }

  @override
  void dispose() {
    _hit.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      label: '${widget.lives} can',
      child: RepaintBoundary(
        child: AnimatedBuilder(
            animation: Listenable.merge([_hit, _pulse]),
            builder: (context, _) => CustomPaint(
                  size: const Size(90, 22),
                  painter: _HeartsPainter(widget.lives, _previous,
                      _hit.isAnimating ? _hit.value : 1, _pulse.value),
                )),
      ));
}

class _HeartsPainter extends CustomPainter {
  final int lives, previous;
  final double hit, pulse;
  _HeartsPainter(this.lives, this.previous, this.hit, this.pulse);
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 5; i++) {
      final breaking = i >= lives && i < previous && hit < 1;
      canvas.save();
      canvas.translate(i * 18 + 9, 11);
      final scale = breaking
          ? 1 + math.sin(hit * math.pi) * .22
          : (lives == 1 && i == 0 ? 1 + pulse * .08 : 1.0);
      canvas.scale(scale);
      canvas.translate(-8, -7.5);
      PixelHeartPainter(active: i < lives, loss: breaking ? hit : null)
          .paint(canvas, const Size(16, 15));
      if (breaking) {
        final p = Paint()
          ..color = const Color(0xFFED4545).withValues(alpha: 1 - hit);
        for (var j = 0; j < 4; j++) {
          final a = j * math.pi / 2 + .6;
          canvas.drawRect(
              Rect.fromCenter(
                  center: Offset(
                      8 + math.cos(a) * hit * 12, 7 + math.sin(a) * hit * 12),
                  width: 2,
                  height: 2),
              p);
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_HeartsPainter old) =>
      lives != old.lives ||
      previous != old.previous ||
      hit != old.hit ||
      pulse != old.pulse;
}

/// Integer pixel mask: black outline, red fill and a tiny square highlight.
class PixelHeartPainter extends CustomPainter {
  final bool active;
  final double? loss;
  const PixelHeartPainter({required this.active, this.loss});
  static const _mask = [
    '.##...##.',
    '#rr#.#rr#',
    '#rhr#rrr#',
    '#rrrrrrr#',
    '.#rrrrr#.',
    '..#rrr#..',
    '...#r#...',
    '....#....'
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width / 9, size.height / 8);
    final p = Paint()..isAntiAlias = false;
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 9; x++) {
        final pixel = _mask[y][x];
        if (pixel == '.') continue;
        final on = active || loss != null;
        p.color = pixel == '#'
            ? const Color(0xFF080C16)
            : on
                ? (pixel == 'h'
                    ? const Color(0xFFFFAD9B)
                    : const Color(0xFFED343D))
                : const Color(0xFF43516A);
        if (loss != null) {
          p.color = Color.lerp(p.color, const Color(0xFF43516A), loss!)!;
        }
        final split =
            loss == null ? 0.0 : math.sin(loss! * math.pi) * (x < 4 ? -2 : 2);
        canvas.drawRect(
            Rect.fromLTWH(x * unit + split, y * unit, unit, unit), p);
      }
    }
  }

  @override
  bool shouldRepaint(PixelHeartPainter old) =>
      active != old.active || loss != old.loss;
}
