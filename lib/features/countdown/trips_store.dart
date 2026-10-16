import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/services/social_bridge.dart';
import 'countdown_screen.dart' show Trip, parseTrips;

/// Uçuş listesinin tek kaynağı (Oyunlar kartı + sayaç ekranı).
///
/// Ücretsiz Cloudflare kotası için tutumlu: geri sayım yazısı cihazda
/// hesaplanır, sunucuya yalnız şu durumlarda gidilir:
///  • uygulama öne gelince (en fazla dakikada bir),
///  • uygulama ekrandayken 15 dakikada bir,
///  • ekran açılırken / aşağı çekip yenileyince ve ekleme-silmede.
/// Aynı anda tek istek çalışır.
class TripsStore with WidgetsBindingObserver {
  TripsStore._();
  static final TripsStore instance = TripsStore._();

  static const minAge = Duration(minutes: 1);
  static const pollEvery = Duration(minutes: 15);

  /// Liste değişince artar.
  final ValueNotifier<int> changes = ValueNotifier(0);
  List<Trip> trips = const [];
  bool connected = false, loaded = false;

  /// Son yenilemede sunucuya ulaşılamadıysa (liste önbellekten).
  String? error;

  /// Testlerde sahte sunucu bağlamak için.
  @visibleForTesting
  Future<Map<String, dynamic>> Function(String action,
      [Map<String, dynamic> data]) call = socialCall;

  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  DateTime? _fetched;
  Future<void>? _running;
  Timer? _poll;

  void start() {
    if (_poll != null) return;
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(pollEvery, (_) {
      final s = WidgetsBinding.instance.lifecycleState;
      if (s == null || s == AppLifecycleState.resumed) refresh();
    });
  }

  /// Oyunlar ekranı kapanınca (yalnız testlerde) zamanlayıcıyı bırakır.
  void stop() {
    if (_poll == null) return;
    _poll?.cancel();
    _poll = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  /// [force] olmadan son yenilemeden bu yana [minAge] geçmediyse istek atmaz.
  Future<void> refresh({bool force = false}) {
    final running = _running;
    if (running != null) return running;
    final last = _fetched;
    if (!force && last != null && clock().difference(last) < minAge) {
      return Future.value();
    }
    return _running = _load().whenComplete(() => _running = null);
  }

  Future<void> _load() async {
    _apply(await call('trips'));
    _fetched = clock();
  }

  /// Ekleme/silme: sunucunun döndürdüğü güncel liste hemen uygulanır.
  Future<Map<String, dynamic>> add(String destination, DateTime arrival) =>
      _write('tripAdd', {
        'destination': destination,
        'arrival': arrival.millisecondsSinceEpoch ~/ 1000,
      });

  Future<Map<String, dynamic>> delete(int id) =>
      _write('tripDelete', {'id': id});

  Future<Map<String, dynamic>> _write(
      String action, Map<String, dynamic> data) async {
    final r = await call(action, data);
    if (r['error'] == null) {
      _apply(r);
      _fetched = clock();
    }
    return r;
  }

  void _apply(Map<String, dynamic> r) {
    loaded = true;
    connected = r['connected'] == true;
    error = r['offline'] == true ? r['error'] as String? : null;
    if (r['trips'] != null) trips = parseTrips(r);
    changes.value++;
  }
}
