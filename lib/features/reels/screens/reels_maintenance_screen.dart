import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../surprise/pixel_font.dart';
import '../../surprise/pixel_sprites.dart';

/// Soru bölümü bakımdayken gösterilen ekran (piksel yazı).
class ReelsMaintenanceScreen extends StatefulWidget {
  const ReelsMaintenanceScreen({super.key});

  static const title = 'Bakımda.';
  static const lines = ['Çok Yakında', 'Daha İyi İçeriklerle', 'Döneceğiz'];

  /// Ekran okuyucular ve testler için düz metin.
  static String get message => '$title ${lines.join(' ')} 🥰';

  @override
  State<ReelsMaintenanceScreen> createState() => _ReelsMaintenanceScreenState();
}

class _ReelsMaintenanceScreenState extends State<ReelsMaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hareket azaltma açıksa sabit dur.
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                label: ReelsMaintenanceScreen.message,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _MaintenancePainter(_clock, pad),
                  ),
                ),
              ),
            ),
            Positioned(
              top: pad.top + 4,
              left: 6,
              child: IconButton(
                tooltip: 'Geri',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenancePainter extends CustomPainter {
  _MaintenancePainter(this.clock, this.pad) : super(repaint: clock);
  final Animation<double> clock;
  final EdgeInsets pad;

  ui.Picture? _text;
  Size _textFor = Size.zero;
  double _px = 3;
  double _textHeight = 0;

  static final _stars = List.generate(34, (i) {
    final r = Random(i * 7919 + 13);
    return (
      r.nextDouble(),
      r.nextDouble(),
      r.nextDouble() * 2 * pi,
      r.nextBool()
    );
  });
  static final _paint = Paint()..isAntiAlias = false;

  static const _titleColor = Color(0xFFFF9EC4);
  static const _textColor = Color(0xFFFFE6F0);
  static const _shadow = Color(0xFF7A2350);

  void _layoutText(Size size) {
    final widest = ReelsMaintenanceScreen.lines.map(pixelLineWidth).reduce(max);
    const lineGap = 4; // piksel
    // Yüz + başlık + satırlar, piksel boyutu başına toplam yükseklik. Yatay
    // telefonda yükseklik de sınırlar; yazı kesilmez.
    final unit = kLoveFaceSprite.length * 1.6 +
        6 +
        (kGlyphRows + 3) * 1.8 +
        ReelsMaintenanceScreen.lines.length * (kGlyphRows + lineGap);
    _px = min((size.width - 48) / widest,
            (size.height - pad.top - pad.bottom - 80) / unit)
        .floorToDouble()
        .clamp(2.0, 5.0);
    final titlePx = (_px * 1.8).roundToDouble();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    var y = 0.0;
    const title = ReelsMaintenanceScreen.title;
    final tw = pixelLineWidth(title) * titlePx;
    paintPixelText(c, title, Offset(((size.width - tw) / 2).roundToDouble(), y),
        titlePx, _titleColor,
        shadow: _shadow);
    y += (kGlyphRows + 3) * titlePx;
    for (final line in ReelsMaintenanceScreen.lines) {
      final w = pixelLineWidth(line) * _px;
      paintPixelText(c, line, Offset(((size.width - w) / 2).roundToDouble(), y),
          _px, _textColor,
          shadow: _shadow);
      y += (kGlyphRows + lineGap) * _px;
    }
    _text?.dispose();
    _text = rec.endRecording();
    _textHeight = y;
    _textFor = size;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_text == null || size != _textFor) _layoutText(size);
    final t = clock.value * 2 * pi;

    // Yıldızlar
    final sp = max(2.0, _px - 1);
    for (final (fx, fy, ph, big) in _stars) {
      final a = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * 2 + ph));
      final x = (fx * size.width / sp).floorToDouble() * sp;
      final y = ((pad.top + fy * size.height * 0.9) / sp).floorToDouble() * sp;
      _paint.color = const Color(0xFFFFF4FA).withValues(alpha: a * 0.8);
      canvas.drawRect(Rect.fromLTWH(x, y, sp, sp), _paint);
      if (big && a > 0.75) {
        _paint.color =
            const Color(0xFFFFC4DA).withValues(alpha: (a - 0.75) * 3);
        canvas.drawRect(Rect.fromLTWH(x - sp, y, sp, sp), _paint);
        canvas.drawRect(Rect.fromLTWH(x + sp, y, sp, sp), _paint);
        canvas.drawRect(Rect.fromLTWH(x, y - sp, sp, sp), _paint);
        canvas.drawRect(Rect.fromLTWH(x, y + sp, sp, sp), _paint);
      }
    }

    // 🥰 yüz: piksel adımlarla zıplar.
    final facePx = (_px * 1.6).roundToDouble();
    final faceW = kLoveFaceSprite.first.length * facePx;
    final faceH = kLoveFaceSprite.length * facePx;
    final gap = 6 * _px;
    final block = faceH + gap + _textHeight;
    final top = max(pad.top + 56, (size.height - block) / 2 - 10);
    final bob = (sin(t * 2) > 0.2 ? -1 : 0) * _px;
    _drawSprite(canvas, kLoveFaceSprite,
        Offset(((size.width - faceW) / 2).roundToDouble(), top + bob), facePx);

    canvas.save();
    canvas.translate(0, (top + faceH + gap).roundToDouble());
    canvas.drawPicture(_text!);
    canvas.restore();
  }

  void _drawSprite(Canvas c, List<String> rows, Offset o, double px) {
    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final ch = row[x];
        if (ch == '.') continue;
        _paint.color = kSpritePalette[ch]!;
        c.drawRect(Rect.fromLTWH(o.dx + x * px, o.dy + y * px, px, px), _paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MaintenancePainter old) => old.pad != pad;
}
