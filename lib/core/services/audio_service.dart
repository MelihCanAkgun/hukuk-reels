import 'dart:math';
import 'package:just_audio/just_audio.dart';

/// ─────────────────────────────────────────────────
/// Arka Plan Müzik Servisi
///
/// Her Reel kartı için sillycat tarzı bir melodi
/// döngüsel (loop) olarak çalar. Sayfa değiştiğinde
/// müzik de değişir.
/// ─────────────────────────────────────────────────
class AudioService {
  static AudioService? _instance;
  AudioService._();

  static AudioService get instance {
    _instance ??= AudioService._();
    return _instance!;
  }

  final _player = AudioPlayer();
  final _random = Random();
  bool _initialized = false;
  bool _muted = false;
  int _currentTrackIndex = -1;

  /// Mevcut parça listesi (asset yolları)
  static const _tracks = [
    'assets/audio/sillycat_1.wav',
    'assets/audio/sillycat_2.wav',
    'assets/audio/sillycat_3.wav',
    'assets/audio/sillycat_4.wav',
    'assets/audio/sillycat_5.wav',
  ];

  bool get isMuted => _muted;
  bool get isPlaying => _player.playing;

  /// İlk kullanımda çağrılır
  Future<void> init() async {
    if (_initialized) return;
    _player.setLoopMode(LoopMode.one);
    _player.setVolume(0.4);
    _initialized = true;
  }

  /// Belirli bir Reel index'ine göre parça çal
  /// Her reel'e tutarlı ama farklı bir parça atanır
  Future<void> playForReel(int reelIndex) async {
    if (_muted) return;

    final trackIndex = reelIndex % _tracks.length;

    // Aynı parça zaten çalıyorsa tekrar başlatma
    if (trackIndex == _currentTrackIndex && _player.playing) return;

    _currentTrackIndex = trackIndex;

    try {
      await _player.setAsset(_tracks[trackIndex]);
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (e) {
      // Asset bulunamazsa sessizce devam et
      // (Web'de ilk autoplay browser tarafından engellenebilir)
    }
  }

  /// Rastgele parça çal
  Future<void> playRandom() async {
    final index = _random.nextInt(_tracks.length);
    await playForReel(index);
  }

  /// Duraklat
  Future<void> pause() async {
    await _player.pause();
  }

  /// Devam et
  Future<void> resume() async {
    if (!_muted) {
      await _player.play();
    }
  }

  /// Sessize al / aç
  Future<void> toggleMute() async {
    _muted = !_muted;
    if (_muted) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Ses seviyesi (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Temizlik
  Future<void> dispose() async {
    await _player.dispose();
  }
}
