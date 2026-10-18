import 'dart:math' as math;

/// Aktiflik ekranının hesapları (saf; test edilebilir).
///
/// Oturum süreleri yerel saate göre saat ve gün dilimlerine bölünür. Bölüm
/// süreleri sunucuda Türkiye takvim günüyle tutulur (`day`).

class ActivityPlayer {
  ActivityPlayer(this.id, this.name, this.lastSeen);
  final int id;
  final String name;

  /// Hiç görülmediyse null.
  final DateTime? lastSeen;
}

class ActivitySession {
  ActivitySession(this.player, this.started, this.last, this.device,
      [this.area = 'other']);
  final int player;
  final DateTime started, last;
  final String device;

  /// Son bildirimdeki bölüm (oyuncu şu an aktifse nerede olduğu).
  final String area;

  Duration get length => last.difference(started);
}

class ActivityUsage {
  ActivityUsage(this.player, this.day, this.area, this.seconds);
  final int player, day;
  final String area;
  final int seconds;
}

DateTime _at(Object? seconds) =>
    DateTime.fromMillisecondsSinceEpoch((seconds as int) * 1000);

List<ActivityPlayer> parseActivityPlayers(Map<String, dynamic> r) => [
      for (final p in (r['players'] as List? ?? const []).whereType<Map>())
        ActivityPlayer(
          p['id'] as int,
          (p['name'] as String?) ?? 'Oyuncu ${p['id']}',
          (p['lastSeen'] as int? ?? 0) > 0 ? _at(p['lastSeen']) : null,
        )
    ];

List<ActivitySession> parseActivitySessions(Map<String, dynamic> r) => [
      for (final s in (r['sessions'] as List? ?? const []).whereType<Map>())
        ActivitySession(
            s['player'] as int,
            _at(s['started']),
            _at(s['last']),
            (s['device'] as String?) ?? 'other',
            (s['area'] as String?) ?? 'other')
    ];

List<ActivityUsage> parseActivityUsage(Map<String, dynamic> r) => [
      for (final u in (r['usage'] as List? ?? const []).whereType<Map>())
        ActivityUsage(u['player'] as int, u['day'] as int,
            (u['area'] as String?) ?? 'other', u['seconds'] as int)
    ];

/// Sunucunun gün numarası: Türkiye (UTC+3) takvim günü.
int trDay(DateTime t) => (t.millisecondsSinceEpoch ~/ 1000 + 10800) ~/ 86400;

const kAreaNames = {
  'home': 'Ana ekran',
  'block': 'Block Blast',
  'battle': '1v1 Battle',
  'flappy': 'Flappy Cat',
  'subway': 'Subway Silly',
  'tower': 'Adliye Kulesi',
  'summaries': 'Özetler',
  'questions': 'Soru bankası',
  'beat': 'Yanlış Soruları Döv',
  'profile': 'Profil',
  'countdown': 'Geri sayım',
  'leaderboard': 'Sıralama',
  'other': 'Diğer',
};
String areaName(String area) => kAreaNames[area] ?? kAreaNames['other']!;

/// Takvim günü farkı (yaz saati geçişlerinden etkilenmez).
int _dayIndex(DateTime t, DateTime start) =>
    DateTime.utc(t.year, t.month, t.day)
        .difference(DateTime.utc(start.year, start.month, start.day))
        .inDays;

/// Bir dönemin (son [days] gün, bugün dahil) özeti; [player] null ise
/// iki oyuncu birlikte.
class ActivityStats {
  ActivityStats({
    required List<ActivitySession> sessions,
    required List<ActivityUsage> usage,
    required DateTime now,
    required this.days,
    this.player,
    int? today,
  }) : start = DateTime(now.year, now.month, now.day - (days - 1)) {
    final picked = [
      for (final s in sessions)
        if (player == null || s.player == player) s
    ];
    daily = List.generate(days, (_) => <int, Duration>{});
    heat = List.generate(7, (_) => List.filled(24, Duration.zero));
    for (final s in picked) {
      if (!s.last.isAfter(start)) continue;
      if (!s.started.isBefore(start)) {
        entries++;
        if (s.length > longest) longest = s.length;
      }
      // Oturumu saat sınırlarında böl (dönem başından önceki kısım sayılmaz).
      var c = s.started.isBefore(start) ? start : s.started;
      while (c.isBefore(s.last)) {
        final next = DateTime(c.year, c.month, c.day, c.hour + 1);
        final end = next.isBefore(s.last) ? next : s.last;
        final part = end.difference(c);
        final i = _dayIndex(c, start);
        if (i >= 0 && i < days) {
          daily[i][s.player] = (daily[i][s.player] ?? Duration.zero) + part;
          heat[c.weekday - 1][c.hour] += part;
          total += part;
        }
        c = end;
      }
    }
    final last = today ?? trDay(now);
    final byArea = <String, int>{};
    for (final u in usage) {
      if (player != null && u.player != player) continue;
      if (u.day <= last - days || u.day > last) continue;
      byArea[u.area] = (byArea[u.area] ?? 0) + u.seconds;
    }
    areas = [
      for (final e in byArea.entries)
        if (e.value > 0) (e.key, Duration(seconds: e.value))
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    var best = Duration.zero;
    for (var d = 0; d < 7; d++) {
      for (var h = 0; h < 24; h++) {
        if (heat[d][h] > best) {
          best = heat[d][h];
          peak = (d + 1, h);
        }
      }
    }
    heatMax = best;
  }

  final int days;
  final int? player;

  /// Dönemin ilk günü (yerel gece yarısı).
  final DateTime start;

  int entries = 0;
  Duration total = Duration.zero, longest = Duration.zero;

  /// Gün gün (eskiden bugüne) oyuncu başına süre.
  late final List<Map<int, Duration>> daily;

  /// [haftanın günü 0=Pzt][saat] toplam süre.
  late final List<List<Duration>> heat;
  late final Duration heatMax;

  /// En yoğun (haftanın günü 1–7, saat); hiç kayıt yoksa null.
  (int, int)? peak;

  /// Bölümler, en çok zaman geçirilenden başlayarak.
  late final List<(String, Duration)> areas;

  Duration get dailyAverage =>
      Duration(seconds: (total.inSeconds / days).round());

  Duration dayTotal(int i) =>
      daily[i].values.fold(Duration.zero, (a, b) => a + b);

  Duration get dayMax => [for (var i = 0; i < days; i++) dayTotal(i)]
      .fold(Duration.zero, (a, b) => a > b ? a : b);

  /// Isı haritası yoğunluğu 0–1 (karekök: az kullanım da görünür).
  double heatLevel(int weekday0, int hour) => heatMax == Duration.zero
      ? 0
      : math.sqrt(heat[weekday0][hour].inSeconds / heatMax.inSeconds);
}
