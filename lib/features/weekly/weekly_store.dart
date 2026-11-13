import 'package:flutter/widgets.dart';

import '../../core/services/social_bridge.dart';
import '../game/game_leaderboard.dart';

/// Haftalık meydan okuma: turu yönetici (1. oyuncu) elle başlatır, tur 7 gün
/// sürer. Dört oyunun da o turdaki en iyi skoru sayılır. Oyunu yüksek skor
/// alır, turu (ve kupasını) daha çok oyun alan kazanır; eşitlikte sunucu yazı
/// tura atar.
///
/// Veri ekran açılınca ve sekmeye dönülünce sunucudan gelir; bağlantı yoksa
/// son kopya gösterilir.
class WeeklyStore {
  WeeklyStore._();
  static final WeeklyStore instance = WeeklyStore._();

  /// Veri değişince artar.
  final ValueNotifier<int> changes = ValueNotifier(0);
  WeeklyData? data;
  bool connected = false, loaded = false;
  String? error;

  @visibleForTesting
  Future<Map<String, dynamic>> Function(String action,
      [Map<String, dynamic> data]) call = socialCall;

  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  DateTime get now => clock();

  /// Sekmeye dönünce bundan yeniyse sunucuya gidilmez.
  static const minAge = Duration(seconds: 20);

  Future<void>? _running;
  DateTime? _fetched;

  Future<void> refresh({bool force = false}) {
    final last = _fetched;
    if (!force && last != null && clock().difference(last) < minAge) {
      return Future.value();
    }
    return _running ??= _refresh().whenComplete(() => _running = null);
  }

  /// Biten turun sonucu izlendi: bir daha gösterilmez.
  Future<void> markSeen(int round) => _load('weeklySeen', {'round': round});

  /// Yeni tur başlatır (yalnız yönetici). Hata varsa mesajı döner.
  Future<String?> start() => _write('weeklyStart');

  /// Süren turu kupasız bitirir (yalnız yönetici).
  Future<String?> cancel() => _write('weeklyCancel');

  Future<String?> _write(String action) async {
    final r = await call(action);
    if (r['error'] != null) return r['error'] as String;
    _apply(r);
    return null;
  }

  /// İlk açılışta önce cihazdaki son kopya gösterilir, güncel durum arkadan
  /// gelir.
  Future<void> _refresh() async {
    if (!loaded) {
      final cached = await call('weekly', {'cached': true});
      _apply(cached);
      if (cached['cached'] != true) return;
    }
    await _load('weekly');
  }

  Future<void> _load(String action,
      [Map<String, dynamic> body = const {}]) async {
    _apply(await call(action, body));
  }

  void _apply(Map<String, dynamic> r) {
    _fetched = clock();
    loaded = true;
    connected = r['connected'] == true;
    if (r['me'] is int) {
      data = WeeklyData.fromJson(r);
      error = r['offline'] == true ? r['error'] as String? : null;
    } else {
      error = r['error'] as String?;
    }
    changes.value++;
  }

  @visibleForTesting
  void reset() {
    data = null;
    connected = loaded = false;
    error = null;
    _fetched = null;
    call = socialCall;
    clock = DateTime.now;
  }
}

/// Biten bir turun sonucu.
class WeeklyResult {
  WeeklyResult.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        start = _time(j['start'] as int),
        end = _time(j['end'] as int),
        winner = j['winner'] as int,
        wins = _intMap(j['wins']),
        coin = j['coin'] == true,
        trophy = j['trophy'] as int,
        detail = [
          for (final d in (j['detail'] as List? ?? const []).whereType<Map>())
            (
              game: LeaderboardGame.values.byName(d['game'] as String),
              scores: {1: d['s1'] as int, 2: d['s2'] as int}
            )
        ];

  final int id, winner, trophy;
  final DateTime start, end;
  final Map<int, int> wins;

  /// Eşitlik yazı turayla bozuldu.
  final bool coin;
  final List<({LeaderboardGame game, Map<int, int> scores})> detail;

  /// "2-1" (kazananın sayısı önce; yazı turada "2-2").
  String get score {
    final a = wins[winner] ?? 0, b = wins[3 - winner] ?? 0;
    return '$a-$b';
  }
}

/// Süren tur.
class WeeklyRound {
  WeeklyRound.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        start = _time(j['start'] as int),
        end = _time(j['end'] as int),
        trophy = j['trophy'] as int;

  final int id, trophy;
  final DateTime start, end;

  /// "3 gün 4 sa", "5 sa 12 dk", "8 dk"; süre dolduysa "bitti".
  String remaining(DateTime now) {
    final left = end.difference(now);
    if (left.isNegative) return 'bitti';
    if (left.inDays >= 1) return '${left.inDays} gün ${left.inHours % 24} sa';
    if (left.inHours >= 1) {
      return '${left.inHours} sa ${left.inMinutes % 60} dk';
    }
    return '${left.inMinutes < 1 ? 1 : left.inMinutes} dk';
  }
}

class WeeklyData {
  WeeklyData.fromJson(Map<String, dynamic> j)
      : me = j['me'] as int,
        round = j['round'] is Map
            ? WeeklyRound.fromJson((j['round'] as Map).cast<String, dynamic>())
            : null,
        canStart = j['canStart'] == true,
        nextTrophy = (j['nextTrophy'] as int?) ?? 0,
        players = {
          for (final p in (j['players'] as List? ?? const []).whereType<Map>())
            p['id'] as int: (p['name'] as String?) ?? 'Oyuncu'
        },
        totals = _intMap(j['totals']),
        history = [
          for (final h in (j['history'] as List? ?? const []).whereType<Map>())
            // İzlenmemiş sonuç rafta ve geçmişte görünmez (sürprizi bozmasın).
            if (j['reveal'] is! Map || h['id'] != (j['reveal'] as Map)['id'])
              WeeklyResult.fromJson(h.cast<String, dynamic>())
        ],
        reveal = j['reveal'] is Map
            ? WeeklyResult.fromJson(
                (j['reveal'] as Map).cast<String, dynamic>())
            : null,
        _scores = {} {
    final hidden = reveal;
    if (hidden != null && (totals[hidden.winner] ?? 0) > 0) {
      totals[hidden.winner] = totals[hidden.winner]! - 1;
    }
    for (final s in (j['scores'] as List? ?? const []).whereType<Map>()) {
      (_scores[s['game'] as String] ??= {})[s['player'] as int] =
          s['best'] as int;
    }
    // Bu cihazda yapılıp henüz gönderilememiş skorlar (çevrimdışı).
    final local = j['localBests'];
    if (local is Map && round != null) {
      local.forEach((game, value) {
        final mine = (_scores['$game'] ??= {});
        if (value is int && value > (mine[me] ?? 0)) mine[me] = value;
      });
    }
  }

  final int me;

  /// Süren tur; yoksa null (yönetici yenisini başlatana dek).
  final WeeklyRound? round;

  /// Bu oyuncu yeni tur başlatabilir (yönetici ve süren tur yok).
  final bool canStart;

  /// Bir sonraki turun kupası.
  final int nextTrophy;
  final Map<int, String> players;

  /// Oyuncu başına kazanılan toplam tur.
  final Map<int, int> totals;
  final List<WeeklyResult> history;

  /// Son biten turun henüz izlenmemiş sonucu.
  final WeeklyResult? reveal;
  final Map<String, Map<int, int>> _scores;

  int get other => 3 - me;
  String nameOf(int player) => players[player] ?? 'Oyuncu';

  int scoreOf(LeaderboardGame game, int player) =>
      _scores[game.name]?[player] ?? 0;

  /// Oyunu bu turda önde götüren oyuncu; eşitse (ya da oynanmadıysa) null.
  int? leaderOf(LeaderboardGame game) {
    final a = scoreOf(game, 1), b = scoreOf(game, 2);
    return a == b ? null : (a > b ? 1 : 2);
  }

  /// Oyuncunun bu turda önde olduğu oyun sayısı.
  int winsOf(int player) =>
      LeaderboardGame.values.where((g) => leaderOf(g) == player).length;

  /// Oyuncunun her kupadan kaç tane kazandığı (kupa sırası → adet).
  Map<int, int> trophiesOf(int player) {
    final out = <int, int>{};
    for (final h in history) {
      if (h.winner == player) out[h.trophy] = (out[h.trophy] ?? 0) + 1;
    }
    return out;
  }
}

const _months = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', //
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
];

/// Turun tarih aralığı: "13–20 Kas", "28 Kas–5 Ara".
String roundRangeText(DateTime start, DateTime end) => start.month == end.month
    ? '${start.day}–${end.day} ${_months[end.month - 1]}'
    : '${start.day} ${_months[start.month - 1]}–${end.day} ${_months[end.month - 1]}';

Map<int, int> _intMap(Object? value) => {
      if (value is Map)
        for (final e in value.entries)
          int.parse('${e.key}'): (e.value as num).toInt()
    };

DateTime _time(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
