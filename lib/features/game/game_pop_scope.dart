import 'package:flutter/widgets.dart';

/// Oyun sürerken iOS'taki kenardan sağa kaydırma ile geri dönüşü kapatır
/// (Subway'deki kaydırmalar ya da kenara yakın dokunuşlar oyundan
/// çıkarmasın). Hazır, duraklatılmış ve bitmiş ekranlarda kaydırma çalışır.
/// Sol üstteki geri tuşu ([Navigator.maybePop]) her zaman çıkar.
class GamePopScope extends StatelessWidget {
  const GamePopScope({super.key, required this.playing, required this.child});

  final bool playing;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !playing,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.of(context).pop();
        },
        child: child,
      );
}
