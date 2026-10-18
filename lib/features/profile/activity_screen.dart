import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/activity_area.dart';
import '../../core/services/social_bridge.dart';
import '../../core/widgets/readable_width.dart';
import 'activity_stats.dart';

export 'activity_stats.dart';

/// Yalnız Oyuncu 1 (yönetici) için: oyuncuların son görülmesi, günlük süre,
/// saat haritası, bölümler ve girişler. Sunucu `/activity` isteğini diğer
/// oyuncuya 404 ile reddeder; Profil ekranı da bu bölümü yalnız yöneticiye
/// gösterir.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, this.load, this.clock = DateTime.now});

  /// Testlerde sahte sunucu bağlamak için.
  final Future<Map<String, dynamic>> Function()? load;
  final DateTime Function() clock;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

/// Ekran açıkken sayfa bu aralıkla tazelenir.
const _refreshEvery = Duration(seconds: 30);

/// Son bildirimden bu kadar süre geçmediyse oyuncu "şu an aktif" sayılır
/// (uygulama ekrandayken iki dakikada bir nabız gönderir).
const kActiveWindow = Duration(seconds: 150);

/// Girişler listesinde ilk gösterilen satır sayısı.
const _previewEntries = 20;

const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık'
];
const _weekdays = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar'
];
const _weekdaysShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

const _playerColors = [AppTheme.accent, Color(0xFF7FD8E8)];
Color _colorOf(int player) => _playerColors[(player - 1).clamp(0, 1)];

String _two(int n) => n.toString().padLeft(2, '0');
String clockLabel(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

int _dayDiff(DateTime t, DateTime now) =>
    DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(t.year, t.month, t.day))
        .inDays;

/// "az önce", "12 dk önce", "3 sa önce", "dün 23:41", "14 Ekim 21:03".
String seenLabel(DateTime t, DateTime now) {
  final d = now.difference(t);
  if (d.inSeconds < 60) return 'az önce';
  if (d.inMinutes < 60) return '${d.inMinutes} dk önce';
  final days = _dayDiff(t, now);
  if (days <= 0) return '${d.inHours} sa önce';
  if (days == 1) return 'dün ${clockLabel(t)}';
  final date = '${t.day} ${_months[t.month - 1]}';
  return '${t.year == now.year ? date : '$date ${t.year}'} ${clockLabel(t)}';
}

/// Saat (bugünse) ya da gün + saat: "21:03", "dün 21:03", "14 Ekim 21:03".
String whenLabel(DateTime t, DateTime now) =>
    _dayDiff(t, now) <= 0 ? clockLabel(t) : seenLabel(t, now);

/// Gün başlığı: "Bugün", "Dün", "14 Ekim Salı".
String dayLabel(DateTime t, DateTime now) {
  final days = _dayDiff(t, now);
  if (days <= 0) return 'Bugün';
  if (days == 1) return 'Dün';
  final date = '${t.day} ${_months[t.month - 1]}';
  return '${t.year == now.year ? date : '$date ${t.year}'} '
      '${_weekdays[t.weekday - 1]}';
}

/// "1 dk'dan kısa", "25 dk", "2 sa 5 dk".
String lengthLabel(Duration d) {
  if (d.inMinutes < 1) return "1 dk'dan kısa";
  if (d.inHours < 1) return '${d.inMinutes} dk';
  final m = d.inMinutes % 60;
  return m == 0 ? '${d.inHours} sa' : '${d.inHours} sa $m dk';
}

/// Kısa süre: "0", "45 dk", "2 sa 5 dk" (özet kutuları ve grafik için).
String shortLength(Duration d) => d.inMinutes < 1 ? '0 dk' : lengthLabel(d);

/// "Cumartesi 21:00–22:00".
String peakLabel((int, int) peak) =>
    '${_weekdays[peak.$1 - 1]} ${_two(peak.$2)}:00–${_two((peak.$2 + 1) % 24)}:00';

const _devices = {
  'ipad': ('iPad', Icons.tablet_mac_rounded),
  'iphone': ('iPhone', Icons.phone_iphone_rounded),
  'android': ('Android', Icons.phone_android_rounded),
  'mac': ('Mac', Icons.laptop_mac_rounded),
  'windows': ('Windows', Icons.laptop_windows_rounded),
  'other': ('Tarayıcı', Icons.public_rounded),
};
(String, IconData) _device(String d) => _devices[d] ?? _devices['other']!;

class _ActivityScreenState extends State<ActivityScreen>
    with WidgetsBindingObserver {
  List<ActivityPlayer> _players = const [];
  List<ActivitySession> _sessions = const [];
  List<ActivityUsage> _usage = const [];
  int? _today;
  bool _loading = true;
  String? _error;

  /// null: herkes; aksi hâlde yalnız bu oyuncu.
  int? _filter;
  int _days = 7;
  bool _allEntries = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(_refreshEvery, (_) {
      final s = WidgetsBinding.instance.lifecycleState;
      if (s == null || s == AppLifecycleState.resumed) _refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final r = await (widget.load ?? () => socialCall('activity'))();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['error'] != null) {
        _error = r['status'] == 404
            ? 'Bu bölüm yalnız yönetici hesabında açılır.'
            : r['error'] as String;
        return;
      }
      if (r['connected'] != true) {
        _error = 'Önce sıralamaya oyuncu kodunla katıl.';
        return;
      }
      _error = null;
      _players = parseActivityPlayers(r);
      _sessions = parseActivitySessions(r);
      _usage = parseActivityUsage(r);
      _today = r['today'] as int?;
    });
  }

  String _nameOf(int id) {
    for (final p in _players) {
      if (p.id == id) return p.name;
    }
    return 'Oyuncu $id';
  }

  @override
  Widget build(BuildContext context) =>
      ActivityAreaScope(area: 'profile', child: _areaBody(context));

  Widget _areaBody(BuildContext context) {
    final now = widget.clock();
    final gutter = readableGutter(context);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.accent,
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 28),
                    children: _loading
                        ? const [
                            SizedBox(height: 80),
                            Center(
                                child: CircularProgressIndicator(
                                    color: AppTheme.accent)),
                          ]
                        : _error != null && _players.isEmpty
                            ? [_message(Icons.lock_outline_rounded, _error!)]
                            : _content(now),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Geri',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary),
            ),
            const Icon(Icons.insights_rounded, color: AppTheme.accent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Aktiflik',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Yenile',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded,
                  color: AppTheme.textSecondary),
            ),
          ],
        ),
      );

  List<Widget> _content(DateTime now) {
    final stats = ActivityStats(
        sessions: _sessions,
        usage: _usage,
        now: now,
        days: _days,
        player: _filter,
        today: _today);
    final shown = [
      for (final s in _sessions)
        if ((_filter == null || s.player == _filter) &&
            s.last.isAfter(stats.start))
          s
    ];
    final visible = _allEntries ? shown : shown.take(_previewEntries).toList();
    final days = <String, List<ActivitySession>>{};
    for (final s in visible) {
      days.putIfAbsent(dayLabel(s.started, now), () => []).add(s);
    }
    return [
      if (_error != null) ...[
        _message(Icons.cloud_off_rounded, _error!),
        const SizedBox(height: 12),
      ],
      _playerCards(now),
      const SizedBox(height: 16),
      _controls(),
      const SizedBox(height: 12),
      _summary(stats),
      _sectionTitle('GÜNLÜK SÜRE', Icons.bar_chart_rounded),
      _card(_DailyChart(
          stats: stats,
          now: now,
          filter: _filter,
          names: {for (final p in _players) p.id: p.name})),
      _sectionTitle('SAATLER', Icons.grid_on_rounded),
      _card(_HeatMap(stats: stats, color: _heatColor)),
      _sectionTitle('BÖLÜMLER', Icons.donut_small_rounded),
      _card(_areas(stats)),
      _sectionTitle('GİRİŞLER', Icons.login_rounded),
      if (shown.isEmpty)
        _message(Icons.hourglass_empty_rounded,
            'Bu dönemde giriş kaydı yok. Uygulama açıldıkça burada görünür.')
      else ...[
        for (final day in days.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
            child: Text(
              day.key,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          _sessionGroup(day.value, now),
          const SizedBox(height: 8),
        ],
        if (shown.length > visible.length)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _allEntries = true),
              child: Text('Tümünü göster (${shown.length})'),
            ),
          ),
      ],
      const SizedBox(height: 10),
      const Text(
        'Son 30 gün gösterilir; kayıtlar 90 gün sonra silinir. '
        'Bu sayfayı yalnız yönetici hesabı görür.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
      ),
    ];
  }

  Color get _heatColor =>
      _filter == null ? AppTheme.success : _colorOf(_filter!);

  Widget _sectionTitle(String title, IconData icon) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.accent),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: child,
      );

  Widget _playerCards(DateTime now) => LayoutBuilder(builder: (context, c) {
        final cards = [for (final p in _players) _playerCard(p, now)];
        if (c.maxWidth < 520) {
          return Column(children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              cards[i],
            ]
          ]);
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: cards[i]),
              ],
            ],
          ),
        );
      });

  Widget _controls() => Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('Tümü', null),
              for (final p in _players) _chip(p.name, p.id),
            ],
          ),
          SegmentedButton<int>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: 7, label: Text('7 gün')),
              ButtonSegment(value: 30, label: Text('30 gün')),
            ],
            selected: {_days},
            onSelectionChanged: (s) => setState(() {
              _days = s.first;
              _allEntries = false;
            }),
          ),
        ],
      );

  Widget _summary(ActivityStats s) {
    final tiles = [
      _stat('Toplam süre', shortLength(s.total), Icons.timer_outlined),
      _stat('Giriş', '${s.entries}', Icons.login_rounded),
      _stat('Günlük ortalama', shortLength(s.dailyAverage),
          Icons.calendar_today_rounded),
      _stat(
          'En uzun oturum', shortLength(s.longest), Icons.trending_up_rounded),
    ];
    return LayoutBuilder(builder: (context, c) {
      final perRow = c.maxWidth < 520 ? 2 : 4;
      final w = (c.maxWidth - 8 * (perRow - 1)) / perRow;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final t in tiles) SizedBox(width: w, child: t)],
      );
    });
  }

  Widget _stat(String label, String value, IconData icon) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    key: ValueKey('activity-stat-$label'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _areas(ActivityStats s) {
    if (s.areas.isEmpty) {
      return const Text(
        'Bölüm süreleri bu güncellemeden sonra toplanmaya başladı; '
        'uygulama kullanıldıkça burada görünür.',
        style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
      );
    }
    final sum = s.areas.fold(Duration.zero, (a, b) => a + b.$2);
    final top = s.areas.first.$2;
    return Column(
      children: [
        for (final (area, time) in s.areas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        areaName(area),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${shortLength(time)} · '
                      '%${(time.inSeconds / sum.inSeconds * 100).round()}',
                      key: ValueKey('activity-area-$area'),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: time.inSeconds / top.inSeconds,
                    minHeight: 6,
                    color: _heatColor,
                    backgroundColor: AppTheme.bgElevated,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _playerCard(ActivityPlayer p, DateTime now) {
    final seen = p.lastSeen;
    final active = seen != null && now.difference(seen) < kActiveWindow;
    ActivitySession? latest;
    for (final s in _sessions) {
      if (s.player == p.id) {
        latest = s;
        break;
      }
    }
    final where = active && latest != null && latest.area != 'other'
        ? ' · ${areaName(latest.area)}'
        : '';
    final week = ActivityStats(
        sessions: _sessions, usage: const [], now: now, days: 7, player: p.id);
    final color = _colorOf(p.id);
    return Container(
      key: ValueKey('activity-player-${p.id}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: active
                ? AppTheme.success.withValues(alpha: .55)
                : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .16),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: .5)),
                ),
                child: Text(
                  p.name.characters.first.toUpperCase(),
                  style: TextStyle(
                      color: color, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                active ? AppTheme.success : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            active
                                ? 'Şu an aktif$where'
                                : seen == null
                                    ? 'Henüz görülmedi'
                                    : 'Son görülme: ${seenLabel(seen, now)}',
                            key: ValueKey('activity-seen-${p.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? AppTheme.success
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _fact(
                  Icons.login_rounded,
                  latest == null
                      ? '—'
                      : 'Son giriş ${whenLabel(latest.started, now)}'),
              _fact(Icons.calendar_view_week_rounded,
                  '7 gün: ${week.entries} giriş · ${lengthLabel(week.total)}'),
              if (latest != null)
                _fact(_device(latest.device).$2, _device(latest.device).$1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fact(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ),
        ],
      );

  Widget _chip(String label, int? player) {
    final selected = _filter == player;
    return ChoiceChip(
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => setState(() {
        _filter = player;
        _allEntries = false;
      }),
    );
  }

  Widget _sessionGroup(List<ActivitySession> sessions, DateTime now) {
    final rows = <Widget>[];
    for (var i = 0; i < sessions.length; i++) {
      if (i > 0) {
        rows.add(const Divider(
            height: 1, thickness: 1, indent: 40, color: AppTheme.border));
      }
      rows.add(_sessionRow(sessions[i], now));
    }
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: rows),
    );
  }

  Widget _sessionRow(ActivitySession s, DateTime now) {
    final live = now.difference(s.last) < kActiveWindow;
    final device = _device(s.device);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: _colorOf(s.player)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameOf(s.player),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(device.$2, size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(device.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppTheme.textMuted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                live
                    ? '${clockLabel(s.started)} → şu an'
                    : '${clockLabel(s.started)} → ${clockLabel(s.last)}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                lengthLabel(s.length),
                style: TextStyle(
                  fontSize: 11.5,
                  color: live ? AppTheme.success : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _message(IconData icon, String text) => Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
            ),
          ],
        ),
      );
}

/// Gün gün toplam süre; "Tümü" seçiliyse iki oyuncu üst üste.
class _DailyChart extends StatelessWidget {
  const _DailyChart(
      {required this.stats,
      required this.now,
      required this.filter,
      required this.names});

  final ActivityStats stats;
  final DateTime now;
  final int? filter;
  final Map<int, String> names;

  static const _barArea = 110.0;

  String _label(int i) {
    final d =
        DateTime(stats.start.year, stats.start.month, stats.start.day + i);
    if (stats.days <= 7) return _weekdaysShort[d.weekday - 1];
    final last = i == stats.days - 1;
    return last || (stats.days - 1 - i) % 7 == 0 ? '${d.day}' : '';
  }

  @override
  Widget build(BuildContext context) {
    final max = stats.dayMax;
    final players = filter == null ? const [1, 2] : [filter!];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          max == Duration.zero
              ? 'Bu dönemde kayıt yok.'
              : 'En yoğun gün: ${lengthLabel(max)} · '
                  'günlük ortalama ${shortLength(stats.dailyAverage)}',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _barArea + 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < stats.days; i++)
                Expanded(
                  child: Tooltip(
                    message:
                        '${dayLabel(DateTime(stats.start.year, stats.start.month, stats.start.day + i), now)}: '
                        '${shortLength(stats.dayTotal(i))}',
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: stats.days <= 7 ? 6 : 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          for (final p in players.reversed)
                            Container(
                              height: max == Duration.zero
                                  ? 0
                                  : _barArea *
                                      (stats.daily[i][p] ?? Duration.zero)
                                          .inSeconds /
                                      max.inSeconds,
                              decoration: BoxDecoration(
                                color: _colorOf(p),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          Container(
                              height: 2,
                              color: AppTheme.border,
                              margin: const EdgeInsets.only(top: 1)),
                          SizedBox(
                            height: 15,
                            child: Text(
                              _label(i),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 10,
                                color: i == stats.days - 1
                                    ? AppTheme.textPrimary
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (filter == null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (final e in names.entries)
                _Legend(color: _colorOf(e.key), label: e.value),
            ],
          ),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
        ],
      );
}

/// Haftanın günü × saat ısı haritası: hangi saatlerde aktif olunduğu.
class _HeatMap extends StatelessWidget {
  const _HeatMap({required this.stats, required this.color});

  final ActivityStats stats;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final peak = stats.peak;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          peak == null
              ? 'Bu dönemde kayıt yok.'
              : 'En aktif saat: ${peakLabel(peak)}',
          key: const ValueKey('activity-peak'),
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          const labelW = 30.0;
          final cell = math.min(22.0, (c.maxWidth - labelW) / 24);
          final h = math.min(cell * 1.15, 20.0);
          return Column(
            children: [
              for (var d = 0; d < 7; d++)
                SizedBox(
                  height: h,
                  child: Row(
                    children: [
                      SizedBox(
                        width: labelW,
                        child: Text(_weekdaysShort[d],
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textMuted)),
                      ),
                      for (var hour = 0; hour < 24; hour++)
                        Container(
                          width: cell,
                          height: h,
                          padding: const EdgeInsets.all(1),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: stats.heat[d][hour] == Duration.zero
                                  ? AppTheme.bgElevated
                                  : Color.lerp(color.withValues(alpha: .25),
                                      color, stats.heatLevel(d, hour)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: labelW),
                  for (final hour in const [0, 6, 12, 18])
                    SizedBox(
                      width: cell * 6,
                      child: Text(
                        _two(hour),
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ),
                ],
              ),
            ],
          );
        }),
      ],
    );
  }
}
