import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'web_audio_bridge_stub.dart'
    if (dart.library.js_interop) 'web_audio_bridge_web.dart' as bridge;

/// Oyun ses efektleri (yerleştirme, satır silme, kombo, oyun bitti).
///
/// Web'de efektler WebAudio buffer'larıyla çalınır (index.html'deki
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

  final Map<String, AudioPlayer> _players = {}; // yalnızca web dışı
  bool _initialized = false;
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

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      _volume = prefs.getDouble(_kVol) ?? 0.9;
    } catch (_) {}
    volumeListenable.value = _volume;

    if (kIsWeb) {
      for (final e in _files.entries) {
        bridge.sfxLoad(e.key, '${Uri.base}assets/${e.value}');
      }
      bridge.sfxSetVolume(_volume);
      return;
    }

    for (final e in _files.entries) {
      try {
        final p = AudioPlayer();
        await p.setAsset(e.value, preload: true);
        await p.setVolume(_volume);
        _players[e.key] = p;
      } catch (err) {
        debugPrint('[Sfx] ${e.key} yüklenemedi: $err');
      }
    }
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    volumeListenable.value = _volume;
    if (kIsWeb) {
      bridge.sfxSetVolume(_volume);
    } else {
      for (final p in _players.values) {
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

  void _play(String key) {
    if (!enabled) return;
    if (kIsWeb) {
      bridge.sfxPlay(key);
      return;
    }
    final p = _players[key];
    if (p == null) return;
    // Ateşle-unut. Önce pause: klip bittiğinde just_audio "completed +
    // playing" durumunda kalır; pause'suz seek(0)+play ikinci kez çalmaz.
    () async {
      try {
        if (p.playing) await p.pause();
        await p.seek(Duration.zero);
        await p.play();
      } catch (_) {}
    }();
  }

  void place() => _play('place');
  void clear() => _play('clear');
  void combo() => _play('combo');
  void gameOver() => _play('over');
}
