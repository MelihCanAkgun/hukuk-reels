import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/profile/activity_screen.dart';
import 'package:hukuk_reels/features/profile/profile_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 18 Ekim 2026 Cumartesi 21:30 (yerel saat).
final _now = DateTime(2026, 10, 18, 21, 30);
int _s(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

Map<String, dynamic> _activity() => {
      'connected': true,
      'now': _s(_now),
      'players': [
        {'id': 1, 'name': 'mqcan 😎', 'lastSeen': _s(_now)},
        {
          'id': 2,
          'name': 'ari',
          'lastSeen': _s(_now.subtract(const Duration(minutes: 12)))
        },
      ],
      'sessions': [
        {
          'player': 1,
          'started': _s(DateTime(2026, 10, 18, 21, 5)),
          'last': _s(_now),
          'device': 'ipad'
        },
        {
          'player': 2,
          'started': _s(DateTime(2026, 10, 18, 20, 40)),
          'last': _s(DateTime(2026, 10, 18, 21, 18)),
          'device': 'iphone'
        },
        {
          'player': 2,
          'started': _s(DateTime(2026, 10, 17, 23, 41)),
          'last': _s(DateTime(2026, 10, 18, 0, 6)),
          'device': 'iphone'
        },
        {
          'player': 1,
          'started': _s(DateTime(2026, 10, 14, 9, 0)),
          'last': _s(DateTime(2026, 10, 14, 9, 0, 30)),
          'device': 'mac'
        },
      ],
    };

Map<String, dynamic> _state(int me) => {
      'configured': true,
      'connected': true,
      'me': me,
      'players': [
        {'id': 1, 'name': 'mqcan 😎', 'best': 10, 'active': 1},
        {'id': 2, 'name': 'ari', 'best': 5, 'active': 1},
      ],
    };

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'flower_surprise_seen_v2': true});
    await ProgressService.instance.init();
  });

  test('time labels', () {
    expect(seenLabel(_now.subtract(const Duration(seconds: 20)), _now),
        'az önce');
    expect(seenLabel(_now.subtract(const Duration(minutes: 12)), _now),
        '12 dk önce');
    expect(seenLabel(DateTime(2026, 10, 18, 8), _now), '13 sa önce');
    expect(seenLabel(DateTime(2026, 10, 17, 23, 41), _now), 'dün 23:41');
    expect(seenLabel(DateTime(2026, 10, 14, 9, 5), _now), '14 Ekim 09:05');
    expect(seenLabel(DateTime(2025, 12, 31, 9, 5), _now),
        '31 Aralık 2025 09:05');
    expect(dayLabel(DateTime(2026, 10, 18, 1), _now), 'Bugün');
    expect(dayLabel(DateTime(2026, 10, 17, 23), _now), 'Dün');
    expect(dayLabel(DateTime(2026, 10, 14, 9), _now), '14 Ekim Çarşamba');
    expect(whenLabel(DateTime(2026, 10, 18, 9, 5), _now), '09:05');
    expect(whenLabel(DateTime(2026, 10, 17, 9, 5), _now), 'dün 09:05');
    expect(lengthLabel(const Duration(seconds: 30)), "1 dk'dan kısa");
    expect(lengthLabel(const Duration(minutes: 25)), '25 dk');
    expect(lengthLabel(const Duration(minutes: 120)), '2 sa');
    expect(lengthLabel(const Duration(minutes: 125)), '2 sa 5 dk');
  });

  for (final size in const [Size(320, 568), Size(393, 852), Size(1180, 820)]) {
    testWidgets('activity shows last seen and entries on $size',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          home: ActivityScreen(
              load: () async => _activity(), clock: () => _now)));
      await tester.pump();
      expect(find.text('Şu an aktif'), findsOneWidget);
      expect(find.text('Son görülme: 12 dk önce'), findsOneWidget);
      expect(find.text('Son giriş 21:05'), findsOneWidget);
      expect(find.text('Son giriş 20:40'), findsOneWidget);
      expect(find.text('21:05 → şu an'), findsOneWidget);
      expect(find.text('20:40 → 21:18'), findsOneWidget);
      expect(find.text('38 dk'), findsOneWidget);
      // ari: iki giriş (63 dk), mqcan: iki giriş (25 dk + 30 sn).
      expect(find.text('7 gün: 2 giriş · 1 sa 3 dk'), findsOneWidget);
      expect(find.text('7 gün: 2 giriş · 25 dk'), findsOneWidget);
      final list = find.byType(Scrollable).first;
      for (final label in ['Bugün', 'Dün', '14 Ekim Çarşamba']) {
        await tester.scrollUntilVisible(find.text(label), 200,
            scrollable: list);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('filter keeps only one player\'s entries', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home:
            ActivityScreen(load: () async => _activity(), clock: () => _now)));
    await tester.pump();
    expect(find.text('20:40 → 21:18'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'mqcan 😎'));
    await tester.pump();
    expect(find.text('20:40 → 21:18'), findsNothing);
    expect(find.text('21:05 → şu an'), findsOneWidget);
    expect(find.text('Dün'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tümü'));
    await tester.pump();
    expect(find.text('20:40 → 21:18'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a refused request shows no data', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ActivityScreen(
            load: () async => {'error': 'Bulunamadı.', 'status': 404},
            clock: () => _now)));
    await tester.pump();
    expect(find.text('Bu bölüm yalnız yönetici hesabında açılır.'),
        findsOneWidget);
    expect(find.text('GİRİŞLER'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (final me in [1, 2]) {
    testWidgets('profile shows Aktiflik only to Player 1 (me: $me)',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          home: ProfileSettingsScreen(loadState: () async => _state(me))));
      await tester.pump(const Duration(milliseconds: 300));
      final list = find.byType(Scrollable).first;
      // Listenin sonuna kadar kaydır: her bölüm bir kez kurulmuş olur.
      await tester.scrollUntilVisible(find.text('Her şeyi sıfırla'), 300,
          scrollable: list);
      await tester.dragUntilVisible(
          find.text('Her şeyi sıfırla'), list, const Offset(0, 200));
      if (me == 1) {
        await tester.scrollUntilVisible(find.text('Aktiflik'), -200,
            scrollable: list);
        expect(find.text('YÖNETİCİ'), findsOneWidget);
        await tester.tap(find.text('Aktiflik'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(ActivityScreen), findsOneWidget);
      } else {
        for (var y = 0; y < 30; y++) {
          expect(find.text('Aktiflik'), findsNothing);
          expect(find.text('YÖNETİCİ'), findsNothing);
          await tester.drag(list, const Offset(0, 120));
          await tester.pump();
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
