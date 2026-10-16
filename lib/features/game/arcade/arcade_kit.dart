import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'arcade_sprites.dart';

export 'arcade_sprites.dart';

/// Piksel sprite'ları bir kez 1 piksel = 1 birim [ui.Image]'a çevirir;
/// oyunlar onları en-yakın-komşu ölçekleme ile çizer (keskin pikseller,
/// kare başına tek drawImageRect).
class SpriteBank {
  SpriteBank._();
  static final SpriteBank instance = SpriteBank._();

  final Map<List<String>, ui.Image> _images = Map.identity();

  ui.Image of(List<String> rows) => _images.putIfAbsent(rows, () {
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        final paint = Paint()..isAntiAlias = false;
        for (var y = 0; y < rows.length; y++) {
          final row = rows[y];
          for (var x = 0; x < row.length; x++) {
            final ch = row[x];
            if (ch == '.') continue;
            paint.color = kArcadePalette[ch]!;
            c.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
          }
        }
        return rec.endRecording().toImageSync(rows.first.length, rows.length);
      });
}

/// Sprite çizimi için ortak boya (yumuşatmasız).
final Paint kPixelPaint = Paint()
  ..filterQuality = FilterQuality.none
  ..isAntiAlias = false;

/// [rows] sprite'ını [dst] dikdörtgenine çizer. [opacity] < 1 ise saydam.
/// [tint] verilirse sprite'ın yalnız dolu pikselleri o renge doğru boyanır
/// (sis / uzaklık efekti; rengin alfası karışım oranıdır).
void drawSprite(Canvas canvas, List<String> rows, Rect dst,
    {double opacity = 1, bool flipX = false, Color? tint}) {
  final img = SpriteBank.instance.of(rows);
  final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
  kPixelPaint.color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0));
  kPixelPaint.colorFilter = tint == null || tint.a < 0.01
      ? null
      : ColorFilter.mode(tint, BlendMode.srcATop);
  if (flipX) {
    canvas.save();
    canvas.translate(dst.center.dx, 0);
    canvas.scale(-1, 1);
    canvas.translate(-dst.center.dx, 0);
    canvas.drawImageRect(img, src, dst, kPixelPaint);
    canvas.restore();
  } else {
    canvas.drawImageRect(img, src, dst, kPixelPaint);
  }
}

/// Basit parçacık (toz, tüy, kıvılcım). Konum/hız oyun biriminde.
class Particle {
  double x, y, vx, vy, life, maxLife, size;
  final Color color;
  final double gravity;
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color,
      {this.gravity = 0})
      : maxLife = life;
  double get t => (life / maxLife).clamp(0.0, 1.0);
}

class ParticleSystem {
  final List<Particle> items = [];
  final math.Random rng = math.Random();

  void burst(double x, double y, int n, List<Color> colors,
      {double speed = 60,
      double life = 0.6,
      double size = 2,
      double gravity = 0,
      double spread = math.pi * 2,
      double angle = 0}) {
    for (var i = 0; i < n; i++) {
      final a = angle + (rng.nextDouble() - 0.5) * spread;
      final v = speed * (0.4 + rng.nextDouble() * 0.6);
      items.add(Particle(
          x,
          y,
          math.cos(a) * v,
          math.sin(a) * v,
          life * (0.6 + rng.nextDouble() * 0.4),
          size * (0.6 + rng.nextDouble() * 0.6),
          colors[rng.nextInt(colors.length)],
          gravity: gravity));
    }
    if (items.length > 220) items.removeRange(0, items.length - 220);
  }

  void update(double dt) {
    for (final p in items) {
      p.life -= dt;
      p.vy += p.gravity * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }
    items.removeWhere((p) => p.life <= 0);
  }

  void clear() => items.clear();
}

/// Kısa süreli ekran sarsıntısı.
class Shake {
  double _t = 0, _amp = 0;
  final math.Random _rng = math.Random();
  void kick(double amp, [double dur = 0.3]) {
    _amp = math.max(_amp, amp);
    _t = math.max(_t, dur);
  }

  void update(double dt) {
    _t = math.max(0, _t - dt);
    if (_t == 0) _amp = 0;
  }

  Offset get offset => _t <= 0
      ? Offset.zero
      : Offset((_rng.nextDouble() - 0.5) * 2 * _amp * math.min(1, _t * 5),
          (_rng.nextDouble() - 0.5) * 2 * _amp * math.min(1, _t * 5));
  void reset() => _t = _amp = 0;
}

/// Piksel yazı tipinde çerçeveli (konturlu) sayı / metin çizer.
void drawOutlinedText(Canvas canvas, String text, Offset center, double size,
    {Color fill = const Color(0xFFFFFFFF),
    Color stroke = const Color(0xFF2B1220),
    double opacity = 1}) {
  final style = TextStyle(
    fontFamily: 'PixelifySans',
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1,
  );
  final strokeTp = TextPainter(
    text: TextSpan(
        text: text,
        style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.18
              ..strokeJoin = StrokeJoin.round
              ..color = stroke.withValues(alpha: opacity))),
    textDirection: TextDirection.ltr,
  )..layout();
  final fillTp = TextPainter(
    text: TextSpan(
        text: text,
        style: style.copyWith(color: fill.withValues(alpha: opacity))),
    textDirection: TextDirection.ltr,
  )..layout();
  final o = center - Offset(fillTp.width / 2, fillTp.height / 2);
  strokeTp.paint(canvas, o);
  fillTp.paint(canvas, o);
  strokeTp.dispose();
  fillTp.dispose();
}

/// İki renk arası doğrusal geçiş, kısaltma.
Color lerpColor(Color a, Color b, double t) => Color.lerp(a, b, t)!;
