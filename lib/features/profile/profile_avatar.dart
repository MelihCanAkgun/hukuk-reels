import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/services/progress_service.dart';

/// Profil fotoğrafı; yoksa takma adın baş harfi (o da yoksa 👤).
/// [ProgressService.profileChanges] dinlenir, değişince kendini yeniler.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.size, this.ring = true});

  final double size;

  /// Dışta pembe degrade halka.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return ValueListenableBuilder<int>(
      valueListenable: progress.profileChanges,
      builder: (context, _, __) {
        final bytes = progress.avatar;
        final nick = progress.nick;
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final Widget inner = bytes != null
            ? Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: (size * dpr).round(),
                errorBuilder: (_, __, ___) => _fallback(nick),
              )
            : _fallback(nick);
        return Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(ring ? (size * 0.045).clamp(1.5, 4.0) : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: ring ? AppTheme.pinkGradient : null,
          ),
          child: Container(
            padding: EdgeInsets.all(ring ? (size * 0.03).clamp(1.0, 3.0) : 0),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppTheme.bg),
            child: ClipOval(child: SizedBox.expand(child: inner)),
          ),
        );
      },
    );
  }

  Widget _fallback(String? nick) {
    final initial = (nick == null || nick.isEmpty)
        ? null
        : nick.characters.first.toUpperCase();
    return Container(
      color: AppTheme.surfaceHigh,
      alignment: Alignment.center,
      child: Text(
        initial ?? '👤',
        style: TextStyle(
          fontSize: size * (initial == null ? 0.42 : 0.44),
          fontWeight: FontWeight.w800,
          color: AppTheme.accent,
          height: 1,
        ),
      ),
    );
  }
}
