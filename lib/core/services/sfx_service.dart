import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'web_audio_bridge_stub.dart'
    if (dart.library.js_interop) 'web_audio_bridge_web.dart' as bridge;

/// Oyun ses efektleri (yerleştirme, satır silme, kombo, oyun bitti).
///
/// Web'de efektler WebAudio buffer'larıyla çalınır (audio.js içindeki
/// sfxLoad/sfxPlay): her çağrıda yeni BufferSource açıldığı için efekt
/// sınırsız kez ve üst üste çalabilir; gecikme çok düşüktür ve ses
/// seviyesi iOS'ta da gerçekten uygulanır (GainNode).
///
/// Web dışı platformlarda önceden yüklenmiş [AudioPlayer]'lara düşülür
/// (pause → seek(0) → play; "completed" durumunda takılı kalmaz).
///
/// Ses seviyesi kalıcıdır; müzik panelindeki "Oyun Efektleri"
/// kaydırıcısından ayarlanır, 0'a çekmek tamamen kapatır.
class SfxService {
  SfxService._();
  static final SfxService instance = SfxService._();

  static const _kVol = 'sfx_vol_v1';

  final Map<String, List<AudioPlayer>> _players = {}; // iki ses kanalı / efekt
  final Set<AudioPlayer> _busy = {};
  bool _initialized = false;
  Future<void>? _initializing;
  double _volume = 0.9;

  /// UI kaydırıcısının dinlediği canlı değer.
  final ValueNotifier<double> volumeListenable = ValueNotifier(0.9);

  double get volume => _volume;
  bool get enabled => _volume > 0.005;

  static const _files = {
    'place': 'assets/sfx/place.wav',
    'clear': 'assets/sfx/clear.wav',
    'combo': 'assets/sfx/combo.wav',
    'over': 'assets/sfx/over.wav',
  };

  Future<void> init() =>
      _initializing ??= _initialize().whenComplete(() => _initializing = null);

  Future<void> _initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      _volume = prefs.getDouble(_kVol) ?? 0.9;
    } catch (_) {}
    volumeListenable.value = _volume;

    if (kIsWeb) {
      for (final e in _files.entries) {
        bridge.sfxLoad(e.key, Uri.base.resolve('assets/${e.value}').toString());
      }
      bridge.sfxSetVolume(_volume);
      _initialized = true;
      return;
    }

    for (final e in _files.entries) {
      final pool = _players.putIfAbsent(e.key, () => []);
      while (pool.length < 2) {
        final player = AudioPlayer();
        try {
          await player.setAsset(e.value, preload: true);
          await player.setVolume(_volume);
          pool.add(player);
        } catch (error) {
          await player.dispose();
          debugPrint('[Sfx] ${e.key} yüklenemedi: $error');
          break;
        }
      }
    }
    _initialized = _players.values.every((pool) => pool.length == 2);
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    volumeListenable.value = _volume;
    if (kIsWeb) {
      bridge.sfxSetVolume(_volume);
    } else {
      for (final p in _players.values.expand((pool) => pool)) {
        try {
          await p.setVolume(_volume);
        } catch (_) {}
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      await prefs.setDouble(_kVol, _volume);
    } catch (_) {}
  }

  void _play(String key, {double rate = 1}) {
    if (!enabled) return;
    if (kIsWeb) {
      bridge.sfxPlay(key, rate);
      return;
    }
    final available =
        (_players[key] ?? <AudioPlayer>[]).where((p) => !_busy.contains(p));
    if (available.isEmpty) return;
    final p = available.first;
    _busy.add(p);
    // Ateşle-unut. Önce pause: klip bittiğinde just_audio "completed +
    // playing" durumunda kalır; pause'suz seek(0)+play ikinci kez çalmaz.
    () async {
      try {
        if (p.playing) await p.pause();
        await p.setSpeed(rate);
        await p.seek(Duration.zero);
        await p.play();
      } catch (_) {
      } finally {
        _busy.remove(p);
      }
    }();
  }

  void place() => _play('place');
  void clear() => _play('clear');
  void combo([int chain = 1]) =>
      _play('combo', rate: 1 + (chain - 1).clamp(0, 8) * 0.04);
  void gameOver() => _play('over');
}
