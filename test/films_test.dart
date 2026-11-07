import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/app/theme.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/films/film_roulette.dart';
import 'package:hukuk_reels/features/films/film_store.dart';
import 'package:hukuk_reels/features/films/films_screen.dart';
import 'package:hukuk_reels/features/profile/profile_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _now = 1794000000; // 2026-11

Map<String, dynamic> _film(int id,
        {String? title,
        int runtime = 100,
        List<String> genres = const ['Dram'],
        double? imdb = 7.0,
        int addedBy = 1,
        int added = _now,
        int? watched,
        List<Map<String, dynamic>> providers = const []}) =>
    {
      'id': id,
      'tmdbId': 1000 + id,
      'imdbId': 'tt000000$id',
      'title': title ?? 'Film $id',
      'originalTitle': 'Movie $id',
      'year': 2010 + id,
      'runtime': runtime,
      'genres': genres,
      'overview': 'Özet $id',
      'poster': null,
      'tmdbRating': 7.5,
      'imdbRating': imdb,
      'providers': providers,
      'addedBy': addedBy,
      'added': added,
      'watched': watched,
      'watchedBy': watched == null ? null : 1,
    };

Map<String, dynamic> _episode(int id, int season, int episode,
        {String? title, int? watched}) =>
    {
      ..._film(id,
          title: title ?? 'Bölüm $episode', runtime: 60, watched: watched),
      'tmdbId': -(5000 + id),
      'kind': 'episode',
      'showId': 42009,
      'showTitle': 'Black Mirror',
      'season': season,
      'episode': episode,
      'still': '/still$id.jpg',
    };

/// Sahte Worker: aynı yanıt biçimini döndürür ve çağrıları kaydeder.
class _Server {
  _Server(this.films);
  final List<Map<String, dynamic>> films;
  final List<Map<String, dynamic>> ratings = [];
  final calls = <String>[];
  final data = <String, Map<String, dynamic>>{};
  bool connected = true;

  Map<String, dynamic> list() => {
        'films': films,
        'ratings': ratings,
        'players': [
          {'id': 1, 'name': 'mqcan'},
          {'id': 2, 'name': 'ari'},
        ],
        'me': 1,
        'connected': connected,
      };

  Future<Map<String, dynamic>> call(String action,
      [Map<String, dynamic> data = const {}]) async {
    calls.add(action);
    this.data[action] = data;
    if (!connected) return {'films': [], 'connected': false};
    switch (action) {
      case 'filmSearch':
        return {
          'results': [
            {
              'tmdbId': 27205,
              'title': 'Başlangıç',
              'originalTitle': 'Inception',
              'year': 2010,
              'poster': null,
              'tmdbRating': 8.4,
              'inList': false,
            },
            {
              'kind': 'tv',
              'tmdbId': 42009,
              'title': 'Black Mirror',
              'originalTitle': 'Black Mirror',
              'year': 2011,
              'poster': null,
              'tmdbRating': 8.3,
              'inList': false,
              'listedEpisodes': 0,
            },
          ]
        };
      case 'filmShow':
        return {
          'show': {
            'tmdbId': 42009,
            'title': 'Black Mirror',
            'year': 2011,
            'poster': null,
            'seasons': [
              {'season': 1, 'name': 'Sezon 1', 'episodes': 3, 'year': 2011},
              {'season': 3, 'name': 'Sezon 3', 'episodes': 2, 'year': 2016},
            ],
          }
        };
      case 'filmSeason':
        final listed = {
          for (final f in films)
            if (f['kind'] == 'episode' && f['season'] == data['season'])
              f['episode']
        };
        return {
          'episodes': [
            for (final (n, title) in data['season'] == 3
                ? [(1, 'Nosedive'), (2, 'Oyun Testi')]
                : [(1, 'Milli Marş'), (2, '15 Milyon'), (3, 'Geçmişin')])
              {
                'episode': n,
                'title': title,
                'englishTitle': null,
                'overview': '',
                'runtime': 60,
                'year': 2016,
                'still': null,
                'tmdbRating': 7.9,
                'inList': listed.contains(n),
              }
          ]
        };
      case 'filmEpisodes':
        for (final n in (data['episodes'] as List).cast<int>()) {
          films.insert(
              0,
              _episode(200 + n, data['season'] as int, n,
                  title: n == 1 ? 'Nosedive' : 'Oyun Testi'));
        }
      case 'filmAdd':
        films.insert(0, _film(99, title: 'Başlangıç'));
      case 'filmWatched':
        final f = films.firstWhere((f) => f['id'] == data['id']);
        f['watched'] = data['watched'] == true ? _now : null;
        f['watchedBy'] = data['watched'] == true ? 1 : null;
      case 'filmRate':
        ratings.removeWhere((r) => r['film'] == data['id'] && r['player'] == 1);
        ratings.add({
          'film': data['id'],
          'player': 1,
          'hearts': data['hearts'],
          'comment': data['comment'],
        });
      case 'filmDelete':
        films.removeWhere((f) => f['id'] == data['id']);
    }
    return list();
  }
}

Film _parsed(Map<String, dynamic> j) => Film.fromJson(j);

Future<_Server> _open(WidgetTester tester, List<Map<String, dynamic>> films,
    {bool connected = true}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(393, 852) * 2;
  addTearDown(tester.view.reset);
  final server = _Server(films)..connected = connected;
  FilmStore.instance.call = server.call;
  await tester
      .pumpWidget(MaterialApp(theme: AppTheme.dark, home: const FilmsScreen()));
  await tester.pumpAndSettle();
  return server;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.init();
  });

  test('filters and sorting', () {
    final films = [
      _parsed(_film(1, runtime: 85, genres: ['Komedi'], imdb: 6.1, added: 10)),
      _parsed(_film(2,
          runtime: 150,
          genres: ['Dram'],
          imdb: 8.8,
          addedBy: 2,
          added: 20,
          providers: [
            {'name': 'Netflix', 'logo': null}
          ])),
      _parsed(_film(3, runtime: 110, imdb: null, added: 30)),
      _parsed(_film(4, watched: 40, added: 5)),
      _parsed(_film(5, watched: 50, added: 6)),
    ];
    List<int> ids(FilmFilter f) =>
        [for (final x in filterFilms(films, f)) x.id];
    expect(ids(const FilmFilter()), [3, 2, 1]);
    expect(ids(const FilmFilter(watched: true)), [5, 4]);
    expect(ids(const FilmFilter(sort: FilmSort.imdb)), [2, 3, 1]);
    expect(ids(const FilmFilter(sort: FilmSort.runtime)), [1, 3, 2]);
    expect(ids(const FilmFilter(genre: 'Komedi')), [1]);
    expect(ids(const FilmFilter(length: FilmLength.short)), [1]);
    expect(ids(const FilmFilter(length: FilmLength.medium)), [3]);
    expect(ids(const FilmFilter(length: FilmLength.long)), [2]);
    expect(ids(const FilmFilter(addedBy: 2)), [2]);
    expect(ids(const FilmFilter(platform: 'Netflix')), [2]);
    expect(const FilmFilter(genre: 'Dram').cleared().narrowed, isFalse);

    final mixed = [...films, _parsed(_episode(6, 3, 1, title: 'Nosedive'))];
    expect([
      for (final x
          in filterFilms(mixed, const FilmFilter(kind: FilmKind.episode)))
        x.id
    ], [
      6
    ]);
    expect([
      for (final x
          in filterFilms(mixed, const FilmFilter(kind: FilmKind.movie)))
        x.id
    ], [
      3,
      2,
      1
    ]);
  });

  test('an episode knows its code and links', () {
    final e = _parsed(_episode(7, 3, 4));
    expect(e.isEpisode, isTrue);
    expect(e.episodeCode, 'S3:B4');
    expect(e.letterboxdUrl, isNull);
    expect(e.tmdbUrl, 'https://www.themoviedb.org/tv/42009/season/3/episode/4');
    final f = _parsed(_film(1));
    expect(f.isEpisode, isFalse);
    expect(f.episodeCode, isNull);
    expect(f.letterboxdUrl, 'https://letterboxd.com/tmdb/1001/');
  });

  test('runtime and date texts', () {
    expect(runtimeText(45), '45 dk');
    expect(runtimeText(120), '2 sa');
    expect(runtimeText(148), '2 sa 28 dk');
    final now = DateTime(2026, 11, 20, 10);
    expect(agoText(DateTime(2026, 11, 20, 1), now), 'bugün');
    expect(agoText(DateTime(2026, 11, 19, 23), now), 'dün');
    expect(agoText(DateTime(2026, 11, 17), now), '3 gün önce');
    expect(agoText(DateTime(2026, 11, 1), now), '2 hafta önce');
    expect(agoText(DateTime(2026, 9, 1), now), '01.09.2026');
  });

  testWidgets('without a player code the tab explains how to join',
      (tester) async {
    await _open(tester, [], connected: false);
    expect(find.textContaining('oyuncu kodunla bağlan'), findsOneWidget);
    expect(find.byKey(const ValueKey('film-add')), findsNothing);
  });

  testWidgets('list, tabs, detail: mark watched and rate', (tester) async {
    final server = await _open(tester, [
      _film(1, title: 'Amélie'),
      _film(2, title: 'Parazit', watched: _now),
    ]);
    expect(find.text('İzleyeceklerimiz (1)'), findsOneWidget);
    expect(find.text('İzlediklerimiz (1)'), findsOneWidget);
    expect(find.text('Amélie'), findsWidgets);
    expect(find.text('Parazit'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('film-1')));
    await tester.pumpAndSettle();
    expect(find.text('Özet 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('film-watched')));
    await tester.pumpAndSettle();
    expect(server.calls, contains('filmWatched'));
    expect(find.text('Puanlarımız'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('film-rate-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('heart-4')));
    await tester.enterText(
        find.byKey(const ValueKey('film-comment')), 'Çok tatlıydı');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('film-rate-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('film-rate-save')));
    await tester.pumpAndSettle();
    expect(server.ratings.single['hearts'], 4);
    expect(server.ratings.single['comment'], 'Çok tatlıydı');
    expect(find.text('Çok tatlıydı'), findsOneWidget);

    // Detay kapanınca film İzlediklerimiz'e geçmiş olur.
    Navigator.of(tester.element(find.text('Puanlarımız'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('İzleyeceklerimiz (0)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('films-watched-tab')));
    await tester.pumpAndSettle();
    expect(find.text('Amélie'), findsWidgets);
    expect(find.text('Parazit'), findsWidgets);
  });

  testWidgets('the adder photo: own profile photo or the other player\'s',
      (tester) async {
    await _open(tester, [
      _film(1, title: 'Benim', addedBy: 1),
      _film(2, title: 'Onun', addedBy: 2),
    ]);
    Finder avatarIn(int id, Type type) => find.descendant(
        of: find.byKey(ValueKey('film-$id')), matching: find.byType(type));
    expect(avatarIn(1, ProfileAvatar), findsOneWidget);
    expect(avatarIn(1, PeerAvatar), findsNothing);
    expect(avatarIn(2, PeerAvatar), findsOneWidget);
    expect(avatarIn(2, ProfileAvatar), findsNothing);
  });

  testWidgets('search adds a film; delete asks first', (tester) async {
    final server = await _open(tester, []);
    expect(find.text('Listeniz boş. İlk filmi ya da bölümü ekleyin!'),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('film-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('film-search-field')), 'incep');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Başlangıç'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('film-result-27205')));
    await tester.pumpAndSettle();
    expect(server.calls, contains('filmAdd'));
    expect(find.text('Listede ✓'), findsOneWidget);

    Navigator.of(tester.element(find.text('Listede ✓'))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('film-99')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('film-99')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('film-delete')), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(const ValueKey('film-delete')));
    await tester.pumpAndSettle();
    expect(server.calls, isNot(contains('filmDelete')));
    await tester.tap(find.byKey(const ValueKey('film-delete-confirm')));
    await tester.pumpAndSettle();
    expect(server.calls, contains('filmDelete'));
    expect(find.text('Listeniz boş. İlk filmi ya da bölümü ekleyin!'),
        findsOneWidget);
  });

  testWidgets('filter chips narrow the grid', (tester) async {
    await _open(tester, [
      _film(1, title: 'Kısa', runtime: 80),
      _film(2, title: 'Uzun', runtime: 170),
    ]);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('film-chip-length')), 120,
        scrollable: find
            .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.byKey(const ValueKey('film-chip-length')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('film-option-120 dk üstü')));
    await tester.pumpAndSettle();
    expect(find.text('Uzun'), findsWidgets);
    expect(find.text('Kısa'), findsNothing);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('film-chip-clear')), -120,
        scrollable: find
            .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.byKey(const ValueKey('film-chip-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Kısa'), findsWidgets);
  });

  testWidgets('the dice slows down and lands on a film', (tester) async {
    final pool = [for (var i = 1; i <= 3; i++) _parsed(_film(i))];
    Film? picked;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              picked = await showFilmRoulette(context, pool, random: Random(7)),
          child: const Text('zar'),
        ),
      ),
    ));
    await tester.tap(find.text('zar'));
    await tester.pump();
    // Dönerken seçilemez.
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('roulette-pick')))
            .onPressed,
        isNull);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    final title =
        tester.widget<Text>(find.byKey(const ValueKey('roulette-title'))).data;
    await tester.tap(find.byKey(const ValueKey('roulette-pick')));
    await tester.pumpAndSettle();
    expect(picked?.title, title);
  });

  testWidgets('a show opens its seasons; picked episodes are added one by one',
      (tester) async {
    final server = await _open(tester, []);
    await tester.tap(find.byKey(const ValueKey('film-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('film-search-field')), 'black mirror');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.textContaining('📺 Dizi'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('film-result-42009')));
    await tester.pumpAndSettle();
    expect(server.calls, containsAll(['filmShow', 'filmSeason']));
    expect(server.data['filmSeason']!['season'], 1);
    expect(find.text('Milli Marş'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('season-3')));
    await tester.pumpAndSettle();
    expect(find.text('Nosedive'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('episode-1')));
    await tester.tap(find.byKey(const ValueKey('episode-2')));
    await tester.pump();
    expect(find.text('2 bölümü ekle'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('episode-add')));
    await tester.pumpAndSettle();
    expect(server.data['filmEpisodes'], {
      'showId': 42009,
      'season': 3,
      'episodes': [1, 2]
    });
    expect(find.text('Listede ✓'), findsNWidgets(2));
    expect(find.textContaining('2 bölüm listeye eklendi'), findsOneWidget);

    // Aramaya dönülür; sayfa kapanınca bölümler ayrı kartlar.
    await tester.tap(find.byKey(const ValueKey('episode-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('film-search-field')), findsOneWidget);
    Navigator.of(
            tester.element(find.byKey(const ValueKey('film-search-field'))))
        .pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('film-201')), findsOneWidget);
    expect(find.byKey(const ValueKey('film-202')), findsOneWidget);
    expect(find.text('S3:B1'), findsOneWidget);
    expect(find.text('S3:B2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('film-201')));
    await tester.pumpAndSettle();
    expect(find.text('📺 Black Mirror'), findsOneWidget);
    expect(find.text('3. Sezon 1. Bölüm'), findsOneWidget);
    expect(find.byKey(const ValueKey('film-link-Letterboxd')), findsNothing);
    expect(find.byKey(const ValueKey('film-link-TMDB')), findsOneWidget);
  });

  testWidgets('the Film/Dizi chip shows only episodes', (tester) async {
    await _open(tester, [
      _film(1, title: 'Amélie'),
      _episode(2, 3, 1, title: 'Nosedive'),
    ]);
    expect(find.text('Amélie'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('film-chip-kind')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('film-option-Dizi bölümleri')));
    await tester.pumpAndSettle();
    expect(find.text('Nosedive'), findsWidgets);
    expect(find.text('Amélie'), findsNothing);
  });
}
