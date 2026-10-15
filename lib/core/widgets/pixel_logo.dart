import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../features/surprise/pixel_sprites.dart';
import 'pixel_logo_data.dart';

export 'pixel_logo_data.dart';

/// Piksel-art logo. Sprite [size]×[size] kutuya en-boy oranı korunarak
/// sığdırılır; her boyut için bir kez [ui.Picture]'a kaydedilip tekrar çizilir.
class PixelLogo extends StatelessWidget {
  const PixelLogo(
    this.rows, {
    super.key,
    this.size = 24,
    this.palette = kLogoPalette,
  });

  final List<String> rows;
  final double size;
  final Map<String, Color> palette;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PixelLogoPainter(rows, palette)),
      );
}

/// Beat modunun piksel sopası, çapraz duruşlu küçük ikon olarak.
class PixelBatIcon extends StatelessWidget {
  const PixelBatIcon({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _BatIconPainter()),
      );
}

final Map<String, ui.Picture> _cache = {};

ui.Picture _picture(List<String> rows, Map<String, Color> palette, double px) {
  final key = '${identityHashCode(rows)}@$px';
  return _cache.putIfAbsent(key, () {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final ch = row[x];
        if (ch == '.') continue;
        paint.color = palette[ch]!;
        // Komşu karelerin arasında ince boşluk kalmasın diye hafif taşır.
        c.drawRect(Rect.fromLTWH(x * px, y * px, px + 0.35, px + 0.35), paint);
      }
    }
    return rec.endRecording();
  });
}

class _PixelLogoPainter extends CustomPainter {
  _PixelLogoPainter(this.rows, this.palette);
  final List<String> rows;
  final Map<String, Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = rows.first.length;
    final px = (size.width / cols < size.height / rows.length
            ? size.width / cols
            : size.height / rows.length)
        .toDouble();
    canvas.translate(
        (size.width - cols * px) / 2, (size.height - rows.length * px) / 2);
    canvas.drawPicture(_picture(rows, palette, px));
  }

  @override
  bool shouldRepaint(_PixelLogoPainter old) =>
      old.rows != rows || old.palette != palette;
}

class _BatIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final px = size.height / kBatSprite.length * 1.25;
    final w = kBatSprite.first.length * px, h = kBatSprite.length * px;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(0.75);
    canvas.translate(-w / 2, -h / 2);
    canvas.drawPicture(_picture(kBatSprite, kSpritePalette, px));
  }

  @override
  bool shouldRepaint(_BatIconPainter old) => false;
}
