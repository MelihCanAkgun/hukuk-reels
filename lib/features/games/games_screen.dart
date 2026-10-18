import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/progress_service.dart';
import '../../core/widgets/pixel_logo.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/readable_width.dart';
import '../game/block_battle_lobby.dart';
import '../game/block_blast_screen.dart';
import '../game/flappy_cat_screen.dart';
import '../game/game_leaderboard.dart';
import '../game/subway_cat_screen.dart';
import '../game/tower_screen.dart';
import '../reels/widgets/music_button.dart';

/// "Oyunlar" sekmesi: dört mini oyun ızgarası ve arkadaşla oynama
/// (1v1 Battle, sıralama). Oyundan dönünce rekorlar tazelenir.
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final _progress = ProgressService.instance;

  Future<void> _push(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {}); // dönüşte rekor güncellensin
  }

  @override
  Widget build(BuildContext context) {
    final gutter = readableGutter(context);
    final games = [
      _gameCard(
        logo: kLogoBlockBlast,
        title: 'Block Blast',
        record: '${_progress.blockHigh}',
        colors: const [Color(0xFF2E4C80), Color(0xFF1C2D52)],
        screen: const BlockBlastScreen(),
      ),
      _gameCard(
        logo: kLogoFlappyCat,
        title: 'Flappy Silly Cat',
        record: '${_progress.flappyHigh}',
        colors: const [Color(0xFF2F6A73), Color(0xFF1B3A44)],
        screen: const FlappyCatScreen(),
      ),
      _gameCard(
        logo: kLogoSubwaySilly,
        title: 'Subway Silly',
        record: '${_progress.subwayHigh}',
        colors: const [Color(0xFF5B2C6F), Color(0xFF32183F)],
        screen: const SubwayCatScreen(),
      ),
      _gameCard(
        logo: kLogoAdliyeKulesi,
        title: 'Adliye Kulesi',
        record: '${_progress.towerHigh} kat',
        colors: const [Color(0xFF7A4A2A), Color(0xFF452817)],
        screen: const TowerScreen(),
      ),
    ];
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                child: Row(
                  children: [
                    // Ayrı bir sayfa olarak açıldıysa geri tuşu.
                    if (ModalRoute.of(context)?.canPop ?? false)
                      IconButton(
                        tooltip: 'Geri',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary),
                      )
                    else
                      const SizedBox(width: 8),
                    const PixelLogo(kLogoGames, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Oyunlar',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sıralama',
                      onPressed: () => _push(const GameLeaderboard()),
                      icon: const PixelLogo(kLogoLeaderboard, size: 24),
                    ),
                    const MusicButton(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  primary: true,
                  padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 24),
                  children: [
                    const Text(
                      'Canın mı sıkıldı? Birini seç 👇',
                      style: TextStyle(
                          fontSize: 13.5, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(builder: (context, c) {
                      final cols = c.maxWidth >= 640 ? 4 : 2;
                      final w = (c.maxWidth - 12 * (cols - 1)) / cols;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final g in games) SizedBox(width: w, child: g)
                        ],
                      );
                    }),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 26, 4, 10),
                      child: Text(
                        'ARKADAŞINLA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    _rowCard(
                      logo: kLogoBattle,
                      title: '1v1 Battle',
                      subtitle: 'Block Blast\'ta aynı anda yarış',
                      onTap: () => _push(const BlockBattleLobby()),
                    ),
                    const SizedBox(height: 10),
                    _rowCard(
                      logo: kLogoLeaderboard,
                      title: 'Sıralama',
                      subtitle: 'Her oyunda ikinizin rekoru',
                      onTap: () => _push(const GameLeaderboard()),
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

  Widget _gameCard({
    required List<String> logo,
    required String title,
    required String record,
    required List<Color> colors,
    required Widget screen,
  }) {
    return Pressable(
      key: ValueKey('game-$title'),
      semanticLabel: '$title oyna',
      onTap: () => _push(screen),
      child: Container(
        height: 156,
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelLogo(logo, size: 50),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: 14, color: Color(0xFFFFD36A)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    record,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: .8),
                    ),
                  ),
                ),
                const Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowCard({
    required List<String> logo,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      Pressable(
        semanticLabel: title,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              PixelLogo(logo, size: 34),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted),
            ],
          ),
        ),
      );
}
