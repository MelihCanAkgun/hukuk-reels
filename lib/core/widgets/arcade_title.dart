import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'pixel_logo.dart';

/// Ekranların ortak başlık çubuğu (arcade teması): ayrı sayfa olarak
/// açıldıysa geri tuşu, isteğe bağlı piksel simge, piksel yazı tipinde
/// başlık ve sağda eylemler. Bütün sekmeler ve alt ekranlar aynı ölçüyü
/// kullanır.
class ArcadeTitleBar extends StatelessWidget {
  const ArcadeTitleBar({
    super.key,
    required this.title,
    this.logo,
    this.actions = const [],
    this.titleKey,
  });

  final String title;

  /// Başlığın solundaki piksel simge (ör. [kLogoGames]).
  final List<String>? logo;
  final List<Widget> actions;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Padding(
      padding: EdgeInsets.fromLTRB(canPop ? 4 : 16, 8, 12, 6),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            if (canPop)
              IconButton(
                tooltip: 'Geri',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppTheme.textPrimary),
              ),
            if (logo != null) ...[
              PixelLogo(logo!, size: 26),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: Text(
                title,
                key: titleKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.screenTitle,
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// Liste içindeki bölüm etiketi ("ÖZETLER", "SEVGİLİNLE").
class ArcadeSectionLabel extends StatelessWidget {
  const ArcadeSectionLabel(this.text, {super.key, this.padding});

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Text(text, style: AppTheme.sectionLabel),
      );
}
