import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/app/theme.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/films/film_store.dart';
import 'package:hukuk_reels/features/films/film_swipe.dart';
import 'package:hukuk_reels/features/films/film_swipe_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _card(int pos, {bool suggested = false}) => {
      'pos': pos,
      'filmId': suggested ? null : 100 + pos,
      'tmdbId': 1000 + pos,
      'suggested': suggested,
      'title': 'Film $pos',
      'originalTitle': 'Movie $pos',
      'year': 2010 + pos,
      'runtime': suggested ? null : 100 + pos,
      'genres': ['Dram', 'Gerilim', 'Suç'],
      'overview': 'Özet $pos',
      'poster': null,
      'tmdbRating': 7.5,
      'imdbRating': null,
      'showTitle': null,
      'season': null,
      'episode': null,
    };

/// Sahte Worker: oyları saklar; ikinci oyuncu [otherVotes] ile oy vermiştir.
class _Server {
  _Server({this.cards = 4, this.otherVotes});
  final int cards;

  /// Diğer oyuncunun oyları (kart sırası → oy); null: henüz oylamadı.
  final Map<int, int>? otherVotes;
  final calls = <String>[];
  final votes = <int, int>{};
  bool started = false, offline = false;
  Completer<void>? gate;

  Map<String, dynamic> state() {
    if (!started) return {'session': null, 'me': 1};
    final all = [
      for (var i = 0; i < cards; i++) _card(i, suggested: i == cards - 1)
    ];
    final done = votes.length >= cards && otherVotes != null;
    return {
      'me': 1,
      'players': [
        {'id': 1, 'name': 'mqcan'},
        {'id': 2, 'name': 'ari'},
      ],
      'session': {
        'id': 5,
        'status': done ? 'done' : 'open',
        'startedBy': 1,
        'created': 1,
        'total': cards,
        'cards': all,
        'votes': {for (final e in votes.entries) '${e.key}': e.value},
        'superUsed': votes.containsValue(2),
        'otherCount': otherVotes == null ? 1 : cards,
        'otherDone': otherVotes != null,
        'matches': done
            ? [
                for (final c in all)
                  if ((votes[c['pos']] ?? 0) > 0 &&
                      (otherVotes![c['pos']] ?? 0) > 0)
                    {
                      ...c,
                      'supers': [
                        if (votes[c['pos']] == 2) 1,
                        if (otherVotes![c['pos']] == 2) 2,
                      ]
                    }
              ]
            : null,
      },
    };
  }

  Future<Map<String, dynamic>> call(String action,
      [Map<String, dynamic> data = const {}]) async {
    calls.add(action);
    await gate?.future;
    if (offline) return {'error': 'Bağlantı kurulamadı.'};
    if (action == 'swipeStart') started = true;
    if (action == 'swipeCancel') {
      started = false;
      votes.clear();
    }
    if (action == 'swipeVote') {
      votes[data['pos'] as int] = data['vote'] as int;
    }
    return state();
  }
}

Future<_Server> _open(WidgetTester tester, _Server server) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(393, 852) * 2;
  addTearDown(tester.view.reset);
  SwipeStore.instance
    ..reset()
    ..call = server.call;
  // Liste tazelemesi gerçek köprüye gitmesin.
  FilmStore.instance.call = (String action,
          [Map<String, dynamic> data = const {}]) async =>
      {'films': [], 'connected': true, 'me': 1};
  addTearDown(SwipeStore.instance.reset);
  // Aynı testte ikinci açılış: ekran baştan kurulsun.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const FilmSwipeScreen()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return server;
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await _fly(tester);
}

/// Düğmenin basılı kalma süresi, kartın uçuşu (220 ms) ve oyun işlenmesi.
Future<void> _fly(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 50));
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.init();
  });

  test('kart bilgileri ve oturum durumu', () {
    final c = SwipeCard.fromJson(_card(3));
    expect(c.meta, '2013 · 1 sa 43 dk · Dram, Gerilim');
    expect(c.posterUrl(), isNull);
    final e = SwipeCard.fromJson(
        {..._card(1), 'showTitle': 'Black Mirror', 'season': 3, 'episode': 1});
    expect(e.episodeLabel, 'Black Mirror · S3:B1');
    final server = _Server()..started = true;
    server.votes[0] = 1;
    final s = SwipeSession.fromJson(
        (server.state()['session'] as Map).cast<String, dynamic>());
    expect(s.next!.pos, 1);
    expect([s.mineDone, s.superUsed, s.isOpen], [false, false, true]);
    final summary = SwipeSummary.fromJson({
      'id': 5,
      'status': 'open',
      'startedBy': 2,
      'total': 15,
      'mine': 4,
      'otherDone': false
    });
    expect(summary.myTurn, isTrue);
  });

  testWidgets('başlat, düğmelerle oyla, diğerini bekle', (tester) async {
    final server = await _open(tester, _Server());
    await tester.tap(find.byKey(const ValueKey('swipe-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_text(tester, 'swipe-progress'), '1 / 4');
    expect(_text(tester, 'swipe-title'), 'Film 0');
    expect(find.text('LİSTENİZDEN'), findsWidgets);
    await _tap(tester, 'swipe-like');
    expect(_text(tester, 'swipe-title'), 'Film 1');
    await _tap(tester, 'swipe-super');
    expect(_text(tester, 'swipe-progress'), '3 / 4');
    // Süper beğeni bir kez: ikinci dokunuş oy vermez.
    await _tap(tester, 'swipe-super');
    expect(_text(tester, 'swipe-progress'), '3 / 4');
    await _tap(tester, 'swipe-pass');
    expect(find.text('YENİ ÖNERİ'), findsOneWidget);
    await _tap(tester, 'swipe-like');
    expect(server.votes, {0: 1, 1: 2, 2: 0, 3: 1});
    expect(find.byKey(const ValueKey('swipe-waiting')), findsOneWidget);
    expect(find.textContaining('ari bekleniyor (1/4)'), findsOneWidget);
    expect(find.text('BEĞENDİKLERİN (3)'), findsOneWidget);
    expect(find.text('Süper beğendin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'kartı sağa sürüklemek beğenir, sola geçer, az sürükleme oy vermez',
      (tester) async {
    final server = await _open(tester, _Server()..started = true);
    final card = find.byKey(const ValueKey('swipe-card'));
    await tester.drag(card, const Offset(40, 0));
    await _fly(tester);
    expect(server.votes, isEmpty);
    await tester.drag(card, const Offset(220, 0));
    await _fly(tester);
    expect(server.votes, {0: 1});
    await tester.drag(card, const Offset(-220, 0));
    await _fly(tester);
    await tester.drag(card, const Offset(0, -260));
    await _fly(tester);
    expect(server.votes, {0: 1, 1: 0, 2: 2});
    expect(tester.takeException(), isNull);
  });

  testWidgets('bağlantı yavaşken kaydırma beklemez; kopunca oylar saklanır',
      (tester) async {
    final server = await _open(tester, _Server()..started = true);
    server.gate = Completer<void>();
    await _tap(tester, 'swipe-like');
    await _tap(tester, 'swipe-pass');
    // Sunucu henüz yanıt vermedi ama ekran üçüncü kartta.
    expect(_text(tester, 'swipe-title'), 'Film 2');
    expect(server.votes, isEmpty);
    expect(SwipeStore.instance.sending, isTrue);
    server.offline = true;
    server.gate!.complete();
    server.gate = null;
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey('swipe-retry')), findsOneWidget);
    expect(_text(tester, 'swipe-title'), 'Film 2');
    // Bağlantı geldi: bekleyen oylar sırayla gider.
    server.offline = false;
    await tester.tap(find.byKey(const ValueKey('swipe-retry')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(server.votes, {0: 1, 1: 0});
    expect(SwipeStore.instance.sending, isFalse);
    expect(find.byKey(const ValueKey('swipe-retry')), findsNothing);
  });

  testWidgets('ikisi de bitirince eşleşmeler; süper beğenilen başta',
      (tester) async {
    final server = await _open(
        tester,
        _Server(otherVotes: {0: 1, 1: 0, 2: 2, 3: 1})
          ..started = true
          ..votes.addAll({0: 1, 1: 1, 2: 1}));
    expect(_text(tester, 'swipe-progress'), '4 / 4');
    await _tap(tester, 'swipe-like');
    expect(server.votes.length, 4);
    expect(_text(tester, 'swipe-result-title'), '3 filmde eşleştiniz! 🎉');
    expect(find.text('EN İYİ EŞLEŞME'), findsOneWidget);
    expect(find.text('ari süper beğendi'), findsOneWidget);
    expect(find.byKey(const ValueKey('swipe-match-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('swipe-match-1')), findsNothing);
    expect(find.byKey(const ValueKey('swipe-again')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('eşleşme yoksa yeni tur önerilir; iptal oturumu kapatır',
      (tester) async {
    var server = await _open(
        tester,
        _Server(cards: 2, otherVotes: {0: 0, 1: 0})
          ..started = true
          ..votes.addAll({0: 1, 1: 1}));
    expect(find.text('Bu sefer eşleşme çıkmadı 😅'), findsOneWidget);
    expect(find.byKey(const ValueKey('swipe-start')), findsOneWidget);
    server = await _open(tester, _Server()..started = true);
    await tester.tap(find.byKey(const ValueKey('swipe-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İptal et'));
    await tester.pumpAndSettle();
    expect(server.calls, contains('swipeCancel'));
    expect(find.byKey(const ValueKey('swipe-start')), findsOneWidget);
  });

  testWidgets('İzle şeridi oturumun durumunu söyler', (tester) async {
    Future<String> banner(Map<String, dynamic>? swipe) async {
      FilmStore.instance.call =
          (String action, [Map<String, dynamic> data = const {}]) async => {
                'films': [],
                'players': [
                  {'id': 1, 'name': 'mqcan'},
                  {'id': 2, 'name': 'ari'},
                ],
                'me': 1,
                'connected': true,
                'swipe': swipe,
              };
      await FilmStore.instance.refresh(force: true);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: SwipeBanner(key: UniqueKey(), onTap: () {}))));
      return _text(tester, 'swipe-banner-text');
    }

    Map<String, dynamic> s(int by, int mine, {String status = 'open'}) => {
          'id': 1,
          'status': status,
          'startedBy': by,
          'total': 15,
          'mine': mine,
          'otherDone': false,
        };
    expect(await banner(null), contains('kaydırın'));
    expect(await banner(s(2, 0)), 'ari seçim başlattı: sıra sende!');
    expect(await banner(s(1, 6)), 'Kaydırmaya devam et (6/15)');
    expect(await banner(s(1, 15)), 'ari bekleniyor…');
    expect(await banner(s(1, 15, status: 'done')), contains('eşleşmeleri gör'));
  });
}
