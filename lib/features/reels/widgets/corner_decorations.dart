import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';

/// Ekranın dört köşesine, soruyu kapatmayacak şekilde yerleştirilen
/// dekoratif görseller. Dokunmayı engellemez (IgnorePointer).
class CornerDecorations extends StatelessWidget {
  const CornerDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.showCornerImages || AppConfig.cornerImages.isEmpty) {
      return const SizedBox.shrink();
    }

    final imgs = AppConfig.cornerImages;
    final pad = MediaQuery.of(context).padding;

    return IgnorePointer(
      child: Stack(
        children: [
          if (imgs.isNotEmpty)
            _corner(imgs[0], top: pad.top + 6, left: -6, angle: -0.18),
          if (imgs.length > 1)
            _corner(imgs[1], top: pad.top + 6, right: -6, angle: 0.18),
          if (imgs.length > 2)
            _corner(imgs[2], bottom: pad.bottom + 10, left: -6, angle: 0.18),
          if (imgs.length > 3)
            _corner(imgs[3], bottom: pad.bottom + 10, right: -6, angle: -0.18),
        ],
      ),
    );
  }

  Widget _corner(
    String asset, {
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
        opacity: AppConfig.cornerImageOpacity,
        child: Transform.rotate(
          angle: angle,
          child: Image.asset(
            asset,
            width: AppConfig.cornerImageSize,
            height: AppConfig.cornerImageSize,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
