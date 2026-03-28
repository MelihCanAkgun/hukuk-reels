import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app_shell.dart';
import 'app/theme.dart';
import 'core/services/audio_service.dart';
import 'core/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive veritabanını başlat
  await DatabaseService.instance.init();

  // Ses servisini başlat
  await AudioService.instance.init();

  // Tam ekran immersive mod
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const HukukReelsApp());
}

class HukukReelsApp extends StatelessWidget {
  const HukukReelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hukuk Reels',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
