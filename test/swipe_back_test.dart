import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/app/theme.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/game/block_blast_screen.dart';
import 'package:hukuk_reels/features/game/flappy_cat_screen.dart';
import 'package:hukuk_reels/features/game/subway_cat_screen.dart';
import 'package:hukuk_reels/features/game/tower_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// iPhone'da kenardan sağa kaydırma Flutter'ın kendi iOS geri hareketidir
// (tarayıcı geçmişi kapalı: main.dart setUrlStrategy(null)).

Future<void> _frames(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

final _nav = GlobalKey<NavigatorState>();

Future<void> _open(WidgetTester tester, Widget game) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(393, 852) * 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
      navigatorKey: _nav,
      theme: AppTheme.dark,
      home: const Scaffold(body: Text('Ana ekran'))));
  _nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => game));
  await _frames(tester, 700);
  expect(find.byWidget(game), findsOneWidget);
}

Future<void> _edgeSwipe(WidgetTester tester) async {
  await tester.dragFrom(const Offset(4, 420), const Offset(320, 0));
  await _frames(tester, 900);
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
  final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

  final games = <String, Widget Function()>{
    'Block Blast': () => const BlockBlastScreen(),
    'Flappy': () => const FlappyCatScreen(),
    'Subway': () => const SubwayCatScreen(),
    'Adliye Kulesi': () => const TowerScreen(),
  };
  for (final g in games.entries) {
    testWidgets('${g.key}: edge swipe returns to the previous screen',
        (tester) async {
      final game = g.value();
      await _open(tester, game);
      await _edgeSwipe(tester);
      expect(find.byWidget(game), findsNothing);
      expect(find.text('Ana ekran'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }, variant: ios);
  }

  testWidgets('Subway: swipes during a run never leave; back button does',
      (tester) async {
    const game = SubwayCatScreen();
    await _open(tester, game);
    (tester.state(find.byWidget(game)) as dynamic).debugStart(god: true);
    await _frames(tester, 300);
    await _edgeSwipe(tester);
    expect(find.byWidget(game), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await _frames(tester, 900);
    expect(find.byWidget(game), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }, variant: ios);

  testWidgets('Adliye Kulesi: a running tower is not left by a swipe',
      (tester) async {
    const game = TowerScreen();
    await _open(tester, game);
    final dynamic st = tester.state(find.byWidget(game));
    st.autopilot();
    await _frames(tester, 200);
    expect(st.phaseName, 'playing');
    await _edgeSwipe(tester);
    expect(find.byWidget(game), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, variant: ios);

  testWidgets('Block Blast tray leaves the 20 px edge to the back gesture',
      (tester) async {
    await _open(tester, const BlockBlastScreen());
    expect(tester.getRect(find.byKey(const ValueKey('block-tray-0'))).left,
        greaterThanOrEqualTo(20));
    expect(tester.getRect(find.byKey(const ValueKey('block-tray-2'))).right,
        lessThanOrEqualTo(393 - 20));
    await tester.pumpWidget(const SizedBox());
  }, variant: ios);
}
