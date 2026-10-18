import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/social_bridge.dart';
import '../../core/widgets/readable_width.dart';

/// Yalnız Oyuncu 1 (yönetici) için: oyuncuların son görülmesi ve giriş
/// saatleri. Sunucu `/activity` isteğini diğer oyuncuya 404 ile reddeder;
/// Profil ekranı da bu bölümü yalnız yöneticiye gösterir.
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

/// Son nabızdan bu kadar süre geçmediyse oyuncu "şu an aktif" sayılır
/// (uygulama ekrandayken iki dakikada bir nabız gönderir).
const kActiveWindow = Duration(seconds: 150);

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

const _playerColors = [AppTheme.accent, Color(0xFF7FD8E8)];
Color _colorOf(int player) => _playerColors[(player - 1).clamp(0, 1)];

class ActivityPlayer {
  ActivityPlayer(this.id, this.name, this.lastSeen);
  final int id;
  final String name;

  /// Hiç görülmediyse null.
  final DateTime? lastSeen;
}

class ActivitySession {
  ActivitySession(this.player, this.started, this.last, this.device);
  final int player;
  final DateTime started, last;
  final String device;

  Duration get length => last.difference(started);
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
        ActivitySession(s['player'] as int, _at(s['started']), _at(s['last']),
            (s['device'] as String?) ?? 'other')
    ];

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
  bool _loading = true;
  String? _error;

  /// null: herkes; aksi hâlde yalnız bu oyuncunun girişleri.
  int? _filter;
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
    });
  }

  String _nameOf(int id) {
    for (final p in _players) {
      if (p.id == id) return p.name;
    }
    return 'Oyuncu $id';
  }

  @override
  Widget build(BuildContext context) {
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
    final shown = _filter == null
        ? _sessions
        : _sessions.where((s) => s.player == _filter).toList();
    final days = <String, List<ActivitySession>>{};
    for (final s in shown) {
      days.putIfAbsent(dayLabel(s.started, now), () => []).add(s);
    }
    return [
      if (_error != null) ...[
        _message(Icons.cloud_off_rounded, _error!),
        const SizedBox(height: 12),
      ],
      LayoutBuilder(builder: (context, c) {
        final cards = [for (final p in _players) _playerCard(p, now)];
        if (c.maxWidth < 520) {
          return Column(children: [
            for (final card in cards) ...[card, const SizedBox(height: 10)]
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
      }),
      const SizedBox(height: 18),
      const Text(
        'GİRİŞLER',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppTheme.textSecondary,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _chip('Tümü', null),
          for (final p in _players) _chip(p.name, p.id),
        ],
      ),
      const SizedBox(height: 10),
      if (shown.isEmpty)
        _message(Icons.hourglass_empty_rounded,
            'Henüz giriş kaydı yok. Uygulama açıldıkça burada görünür.')
      else
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
      const SizedBox(height: 10),
      const Text(
        'Son 30 gün gösterilir; kayıtlar 90 gün sonra silinir. '
        'Bu sayfayı yalnız yönetici hesabı görür.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
      ),
    ];
  }

  Widget _playerCard(ActivityPlayer p, DateTime now) {
    final seen = p.lastSeen;
    final active = seen != null && now.difference(seen) < kActiveWindow;
    final week = _sessions
        .where((s) =>
            s.player == p.id &&
            now.difference(s.started) < const Duration(days: 7))
        .toList();
    final total = week.fold(Duration.zero, (sum, s) => sum + s.length);
    ActivitySession? latest;
    for (final s in _sessions) {
      if (s.player == p.id) {
        latest = s;
        break;
      }
    }
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
                                ? 'Şu an aktif'
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
                  '7 gün: ${week.length} giriş · ${lengthLabel(total)}'),
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
      onSelected: (_) => setState(() => _filter = player),
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
