import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/app/theme.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/core/widgets/pixel_logo_data.dart';
import 'package:hukuk_reels/features/game/game_leaderboard.dart';
import 'package:hukuk_reels/features/games/games_screen.dart';
import 'package:hukuk_reels/features/weekly/weekly_screen.dart';
import 'package:hukuk_reels/features/weekly/weekly_shelf.dart';
import 'package:hukuk_reels/features/weekly/weekly_store.dart';
import 'package:hukuk_reels/features/weekly/weekly_trophies.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tur 2026-11-13 20:00'de (Türkiye) başladı, 7 gün sürer.
const _start = 1794589200;
const _end = _start + 7 * 86400;

Map<String, dynamic> _result(int id, int winner,
        {bool coin = false, List<int> wins = const [3, 1]}) =>
    {
      'id': id,
      'start': _start - (10 - id) * 8 * 86400,
      'end': _start - (10 - id) * 8 * 86400 + 7 * 86400,
      'winner': winner,
      'wins': {'1': wins[0], '2': wins[1]},
      'coin': coin,
      'trophy': (id - 1) % 7,
      'detail': [
        {'game': 'block', 's1': 900, 's2': 400},
        {'game': 'flappy', 's1': 12, 's2': 30},
        {'game': 'subway', 's1': 0, 's2': 0},
        {'game': 'tower', 's1': 7, 's2': 7},
      ],
    };

Map<String, dynamic> _state({
  List<Map<String, dynamic>> scores = const [],
  List<Map<String, dynamic>> history = const [],
  Map<String, dynamic>? reveal,
  bool round = true,
  int me = 1,
  Map<String, dynamic> extra = const {},
}) =>
    {
      'now': _start + 3600,
      'me': me,
      'round': round
          ? {'id': 9, 'start': _start, 'end': _end, 'trophy': 1, 'startedBy': 1}
          : null,
      'canStart': me == 1 && !round,
      'nextTrophy': 2,
      'players': [
        {'id': 1, 'name': 'mqcan'},
        {'id': 2, 'name': 'ari'},
      ],
      'scores': scores,
      'wins': {'1': 0, '2': 0},
      'totals': {
        '1': history.where((h) => h['winner'] == 1).length,
        '2': history.where((h) => h['winner'] == 2).length,
      },
      'history': history,
      'reveal': reveal,
      'connected': true,
      ...extra,
    };

Map<String, dynamic> _score(int player, String game, int best) =>
    {'player': player, 'game': game, 'best': best};

class _Server {
  _Server(this.state);
  Map<String, dynamic> state;
  final calls = <String>[];
  final seen = <int>[];

  Future<Map<String, dynamic>> call(String action,
      [Map<String, dynamic> data = const {}]) async {
    calls.add(action);
    if (action == 'weeklySeen') {
      seen.add(data['round'] as int);
      state = {...state, 'reveal': null};
    }
    if (action == 'weeklyStart') state = _state(me: state['me'] as int);
    if (action == 'weeklyCancel') {
      state = _state(me: state['me'] as int, round: false);
    }
    return state;
  }
}

Future<_Server> _open(WidgetTester tester, Map<String, dynamic> state,
    {Widget home = const WeeklyScreen()}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(393, 852) * 2;
  addTearDown(tester.view.reset);
  final server = _Server(state);
  WeeklyStore.instance
    ..reset()
    ..call = server.call
    ..clock = () => DateTime.fromMillisecondsSinceEpoch(
        (_start + 2 * 86400 + 5 * 3600) * 1000);
  addTearDown(WeeklyStore.instance.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: home));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return server;
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.init();
  });

  test('yedi farklı kupa; sprite satırları eşit genişlikte', () {
    expect(kWeeklyTrophies.length, 7);
    expect(kWeeklyTrophies.map((t) => t.name).toSet().length, 7);
    for (final t in kWeeklyTrophies) {
      expect(t.sprite.map((r) => r.length).toSet().length, 1, reason: t.name);
      for (final ch in t.sprite.join().split('')) {
        expect(ch == '.' || kLogoPalette.containsKey(ch), isTrue,
            reason: '${t.name}: $ch');
      }
    }
    expect(weeklyTrophy(9).name, kWeeklyTrophies[2].name);
  });

  test('tur aralığı ve kalan süre metinleri', () {
    DateTime at(int seconds) =>
        DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    expect(roundRangeText(DateTime(2026, 11, 13), DateTime(2026, 11, 20)),
        '13–20 Kas');
    expect(roundRangeText(DateTime(2026, 11, 28), DateTime(2026, 12, 5)),
        '28 Kas–5 Ara');
    final r = WeeklyData.fromJson(_state()).round!;
    expect(r.remaining(at(_start + 86400)), '6 gün 0 sa');
    expect(r.remaining(at(_end - 3 * 3600 - 60)), '3 sa 1 dk');
    expect(r.remaining(at(_end - 20)), '1 dk');
    expect(r.remaining(at(_end + 5)), 'bitti');
  });

  test('durum: yüksek skor oyunu alır; gönderilmemiş yerel skor sayılır', () {
    final d = WeeklyData.fromJson(_state(scores: [
      _score(1, 'block', 500),
      _score(2, 'block', 800),
      _score(1, 'tower', 9),
      _score(2, 'tower', 9),
      _score(2, 'flappy', 14),
    ], extra: {
      'localBests': {'block': 950, 'flappy': 3},
    }));
    expect(d.scoreOf(LeaderboardGame.block, 1), 950);
    expect(d.leaderOf(LeaderboardGame.block), 1);
    expect(d.leaderOf(LeaderboardGame.tower), isNull);
    expect(d.leaderOf(LeaderboardGame.flappy), 2);
    expect(d.leaderOf(LeaderboardGame.subway), isNull);
    expect([d.winsOf(1), d.winsOf(2)], [1, 1]);
  });

  testWidgets('ekran: kupa, durum, skorlar, raf ve geçmiş', (tester) async {
    await _open(
        tester,
        _state(scores: [
          _score(1, 'block', 500),
          _score(2, 'block', 800),
          _score(1, 'tower', 9),
          _score(1, 'subway', 120),
        ], history: [
          _result(8, 1),
          _result(7, 2, coin: true, wins: [2, 2]),
          _result(1, 1),
        ]));
    expect(_text(tester, 'weekly-trophy'), kWeeklyTrophies[1].name);
    expect(_text(tester, 'weekly-remaining'), '13–20 Kas · 4 gün 19 sa kaldı');
    expect(_text(tester, 'weekly-standing'), '2 – 1');
    expect(_text(tester, 'weekly-block-2'), '800');
    expect(_text(tester, 'weekly-tower-1'), '9 kat');
    expect(_text(tester, 'weekly-flappy-1'), '–');
    expect(find.text('ari önde'), findsOneWidget);
    expect(find.text('Öndesin'), findsNWidgets(2));
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('weekly-history-7')), 300);
    expect(find.text('2 tur kazandı'), findsOneWidget);
    expect(find.text('1 tur kazandı'), findsOneWidget);
    expect(find.text('ari kazandı (yazı tura)'), findsOneWidget);
    // Aynı kupa iki kez kazanıldı: "×2".
    expect(find.text('×2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('biten turun sonucu bir kez gösterilir', (tester) async {
    final server =
        await _open(tester, _state(round: false, reveal: _result(8, 2)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('TURUN SONUCU'), findsOneWidget);
    expect(_text(tester, 'weekly-winner-name'), 'ari');
    expect(find.byKey(const ValueKey('coin-flip')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('weekly-result-close')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(server.seen, [8]);
    expect(find.text('TURUN SONUCU'), findsNothing);
  });

  testWidgets('eşitlikte yazı tura atılır, sonra kazanan görünür',
      (tester) async {
    await _open(
        tester,
        _state(
            round: false,
            reveal: _result(8, 1, coin: true, wins: const [2, 2])));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('weekly-tie')), findsOneWidget);
    expect(find.byKey(const ValueKey('weekly-winner-name')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('weekly-flip')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('coin-flip')), findsOneWidget);
    // Para dönerken çerçeveler hatasız çizilir.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(_text(tester, 'weekly-winner-name'), 'mqcan');
    expect(find.textContaining('Tebrikler!'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('weekly-result-close')));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('tur yokken yönetici başlatır ve iptal edebilir', (tester) async {
    final server = await _open(tester, _state(round: false));
    expect(find.byKey(const ValueKey('weekly-idle')), findsOneWidget);
    expect(find.text(kWeeklyTrophies[2].name), findsOneWidget);
    expect(find.byKey(const ValueKey('weekly-cancel')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('weekly-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(server.calls, contains('weeklyStart'));
    expect(find.byKey(const ValueKey('weekly-standing')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('weekly-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('weekly-cancel-confirm')));
    await tester.pumpAndSettle();
    expect(server.calls, contains('weeklyCancel'));
    expect(find.byKey(const ValueKey('weekly-idle')), findsOneWidget);
  });

  testWidgets('diğer oyuncu turu başlatamaz, bekler', (tester) async {
    await _open(tester, _state(round: false, me: 2));
    expect(find.byKey(const ValueKey('weekly-start')), findsNothing);
    expect(find.textContaining('Yeni turu mqcan başlatacak'), findsOneWidget);
    await _open(tester, _state(me: 2));
    expect(find.byKey(const ValueKey('weekly-cancel')), findsNothing);
  });

  testWidgets('Oyunlar sekmesindeki kart durumu gösterir', (tester) async {
    await _open(
        tester,
        _state(scores: [
          _score(1, 'block', 500),
          _score(2, 'tower', 3),
          _score(2, 'flappy', 3),
        ]),
        home: const GamesScreen());
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('weekly-card')), 200);
    expect(_text(tester, 'weekly-card-status'), '1 – 2 · 4 gün 19 sa kaldı');
    await tester.tap(find.byKey(const ValueKey('weekly-card')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('weekly-standing')), findsOneWidget);
    await tester.tap(find.byTooltip('Geri'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('profildeki raf kazanılan kupaları sayar; bağlı değilken gizli',
      (tester) async {
    await _open(tester, _state(history: [_result(8, 1)]),
        home: const Scaffold(body: WeeklyTrophyShelf()));
    expect(_text(tester, 'profile-trophy-count'), '1 tur kazandın');
    await _open(tester, {'connected': false},
        home: const Scaffold(body: WeeklyTrophyShelf()));
    expect(find.byKey(const ValueKey('profile-trophies')), findsNothing);
  });
}
