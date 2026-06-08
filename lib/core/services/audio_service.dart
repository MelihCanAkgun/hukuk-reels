import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../config/app_config.dart';

/// Arka plan müziği servisi.
///
/// AppConfig.musicTracks listesindeki parçaları kesintisiz döngü hâlinde
/// çalar. Müzik SORU DEĞİŞTİKÇE DEĞİŞMEZ; yalnızca kullanıcı denetim
/// masasından (çal/durdur, sonraki/önceki) değiştirir.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  bool _userPaused = false; // kullanıcı bilerek durdurduysa true

  bool get hasTracks => AppConfig.musicTracks.isNotEmpty;

  // ── Canlı durum akışları (UI StreamBuilder ile dinler) ──
  Stream<bool> get playingStream => _player.playingStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<double> get volumeStream => _player.volumeStream;

  bool get isPlaying => _player.playing;
  double get volume => _player.volume;

  /// Şu an çalan parçanın dosya adı (uzantısız).
  String get currentTrackName {
    if (!hasTracks) return '';
    final i = _player.currentIndex ?? 0;
    final path = AppConfig.musicTracks[i % AppConfig.musicTracks.length];
    final file = path.split('/').last;
    final dot = file.lastIndexOf('.');
    final name = dot > 0 ? file.substring(0, dot) : file;
    return name.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  }

  Future<void> init() async {
    if (_initialized || !hasTracks) return;
    try {
      final sources = AppConfig.musicTracks.map(_sourceFor).toList();
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        preload: false,
      );
      await _player.setLoopMode(LoopMode.all);
      await _player.setVolume(AppConfig.musicVolume);
      // Karıştırma KAPALI: parçalar listedeki sırayla çalar
      // (ilk parça Wildflower, son parça Bal).
      await _player.setShuffleModeEnabled(false);
      _initialized = true;
    } catch (e) {
      debugPrint('[Audio] init hatası: $e');
    }
  }

  AudioSource _sourceFor(String assetPath) {
    if (kIsWeb) {
      final url = '${Uri.base}assets/$assetPath';
      return AudioSource.uri(Uri.parse(url));
    }
    return AudioSource.asset(assetPath);
  }

  /// İlk kullanıcı etkileşiminde çağrılır (web autoplay kısıtı için).
  Future<void> start() async {
    if (!hasTracks || _userPaused) return;
    await init();
    if (_player.playing) return;
    try {
      await _player.play();
    } catch (e) {
      debugPrint('[Audio] start hatası: $e');
    }
  }

  /// Denetim masası: çal / durdur.
  Future<void> playPause() async {
    await init();
    if (_player.playing) {
      _userPaused = true;
      await _player.pause();
    } else {
      _userPaused = false;
      try {
        await _player.play();
      } catch (e) {
        debugPrint('[Audio] play hatası: $e');
      }
    }
  }

  /// Denetim masası: sonraki parça.
  Future<void> next() async {
    if (!hasTracks) return;
    await init();
    _userPaused = false;
    try {
      await _player.seekToNext();
      if (!_player.playing) await _player.play();
    } catch (e) {
      debugPrint('[Audio] next hatası: $e');
    }
  }

  /// Denetim masası: önceki parça.
  Future<void> previous() async {
    if (!hasTracks) return;
    await init();
    _userPaused = false;
    try {
      await _player.seekToPrevious();
      if (!_player.playing) await _player.play();
    } catch (e) {
      debugPrint('[Audio] previous hatası: $e');
    }
  }

  Future<void> setVolume(double v) async {
    await _player.setVolume(v.clamp(0.0, 1.0));
  }

  // ── Uygulama yaşam döngüsü ──
  Future<void> pauseForLifecycle() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> resumeForLifecycle() async {
    if (_userPaused || !hasTracks) return;
    try {
      await _player.play();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
