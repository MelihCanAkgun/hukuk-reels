import 'package:flutter/widgets.dart';

/// Kutusuna her zaman sığan, çok satırlı metin: yazı tipi boyutu, metin
/// kutuya sığana kadar küçültülür ([maxSize] → [minSize]). En küçük boyutta
/// bile sığmazsa kutunun dışına asla taşmaz (kırpılır).
///
/// Ölçüm ve çizim aynı ölçekle yapılır (sistem yazı büyütmesi uygulanmaz);
/// böylece ölçülen boyut ekrandakiyle birebir aynıdır.
class FitText extends StatelessWidget {
  const FitText(
    this.text, {
    super.key,
    required this.style,
    this.maxSize = 28,
    this.minSize = 8,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle style;
  final double maxSize, minSize;
  final TextAlign textAlign;

  /// [box] içine sığan en büyük tam sayı boyutu (ikili arama).
  static double fit(String text, TextStyle style, Size box,
      {double maxSize = 28,
      double minSize = 8,
      TextAlign align = TextAlign.center}) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    double widest(double size) {
      var max = 0.0;
      for (final w in words) {
        final p = TextPainter(
          text: TextSpan(text: w, style: style.copyWith(fontSize: size)),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.noScaling,
        )..layout();
        if (p.width > max) max = p.width;
        p.dispose();
      }
      return max;
    }

    bool fits(double size, {bool wholeWords = true}) {
      // Önce kelimeler bölünmeden sığmalı ("görü-şürüz" olmasın).
      if (wholeWords && widest(size) > box.width - 1) return false;
      final p = TextPainter(
        text: TextSpan(text: text, style: style.copyWith(fontSize: size)),
        textAlign: align,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: box.width);
      final ok = p.height <= box.height && p.width <= box.width;
      p.dispose();
      return ok;
    }

    var lo = minSize.floor(), hi = maxSize.floor();
    // Çok uzun tek kelime en küçük boyutta bile sığmıyorsa bölünmesine izin ver.
    if (!fits(lo.toDouble())) {
      bool broken(double s) => fits(s, wholeWords: false);
      return broken(lo.toDouble()) ? _largest(lo, hi, broken) : minSize;
    }
    return _largest(lo, hi, fits);
  }

  /// [lo] sığdığı bilinen; [lo, hi] aralığında sığan en büyük tam sayı.
  static double _largest(int lo, int hi, bool Function(double) fits) {
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (fits(mid.toDouble())) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    // Ölçüm, Text'in çizerken uygulayacağı varsayılan stille (tema harf
    // aralığı vb.) birleşmiş hâliyle yapılmalı; yoksa ekrandaki metin
    // ölçülenden geniş çıkar ve kelimeler bölünür.
    final effective = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(builder: (context, c) {
      final size = fit(text, effective, c.biggest,
          maxSize: maxSize, minSize: minSize, align: textAlign);
      return ClipRect(
        child: Center(
          child: Text(
            text,
            textAlign: textAlign,
            textScaler: TextScaler.noScaling,
            style: effective.copyWith(fontSize: size),
          ),
        ),
      );
    });
  }
}
