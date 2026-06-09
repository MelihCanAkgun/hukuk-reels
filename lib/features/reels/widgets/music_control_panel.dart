import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/audio_service.dart';

/// Küçük müzik denetim masası: çal/durdur, sonraki/önceki parça ve ses
/// seviyesi. Müzik soru değiştikçe değişmez; sadece buradan yönetilir.
class MusicControlPanel extends StatelessWidget {
  final VoidCallback onClose;
  const MusicControlPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final audio = AudioService.instance;

    return Container(
      width: 250,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq_rounded,
                  color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Müzik',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded,
                    color: AppTheme.textMuted, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Parça adı (canlı)
          StreamBuilder<int?>(
            stream: audio.currentIndexStream,
            builder: (context, _) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note_rounded,
                      color: AppTheme.accent, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audio.currentTrackName.isEmpty
                          ? '—'
                          : audio.currentTrackName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Kontrol butonları
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ctrlButton(
                icon: Icons.skip_previous_rounded,
                onTap: audio.previous,
              ),
              StreamBuilder<bool>(
                stream: audio.playingStream,
                initialData: audio.isPlaying,
                builder: (context, snap) {
                  final playing = snap.data ?? false;
                  return _ctrlButton(
                    icon: playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    primary: true,
                    onTap: audio.playPause,
                  );
                },
              ),
              _ctrlButton(
                icon: Icons.skip_next_rounded,
                onTap: audio.next,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Ses seviyesi
          StreamBuilder<double>(
            stream: audio.volumeStream,
            initialData: audio.volume,
            builder: (context, snap) {
              final vol = (snap.data ?? audio.volume).clamp(0.0, 1.0);
              return Row(
                children: [
                  Icon(
                    vol == 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: AppTheme.textMuted,
                    size: 17,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        activeTrackColor: AppTheme.accent,
                        inactiveTrackColor: AppTheme.border,
                        thumbColor: AppTheme.accent,
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                      ),
                      child: Slider(
                        value: vol,
                        onChanged: (v) => audio.setVolume(v),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _ctrlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: primary ? 50 : 42,
        height: primary ? 50 : 42,
        decoration: BoxDecoration(
          gradient: primary ? AppTheme.pinkGradient : null,
          color: primary ? null : AppTheme.surfaceHigh,
          shape: BoxShape.circle,
          border: primary ? null : Border.all(color: AppTheme.border),
        ),
        child: Icon(
          icon,
          color: primary ? Colors.white : AppTheme.textPrimary,
          size: primary ? 28 : 22,
        ),
      ),
    );
  }
}
