import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/services/avatar_sync.dart';
import '../../core/services/social_bridge.dart';
import '../../core/widgets/pixel_logo.dart';
import '../profile/profile_avatar.dart';
import 'countdown_text.dart';
import '../home/home_store.dart';
import '../../core/widgets/readable_width.dart';

/// Sunucudaki bir uçuş (yalnız iki oyuncu görebilir).
class Trip {
  Trip.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        player = j['player'] as int,
        name = (j['name'] as String?) ?? 'Oyuncu',
        destination = j['destination'] as String,
        arrival =
            DateTime.fromMillisecondsSinceEpoch((j['arrival'] as int) * 1000),
        created =
            DateTime.fromMillisecondsSinceEpoch((j['created'] as int) * 1000);

  final int id, player;
  final String name, destination;
  final DateTime arrival, created;

  String get sentence => tripSentence(name, destination);

  /// Bilet eklendiğinden varışa kadar geçen yolun oranı (uçak konumu).
  double progress(DateTime now) {
    final total = arrival.difference(created).inSeconds;
    if (total <= 0) return 1;
    return (now.difference(created).inSeconds / total).clamp(0.0, 1.0);
  }
}

List<Trip> parseTrips(Map<String, dynamic> r) => [
      for (final t in (r['trips'] as List? ?? const []).whereType<Map>())
        Trip.fromJson(t.cast<String, dynamic>())
    ];

/// Kavuşma sayacı: uçak biletleri alınınca varış yeri ve zamanı girilir;
/// gün ve saat olarak canlı geri sayım gösterilir.
class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  final _store = HomeStore.instance;
  int? _me;
  bool _busy = false;
  DateTime _now = DateTime.now();
  Timer? _tick;

  List<Trip> get _trips => _store.trips;

  @override
  void initState() {
    super.initState();
    _store.changes.addListener(_changed);
    _load();
    // Yalnız ekran yazısı; sunucuya istek atmaz. Saniye gösterilmiyor.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _store.changes.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() => _now = DateTime.now());
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _store.refresh(force: true),
      socialCall('state').then(AvatarSync.instance.sync), // fotoğraflar
    ]);
    if (!mounted) return;
    setState(() => _me = (results[1] as Map<String, dynamic>)['me'] as int?);
  }

  Future<void> _apply(Future<Map<String, dynamic>> call, String done) async {
    setState(() => _busy = true);
    final r = await call;
    if (!mounted) return;
    setState(() => _busy = false);
    _toast((r['error'] as String?) ?? done);
  }

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(color: AppTheme.textPrimary)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.surfaceHigh,
    ));

  bool _canDelete(Trip t) => t.player == _me || _me == 1;

  Future<void> _delete(Trip t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgElevated,
        title: const Text('Uçuşu sil'),
        content: Text('${dative(t.destination)} ${dateText(t.arrival)} '
            'tarihli uçuş silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child:
                  const Text('Sil', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok == true) {
      await _apply(_store.delete(t.id), 'Uçuş silindi.');
    }
  }

  Future<void> _add() async {
    final result = await showModalBottomSheet<(String, DateTime)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddTripSheet(),
    );
    if (result == null || !mounted) return;
    final (destination, arrival) = result;
    await _apply(
      _store.add(destination, arrival),
      'Uçuş eklendi. Geri sayım başladı ✈️',
    );
    HapticFeedback.lightImpact();
  }

  Widget _avatar(Trip t, double size) => t.player == _me
      ? ProfileAvatar(size: size)
      : PeerAvatar(id: t.player, name: t.name, size: size);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelLogo(kLogoPlane, size: 26),
            SizedBox(width: 8),
            Text('Kavuşma Sayacı',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      floatingActionButton: _store.connected
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : _add,
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.flight_takeoff_rounded),
              label: const Text('Uçuş ekle',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: !_store.loaded
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                      readableGutter(context), 8, readableGutter(context), 100),
                  children: [
                    if (_busy) const LinearProgressIndicator(),
                    if (!_store.connected)
                      _info('Kavuşma sayacı yalnız oyuncu kodu olan ikiniz '
                          'içindir. "İkimizin sıralaması"na oyuncu kodunla '
                          'katılınca kullanabilirsin.')
                    else if (_trips.isEmpty)
                      _empty()
                    else ...[
                      _Hero(
                        trip: _trips.first,
                        now: _now,
                        avatar: _avatar(_trips.first, 76),
                        onDelete: _canDelete(_trips.first)
                            ? () => _delete(_trips.first)
                            : null,
                      ),
                      if (_trips.length > 1) ...[
                        const SizedBox(height: 18),
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text('SIRADAKİ UÇUŞLAR',
                              style: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textMuted)),
                        ),
                        for (final t in _trips.skip(1)) _tile(t),
                      ],
                    ],
                    if (_store.error != null && _store.connected)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                            'Çevrimdışı: son kaydedilen liste gösteriliyor.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textMuted)),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _info(String text) => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(children: [
          const PixelLogo(kLogoPlane, size: 72),
          const SizedBox(height: 16),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary)),
        ]),
      );

  Widget _empty() => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Column(children: [
          PixelLogo(kLogoPlane, size: 84),
          SizedBox(height: 16),
          Text('Henüz uçuş yok',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text(
              'Bileti alınca varış yerini ve saatini ekle;\n'
              'kavuşmaya ne kadar kaldığını birlikte sayalım 💌',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary)),
        ]),
      );

  Widget _tile(Trip t) {
    final left = remainingText(t.arrival.difference(_now));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        _avatar(t, 46),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.sentence,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(left == null ? 'vardı 🎉' : '$left kaldı',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            Text(arrivalText(t.arrival),
                style:
                    const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ]),
        ),
        if (_canDelete(t))
          IconButton(
            tooltip: 'Uçuşu sil',
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.textMuted),
            onPressed: _busy ? null : () => _delete(t),
          ),
      ]),
    );
  }
}

/// En yakın uçuş: büyük geri sayım ve yol boyunca ilerleyen uçak.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.trip,
    required this.now,
    required this.avatar,
    this.onDelete,
  });

  final Trip trip;
  final DateTime now;
  final Widget avatar;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final left = remainingText(trip.arrival.difference(now));
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A2340), Color(0xFF2A1521)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.45)),
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Spacer(),
          avatar,
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: onDelete == null
                  ? null
                  : IconButton(
                      tooltip: 'Uçuşu sil',
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.textMuted),
                      onPressed: onDelete,
                    ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (left != null) ...[
          Text(trip.sentence,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15.5, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(left,
                style: const TextStyle(
                    fontSize: 38,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accent)),
          ),
          const Text('kaldı 💕',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ] else ...[
          Text('${trip.name} ${dative(trip.destination)} vardı!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.accent)),
          const SizedBox(height: 4),
          const Text('Kavuştunuz 💞',
              style: TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
        ],
        const SizedBox(height: 18),
        _FlightPath(progress: trip.progress(now)),
        const SizedBox(height: 10),
        Text(arrivalText(trip.arrival),
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      ]),
    );
  }
}

/// Kesikli yol: uçak bilet eklendiği andan varışa kadar soldan sağa, sarılan
/// çifte doğru ilerler (kalan süre azaldıkça yaklaşır).
class _FlightPath extends StatelessWidget {
  const _FlightPath({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: LayoutBuilder(builder: (context, c) {
        const plane = 34.0, couple = 54.0;
        // Uçağın burnu varışta çiftin yanına değer.
        final track = c.maxWidth - plane - couple + 4;
        return Stack(children: [
          Positioned(
            left: plane / 2,
            right: couple - 6,
            top: 38,
            child: CustomPaint(
                size: const Size(double.infinity, 2),
                painter: _DashPainter(progress)),
          ),
          const Positioned(
              right: 0, bottom: 0, child: PixelLogo(kLogoCouple, size: couple)),
          Positioned(
              left: track * progress,
              top: 22,
              child: const PixelLogo(kLogoPlane, size: plane)),
        ]);
      }),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final done = Paint()..color = AppTheme.accent;
    final todo = Paint()..color = AppTheme.border;
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawRect(
          Rect.fromLTWH(x, 0, 5, 2), x / size.width <= progress ? done : todo);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.progress != progress;
}

/// Uçuş ekleme: varış yeri, tarih ve saat.
class _AddTripSheet extends StatefulWidget {
  const _AddTripSheet();

  @override
  State<_AddTripSheet> createState() => _AddTripSheetState();
}

class _AddTripSheetState extends State<_AddTripSheet> {
  final _dest = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  String? _error;

  @override
  void dispose() {
    _dest.dispose();
    super.dispose();
  }

  DateTime? get _arrival => _date == null || _time == null
      ? null
      : DateTime(
          _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
      helpText: 'Varış tarihi',
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'Varış saati',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t != null) setState(() => _time = t);
  }

  void _save() {
    final dest = _dest.text.trim();
    final at = _arrival;
    setState(() {
      _error = dest.isEmpty
          ? 'Nereye uçuyorsun?'
          : at == null
              ? 'Varış tarihini ve saatini seç.'
              : !at.isAfter(DateTime.now())
                  ? 'Varış zamanı gelecekte olmalı.'
                  : null;
    });
    if (_error == null) Navigator.of(context).pop((dest, at!));
  }

  @override
  Widget build(BuildContext context) {
    final at = _arrival;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          const Row(children: [
            PixelLogo(kLogoPlane, size: 30),
            SizedBox(width: 10),
            Text('Uçuş ekle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 4),
          const Text('Geri sayım senin adınla görünür.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
          const SizedBox(height: 14),
          TextField(
            controller: _dest,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Nereye?',
              hintText: 'Örn. İstanbul',
              prefixIcon: Icon(Icons.place_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_rounded),
                label: Text(_date == null ? 'Tarih' : dateText(_date!)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(_time == null
                    ? 'Saat'
                    : '${_time!.hour.toString().padLeft(2, '0')}:'
                        '${_time!.minute.toString().padLeft(2, '0')}'),
              ),
            ),
          ]),
          if (at != null && _dest.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Önizleme: ${dative(_dest.text.trim())} '
              '${remainingText(at.difference(DateTime.now())) ?? 'geçmiş bir zaman'}',
              style: const TextStyle(
                  fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppTheme.danger)),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _save,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Kaydet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
