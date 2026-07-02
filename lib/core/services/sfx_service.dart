import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oyun ses efektleri (yerleştirme, satır silme, kombo, oyun bitti).
///
/// Her efekt kendi önceden yüklenmiş [AudioPlayer]'ında durur; çalmak
/// yalnızca seek(0)+play olduğundan gecikme düşüktür (iOS/Safari dahil).
/// Ses seviyesi kalıcıdır ve müzik panelindeki "Efektler" kaydırıcısından
/// ayarlanır; 0'a çekmek tamamen kapatır.
class SfxService {
  SfxService._();
  static final SfxService instance = SfxService._();

  static const _kVol = 'sfx_vol_v1';

  final Map<String, AudioPlayer> _players = {};
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
    for (final e in _files.entries) {
      try {
        final p = AudioPlayer();
        if (kIsWeb) {
          await p.setUrl('${Uri.base}assets/${e.value}', preload: true);
        } else {
          await p.setAsset(e.value, preload: true);
        }
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
    for (final p in _players.values) {
      try {
        await p.setVolume(_volume);
      } catch (_) {}
    }
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      await prefs.setDouble(_kVol, _volume);
    } catch (_) {}
  }

  void _play(String key) {
    if (!enabled) return;
    final p = _players[key];
    if (p == null) return;
    // Beklemeden ateşle-unut: oyun akışını hiçbir zaman bloklamaz.
    p.seek(Duration.zero).then((_) => p.play()).catchError((_) {});
  }

  void place() => _play('place');
  void clear() => _play('clear');
  void combo() => _play('combo');
  void gameOver() => _play('over');
}
