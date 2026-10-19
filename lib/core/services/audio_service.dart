import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../config/app_config.dart';
import 'web_audio_bridge_stub.dart'
    if (dart.library.js_interop) 'web_audio_bridge_web.dart' as bridge;

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
  Future<void>? _initializing;
  bool _hasStarted = false;
  bool _userPaused = false; // kullanıcı bilerek durdurduysa true
  bool _specialActive = false; // sürpriz ekranındaki parça tekrarda mı
  bool _prepared = false;

  bool get hasTracks => AppConfig.musicTracks.isNotEmpty;

  // ── Canlı durum akışları (UI StreamBuilder ile dinler) ──
  Stream<bool> get playingStream => _player.playingStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<double> get volumeStream => _player.volumeStream;

  /// Çalma istendi ama parça henüz ses vermiyor (yükleniyor/tamponluyor).
  Stream<bool> get loadingStream => _player.playerStateStream
      .map((s) =>
          s.playing &&
          (s.processingState == ProcessingState.loading ||
              s.processingState == ProcessingState.buffering))
      .distinct();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  bool get isPlaying => _player.playing;
  double get volume => _player.volume;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  /// Çalan parçanın listedeki sırası (0'dan).
  int get currentIndex => hasTracks
      ? (_player.currentIndex ?? 0) % AppConfig.musicTracks.length
      : 0;
  int get trackCount => AppConfig.musicTracks.length;

  /// Şu an çalan parçanın dosya adı (uzantısız).
  String get currentTrackName => hasTracks ? trackName(currentIndex) : '';

  /// [i]. parçanın okunur adı: "Bari_Ruyalarima_Gel_Be.m4a" → "Bari Ruyalarima Gel Be".
  String trackName(int i) {
    final file = AppConfig.musicTracks[i].split('/').last;
    final dot = file.lastIndexOf('.');
    final name = dot > 0 ? file.substring(0, dot) : file;
    return name.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  }

  Future<void> init() =>
      _initializing ??= _initialize().whenComplete(() => _initializing = null);

  Future<void> _initialize() async {
    if (_initialized || !hasTracks) return;
    try {
      final sources = AppConfig.musicTracks.map(_sourceFor).toList();
      // Her açılışta rastgele bir parçadan başla.
      final startIndex =
          sources.length > 1 ? Random().nextInt(sources.length) : 0;
      await _player.setAudioSources(
        sources,
        preload: false,
        initialIndex: startIndex,
      );
      await _player.setLoopMode(LoopMode.all);
      await _player.setVolume(AppConfig.musicVolume);
      // Karıştırma AÇIK + sıra yeniden rastgelelenir: her girişte parçalar
      // rastgele sırayla çalar.
      await _player.setShuffleModeEnabled(true);
      await _player.shuffle();
      _initialized = true;
    } catch (e) {
      debugPrint('[Audio] init hatası: $e');
    }
  }

  /// Çalan parçayı çalmadan önce yükler (denetim masası açılınca).
  ///
  /// `preload: false` yüzünden parça ilk Çal'a kadar hiç inmiyordu; play
  /// önce ağdan üstveriyi bekliyor, müzik geç geliyordu. iOS Safari ise bu
  /// beklemeden sonra gelen play()'i dokunuşa saymayıp hiç çalmıyordu.
  /// Kaynak hazırsa play() dokunuşun içinde doğrudan <audio>'ya ulaşır.
  void prepare() {
    if (!hasTracks || _prepared) return;
    _prepared = true;
    unawaited(() async {
      try {
        await init();
        if (!_initialized) {
          _prepared = false;
          return;
        }
        if (_player.processingState == ProcessingState.idle) {
          await _player.load();
        }
      } catch (e) {
        _prepared = false; // çevrimdışı vb.: sonraki açılışta yeniden dene
        debugPrint('[Audio] hazırlama hatası: $e');
      }
    }());
  }

  AudioSource _sourceFor(String assetPath) {
    if (kIsWeb) {
      // Music is streamed outside the offline shell. Change its URL when the
      // encoding changes so Safari/CDN range caches cannot reuse old audio.
      final url = Uri.base.resolve('assets/$assetPath').replace(
        queryParameters: const {'audio': '48k-v1'},
      );
      return AudioSource.uri(url);
    }
    return AudioSource.asset(assetPath);
  }

  void _play() {
    _hasStarted = true;
    unawaited(_player.play().catchError((Object error) {
      debugPrint('[Audio] play hatası: $error');
    }));
    bridge.musicSetVolume(_player.volume);
  }

  /// İlk kullanıcı etkileşiminde çağrılır (web autoplay kısıtı için).
  Future<void> start() async {
    if (!hasTracks || _userPaused) return;
    await init();
    if (_player.playing) return;
    try {
      _play();
      // iOS Safari <audio>.volume'u yok sayar; müzik elemanını GainNode'a
      // bağlayıp başlangıç seviyesini uygula (iOS dışında no-op).
      bridge.musicSetVolume(_player.volume);
    } catch (e) {
      debugPrint('[Audio] start hatası: $e');
    }
  }

  /// [assetPath] parçasını baştan çalar ve [endSpecial] çağrılana kadar
  /// tekrarlar (çiçek sürprizinde Wildflower). Web autoplay kısıtı nedeniyle
  /// bir dokunuşun içinden çağrılmalıdır.
  Future<void> playSpecial(String assetPath) async {
    final index = AppConfig.musicTracks.indexOf(assetPath);
    if (index < 0) return;
    _userPaused = false;
    _specialActive = true;
    try {
      if (!_initialized) await init();
      if (!_initialized) return;
      unawaited(_player.setLoopMode(LoopMode.one).catchError((Object _) {}));
      final seek = _player.seek(Duration.zero, index: index);
      if (!_player.playing) _play();
      await seek;
    } catch (e) {
      debugPrint('[Audio] özel parça hatası: $e');
    }
  }

  /// Özel parçadan çıkınca normal karışık döngüye döner; çalan parça kesilmez.
  Future<void> endSpecial() async {
    if (!_specialActive) return;
    _specialActive = false;
    try {
      await _player.setLoopMode(LoopMode.all);
    } catch (_) {}
  }

  /// Denetim masası: çal / durdur.
  Future<void> playPause() async {
    // Hazırsa beklemeden çal: iOS play()'i yalnız dokunuşun içinde kabul eder.
    if (!_initialized) await init();
    if (_player.playing) {
      _userPaused = true;
      await _player.pause();
    } else {
      _userPaused = false;
      try {
        _play();
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
      if (!_player.playing) _play();
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
      if (!_player.playing) _play();
    } catch (e) {
      debugPrint('[Audio] previous hatası: $e');
    }
  }

  /// Denetim masası: listeden parça seç.
  Future<void> playTrack(int index) async {
    if (index < 0 || index >= trackCount) return;
    await init();
    _userPaused = false;
    try {
      await _player.seek(Duration.zero, index: index);
      if (!_player.playing) _play();
    } catch (e) {
      debugPrint('[Audio] parça seçme hatası: $e');
    }
  }

  /// Denetim masası: parçada ileri/geri sar.
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (_) {}
  }

  Future<void> setVolume(double v) async {
    final vol = v.clamp(0.0, 1.0);
    // iOS'ta element.volume işlemez; GainNode üzerinden gerçekten uygula.
    bridge.musicSetVolume(vol);
    await _player.setVolume(vol);
  }

  // ── Uygulama yaşam döngüsü ──
  Future<void> pauseForLifecycle() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> resumeForLifecycle() async {
    if (_userPaused || !hasTracks || !_hasStarted) return;
    try {
      _play();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
