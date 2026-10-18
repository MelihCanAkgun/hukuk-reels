import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/core/services/activity_area.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/profile/activity_screen.dart';
import 'package:hukuk_reels/features/profile/profile_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 18 Ekim 2026 Pazar 21:30 (yerel saat).
final _now = DateTime(2026, 10, 18, 21, 30);
int _s(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

Map<String, dynamic> _session(
        int player, DateTime started, DateTime last, String device,
        [String area = 'other']) =>
    {
      'player': player,
      'started': _s(started),
      'last': _s(last),
      'device': device,
      'area': area
    };

Map<String, dynamic> _activity() {
  final today = trDay(_now);
  return {
    'connected': true,
    'now': _s(_now),
    'today': today,
    'players': [
      {'id': 1, 'name': 'mqcan 😎', 'lastSeen': _s(_now)},
      {
        'id': 2,
        'name': 'ari',
        'lastSeen': _s(_now.subtract(const Duration(minutes: 12)))
      },
    ],
    // Sunucu sırası: başlangıca göre yeniden eskiye.
    'sessions': [
      _session(1, DateTime(2026, 10, 18, 21, 5), _now, 'ipad', 'block'),
      _session(2, DateTime(2026, 10, 18, 20, 40),
          DateTime(2026, 10, 18, 21, 18), 'iphone'),
      _session(2, DateTime(2026, 10, 17, 23, 41), DateTime(2026, 10, 18, 0, 6),
          'iphone'),
      _session(1, DateTime(2026, 10, 14, 9, 0),
          DateTime(2026, 10, 14, 9, 0, 30), 'mac'),
      _session(
          1, DateTime(2026, 9, 28, 10, 0), DateTime(2026, 9, 28, 11, 0), 'mac'),
    ],
    'usage': [
      {'player': 1, 'day': today, 'area': 'block', 'seconds': 1500},
      {'player': 1, 'day': today, 'area': 'home', 'seconds': 300},
      {'player': 2, 'day': today, 'area': 'summaries', 'seconds': 2280},
      {'player': 1, 'day': today - 20, 'area': 'tower', 'seconds': 3600},
    ],
  };
}

Map<String, dynamic> _state(int me) => {
      'configured': true,
      'connected': true,
      'me': me,
      'players': [
        {'id': 1, 'name': 'mqcan 😎', 'best': 10, 'active': 1},
        {'id': 2, 'name': 'ari', 'best': 5, 'active': 1},
      ],
    };

ActivityStats _stats({int days = 7, int? player}) {
  final r = _activity();
  return ActivityStats(
      sessions: parseActivitySessions(r),
      usage: parseActivityUsage(r),
      now: _now,
      days: days,
      player: player,
      today: r['today'] as int);
}

Future<void> _open(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
      home: ActivityScreen(load: () async => _activity(), clock: () => _now)));
  await tester.pump();
}

Future<void> _scrollTo(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 250, scrollable: find.byType(Scrollable).first);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'flower_surprise_seen_v2': true});
    await ProgressService.instance.init();
  });

  test('time labels', () {
    expect(
        seenLabel(_now.subtract(const Duration(seconds: 20)), _now), 'az önce');
    expect(seenLabel(_now.subtract(const Duration(minutes: 12)), _now),
        '12 dk önce');
    expect(seenLabel(DateTime(2026, 10, 18, 8), _now), '13 sa önce');
    expect(seenLabel(DateTime(2026, 10, 17, 23, 41), _now), 'dün 23:41');
    expect(seenLabel(DateTime(2026, 10, 14, 9, 5), _now), '14 Ekim 09:05');
    expect(
        seenLabel(DateTime(2025, 12, 31, 9, 5), _now), '31 Aralık 2025 09:05');
    expect(dayLabel(DateTime(2026, 10, 18, 1), _now), 'Bugün');
    expect(dayLabel(DateTime(2026, 10, 17, 23), _now), 'Dün');
    expect(dayLabel(DateTime(2026, 10, 14, 9), _now), '14 Ekim Çarşamba');
    expect(whenLabel(DateTime(2026, 10, 18, 9, 5), _now), '09:05');
    expect(whenLabel(DateTime(2026, 10, 17, 9, 5), _now), 'dün 09:05');
    expect(lengthLabel(const Duration(seconds: 30)), "1 dk'dan kısa");
    expect(lengthLabel(const Duration(minutes: 25)), '25 dk');
    expect(lengthLabel(const Duration(minutes: 120)), '2 sa');
    expect(lengthLabel(const Duration(minutes: 125)), '2 sa 5 dk');
    expect(peakLabel((7, 23)), 'Pazar 23:00–00:00');
  });

  test('stats split sessions by hour and day and follow the period', () {
    final week = _stats();
    expect(week.entries, 4);
    expect(week.total, const Duration(minutes: 88, seconds: 30));
    expect(week.longest, const Duration(minutes: 38));
    // Gece yarısını geçen oturum iki güne bölünür.
    expect(week.daily[5][2], const Duration(minutes: 19));
    expect(week.daily[6][2], const Duration(minutes: 38 + 6));
    expect(week.daily[6][1], const Duration(minutes: 25));
    expect(week.heat[6][21], const Duration(minutes: 25 + 18));
    expect(week.heat[6][20], const Duration(minutes: 20));
    expect(week.heat[5][23], const Duration(minutes: 19));
    expect(week.peak, (7, 21));
    expect(week.heatLevel(6, 21), 1);
    expect(week.areas, [
      ('summaries', const Duration(minutes: 38)),
      ('block', const Duration(minutes: 25)),
      ('home', const Duration(minutes: 5)),
    ]);

    final month = _stats(days: 30);
    expect(month.entries, 5);
    expect(month.peak, (1, 10));
    expect(month.areas.first, ('tower', const Duration(hours: 1)));

    final mine = _stats(player: 1);
    expect(mine.entries, 2);
    expect(mine.total, const Duration(minutes: 25, seconds: 30));
    expect(mine.areas.map((a) => a.$1), ['block', 'home']);
    expect(mine.daily[6][2], isNull);
  });

  test('a session that started before the period counts only inside it', () {
    final s = ActivityStats(
      sessions: [
        ActivitySession(1, DateTime(2026, 10, 11, 23, 30),
            DateTime(2026, 10, 12, 0, 45), 'ipad')
      ],
      usage: const [],
      now: _now,
      days: 7,
    );
    expect(s.start, DateTime(2026, 10, 12));
    expect(s.entries, 0, reason: 'started before the period');
    expect(s.total, const Duration(minutes: 45));
    expect(s.daily[0][1], const Duration(minutes: 45));
  });

  for (final size in const [Size(320, 568), Size(393, 852), Size(1180, 820)]) {
    testWidgets('activity lays out every section on $size', (tester) async {
      await _open(tester, size);
      expect(find.text('Şu an aktif · Block Blast'), findsOneWidget);
      expect(find.text('Son görülme: 12 dk önce'), findsOneWidget);
      expect(find.text('Son giriş 21:05'), findsOneWidget);
      expect(find.text('Son giriş 20:40'), findsOneWidget);
      // ari: iki giriş (63 dk), mqcan: iki giriş (25 dk + 30 sn).
      expect(find.text('7 gün: 2 giriş · 1 sa 3 dk'), findsOneWidget);
      expect(find.text('7 gün: 2 giriş · 25 dk'), findsOneWidget);
      await _scrollTo(
          tester, find.byKey(const ValueKey('activity-stat-Giriş')));
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('activity-stat-Toplam süre')))
              .data,
          '1 sa 28 dk');
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('activity-stat-Giriş')))
              .data,
          '4');
      await _scrollTo(tester, find.byKey(const ValueKey('activity-peak')));
      expect(find.text('En aktif saat: Pazar 21:00–22:00'), findsOneWidget);
      await _scrollTo(
          tester, find.byKey(const ValueKey('activity-area-summaries')));
      expect(find.text('38 dk · %56'), findsOneWidget);
      expect(find.text('25 dk · %37'), findsOneWidget);
      await _scrollTo(tester, find.text('21:05 → şu an'));
      await _scrollTo(tester, find.text('20:40 → 21:18'));
      expect(find.text('38 dk'), findsWidgets);
      await _scrollTo(tester, find.text('14 Ekim Çarşamba'));
      expect(find.text('28 Eylül Pazartesi'), findsNothing,
          reason: 'outside the 7-day period');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('period and player filters change every section', (tester) async {
    await _open(tester, const Size(393, 3000));
    await tester.tap(find.text('30 gün'));
    await tester.pump();
    expect(find.text('En aktif saat: Pazartesi 10:00–11:00'), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-area-tower')), findsOneWidget);
    expect(find.text('28 Eylül Pazartesi'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'ari'));
    await tester.pump();
    expect(find.byKey(const ValueKey('activity-area-tower')), findsNothing);
    expect(find.text('21:05 → şu an'), findsNothing);
    expect(find.text('20:40 → 21:18'), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('activity-stat-Giriş')))
            .data,
        '2');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tümü'));
    await tester.tap(find.text('7 gün'));
    await tester.pump();
    expect(find.text('21:05 → şu an'), findsOneWidget);
    expect(find.text('28 Eylül Pazartesi'), findsNothing);
    expect(tester.takeException(), isNull);
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

  testWidgets('the top screen is reported as the current area', (tester) async {
    final sent = <String>[];
    ActivityArea.instance
      ..reset()
      ..call = (action, [data = const {}]) async {
        if (action == 'area') sent.add(data['area'] as String);
        return {};
      };
    addTearDown(() => ActivityArea.instance.reset());
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
        navigatorKey: nav,
        home: const ActivityAreaScope(area: 'home', child: SizedBox())));
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) =>
            const ActivityAreaScope(area: 'block', child: SizedBox())));
    await tester.pumpAndSettle();
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) =>
            const ActivityAreaScope(area: 'block', child: SizedBox())));
    await tester.pumpAndSettle();
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(sent, ['home', 'block'], reason: 'same area is not resent');
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(sent, ['home', 'block', 'home']);
    expect(ActivityArea.instance.current, 'home');
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
      if (me == 1) {
        await tester.scrollUntilVisible(find.text('Aktiflik'), 200,
            scrollable: list);
        expect(find.text('YÖNETİCİ'), findsOneWidget);
        await tester.tap(find.text('Aktiflik'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(ActivityScreen), findsOneWidget);
      } else {
        // Listenin sonuna kadar her bölüm kurulur; yönetici satırı hiç yok.
        for (var y = 0; y < 40; y++) {
          expect(find.text('Aktiflik'), findsNothing);
          expect(find.text('YÖNETİCİ'), findsNothing);
          await tester.drag(list, const Offset(0, -150));
          await tester.pump();
        }
        expect(find.text('Her şeyi sıfırla'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('profile records include Adliye Kulesi', (tester) async {
    await ProgressService.instance.submitTowerScore(12);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ProfileSettingsScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('record-Adliye Kulesi')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('record-Adliye Kulesi')))
            .data,
        '${ProgressService.instance.towerHigh} kat');
    expect(ProgressService.instance.towerHigh, greaterThanOrEqualTo(12));
    for (final name in ['Block Blast', 'Flappy Cat', 'Subway Silly']) {
      expect(find.byKey(ValueKey('record-$name')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
