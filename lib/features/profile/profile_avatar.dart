import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/services/avatar_sync.dart';
import '../../core/services/progress_service.dart';

/// Kendi profil fotoğrafımız; yoksa takma adın baş harfi (o da yoksa 👤).
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
      builder: (context, _, __) => AvatarCircle(
        bytes: progress.avatar,
        name: progress.nick,
        size: size,
        ring: ring,
      ),
    );
  }
}

/// Diğer oyuncunun fotoğrafı (yalnızca oyuncu koduyla indirilir).
class PeerAvatar extends StatelessWidget {
  const PeerAvatar({
    super.key,
    required this.id,
    required this.name,
    required this.size,
    this.ring = true,
  });

  final int id;
  final String? name;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final sync = AvatarSync.instance;
    return ValueListenableBuilder<int>(
      valueListenable: sync.changes,
      builder: (context, _, __) => AvatarCircle(
        bytes: sync.photoOf(id),
        name: name,
        size: size,
        ring: ring,
      ),
    );
  }
}

/// Yuvarlak fotoğraf; fotoğraf yoksa ismin baş harfi.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.bytes,
    required this.name,
    required this.size,
    this.ring = true,
  });

  final Uint8List? bytes;
  final String? name;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final data = bytes;
    final Widget inner = data != null
        ? Image.memory(
            data,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            cacheWidth: (size * dpr).round(),
            errorBuilder: (_, __, ___) => _fallback(),
          )
        : _fallback();
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
        decoration:
            const BoxDecoration(shape: BoxShape.circle, color: AppTheme.bg),
        child: ClipOval(child: SizedBox.expand(child: inner)),
      ),
    );
  }

  Widget _fallback() {
    final n = name?.trim();
    final initial =
        (n == null || n.isEmpty) ? null : n.characters.first.toUpperCase();
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
