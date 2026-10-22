import 'dart:math';

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
    'chime': 'assets/sfx/chime.wav',
    'bonk': 'assets/sfx/bonk.wav',
    'ko': 'assets/sfx/ko.wav',
    'nope': 'assets/sfx/nope.wav',
    // Flappy Silly Cat + Subway Silly (tools/game_sfx.py üretir)
    'flap': 'assets/sfx/flap.wav',
    'point': 'assets/sfx/point.wav',
    'hit': 'assets/sfx/hit.wav',
    'fall': 'assets/sfx/fall.wav',
    'coin': 'assets/sfx/coin.wav',
    'jump': 'assets/sfx/jump.wav',
    'slide': 'assets/sfx/slide.wav',
    'swoosh': 'assets/sfx/swoosh.wav',
    'land': 'assets/sfx/land.wav',
    'power': 'assets/sfx/power.wav',
    'powerdown': 'assets/sfx/powerdown.wav',
    'stumble': 'assets/sfx/stumble.wav',
    'crash': 'assets/sfx/crash.wav',
    'medal': 'assets/sfx/medal.wav',
    // Adliye Kulesi
    'stack': 'assets/sfx/stack.wav',
    'perfect': 'assets/sfx/perfect.wav',
    'slice': 'assets/sfx/slice.wav',
    'grow': 'assets/sfx/grow.wav',
    'era': 'assets/sfx/era.wav',
    'miss': 'assets/sfx/miss.wav',
    'girl': 'assets/sfx/girl.wav',
    // Block Blast 1v1 jokerleri
    'freeze': 'assets/sfx/freeze.wav',
    'shatter': 'assets/sfx/shatter.wav',
    'expand': 'assets/sfx/expand.wav',
    'tick': 'assets/sfx/tick.wav',
    'salt': 'assets/sfx/salt.wav',
    'reflect': 'assets/sfx/reflect.wav',
    'shrink': 'assets/sfx/shrink.wav',
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
  // Reuse the short placement impact at a lower pitch; honors the SFX volume.
  void damage() => _play('place', rate: 0.65);
  void gameOver() => _play('over');

  final _rng = Random();

  /// Bukete dokunma: tatlı "bıling"; her seferinde perdesi biraz değişir.
  void chime() => _play('chime', rate: 0.92 + _rng.nextDouble() * 0.2);

  /// Soru dövme: her vuruşta biraz tizleşen 8-bit "bonk".
  void bonk(int hits) => _play('bonk',
      rate: 0.9 + hits.clamp(0, 10) * 0.035 + _rng.nextDouble() * 0.06);

  /// Soru pes etti: 8-bit zafer melodisi.
  void ko() => _play('ko');

  /// Pes etmeden şık seçilmeye çalışıldı.
  void nope() => _play('nope');

  // ── Arcade oyunları ──
  void flap() => _play('flap', rate: 0.95 + _rng.nextDouble() * 0.1);
  void point() => _play('point');
  void hit() => _play('hit');
  void fall() => _play('fall');

  /// Coin: ardışık toplamalarda perde hafifçe yükselir.
  void coin([int streak = 0]) => _play('coin', rate: 1 + (streak % 8) * 0.03);
  void jump() => _play('jump');
  void slide() => _play('slide');
  void swoosh() => _play('swoosh', rate: 0.9 + _rng.nextDouble() * 0.2);
  void land() => _play('land');
  void power() => _play('power');
  void powerDown() => _play('powerdown');
  void stumble() => _play('stumble');
  void crash() => _play('crash');
  void medal() => _play('medal');

  // ── Adliye Kulesi ──
  /// Kat yerleşti; yükseldikçe perde çok hafif düşer (taş ağırlaşır).
  void stack(int floor) => _play('stack',
      rate: 1.04 - (floor % 8) * 0.012 + _rng.nextDouble() * 0.03);

  /// Mükemmel yerleşim: seri boyunca majör gamda yükselen çan.
  void perfect(int streak) {
    const scale = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19];
    final step = scale[(streak - 1).clamp(0, scale.length - 1)];
    _play('perfect', rate: pow(2, step / 12).toDouble());
  }

  void slice() => _play('slice', rate: 0.92 + _rng.nextDouble() * 0.16);
  void grow() => _play('grow');
  void era() => _play('era');
  void miss() => _play('miss');
  void girl() => _play('girl');

  // ── Block Blast 1v1 jokerleri ──
  void freezeThrow() => _play('freeze');
  void freezeHit() => _play('freeze', rate: .8);
  void shatter() => _play('shatter');
  void expand() => _play('expand');
  void salt() => _play('salt');
  void reflect() => _play('reflect');
  void shrink() => _play('shrink');
  void tick({double rate = 1}) => _play('tick', rate: rate);
}
