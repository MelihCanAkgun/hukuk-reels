import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/theme.dart';
import 'core/services/audio_service.dart';
import 'features/intro/confidence_gate_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Arka plan müziğini hazırla (çalma ilk dokunuşta başlar).
  await AudioService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const HukukReelsApp());
}

class HukukReelsApp extends StatelessWidget {
  const HukukReelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medeni Usul Hukuku Final',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const ConfidenceGateScreen(),
    );
  }
}
