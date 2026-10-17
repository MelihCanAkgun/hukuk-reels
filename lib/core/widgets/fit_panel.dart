import 'package:flutter/widgets.dart';

/// Ortalanmış bir paneli (oyun sonu, başlangıç kartı) kısa ekrana sığdırır.
/// Panel kendi genişliğinde dizilir; yüksekliği ekrana sığmazsa (ör. yatay
/// telefon) metin taşmadan orantılı olarak küçültülür.
class FitPanel extends StatelessWidget {
  const FitPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 10),
    this.alignment = Alignment.center,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Panelin kendi satırı içindeki yeri (ör. yatay ekranda sağda).
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (!c.hasBoundedWidth || !c.hasBoundedHeight) return child;
      return Padding(
        padding: padding,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: c.maxWidth - padding.horizontal,
            child: Align(alignment: alignment, child: child),
          ),
        ),
      );
    });
  }
}
