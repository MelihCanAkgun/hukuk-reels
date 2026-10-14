import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/progress_service.dart';
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
/// kapanırsa bir sonraki açılışta yeniden sorulur.
Future<void> showFlowerSurpriseGate(BuildContext context) {
  return Navigator.of(context).push(_fade(ConfidenceGateScreen(
    badge: '🌸 YENİ GÜNCELLEME 🌸',
    title: 'Sana bir sürprizim var…\nGörmek ister misin?',
    taunts: const [
      'Hayır 😟',
      'Emin misin? 🥺',
      'Kaçamazsın 😝',
      'Ama çiçek var 🌷',
      'Hadi ama 🙈',
      'Evet\'e bas 💗',
    ],
    onYes: (gate) {
      AudioService.instance.playSpecial(kFlowerSong);
      ProgressService.instance.setFlowerSurpriseSeen(true);
      Navigator.of(gate).pushReplacement(_fade(const FlowerSurpriseScreen()));
    },
  )));
}

/// 🌷 düğmesi: çiçeği istediği zaman yeniden aç.
Future<void> openFlower(BuildContext context) {
  AudioService.instance.playSpecial(kFlowerSong);
  return Navigator.of(context).push(_fade(const FlowerSurpriseScreen()));
}
