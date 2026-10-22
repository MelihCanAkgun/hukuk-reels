import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/theme.dart';
import 'core/services/audio_service.dart';
import 'core/services/invite_bridge.dart';
import 'core/services/progress_service.dart';
import 'features/game/block_battle_lobby.dart';
import 'features/shell/home_shell.dart';
import 'core/services/sfx_service.dart';
import 'core/widgets/web_safe_area.dart';

void main() async {
  // Tarayıcı geçmişine giriş eklenmez. Böylece iPhone'da kenardan sağa
  // kaydırma Safari'nin "geri" gezinmesini (açılıştaki yükleme ekranının
  // eski görüntüsü, birkaç saniyelik takılma) tetiklemez; hareketi
  // Flutter'ın kendi iOS geri kaydırması karşılar ve önceki ekrana döner.
  setUrlStrategy(null);
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

  // Bildirimdeki 1v1 davetine dokunuldu: lobi oda koduyla açılır. Dinleme ilk
  // kareden sonra başlar; açılışı sağlayan davet o an teslim edilir.
  WidgetsBinding.instance.addPostFrameCallback((_) => listenInvites((room) =>
      navigatorKey.currentState?.push(MaterialPageRoute<void>(
          builder: (_) => BlockBattleLobby(invite: room)))));
}

final navigatorKey = GlobalKey<NavigatorState>();

class HukukReelsApp extends StatelessWidget {
  const HukukReelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hukuk Reels · Oyunlar',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Türkçe tarih/saat seçicileri ve Material metinleri.
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // iPhone'un ana ekran çizgisi ve çentiği için güvenli alan (web).
      builder: (context, child) => WebSafeArea(child: child!),
      // Alt sekmeler: Ana sayfa, Oyunlar, Çalış, Profil.
      home: const HomeShell(),
    );
  }
}
