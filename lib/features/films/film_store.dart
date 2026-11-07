import 'package:flutter/widgets.dart';

import '../../core/services/social_bridge.dart';

/// Ortak izleme listesi (İzle sekmesi): filmler ve tek tek dizi bölümleri
/// (Black Mirror'ın her bölümü ayrı bir öğe). Bilgiler TMDB'den, IMDb puanı
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
  List<FilmReply> replies = const [];

  /// Beğeniler: "film:hedef" → beğenen oyuncular. Hedef "c" + oyuncu id
  /// (o oyuncunun yorumu) ya da "r" + yanıt id.
  Map<String, Set<int>> likes = const {};
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

  /// Dizinin sezonları (bölüm seçmek için).
  Future<({ShowInfo? show, String? error})> show(int tmdbId) async {
    final r = await call('filmShow', {'tmdbId': tmdbId});
    if (r['error'] != null) return (show: null, error: r['error'] as String);
    final m = r['show'];
    return m is Map
        ? (show: ShowInfo.fromJson(m.cast<String, dynamic>()), error: null)
        : (show: null, error: 'Dizi bilgisi alınamadı.');
  }

  /// Bir sezonun bölümleri; listede olanlar işaretli.
  Future<({List<EpisodeResult> episodes, String? error})> season(
      int tmdbId, int season) async {
    final r = await call('filmSeason', {'tmdbId': tmdbId, 'season': season});
    if (r['error'] != null) {
      return (episodes: const <EpisodeResult>[], error: r['error'] as String);
    }
    return (
      episodes: [
        for (final m in (r['episodes'] as List? ?? const []).whereType<Map>())
          EpisodeResult.fromJson(m.cast<String, dynamic>())
      ],
      error: null,
    );
  }

  /// Ekleme/değişiklik: sunucunun döndürdüğü güncel liste hemen uygulanır.
  /// Hata varsa mesajı döner.
  Future<String?> add(int tmdbId) => _write('filmAdd', {'tmdbId': tmdbId});

  /// Seçilen bölümler ayrı ayrı listeye eklenir (en fazla 10).
  Future<String?> addEpisodes(int showId, int season, List<int> episodes) =>
      _write('filmEpisodes',
          {'showId': showId, 'season': season, 'episodes': episodes});

  Future<String?> setWatched(int id, bool watched) =>
      _write('filmWatched', {'id': id, 'watched': watched});

  /// [halves]: yarım kalp cinsinden puan (1–10, ör. 7 = 3,5 kalp).
  Future<String?> rate(int id, int halves, String comment) =>
      _write('filmRate', {'id': id, 'halves': halves, 'comment': comment});

  /// [reviewBy] oyuncusunun yorumuna yanıt.
  Future<String?> reply(int id, int reviewBy, String text) =>
      _write('filmReply', {'id': id, 'reviewBy': reviewBy, 'text': text});

  Future<String?> deleteReply(int reply) =>
      _write('filmReplyDelete', {'reply': reply});

  /// [target]: "c" + oyuncu id yorum, "r" + yanıt id yanıt.
  Future<String?> like(int id, String target, bool like) async {
    // Hemen görünsün; sunucu yanıtı listeyi yeniden kurar.
    final key = '$id:$target';
    final before = likes[key] ?? const <int>{};
    final mine = me;
    if (mine != null) {
      likes = {
        ...likes,
        key: like ? {...before, mine} : ({...before}..remove(mine)),
      };
      changes.value++;
    }
    final error =
        await _write('filmLike', {'id': id, 'target': target, 'like': like});
    if (error != null) {
      likes = {...likes, key: before};
      changes.value++;
    }
    return error;
  }

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
    replies = [
      for (final x in (r['replies'] as List? ?? const []).whereType<Map>())
        FilmReply.fromJson(x.cast<String, dynamic>())
    ];
    final liked = <String, Set<int>>{};
    for (final x in (r['likes'] as List? ?? const []).whereType<Map>()) {
      (liked['${x['film']}:${x['target']}'] ??= {}).add(x['player'] as int);
    }
    likes = liked;
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

  /// Yorumun ya da yanıtın beğenenleri.
  Set<int> likesOf(int film, String target) =>
      likes['$film:$target'] ?? const {};

  /// [reviewBy] oyuncusunun yorumuna gelen yanıtlar (eskiden yeniye).
  List<FilmReply> repliesTo(int film, int reviewBy) => [
        for (final r in replies)
          if (r.film == film && r.reviewBy == reviewBy) r
      ];

  /// İki kişinin de izlediği (izlendi işaretli) yapımların puan tablosu.
  List<FilmTableRow> table({bool byScore = false}) {
    final rows = [
      for (final f in films)
        if (f.isWatched)
          FilmTableRow(f, {for (final r in ratingsOf(f.id)) r.player: r})
    ];
    int byDate(FilmTableRow a, FilmTableRow b) =>
        b.film.watched!.compareTo(a.film.watched!);
    rows.sort(byScore
        ? (a, b) {
            final c = (b.average ?? -1).compareTo(a.average ?? -1);
            return c != 0 ? c : byDate(a, b);
          }
        : byDate);
    return rows;
  }

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
        watchedBy = j['watchedBy'] as int?,
        isEpisode = j['kind'] == 'episode',
        showId = j['showId'] as int?,
        showTitle = j['showTitle'] as String?,
        season = j['season'] as int?,
        episode = j['episode'] as int?,
        still = j['still'] as String?;

  final int id, tmdbId, addedBy;
  final String? imdbId, poster;
  final String title, originalTitle, overview;
  final int? year, runtime, watchedBy;
  final List<String> genres;
  final double? tmdbRating, imdbRating;
  final List<FilmProvider> providers;
  final DateTime added;
  final DateTime? watched;

  /// Film değil, bir dizinin tek bölümü.
  final bool isEpisode;
  final int? showId, season, episode;
  final String? showTitle, still;

  bool get isWatched => watched != null;

  /// "S3:B1" (bölümlerde).
  String? get episodeCode => isEpisode ? 'S$season:B$episode' : null;

  /// Türkçe ad orijinalinden farklıysa orijinal ad küçük yazılır.
  String? get subtitle =>
      originalTitle.isNotEmpty && originalTitle != title ? originalTitle : null;

  String? posterUrl([String size = 'w342']) =>
      poster == null ? null : '$_tmdbImages$size$poster';

  String? get stillUrl => still == null ? null : '${_tmdbImages}w780$still';

  String? get imdbUrl =>
      imdbId == null ? null : 'https://www.imdb.com/title/$imdbId/';

  /// Letterboxd'da dizi yok; yalnız filmlerde.
  String? get letterboxdUrl =>
      isEpisode ? null : 'https://letterboxd.com/tmdb/$tmdbId/';
  String get tmdbUrl => isEpisode
      ? 'https://www.themoviedb.org/tv/$showId/season/$season/episode/$episode'
      : 'https://www.themoviedb.org/movie/$tmdbId';
}

class FilmRating {
  FilmRating.fromJson(Map<String, dynamic> j)
      : film = j['film'] as int,
        player = j['player'] as int,
        halves = (j['halves'] as int?) ?? (j['hearts'] as int) * 2,
        comment = (j['comment'] as String?) ?? '';

  /// Yarım kalp cinsinden puan (1–10).
  final int film, player, halves;
  final String comment;

  double get hearts => halves / 2;
}

class FilmReply {
  FilmReply.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        film = j['film'] as int,
        reviewBy = j['reviewBy'] as int,
        player = j['player'] as int,
        text = (j['text'] as String?) ?? '',
        created = _time(j['created'] as int);

  final int id, film, reviewBy, player;
  final String text;
  final DateTime created;
}

/// Puan tablosunun bir satırı: yapım ve oyuncuların puanları.
class FilmTableRow {
  const FilmTableRow(this.film, this.ratings);
  final Film film;
  final Map<int, FilmRating> ratings;

  /// Verilen puanların ortalaması (yarım kalp cinsinden); puan yoksa null.
  double? get average => ratings.isEmpty
      ? null
      : ratings.values.fold<int>(0, (s, r) => s + r.halves) / ratings.length;
}

/// "3,5" / "4".
String heartsText(int halves) =>
    halves.isEven ? '${halves ~/ 2}' : '${halves ~/ 2},5';

class FilmSearchResult {
  FilmSearchResult.fromJson(Map<String, dynamic> j)
      : isShow = j['kind'] == 'tv',
        listedEpisodes = (j['listedEpisodes'] as int?) ?? 0,
        tmdbId = j['tmdbId'] as int,
        title = j['title'] as String,
        originalTitle = (j['originalTitle'] as String?) ?? '',
        englishTitle = j['englishTitle'] as String?,
        year = j['year'] as int?,
        poster = j['poster'] as String?,
        tmdbRating = (j['tmdbRating'] as num?)?.toDouble(),
        inList = j['inList'] == true;

  /// Dizi: dokununca sezon/bölüm seçimi açılır.
  final bool isShow;

  /// Dizinin listede olan bölüm sayısı.
  final int listedEpisodes;
  final int tmdbId;
  final String title, originalTitle;

  /// İngilizce ad, Türkçe ve orijinal addan farklıysa (ör. Spirited Away).
  final String? englishTitle;
  final int? year;
  final String? poster;
  final double? tmdbRating;
  bool inList;

  String? get posterUrl => poster == null ? null : '${_tmdbImages}w154$poster';
}

class ShowSeason {
  ShowSeason.fromJson(Map<String, dynamic> j)
      : season = j['season'] as int,
        name = (j['name'] as String?) ?? '',
        episodes = j['episodes'] as int,
        year = j['year'] as int?;

  final int season, episodes;
  final String name;
  final int? year;

  /// "3. Sezon"; 0. sezon özel bölümler.
  String get label => season == 0 ? 'Özel bölümler' : '$season. Sezon';
}

class ShowInfo {
  ShowInfo.fromJson(Map<String, dynamic> j)
      : tmdbId = j['tmdbId'] as int,
        title = j['title'] as String,
        year = j['year'] as int?,
        poster = j['poster'] as String?,
        seasons = [
          for (final m in (j['seasons'] as List? ?? const []).whereType<Map>())
            ShowSeason.fromJson(m.cast<String, dynamic>())
        ];

  final int tmdbId;
  final String title;
  final int? year;
  final String? poster;
  final List<ShowSeason> seasons;

  String? get posterUrl => poster == null ? null : '${_tmdbImages}w154$poster';
}

class EpisodeResult {
  EpisodeResult.fromJson(Map<String, dynamic> j)
      : episode = j['episode'] as int,
        title = j['title'] as String,
        englishTitle = j['englishTitle'] as String?,
        overview = (j['overview'] as String?) ?? '',
        runtime = j['runtime'] as int?,
        year = j['year'] as int?,
        still = j['still'] as String?,
        tmdbRating = (j['tmdbRating'] as num?)?.toDouble(),
        inList = j['inList'] == true;

  final int episode;
  final String title, overview;
  final String? englishTitle, still;
  final int? runtime, year;
  final double? tmdbRating;
  bool inList;

  String? get stillUrl => still == null ? null : '${_tmdbImages}w300$still';
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
