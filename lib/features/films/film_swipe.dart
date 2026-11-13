import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/services/social_bridge.dart';
import 'film_store.dart';

/// Oy: geç, beğen, süper beğen (oturumda kişi başı bir tane).
enum SwipeVote { pass, like, superLike }

/// "Ortak karar": biri kısa bir deste başlatır (listeden izlenmemişler ve
/// birkaç TMDB önerisi), ikimiz de kendi zamanımızda kaydırırız. İkimiz de
/// bitirince ortak beğeniler görünür; süper beğenilenler başta.
///
/// Oylar hemen ekrana işlenir ve arka planda sırayla gönderilir: bağlantı
/// yavaş ya da kopuk olsa da kaydırma beklemez; gönderilemeyenler bağlantı
/// gelince yeniden denenir.
class SwipeStore {
  SwipeStore._();
  static final SwipeStore instance = SwipeStore._();

  /// Durum değişince artar.
  final ValueNotifier<int> changes = ValueNotifier(0);
  SwipeSession? session;
  Map<int, String> players = const {};
  int? me;
  bool loaded = false, busy = false;

  /// Son istekteki hata (bağlantı yok vb.).
  String? error;

  @visibleForTesting
  Future<Map<String, dynamic>> Function(String action,
      [Map<String, dynamic> data]) call = socialCall;

  /// Gönderilmeyi bekleyen oylar (sırayla).
  final List<({int session, int pos, SwipeVote vote})> _queue = [];
  Future<void>? _draining;
  int? _listRefreshed;

  /// Henüz sunucuya ulaşmamış oy var.
  bool get sending => _queue.isNotEmpty;

  String nameOf(int? player) => players[player] ?? 'Oyuncu';
  int get other => 3 - (me ?? 1);

  Future<void> load() => _request('swipe');

  Future<void> start() => _request('swipeStart');

  Future<void> cancel() async {
    final s = session;
    if (s == null) return;
    _queue.clear();
    await _request('swipeCancel', {'session': s.id});
  }

  Future<void> _request(String action,
      [Map<String, dynamic> data = const {}]) async {
    busy = true;
    changes.value++;
    final r = await call(action, data);
    busy = false;
    loaded = true;
    if (r['error'] != null) {
      error = r['error'] as String;
    } else {
      error = null;
      _apply(r);
    }
    changes.value++;
  }

  /// Oy hemen işlenir; gönderim arka planda.
  void vote(int pos, SwipeVote vote) {
    final s = session;
    if (s == null || !s.isOpen) return;
    s.votes[pos] = vote;
    _queue.removeWhere((q) => q.session == s.id && q.pos == pos);
    _queue.add((session: s.id, pos: pos, vote: vote));
    changes.value++;
    unawaited(flush());
  }

  /// Bekleyen oyları gönderir; hata olursa durur (sonraki oyda ya da
  /// "Tekrar dene" ile sürer).
  Future<void> flush() =>
      _draining ??= _drain().whenComplete(() => _draining = null);

  Future<void> _drain() async {
    while (_queue.isNotEmpty) {
      final q = _queue.first;
      final r = await call('swipeVote',
          {'session': q.session, 'pos': q.pos, 'vote': q.vote.index});
      if (r['error'] != null) {
        final status = r['status'];
        // Sunucu oyu reddettiyse (oturum bitti/iptal) yeniden denenmez.
        if (status is int && status >= 400 && status < 500 && status != 429) {
          _queue.clear();
          await _request('swipe');
          return;
        }
        error = r['error'] as String;
        changes.value++;
        return;
      }
      if (_queue.isNotEmpty && _queue.first == q) _queue.removeAt(0);
      error = null;
      _apply(r);
      changes.value++;
    }
  }

  void _apply(Map<String, dynamic> r) {
    if (r['me'] is int) me = r['me'] as int;
    final list = r['players'];
    if (list is List) {
      players = {
        for (final p in list.whereType<Map>())
          p['id'] as int: (p['name'] as String?) ?? 'Oyuncu'
      };
    }
    final s = r['session'];
    session =
        s is Map ? SwipeSession.fromJson(s.cast<String, dynamic>()) : null;
    // Henüz gönderilmemiş oylar sunucunun kopyasının üstüne yazılır.
    final current = session;
    if (current != null) {
      for (final q in _queue) {
        if (q.session == current.id) current.votes[q.pos] = q.vote;
      }
    }
    // Eşleşen öneriler listeye eklendi: liste tazelensin.
    if (current != null && current.isDone && _listRefreshed != current.id) {
      _listRefreshed = current.id;
      unawaited(FilmStore.instance.refresh(force: true));
    }
  }

  @visibleForTesting
  void reset() {
    session = null;
    players = const {};
    me = null;
    loaded = busy = false;
    error = null;
    _queue.clear();
    _listRefreshed = null;
    call = socialCall;
  }
}

class SwipeCard {
  SwipeCard.fromJson(Map<String, dynamic> j)
      : pos = j['pos'] as int,
        filmId = j['filmId'] as int?,
        tmdbId = j['tmdbId'] as int,
        suggested = j['suggested'] == true,
        title = j['title'] as String,
        originalTitle = (j['originalTitle'] as String?) ?? '',
        year = j['year'] as int?,
        runtime = j['runtime'] as int?,
        genres = [for (final g in (j['genres'] as List? ?? const [])) '$g'],
        overview = (j['overview'] as String?) ?? '',
        poster = j['poster'] as String?,
        tmdbRating = (j['tmdbRating'] as num?)?.toDouble(),
        imdbRating = (j['imdbRating'] as num?)?.toDouble(),
        showTitle = j['showTitle'] as String?,
        season = j['season'] as int?,
        episode = j['episode'] as int?,
        supers = [for (final p in (j['supers'] as List? ?? const [])) p as int];

  final int pos, tmdbId;

  /// İzleme listesindeki kaydı; liste dışı bir öneriyse null.
  final int? filmId;

  /// TMDB önerisi (listede yoktu).
  final bool suggested;
  final String title, originalTitle, overview;
  final int? year, runtime, season, episode;
  final List<String> genres;
  final String? poster, showTitle;
  final double? tmdbRating, imdbRating;

  /// Eşleşmelerde: bu filmi süper beğenen oyuncular.
  final List<int> supers;

  String? posterUrl([String size = 'w342']) =>
      poster == null ? null : 'https://image.tmdb.org/t/p/$size$poster';

  /// "2010 · 2 sa 28 dk · Dram, Gerilim"
  String get meta => [
        if (year != null) '$year',
        if (runtime != null) runtimeText(runtime!),
        if (genres.isNotEmpty) genres.take(2).join(', '),
      ].join(' · ');

  /// Dizi bölümü: "Black Mirror · S3:B1".
  String? get episodeLabel =>
      showTitle == null ? null : '$showTitle · S$season:B$episode';
}

class SwipeSession {
  SwipeSession.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        status = j['status'] as String,
        startedBy = j['startedBy'] as int,
        cards = [
          for (final c in (j['cards'] as List? ?? const []).whereType<Map>())
            SwipeCard.fromJson(c.cast<String, dynamic>())
        ],
        votes = {
          if (j['votes'] is Map)
            for (final e in (j['votes'] as Map).entries)
              int.parse('${e.key}'): SwipeVote.values[e.value as int]
        },
        otherDone = j['otherDone'] == true,
        otherCount = (j['otherCount'] as int?) ?? 0,
        matches = j['matches'] is List
            ? [
                for (final c in (j['matches'] as List).whereType<Map>())
                  SwipeCard.fromJson(c.cast<String, dynamic>())
              ]
            : null;

  final int id, startedBy, otherCount;
  final String status;
  final List<SwipeCard> cards;

  /// Benim oylarım (kart sırası → oy); diğer oyuncununkiler bitene dek gizli.
  final Map<int, SwipeVote> votes;
  final bool otherDone;

  /// İkimizin de beğendikleri (oturum bitince), en iyi eşleşme başta.
  final List<SwipeCard>? matches;

  bool get isOpen => status == 'open';
  bool get isDone => status == 'done';
  int get total => cards.length;

  /// Oylamadığım ilk kart; hepsi oylandıysa null.
  SwipeCard? get next {
    for (final c in cards) {
      if (!votes.containsKey(c.pos)) return c;
    }
    return null;
  }

  bool get mineDone => votes.length >= cards.length;
  bool get superUsed => votes.values.contains(SwipeVote.superLike);
}

/// Film listesi yanıtındaki özet (İzle sekmesindeki şerit için).
class SwipeSummary {
  SwipeSummary.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        status = j['status'] as String,
        startedBy = j['startedBy'] as int,
        total = j['total'] as int,
        mine = j['mine'] as int,
        otherDone = j['otherDone'] == true;

  final int id, startedBy, total, mine;
  final String status;
  final bool otherDone;

  bool get isOpen => status == 'open';
  bool get myTurn => isOpen && mine < total;
}
