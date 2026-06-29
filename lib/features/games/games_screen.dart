import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/progress_service.dart';
import '../game/block_blast_screen.dart';
import '../game/flappy_cat_screen.dart';
import '../game/subway_cat_screen.dart';
import '../reels/widgets/music_button.dart';

/// Mini oyunların listelendiği ayrı "Oyunlar" sekmesi. (Eskiden profilin
/// içindeydi.) Oyun içinde de müziğe erişilebilsin diye üstte müzik düğmesi
/// var; oyundan dönünce rekorlar tazelenir. Kullanıcı verileri SİLİNMEZ.
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final _progress = ProgressService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Üst bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                    ),
                    const Text('🎮', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    const Text(
                      'Oyunlar',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    const MusicButton(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    const Text(
                      'Canın mı sıkıldı? Birini seç 👇',
                      style: TextStyle(
                          fontSize: 13.5, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    _gameTile(
                      imageAsset: 'assets/images/SHINY_Cuh.png',
                      title: 'Flappy Silly Cat',
                      subtitle: 'Rekor: ${_progress.flappyHigh}',
                      screen: const FlappyCatScreen(),
                    ),
                    const SizedBox(height: 10),
                    _gameTile(
                      emoji: '🧩',
                      title: 'Block Blast',
                      subtitle: 'Rekor: ${_progress.blockHigh}',
                      screen: const BlockBlastScreen(),
                    ),
                    const SizedBox(height: 10),
                    _gameTile(
                      imageAsset: 'assets/images/SHINY_Cuh.png',
                      title: 'Subway Silly',
                      subtitle: 'Rekor: ${_progress.subwayHigh}',
                      screen: const SubwayCatScreen(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameTile({
    String? imageAsset,
    String? emoji,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => screen));
        if (mounted) setState(() {}); // dönüşte rekor güncellensin
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A1E30), Color(0xFF2A1521)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceHigh,
                border: Border.all(color: AppTheme.accent, width: 2),
                image: imageAsset != null
                    ? DecorationImage(
                        image: AssetImage(imageAsset), fit: BoxFit.cover)
                    : null,
              ),
              child: emoji != null
                  ? Text(emoji, style: const TextStyle(fontSize: 22))
                  : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill_rounded,
                color: AppTheme.accent, size: 30),
          ],
        ),
      ),
    );
  }
}
