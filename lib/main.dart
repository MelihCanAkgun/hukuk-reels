import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/theme.dart';
import 'core/services/audio_service.dart';
import 'core/services/progress_service.dart';
import 'features/games/games_screen.dart';
import 'core/services/sfx_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kalıcı ilerleme deposunu ve müziği hazırla.
  await ProgressService.instance.init();
  // Audio must never hold the first frame hostage.
  unawaited(AudioService.instance.init());
  unawaited(SfxService.instance.init());

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const HukukReelsApp());
}

class HukukReelsApp extends StatelessWidget {
  const HukukReelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hukuk Reels · Oyunlar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Oyunlara doğrudan erişim; soru bankası oyun menüsünde.
      home: const GamesScreen(),
    );
  }
}
