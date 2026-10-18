import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/app/theme.dart';
import 'package:hukuk_reels/core/services/activity_area.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/game/block_blast_engine.dart';
import 'package:hukuk_reels/features/home/home_tab.dart';
import 'package:hukuk_reels/features/shell/home_shell.dart';
import 'package:hukuk_reels/features/study/study_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _frames(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _shell(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.reset);
  await tester
      .pumpWidget(MaterialApp(theme: AppTheme.dark, home: const HomeShell()));
  await _frames(tester, 300);
}

Future<void> _tab(WidgetTester tester, String area) async {
  await tester.tap(find.byKey(ValueKey('tab-$area')));
  await _frames(tester, 300);
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

  test('greeting follows the clock', () {
    expect(greeting(DateTime(2026, 1, 1, 4, 59)), 'İyi geceler');
    expect(greeting(DateTime(2026, 1, 1, 5)), 'Günaydın');
    expect(greeting(DateTime(2026, 1, 1, 12)), 'İyi günler');
    expect(greeting(DateTime(2026, 1, 1, 18)), 'İyi akşamlar');
    expect(greeting(DateTime(2026, 1, 1, 23)), 'İyi geceler');
  });

  testWidgets('tabs switch pages, report their area and keep state',
      (tester) async {
    await _shell(tester, const Size(393, 852));
    expect(find.byType(HomeTab), findsOneWidget);
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    expect(ActivityArea.instance.current, 'home');
    // Diğer sekmeler ilk dokunuşa kadar kurulmaz.
    expect(find.byType(StudyScreen, skipOffstage: false), findsNothing);

    await _tab(tester, 'games');
    expect(find.text('Oyunlar'), findsWidgets);
    expect(find.byKey(const ValueKey('game-Adliye Kulesi')), findsOneWidget);
    expect(ActivityArea.instance.current, 'games');

    await _tab(tester, 'study');
    expect(find.text('ÖZETLER'), findsOneWidget);
    expect(ActivityArea.instance.current, 'study');

    await _tab(tester, 'profile');
    expect(find.text('Profil & Ayarlar'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(ActivityArea.instance.current, 'profile');

    // Açılmış sekmeler arka planda yaşar.
    expect(find.byType(StudyScreen, skipOffstage: false), findsOneWidget);
    await _tab(tester, 'home');
    expect(ActivityArea.instance.current, 'home');

    await tester.pumpWidget(const SizedBox());
    await _frames(tester, 50);
    expect(ActivityArea.instance.current, 'other');
  });

  testWidgets('re-tapping the active tab scrolls back to the top',
      (tester) async {
    await _shell(tester, const Size(320, 568));
    await _tab(tester, 'study');
    final list = find.byType(Scrollable).first;
    await tester.drag(list, const Offset(0, -400));
    await _frames(tester, 400);
    final pos = tester.state<ScrollableState>(list).position;
    expect(pos.pixels, greaterThan(0));
    await _tab(tester, 'study');
    await _frames(tester, 300);
    expect(pos.pixels, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('start cards open the games and study tabs', (tester) async {
    await tester.runAsync(ProgressService.instance.clearBlockGame);
    await _shell(tester, const Size(393, 852));
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('start-games')), 200);
    expect(find.byKey(const ValueKey('continue-block')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('start-games')));
    await _frames(tester, 300);
    expect(ActivityArea.instance.current, 'games');
    await _tab(tester, 'home');
    await tester.tap(find.byKey(const ValueKey('start-study')));
    await _frames(tester, 300);
    expect(ActivityArea.instance.current, 'study');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an unfinished Block Blast game shows a continue card',
      (tester) async {
    final g = BlockBlastEngine()..score = 120;
    await tester
        .runAsync(() => ProgressService.instance.saveBlockGame(g.toJson()));
    await _shell(tester, const Size(393, 852));
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('continue-block')), 200);
    expect(find.text('Devam eden oyun · 120 puan'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-games')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(ProgressService.instance.clearBlockGame);
  });

  testWidgets('beat card is disabled until there are wrong answers',
      (tester) async {
    await _shell(tester, const Size(393, 852));
    await _tab(tester, 'study');
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('study-bank')), 200);
    final beat = find.byKey(const ValueKey('study-beat'));
    expect(tester.widget(beat), isA<Opacity>());
    expect(find.byKey(const ValueKey('study-retry')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('wide landscape uses a side rail instead of the bottom bar',
      (tester) async {
    await _shell(tester, const Size(1180, 820));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('Oyunlar').first);
    await _frames(tester, 300);
    expect(ActivityArea.instance.current, 'games');
    // Dikeye dönünce alt çubuk geri gelir, sekme korunur.
    tester.view.physicalSize = const Size(820, 1180) * 2;
    await _frames(tester, 300);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const ValueKey('game-Block Blast')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
