import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Geniş ekranda (iPad, yatay) liste içeriğini okunabilir genişlikte ortalayan
/// yan boşluk. Kaydırma alanı tam genişlikte kalır; yalnız içerik daralır.
double readableGutter(BuildContext context,
    {double maxWidth = 720, double min = 16}) {
  final w = MediaQuery.sizeOf(context).width;
  return math.max(min, (w - maxWidth) / 2);
}
