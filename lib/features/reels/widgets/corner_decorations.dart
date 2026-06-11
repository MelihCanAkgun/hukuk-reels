import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';

/// Soru kartının dört köşesine yerleştirilen dekoratif görseller.
///
/// Kartın İÇİNDE, içeriğin (yazıların) ARKASINDA çizilir; bu yüzden hiçbir
/// yazıyı kapatmaz ama kartın boş köşe alanlarında net görünür.
/// Kart Stack'inin ilk (en alttaki) çocuğu olarak kullanılmalıdır.
class CornerDecorations extends StatelessWidget {
  const CornerDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.showCornerImages || AppConfig.cornerImages.isEmpty) {
      return const SizedBox.shrink();
    }

    final imgs = AppConfig.cornerImages;
    final s = AppConfig.cornerImageSize;
    final o = AppConfig.cornerImageOpacity;
    final bleed = s * 0.22; // köşeden hafif taşma

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            if (imgs.isNotEmpty)
              _img(imgs[0], s, o, top: -bleed, left: -bleed, angle: -0.12),
            if (imgs.length > 1)
              _img(imgs[1], s, o, top: -bleed, right: -bleed, angle: 0.12),
            if (imgs.length > 2)
              _img(imgs[2], s, o, bottom: -bleed, left: -bleed, angle: 0.12),
            if (imgs.length > 3)
              _img(imgs[3], s, o, bottom: -bleed, right: -bleed, angle: -0.12),
          ],
        ),
      ),
    );
  }

  Widget _img(
    String asset,
    double size,
    double opacity, {
    double? top,
    double? bottom,
    double? left,
    double? right,
    double angle = 0,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: angle,
          child: Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            // Büyük PNG'ler küçük çözünürlükte decode edilsin (bellek + hız).
            cacheWidth: 360,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
