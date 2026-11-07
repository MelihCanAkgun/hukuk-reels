import 'package:flutter/widgets.dart';

import '../../core/services/social_bridge.dart';

/// Ortak film listesi (Filmler sekmesi). Film bilgileri TMDB'den, IMDb puanı
/// OMDb'den Worker üzerinden gelir; API anahtarları uygulamada değildir.
///
/// Liste sekme açılınca, aşağı çekip yenileyince ve her değişiklikten sonra
/// sunucudan gelir (uçuşlar gibi düzenli yoklama yok: liste nadiren değişir).
class FilmStore {
  FilmStore._();
  static final FilmStore instance = FilmStore._();

  /// Liste değişince artar.
  final ValueNotifier<int> changes = ValueNotifier(0);
  List<Film> films = const [];
  List<FilmRating> ratings = const [];
  Map<int, String> players = const {};

  /// Bu cihazdaki oyuncu (1 ya da 2).
  int? me;
  bool connected = false, loaded = false;

  /// Son yenilemede sunucuya ulaşılamadıysa (liste önbellekten) ya da hata.
  String? error;

  /// Testlerde sahte sunucu bağlamak için.
  @visibleForTesting
  Future<Map<String, dynamic>> Function(String action,
      [Map<String, dynamic> data]) call = socialCall;

  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  /// Sekmeye dönünce bundan yeniyse sunucuya gidilmez.
  static const minAge = Duration(seconds: 30);

  Future<void>? _running;
  DateTime? _fetched;

  /// [force] olmadan son yenilemeden bu yana [minAge] geçmediyse istek atmaz.
  Future<void> refresh({bool force = false}) {
    final last = _fetched;
    if (!force && last != null && clock().difference(last) < minAge) {
      return Future.value();
    }
    return _running ??= _load().whenComplete(() => _running = null);
  }

  Future<void> _load() async {
    final r = await call('films');
    _fetched = clock();
    if (r['error'] != null && r['films'] == null) {
      loaded = true;
      error = r['error'] as String?;
      changes.value++;
      return;
    }
    _apply(r);
  }

  /// TMDB araması; hata olursa `error` anahtarıyla döner.
  Future<({List<FilmSearchResult> results, String? error})> search(
      String query) async {
    final r = await call('filmSearch', {'query': query});
    if (r['error'] != null) {
      return (results: const <FilmSearchResult>[], error: r['error'] as String);
    }
    return (
      results: [
        for (final m in (r['results'] as List? ?? const []).whereType<Map>())
          FilmSearchResult.fromJson(m.cast<String, dynamic>())
      ],
      error: null,
    );
  }

  /// Ekleme/değişiklik: sunucunun döndürdüğü güncel liste hemen uygulanır.
  /// Hata varsa mesajı döner.
  Future<String?> add(int tmdbId) => _write('filmAdd', {'tmdbId': tmdbId});

  Future<String?> setWatched(int id, bool watched) =>
      _write('filmWatched', {'id': id, 'watched': watched});

  Future<String?> rate(int id, int hearts, String comment) =>
      _write('filmRate', {'id': id, 'hearts': hearts, 'comment': comment});

  Future<String?> delete(int id) => _write('filmDelete', {'id': id});

  Future<String?> _write(String action, Map<String, dynamic> data) async {
    final r = await call(action, data);
    if (r['error'] != null) return r['error'] as String;
    _apply(r);
    return null;
  }

  void _apply(Map<String, dynamic> r) {
    loaded = true;
    connected = r['connected'] == true;
    error = r['offline'] == true ? r['error'] as String? : null;
    films = [
      for (final f in (r['films'] as List? ?? const []).whereType<Map>())
        Film.fromJson(f.cast<String, dynamic>())
    ];
    ratings = [
      for (final x in (r['ratings'] as List? ?? const []).whereType<Map>())
        FilmRating.fromJson(x.cast<String, dynamic>())
    ];
    players = {
      for (final p in (r['players'] as List? ?? const []).whereType<Map>())
        p['id'] as int: (p['name'] as String?) ?? 'Oyuncu'
    };
    if (r['me'] is int) me = r['me'] as int;
    changes.value++;
  }

  Film? byId(int id) {
    for (final f in films) {
      if (f.id == id) return f;
    }
    return null;
  }

  String nameOf(int? player) => players[player] ?? 'Oyuncu';

  List<FilmRating> ratingsOf(int film) => [
        for (final r in ratings)
          if (r.film == film) r
      ]..sort((a, b) => a.player.compareTo(b.player));

  FilmRating? myRating(int film) {
    for (final r in ratings) {
      if (r.film == film && r.player == me) return r;
    }
    return null;
  }
}

const _tmdbImages = 'https://image.tmdb.org/t/p/';

class FilmProvider {
  const FilmProvider(this.name, this.logo);
  final String name;
  final String? logo;
  String? get logoUrl => logo == null ? null : '${_tmdbImages}w92$logo';
}

class Film {
  Film.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        tmdbId = j['tmdbId'] as int,
        imdbId = j['imdbId'] as String?,
        title = j['title'] as String,
        originalTitle = (j['originalTitle'] as String?) ?? '',
        year = j['year'] as int?,
        runtime = j['runtime'] as int?,
        genres = [for (final g in (j['genres'] as List? ?? const [])) '$g'],
        overview = (j['overview'] as String?) ?? '',
        poster = j['poster'] as String?,
        tmdbRating = (j['tmdbRating'] as num?)?.toDouble(),
        imdbRating = (j['imdbRating'] as num?)?.toDouble(),
        providers = [
          for (final p
              in (j['providers'] as List? ?? const []).whereType<Map>())
            FilmProvider('${p['name']}', p['logo'] as String?)
        ],
        addedBy = j['addedBy'] as int,
        added = _time(j['added'] as int),
        watched = j['watched'] == null ? null : _time(j['watched'] as int),
        watchedBy = j['watchedBy'] as int?;

  final int id, tmdbId, addedBy;
  final String? imdbId, poster;
  final String title, originalTitle, overview;
  final int? year, runtime, watchedBy;
  final List<String> genres;
  final double? tmdbRating, imdbRating;
  final List<FilmProvider> providers;
  final DateTime added;
  final DateTime? watched;

  bool get isWatched => watched != null;

  /// Türkçe ad orijinalinden farklıysa orijinal ad küçük yazılır.
  String? get subtitle =>
      originalTitle.isNotEmpty && originalTitle != title ? originalTitle : null;

  String? posterUrl([String size = 'w342']) =>
      poster == null ? null : '$_tmdbImages$size$poster';

  String? get imdbUrl =>
      imdbId == null ? null : 'https://www.imdb.com/title/$imdbId/';
  String get letterboxdUrl => 'https://letterboxd.com/tmdb/$tmdbId/';
  String get tmdbUrl => 'https://www.themoviedb.org/movie/$tmdbId';
}

class FilmRating {
  FilmRating.fromJson(Map<String, dynamic> j)
      : film = j['film'] as int,
        player = j['player'] as int,
        hearts = j['hearts'] as int,
        comment = (j['comment'] as String?) ?? '';

  final int film, player, hearts;
  final String comment;
}

class FilmSearchResult {
  FilmSearchResult.fromJson(Map<String, dynamic> j)
      : tmdbId = j['tmdbId'] as int,
        title = j['title'] as String,
        originalTitle = (j['originalTitle'] as String?) ?? '',
        year = j['year'] as int?,
        poster = j['poster'] as String?,
        tmdbRating = (j['tmdbRating'] as num?)?.toDouble(),
        inList = j['inList'] == true;

  final int tmdbId;
  final String title, originalTitle;
  final int? year;
  final String? poster;
  final double? tmdbRating;
  bool inList;

  String? get posterUrl => poster == null ? null : '${_tmdbImages}w154$poster';
}

DateTime _time(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000);

/// "2 sa 28 dk" / "95 dk".
String runtimeText(int minutes) => minutes < 60
    ? '$minutes dk'
    : minutes % 60 == 0
        ? '${minutes ~/ 60} sa'
        : '${minutes ~/ 60} sa ${minutes % 60} dk';

/// "bugün", "dün", "3 gün önce", "2 hafta önce", "12.11.2026".
String agoText(DateTime t, DateTime now) {
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(t.year, t.month, t.day))
      .inDays;
  if (days <= 0) return 'bugün';
  if (days == 1) return 'dün';
  if (days < 7) return '$days gün önce';
  if (days < 30) return '${days ~/ 7} hafta önce';
  return dateText(t);
}

String dateText(DateTime t) =>
    '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
