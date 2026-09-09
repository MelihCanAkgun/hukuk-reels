import 'dart:math';
import 'package:flutter/material.dart';

/// Presentation only: ranks never change the scoring or block generator.
class BlockCelebrationData {
  final String title;
  final int combo, points;
  final Color color;
  final bool legendary;
  const BlockCelebrationData(this.title, this.combo, this.points, this.color,
      {this.legendary = false});

  factory BlockCelebrationData.forClear(
      {required int combo,
      required int lines,
      required int points,
      required bool allClear}) {
    if (combo >= 6 || lines >= 4) {
      return BlockCelebrationData('SSS', combo, points, const Color(0xFFFFD568),
          legendary: true);
    }
    if (allClear) {
      return BlockCelebrationData(
          'PERFECT!', combo, points, const Color(0xFF80F8EE));
    }
    if (combo >= 4 || lines >= 3) {
      return BlockCelebrationData(
          'SUPER!', combo, points, const Color(0xFFCFA0FF));
    }
    return BlockCelebrationData(
        'COMBO!', combo, points, const Color(0xFF8CCBFF));
  }
}

/// Paint-only celebration. It never intercepts a drag or locks the game.
class BlockCelebration extends StatefulWidget {
  final BlockCelebrationData data;
  const BlockCelebration({super.key, required this.data});
  @override
  State<BlockCelebration> createState() => _BlockCelebrationState();
}

class _BlockCelebrationState extends State<BlockCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _finished = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1250))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _finished = true);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return const SizedBox.shrink();
    return IgnorePointer(
        child: Semantics(
      label:
          '${widget.data.title}, kombo ${widget.data.combo}, ${widget.data.points} puan',
      child: RepaintBoundary(
          child: CustomPaint(
        painter: _CelebrationPainter(_controller, widget.data,
            reducedMotion: MediaQuery.disableAnimationsOf(context)),
        child: const SizedBox.expand(),
      )),
    ));
  }
}

class _CelebrationPainter extends CustomPainter {
  final Animation<double> animation;
  final BlockCelebrationData data;
  final bool reducedMotion;
  late final TextPainter _outline, _title, _detail;
  _CelebrationPainter(this.animation, this.data, {required this.reducedMotion})
      : super(repaint: reducedMotion ? null : animation) {
    final style = TextStyle(
        fontFamily: 'Inter',
        fontSize: data.legendary ? 88 : 52,
        fontWeight: FontWeight.w900,
        letterSpacing: data.legendary ? 6 : -1,
        height: 1);
    _outline = _text(
        data.title,
        style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..color = const Color(0xFF19254B)));
    _title = _text(
        data.title,
        style.copyWith(
            foreground: Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  data.color,
                  Color.lerp(data.color, const Color(0xFFE89B36), .4)!
                ],
                stops: const [0, .45, 1],
              ).createShader(
                  Rect.fromLTWH(0, 0, _outline.width, _outline.height))));
    _detail = _text(
        'KOMBO ×${data.combo}   +${data.points}',
        const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            height: 1,
            fontWeight: FontWeight.w800,
            color: Colors.white));
  }
  TextPainter _text(String text, TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final alpha =
        reducedMotion ? 1.0 : (min(t / .07, (1 - t) / .22)).clamp(0.0, 1.0);
    if (alpha <= 0) return;
    final center = Offset(size.width / 2, size.height * .44);
    if (!reducedMotion) {
      // Expanding shockwave, followed by deterministic confetti and sparks.
      final wave = Curves.easeOutCubic.transform((t / .65).clamp(0.0, 1.0));
      canvas.drawCircle(
          center,
          size.width * (.1 + .38 * wave),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 * (1 - wave)
            ..color = data.color.withValues(alpha: (1 - wave) * .65));
      final count = data.legendary ? 36 : 22;
      for (var i = 0; i < count; i++) {
        final angle = i * 2.399963;
        final travel =
            size.width * (.12 + (i % 5) * .037) * Curves.easeOut.transform(t);
        final position = center +
            Offset(cos(angle) * travel, sin(angle) * travel + 45 * t * t);
        final color = i % 3 == 0 ? Colors.white : data.color;
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(angle + t * (i.isEven ? 4 : -4));
        final paint = Paint()
          ..color = color.withValues(alpha: alpha * (1 - t * .6));
        if (i % 4 == 0) {
          canvas.drawLine(
              const Offset(-5, 0), const Offset(5, 0), paint..strokeWidth = 2);
          canvas.drawLine(const Offset(0, -5), const Offset(0, 5), paint);
        } else {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(-2, -4, 4, 8), const Radius.circular(1)),
              paint);
        }
        canvas.restore();
      }
    }
    final entrance = reducedMotion
        ? 1.0
        : Curves.easeOutBack.transform((t / .22).clamp(0.0, 1.0));
    final scale = (.65 + entrance * .35) *
        min(1.0, size.width * .82 / max(_title.width, _detail.width));
    canvas.save();
    canvas.translate(center.dx, center.dy - (reducedMotion ? 0 : t * 14));
    canvas.scale(scale);
    // A bounded layer fades only the badge, never the board or whole screen.
    final bounds = Rect.fromLTWH(
        -_title.width / 2 - 22, -12, _title.width + 44, _title.height + 66);
    canvas.saveLayer(
        bounds, Paint()..color = Colors.white.withValues(alpha: alpha));
    final origin = Offset(-_title.width / 2, 0);
    _outline.paint(canvas, origin + const Offset(0, 4));
    _title.paint(canvas, origin);
    if (!reducedMotion && t > .18 && t < .6) {
      final textRect = origin & _title.size;
      final sweep = (t - .18) / .42;
      final x = textRect.left - 60 + (_title.width + 120) * sweep;
      canvas.saveLayer(textRect, Paint());
      _title.paint(canvas, origin);
      canvas.drawRect(
          textRect,
          Paint()
            ..blendMode = BlendMode.srcIn
            ..shader = const LinearGradient(colors: [
              Colors.transparent,
              Color(0xB3FFFFFF),
              Colors.transparent
            ]).createShader(Rect.fromLTWH(x - 40, 0, 80, _title.height)));
      canvas.restore();
    }
    final detailBox = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(0, _title.height + 27),
            width: _detail.width + 28,
            height: 34),
        const Radius.circular(17));
    canvas.drawRRect(detailBox, Paint()..color = const Color(0xEA162645));
    canvas.drawRRect(
        detailBox,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = data.color.withValues(alpha: .65));
    _detail.paint(canvas, Offset(-_detail.width / 2, _title.height + 18));
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) =>
      old.data != data || old.reducedMotion != reducedMotion;
}
