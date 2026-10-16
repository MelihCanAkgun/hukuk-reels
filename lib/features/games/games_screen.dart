import 'dart:async';

import 'package:flutter/material.dart';
import '../countdown/countdown_screen.dart';
import '../countdown/countdown_text.dart';
import '../home/cork_board.dart';
import '../home/home_store.dart';
import '../../core/services/battle_bridge.dart';
import '../game/block_battle_lobby.dart';

import '../../app/theme.dart';
import '../../core/widgets/pixel_logo.dart';
import '../../core/services/progress_service.dart';
import '../game/block_blast_screen.dart';
import '../reels/screens/reels_screen.dart';
import '../profile/profile_settings_screen.dart';
import '../profile/profile_avatar.dart';
import '../game/flappy_cat_screen.dart';
import '../game/subway_cat_screen.dart';
import '../reels/widgets/music_button.dart';
import '../surprise/flower_surprise_flow.dart';

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
  // Kavuşma sayacı (yalnız oyuncu koduyla bağlıyken görünür).
  final _tripsStore = HomeStore.instance;
  Timer? _tick;

  void _tripsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tick?.cancel();
    _tripsStore
      ..changes.removeListener(_tripsChanged)
      ..stop();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tripsStore
      ..changes.addListener(_tripsChanged)
      ..start()
      ..refresh(force: true);
    // Yalnız kart yazısı (gün/saat); sunucuya istek atmaz.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted &&
          (_tripsStore.trips.isNotEmpty || _tripsStore.notes.isNotEmpty)) {
        setState(() {});
      }
    });
    // A refresh returns directly to the saved room, within its reconnect window.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final saved = await battleCall('inspect');
      if (!mounted) return;
      if (saved['room'] != null) {
        Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const BlockBattleLobby()));
        return;
      }
      // Güncellemeyle gelen çiçek sürprizi: ilk açılışta bir kez.
      if (!_progress.flowerSurpriseSeen) {
        await showFlowerSurpriseGate(context);
        if (mounted) setState(() {});
      }
    });
  }

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
                    // Rotanın kendisi geri alınabiliyorsa (üstteki rotalar değil).
                    if (ModalRoute.of(context)?.canPop ?? false)
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary),
                      ),
                    const PixelLogo(kLogoGames, size: 24),
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
                    // Sürpriz görülmeden 🌷 görünmesin (spoiler olmasın).
                    if (_progress.flowerSurpriseSeen) ...[
                      _flowerButton(),
                      const SizedBox(width: 6),
                    ],
                    const MusicButton(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    if (_tripsStore.connected) ...[
                      _countdownCard(),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Canın mı sıkıldı? Birini seç 👇',
                      style: TextStyle(
                          fontSize: 13.5, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    _gameTile(
                      logo: kLogoBlockBlast,
                      title: 'Block Blast',
                      subtitle: 'Rekor: ${_progress.blockHigh}',
                      screen: const BlockBlastScreen(),
                    ),
                    const SizedBox(height: 10),
                    _gameTile(
                      logo: kLogoFlappyCat,
                      title: 'Flappy Silly Cat',
                      subtitle: 'Rekor: ${_progress.flappyHigh}',
                      screen: const FlappyCatScreen(),
                    ),
                    const SizedBox(height: 10),
                    _gameTile(
                      logo: kLogoSubwaySilly,
                      title: 'Subway Silly',
                      subtitle: 'Rekor: ${_progress.subwayHigh}',
                      screen: const SubwayCatScreen(),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    ListTile(
                      leading: const PixelLogo(kLogoQuestionBank, size: 30),
                      title: const Text('Soru bankası'),
                      subtitle: Text(ReelsScreen.maintenance
                          ? 'Bakımda · çok yakında 🛠️'
                          : 'Hukuk testlerine devam et'),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ReelsScreen())),
                    ),
                    ListTile(
                      leading: const ProfileAvatar(size: 36),
                      title: const Text('Profil ve ayarlar'),
                      subtitle: _progress.nick == null
                          ? null
                          : Text(_progress.nick!,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const ProfileSettingsScreen()));
                        if (mounted) setState(() {});
                      },
                    ),
                    // Mantar pano: yalnız oyuncu koduyla bağlıyken.
                    if (_tripsStore.connected) ...[
                      const SizedBox(height: 18),
                      const CorkBoard(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countdownCard() {
    final now = DateTime.now();
    final trips = _tripsStore.trips;
    final next = trips.isEmpty ? null : trips.first;
    final left =
        next == null ? null : remainingText(next.arrival.difference(now));
    return GestureDetector(
      onTap: () async {
        // Liste ortak depoda; dönüşte ayrıca istek gerekmez.
        await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CountdownScreen()));
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A2340), Color(0xFF2A1521)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            const PixelLogo(kLogoPlane, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: next == null
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kavuşma Sayacı',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary)),
                        SizedBox(height: 2),
                        Text('Bileti alınca uçuşunu ekle ✈️',
                            style: TextStyle(
                                fontSize: 12.5, color: AppTheme.textSecondary)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            left == null
                                ? '${next.name} ${dative(next.destination)} vardı!'
                                : next.sentence,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5, color: AppTheme.textSecondary)),
                        const SizedBox(height: 2),
                        Text(left == null ? 'Kavuştunuz 💞' : '$left kaldı 💕',
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.accent)),
                      ],
                    ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  /// Sürprizden sonra kalan çiçek. Dokununca çiçek yeniden açılır; uzun
  /// basınca sürpriz bir sonraki açılış için sıfırlanır (test amaçlı).
  Widget _flowerButton() {
    return Semantics(
      button: true,
      label: 'Çiçeğin',
      child: GestureDetector(
        onTap: () => openFlower(context),
        onLongPress: () async {
          await _progress.setFlowerSurpriseSeen(false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Sürpriz sıfırlandı: uygulama yeniden açılınca gösterilecek.'),
          ));
        },
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accent.withValues(alpha: 0.12),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.45)),
          ),
          child: const PixelLogo(kLogoTulip, size: 24),
        ),
      ),
    );
  }

  Widget _gameTile({
    required List<String> logo,
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
              ),
              child: PixelLogo(logo, size: 28),
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
