import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/sfx_service.dart';
import '../../../core/widgets/pressable.dart';

/// Ses denetim masası: çalan parça (ilerleme ve sarma), çal/durdur,
/// önceki/sonraki, parça listesi ve müzik ile oyun efektleri için ayrı ses
/// düzeyleri. Müzik soru değiştikçe değişmez; yalnız buradan yönetilir.
class MusicControlPanel extends StatefulWidget {
  final VoidCallback onClose;
  const MusicControlPanel({super.key, required this.onClose});

  @override
  State<MusicControlPanel> createState() => _MusicControlPanelState();
}

class _MusicControlPanelState extends State<MusicControlPanel> {
  final _audio = AudioService.instance;
  final _sfx = SfxService.instance;

  /// Sessize alınınca dönülecek düzeyler (panel kapanıp açılsa da kalır).
  static double _musicBefore = 0.35, _sfxBefore = 0.9;
  bool _list = false;

  /// Sarma sırasında parmağın gösterdiği konum (bırakınca uygulanır).
  double? _scrub;

  @override
  void initState() {
    super.initState();
    // Çal'a basılmadan parça inmeye başlasın; basınca hemen çalar.
    _audio.prepare();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = math.min(320.0, mq.size.width - 24);
    final maxHeight = mq.size.height - mq.padding.vertical - 70;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        key: const ValueKey('music-panel'),
        width: width,
        constraints: BoxConstraints(maxHeight: math.max(220, maxHeight)),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 10),
                _nowPlaying(),
                const SizedBox(height: 6),
                _progress(),
                const SizedBox(height: 4),
                _controls(),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _list ? _trackList() : const SizedBox(width: 0),
                ),
                const SizedBox(height: 14),
                _sectionTitle('SES DÜZEYİ'),
                const SizedBox(height: 8),
                _mixer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────── Başlık ───────────────

  Widget _header() => Row(
        children: [
          const Text(
            'Ses',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const Spacer(),
          Pressable(
            semanticLabel: 'Kapat',
            onTap: widget.onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppTheme.textSecondary, size: 18),
            ),
          ),
        ],
      );

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppTheme.textMuted,
        ),
      );

  // ─────────────── Çalan parça ───────────────

  Widget _nowPlaying() => StreamBuilder<bool>(
        stream: _audio.playingStream,
        initialData: _audio.isPlaying,
        builder: (context, playing) => StreamBuilder<int?>(
          stream: _audio.currentIndexStream,
          builder: (context, _) {
            final on = playing.data ?? false;
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppTheme.pinkGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: _Equalizer(playing: on)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          on ? 'ŞİMDİ ÇALIYOR' : 'DURAKLATILDI',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: on ? AppTheme.accent : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _audio.currentTrackName.isEmpty
                              ? '—'
                              : _audio.currentTrackName,
                          key: const ValueKey('music-track'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Parça ${_audio.currentIndex + 1} / '
                          '${_audio.trackCount} · karışık',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _progress() => StreamBuilder<Duration?>(
        stream: _audio.durationStream,
        initialData: _audio.duration,
        builder: (context, dur) => StreamBuilder<Duration>(
          stream: _audio.positionStream,
          initialData: _audio.position,
          builder: (context, pos) {
            final total = dur.data ?? Duration.zero;
            final ms = total.inMilliseconds;
            final at = ms <= 0
                ? 0.0
                : (_scrub ?? (pos.data ?? Duration.zero).inMilliseconds / ms)
                    .clamp(0.0, 1.0);
            final shown = Duration(milliseconds: (at * ms).round());
            return Column(
              children: [
                SliderTheme(
                  data: _sliderTheme(thumb: 6),
                  child: SizedBox(
                    height: 26,
                    child: Slider(
                      key: const ValueKey('music-seek'),
                      value: at,
                      onChanged:
                          ms <= 0 ? null : (v) => setState(() => _scrub = v),
                      onChangeEnd: ms <= 0
                          ? null
                          : (v) {
                              _audio.seek(
                                  Duration(milliseconds: (v * ms).round()));
                              setState(() => _scrub = null);
                            },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(_clock(shown), style: _timeStyle),
                      const Spacer(),
                      Text(ms <= 0 ? '--:--' : '-${_clock(total - shown)}',
                          style: _timeStyle),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

  static const _timeStyle = TextStyle(
    fontSize: 11,
    color: AppTheme.textMuted,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static String _clock(Duration d) {
    final s = d.inSeconds.clamp(0, 5999);
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Widget _controls() => Row(
        children: [
          const SizedBox(width: 40),
          const Spacer(),
          _roundButton(
            key: const ValueKey('music-prev'),
            label: 'Önceki parça',
            icon: Icons.skip_previous_rounded,
            onTap: _audio.previous,
          ),
          const SizedBox(width: 14),
          StreamBuilder<bool>(
            stream: _audio.playingStream,
            initialData: _audio.isPlaying,
            builder: (context, snap) {
              final playing = snap.data ?? false;
              return StreamBuilder<bool>(
                stream: _audio.loadingStream,
                builder: (context, loading) => _roundButton(
                  key: const ValueKey('music-play'),
                  label: playing ? 'Duraklat' : 'Çal',
                  icon:
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  primary: true,
                  loading: loading.data ?? false,
                  onTap: _audio.playPause,
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          _roundButton(
            key: const ValueKey('music-next'),
            label: 'Sonraki parça',
            icon: Icons.skip_next_rounded,
            onTap: _audio.next,
          ),
          const Spacer(),
          Pressable(
            key: const ValueKey('music-list'),
            semanticLabel: _list ? 'Parça listesini gizle' : 'Parça listesi',
            onTap: () => setState(() => _list = !_list),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _list
                    ? AppTheme.accent.withValues(alpha: .16)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.queue_music_rounded,
                  size: 21,
                  color: _list ? AppTheme.accent : AppTheme.textSecondary),
            ),
          ),
        ],
      );

  Widget _roundButton({
    required Key key,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
    bool loading = false,
  }) {
    final size = primary ? 56.0 : 44.0;
    return Pressable(
      key: key,
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: primary ? AppTheme.pinkGradient : null,
          color: primary ? null : AppTheme.surfaceHigh,
          shape: BoxShape.circle,
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: .35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Parça yüklenirken tuş halkası döner: basış alındı, ses geliyor.
            if (loading)
              SizedBox(
                key: const ValueKey('music-loading'),
                width: size - 6,
                height: size - 6,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            Icon(icon,
                color: primary ? Colors.white : AppTheme.textPrimary,
                size: primary ? 30 : 24),
          ],
        ),
      ),
    );
  }

  // ─────────────── Parça listesi ───────────────

  Widget _trackList() => StreamBuilder<int?>(
        stream: _audio.currentIndexStream,
        builder: (context, _) {
          final current = _audio.currentIndex;
          return Container(
            key: const ValueKey('music-tracks'),
            margin: const EdgeInsets.only(top: 10),
            constraints: const BoxConstraints(maxHeight: 232),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              primary: false,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _audio.trackCount,
              itemBuilder: (context, i) {
                final on = i == current;
                return InkWell(
                  key: ValueKey('music-track-$i'),
                  onTap: () => _audio.playTrack(i),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: on
                              ? const Icon(Icons.graphic_eq_rounded,
                                  color: AppTheme.accent, size: 17)
                              : Text(
                                  '${i + 1}',
                                  textAlign: TextAlign.center,
                                  style: _timeStyle.copyWith(fontSize: 12),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _audio.trackName(i),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight:
                                  on ? FontWeight.w800 : FontWeight.w500,
                              color:
                                  on ? AppTheme.accent : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );

  // ─────────────── Ses düzeyleri ───────────────

  Widget _mixer() => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            StreamBuilder<double>(
              stream: _audio.volumeStream,
              initialData: _audio.volume,
              builder: (context, snap) {
                final v = (snap.data ?? _audio.volume).clamp(0.0, 1.0);
                return _level(
                  key: const ValueKey('music-volume'),
                  icon: Icons.music_note_rounded,
                  label: 'Müzik',
                  value: v,
                  onChanged: _audio.setVolume,
                  onMute: () {
                    if (v > 0.005) {
                      _musicBefore = v;
                      _audio.setVolume(0);
                    } else {
                      _audio.setVolume(_musicBefore);
                    }
                  },
                );
              },
            ),
            const Divider(color: AppTheme.border, height: 10),
            ValueListenableBuilder<double>(
              valueListenable: _sfx.volumeListenable,
              builder: (context, v, _) => _level(
                key: const ValueKey('sfx-volume'),
                icon: Icons.sports_esports_rounded,
                label: 'Oyun efektleri',
                value: v.clamp(0.0, 1.0),
                onChanged: _sfx.setVolume,
                onMute: () {
                  if (v > 0.005) {
                    _sfxBefore = v;
                    _sfx.setVolume(0);
                  } else {
                    _sfx.setVolume(_sfxBefore);
                  }
                },
              ),
            ),
          ],
        ),
      );

  Widget _level({
    required Key key,
    required IconData icon,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required VoidCallback onMute,
  }) {
    final muted = value <= 0.005;
    return Column(
      key: key,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Text(
              muted ? 'Kapalı' : '%${(value * 100).round()}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: muted ? AppTheme.danger : AppTheme.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Pressable(
              semanticLabel: muted ? '$label sesini aç' : '$label sesini kapat',
              onTap: onMute,
              child: SizedBox(
                width: 30,
                height: 36,
                child: Icon(
                  muted
                      ? Icons.volume_off_rounded
                      : value < .5
                          ? Icons.volume_down_rounded
                          : Icons.volume_up_rounded,
                  size: 19,
                  color: muted ? AppTheme.danger : AppTheme.textMuted,
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: _sliderTheme(thumb: 8),
                child: SizedBox(
                  height: 36,
                  child: Slider(value: value, onChanged: onChanged),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static SliderThemeData _sliderTheme({required double thumb}) =>
      SliderThemeData(
        trackHeight: 4,
        activeTrackColor: AppTheme.accent,
        inactiveTrackColor: AppTheme.border,
        disabledActiveTrackColor: AppTheme.border,
        disabledInactiveTrackColor: AppTheme.border,
        thumbColor: Colors.white,
        disabledThumbColor: AppTheme.textMuted,
        overlayColor: AppTheme.accent.withValues(alpha: .18),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: thumb),
        trackShape: const RoundedRectSliderTrackShape(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      );
}

/// Çalarken oynayan, durunca dinlenen beş çubuklu ekolayzır.
class _Equalizer extends StatefulWidget {
  const _Equalizer({required this.playing});
  final bool playing;

  @override
  State<_Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<_Equalizer>
    with SingleTickerProviderStateMixin {
  late final _ticker = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (widget.playing) _ticker.repeat();
  }

  @override
  void didUpdateWidget(_Equalizer old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_ticker.isAnimating) {
      _ticker.repeat();
    } else if (!widget.playing && _ticker.isAnimating) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ticker,
        builder: (context, _) {
          final t = _ticker.value * 2 * math.pi;
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 5; i++)
                Container(
                  width: 4,
                  height: widget.playing
                      ? 8 +
                          16 * (0.5 + 0.5 * math.sin(t * (1 + i % 3) + i * 1.7))
                      : 6.0 + (i % 2) * 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          );
        },
      );
}
