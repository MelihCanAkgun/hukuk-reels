import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/app/theme.dart';
import 'package:hukuk_reels/core/config/app_config.dart';
import 'package:hukuk_reels/core/services/audio_service.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/core/services/sfx_service.dart';
import 'package:hukuk_reels/core/widgets/pixel_logo.dart';
import 'package:hukuk_reels/core/widgets/web_safe_area.dart';
import 'package:hukuk_reels/features/games/games_screen.dart';
import 'package:hukuk_reels/features/reels/widgets/music_button.dart';
import 'package:hukuk_reels/features/shell/home_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _frames(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'flower_surprise_seen_v2': true});
    await ProgressService.instance.init();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .allMessagesHandler = (channel, handler, message) async {
      if (channel.startsWith('com.ryanheise')) {
        return const StandardMethodCodec()
            .encodeSuccessEnvelope(<String, dynamic>{});
      }
      return handler?.call(message);
    };
  });

  test('track names are readable', () {
    final audio = AudioService.instance;
    expect(audio.trackCount, AppConfig.musicTracks.length);
    final i = AppConfig.musicTracks.indexOf('assets/audio/Sad_Girl.m4a');
    expect(audio.trackName(i), 'Sad Girl');
  });

  for (final size in const [Size(402, 874), Size(874, 402), Size(1180, 820)]) {
    testWidgets('sound panel opens from the top bar · $size', (tester) async {
      _size(tester, size);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: SafeArea(
            child: Align(alignment: Alignment.topRight, child: MusicButton()),
          ),
        ),
      ));
      await tester.tap(find.byType(MusicButton));
      await _frames(tester, 300);
      final panel = find.byKey(const ValueKey('music-panel'));
      expect(panel, findsOneWidget);
      expect(find.text('Ses'), findsOneWidget);
      expect(find.byKey(const ValueKey('music-track')), findsOneWidget);
      expect(find.text('Müzik'), findsOneWidget);
      expect(find.text('Oyun efektleri'), findsOneWidget);
      final rect = tester.getRect(panel);
      expect(rect.right, lessThanOrEqualTo(size.width));
      expect(rect.bottom, lessThanOrEqualTo(size.height));

      // Parça listesi açılır, kapanır.
      await tester.tap(find.byKey(const ValueKey('music-list')));
      await _frames(tester, 300);
      expect(find.byKey(const ValueKey('music-tracks')), findsOneWidget);
      expect(find.byKey(const ValueKey('music-track-1')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('music-list')));
      await _frames(tester, 300);
      expect(find.byKey(const ValueKey('music-tracks')), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.bySemanticsLabel('Kapat'));
      await _frames(tester, 100);
      expect(panel, findsNothing);
    });
  }

  testWidgets('speaker button mutes and restores game effects', (tester) async {
    _size(tester, const Size(402, 874));
    await tester.runAsync(() => SfxService.instance.setVolume(0.6));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(
          body: SafeArea(
              child:
                  Align(alignment: Alignment.topRight, child: MusicButton()))),
    ));
    await tester.tap(find.byType(MusicButton));
    await _frames(tester, 300);
    expect(find.text('%60'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Oyun efektleri sesini kapat'));
    await _frames(tester, 50);
    expect(SfxService.instance.volume, 0);
    expect(find.text('Kapalı'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Oyun efektleri sesini aç'));
    await _frames(tester, 50);
    expect(SfxService.instance.volume, closeTo(0.6, 1e-9));
    await tester.runAsync(() => SfxService.instance.setVolume(0.9));
  });

  testWidgets('leaderboard has its own pixel logo', (tester) async {
    _size(tester, const Size(402, 874));
    await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const GamesScreen()));
    await _frames(tester, 300);
    final logos = tester
        .widgetList<PixelLogo>(find.byType(PixelLogo))
        .map((l) => l.rows)
        .toList();
    expect(logos.where((r) => identical(r, kLogoLeaderboard)), hasLength(2));
    expect(logos.where((r) => identical(r, kLogoBlockBlast)), hasLength(1));
  });

  testWidgets('web safe area lifts the tab bar above the home indicator',
      (tester) async {
    _size(tester, const Size(402, 874));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => WebSafeArea(
          read: () => const EdgeInsets.only(bottom: 34), child: child!),
      home: const HomeShell(),
    ));
    await _frames(tester, 300);
    final bar = tester.getRect(find.byType(NavigationBar));
    expect(bar.bottom, 874, reason: 'bar background reaches the edge');
    final label = tester.getRect(find.text('Ana sayfa'));
    expect(label.bottom, lessThan(874 - 34),
        reason: 'labels stay above the home indicator');
    await tester.pumpWidget(const SizedBox());
    await _frames(tester, 50);
  });

  testWidgets('without a reported inset nothing changes', (tester) async {
    _size(tester, const Size(402, 874));
    late EdgeInsets padding;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) =>
          WebSafeArea(read: () => EdgeInsets.zero, child: child!),
      home: Builder(builder: (context) {
        padding = MediaQuery.paddingOf(context);
        return const SizedBox();
      }),
    ));
    expect(padding, EdgeInsets.zero);
  });
}
