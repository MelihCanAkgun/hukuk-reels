import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/progress_service.dart';
import '../home/home_store.dart';
import '../intro/confidence_gate_screen.dart';
import 'flower_surprise_screen.dart';

Route<void> _fade(Widget page) => PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );

/// Güncellemeden sonraki ilk açılış: kaçan "Hayır"lı soru → çiçek.
/// Sürpriz, "Evet"e basılınca görülmüş sayılır; ondan önce uygulama
/// kapanırsa bir sonraki açılışta yeniden sorulur. Yalnız ari'ye
/// ([HomeStore.isAri]) gösterilir.
Future<void> showFlowerSurpriseGate(BuildContext context) async {
  if (!HomeStore.instance.isAri) return;
  await Navigator.of(context).push(_fade(ConfidenceGateScreen(
    badge: '💌 YENİ GÜNCELLEME 💌',
    title: 'Sana bir sürprizim var…\nGörmek ister misin?',
    taunts: const [
      'Hayır 😟',
      'Emin misin? 🥺',
      'Kaçamazsın 😝',
      'Olmaz öyle 😤',
      'Hadi ama 🙈',
      'Evet\'e bas 💗',
    ],
    onYes: (gate) {
      // Soru açıkken oyuncu değişmiş olabilir (ör. gruptan çıkış).
      if (!HomeStore.instance.isAri) {
        Navigator.of(gate).pop();
        return;
      }
      AudioService.instance.playSpecial(kFlowerSong);
      ProgressService.instance.setFlowerSurpriseSeen(true);
      Navigator.of(gate).pushReplacement(_fade(const FlowerSurpriseScreen()));
    },
  )));
}

/// 🌷 düğmesi: çiçeği istediği zaman yeniden aç (yalnız ari).
Future<void> openFlower(BuildContext context) async {
  if (!HomeStore.instance.isAri) return;
  AudioService.instance.playSpecial(kFlowerSong);
  await Navigator.of(context).push(_fade(const FlowerSurpriseScreen()));
}
