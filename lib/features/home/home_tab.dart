import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/activity_area.dart';
import '../../core/services/notes_bridge.dart';
import '../../core/services/progress_service.dart';
import '../../core/widgets/pixel_logo.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/readable_width.dart';
import '../countdown/countdown_screen.dart';
import '../countdown/countdown_text.dart';
import '../game/block_blast_engine.dart';
import '../game/block_blast_screen.dart';
import '../game/game_leaderboard.dart';
import '../reels/widgets/music_button.dart';
import '../summaries/summaries_screen.dart';
import '../surprise/flower_surprise_flow.dart';
import 'cork_board.dart';
import 'home_store.dart';

/// Ana sayfa sekmesi: selamlama, kavuşma sayacı, mantar pano ve "kaldığın
/// yerden" kısayolları. Oyunlar ve çalışma kendi sekmelerindedir.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, this.onOpenTab, this.clock = DateTime.now});

  /// Kısayol kartlarının sekme değiştirmesi için (bkz. ShellTab).
  final void Function(int tab)? onOpenTab;
  final DateTime Function() clock;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

/// Saate göre selam.
String greeting(DateTime t) {
  final h = t.hour;
  if (h >= 5 && h < 12) return 'Günaydın';
  if (h >= 12 && h < 18) return 'İyi günler';
  if (h >= 18 && h < 23) return 'İyi akşamlar';
  return 'İyi geceler';
}

class _HomeTabState extends State<HomeTab> {
  final _progress = ProgressService.instance;
  final _store = HomeStore.instance;
  final Map<String, SummaryNotes> _notes = {};
  Timer? _tick;

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _store.changes.addListener(_changed);
    _loadNotes();
    // Yalnız kart yazısı (gün/saat); sunucuya istek atmaz.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && (_store.trips.isNotEmpty || _store.notes.isNotEmpty)) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(HomeTab old) {
    super.didUpdateWidget(old);
    // Sekmeye dönüldü: özet notları başka sekmede değişmiş olabilir.
    _loadNotes();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _store.changes.removeListener(_changed);
    super.dispose();
  }

  Future<void> _loadNotes() async {
    for (final s in kSummaries) {
      final info = await summaryNotes(s.id);
      if (!mounted) return;
      final old = _notes[s.id];
      if (old?.count != info.count || old?.edited != info.edited) {
        setState(() => _notes[s.id] = info);
      }
    }
  }

  /// Bitmemiş Block Blast oyunu (hamle kaldıysa ve puan alındıysa).
  BlockBlastEngine? get _savedBlock {
    final g = BlockBlastEngine.restore(_progress.loadBlockGame());
    return g != null && g.score > 0 && g.hasMove ? g : null;
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  Future<void> _openSummary(SummaryInfo s) async {
    final area = Object();
    ActivityArea.instance.enter(area, 'summaries');
    final result = await openSummary(s.id);
    ActivityArea.instance.leave(area);
    if (!mounted) return;
    if (result.startsWith('error:')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.substring(6))));
    }
    await _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final gutter = readableGutter(context);
    final continues = _continueCards();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.accent,
                  onRefresh: () async {
                    await _store.refresh(force: true);
                    await _loadNotes();
                  },
                  child: ListView(
                    primary: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 24),
                    children: [
                      _greeting(),
                      const SizedBox(height: 16),
                      if (_store.connected) ...[
                        _countdownCard(),
                        const SizedBox(height: 14),
                        const CorkBoard(),
                      ] else
                        _connectCard(),
                      _title('KALDIĞIN YERDEN'),
                      if (continues.isEmpty)
                        _startCards()
                      else
                        for (var i = 0; i < continues.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          continues[i],
                        ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 6),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Hukuk Reels',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'PixelifySans',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: .3,
                ),
              ),
            ),
            // Sürpriz görülmeden 🌷 görünmesin (spoiler olmasın).
            if (_progress.flowerSurpriseSeen) ...[
              _flowerButton(),
              const SizedBox(width: 6),
            ],
            const MusicButton(),
          ],
        ),
      );

  Widget _greeting() {
    final nick = _progress.nick;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
      child: Text(
        nick == null
            ? '${greeting(widget.clock())} 👋'
            : '${greeting(widget.clock())}, $nick',
        key: const ValueKey('home-greeting'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppTheme.textSecondary,
          ),
        ),
      );

  List<Widget> _continueCards() {
    final block = _savedBlock;
    return [
      if (block != null)
        _wideCard(
          key: const ValueKey('continue-block'),
          logo: kLogoBlockBlast,
          title: 'Block Blast',
          subtitle: 'Devam eden oyun · ${block.score} puan',
          action: Icons.play_circle_fill_rounded,
          onTap: () => _push(const BlockBlastScreen()),
        ),
      for (final s in kSummaries)
        if ((_notes[s.id]?.count ?? 0) > 0)
          _wideCard(
            key: ValueKey('continue-summary-${s.id}'),
            logo: kLogoLawBook,
            title: s.title,
            subtitle: _notesLine(_notes[s.id]!),
            action: Icons.edit_note_rounded,
            onTap: () => _openSummary(s),
          ),
    ];
  }

  String _notesLine(SummaryNotes n) => n.edited == null
      ? '${n.count} not'
      : '${n.count} not · son düzenleme '
          '${editedLabel(n.edited!, widget.clock())}';

  /// Henüz devam edecek bir şey yoksa iki başlangıç kartı.
  Widget _startCards() => Row(
        children: [
          Expanded(
            child: _smallCard(
              key: const ValueKey('start-games'),
              logo: kLogoGames,
              title: 'Bir oyun seç',
              subtitle: '4 oyun · rekorunu geç',
              onTap: () => widget.onOpenTab?.call(1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _smallCard(
              key: const ValueKey('start-study'),
              logo: kLogoLawBook,
              title: 'Çalışmaya başla',
              subtitle: 'Özetler ve sorular',
              onTap: () => widget.onOpenTab?.call(2),
            ),
          ),
        ],
      );

  Widget _wideCard({
    required Key key,
    required List<String> logo,
    required String title,
    required String subtitle,
    required IconData action,
    required VoidCallback onTap,
  }) =>
      Pressable(
        key: key,
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
              PixelLogo(logo, size: 38),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              Icon(action, color: AppTheme.accent, size: 28),
            ],
          ),
        ),
      );

  Widget _smallCard({
    required Key key,
    required List<String> logo,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      Pressable(
        key: key,
        semanticLabel: title,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PixelLogo(logo, size: 32),
              const SizedBox(height: 10),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );

  /// Oyuncu kodu yoksa: sayaç, pano ve sıralama için katılma çağrısı.
  Widget _connectCard() => _wideCard(
        key: const ValueKey('home-connect'),
        logo: kLogoPlane,
        title: 'Arkadaşınla bağlan',
        subtitle: 'Kavuşma sayacı, mantar pano ve sıralama için katıl',
        action: Icons.chevron_right_rounded,
        onTap: () => _push(const GameLeaderboard()),
      );

  Widget _countdownCard() {
    final now = DateTime.now();
    final trips = _store.trips;
    final next = trips.isEmpty ? null : trips.first;
    final left =
        next == null ? null : remainingText(next.arrival.difference(now));
    return Pressable(
      // Liste ortak depoda; dönüşte ayrıca istek gerekmez.
      onTap: () => _push(const CountdownScreen()),
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
      child: Pressable(
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
}
