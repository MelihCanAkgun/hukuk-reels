import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/avatar_sync.dart';
import '../../core/services/social_bridge.dart';
import '../../core/widgets/arcade_title.dart';
import '../../core/widgets/pixel_logo.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/readable_width.dart';
import '../films/film_reviews.dart' show ArcadeButton, arcadePanel;
import '../game/block_blast_screen.dart';
import '../game/flappy_cat_screen.dart';
import '../game/game_leaderboard.dart';
import '../game/subway_cat_screen.dart';
import '../game/tower_screen.dart';
import '../profile/profile_avatar.dart';
import 'weekly_store.dart';
import 'weekly_trophies.dart';

const _gold = Color(0xFFFFD36A);

String _scoreText(LeaderboardGame game, int score) =>
    score == 0 ? '–' : '$score${game.unit}';

Widget _avatar(WeeklyData d, int id, double size) => id == d.me
    ? ProfileAvatar(size: size, ring: false)
    : PeerAvatar(id: id, name: d.nameOf(id), size: size, ring: false);

/// Haftalık meydan okuma ekranı: turun kupası ve durumu, oyun oyun skorlar,
/// iki oyuncunun kupa rafı ve geçmiş turlar. Tur yokken yönetici yenisini
/// başlatır. Biten turun izlenmemiş sonucu açılışta gösterilir (eşitlikte
/// yazı turayla).
class WeeklyScreen extends StatelessWidget {
  const WeeklyScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Theme(data: AppTheme.arcade, child: const _WeeklyView());
}

class _WeeklyView extends StatefulWidget {
  const _WeeklyView();

  @override
  State<_WeeklyView> createState() => _WeeklyViewState();
}

class _WeeklyViewState extends State<_WeeklyView> {
  final _store = WeeklyStore.instance;
  Timer? _tick;
  bool _revealing = false, _starting = false;

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _maybeReveal();
  }

  @override
  void initState() {
    super.initState();
    _store.changes.addListener(_changed);
    _store.refresh(force: true);
    socialCall('state').then(AvatarSync.instance.sync);
    // Kalan süre dakikada bir yenilenir.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReveal());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _store.changes.removeListener(_changed);
    super.dispose();
  }

  Future<void> _maybeReveal() async {
    final result = _store.data?.reveal;
    if (result == null || _revealing || !mounted) return;
    _revealing = true;
    await showWeeklyResult(context, _store.data!, result);
    await _store.markSeen(result.id);
    _revealing = false;
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    final error = await _store.start();
    if (!mounted) return;
    setState(() => _starting = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  /// Yönetici süren turu kupasız bitirir.
  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.bgElevated,
        title: const Text('Tur iptal edilsin mi?'),
        content:
            const Text('Bu turun skorları silinir ve kupa kimseye verilmez.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Vazgeç')),
          TextButton(
              key: const ValueKey('weekly-cancel-confirm'),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('İptal et')),
        ],
      ),
    );
    if (ok != true) return;
    final error = await _store.cancel();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _play(LeaderboardGame game) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => switch (game) {
              LeaderboardGame.block => const BlockBlastScreen(),
              LeaderboardGame.flappy => const FlappyCatScreen(),
              LeaderboardGame.subway => const SubwayCatScreen(),
              LeaderboardGame.tower => const TowerScreen(),
            }));
    if (mounted) unawaited(_store.refresh(force: true));
  }

  @override
  Widget build(BuildContext context) {
    final d = _store.data;
    final gutter = readableGutter(context);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ArcadeTitleBar(
                title: 'Meydan Okuma',
                logo: kLogoTrophy,
                actions: [
                  if (d != null && d.me == 1 && d.round != null)
                    IconButton(
                      key: const ValueKey('weekly-cancel'),
                      tooltip: 'Turu iptal et',
                      onPressed: _cancel,
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.textSecondary),
                    ),
                ],
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.accent,
                  onRefresh: () => _store.refresh(force: true),
                  child: ListView(
                    primary: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(gutter, 6, gutter,
                        28 + MediaQuery.paddingOf(context).bottom),
                    children: d == null ? [_empty()] : _content(d),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
        child: !_store.loaded
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent))
            : Column(
                children: [
                  const PixelLogo(kLogoTrophy, size: 56),
                  const SizedBox(height: 14),
                  Text(
                    _store.error ??
                        'Haftalık meydan okuma ikiniz arasında. Açmak için '
                            'Profil\'den oyuncu kodunla bağlan.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14.5,
                        height: 1.4),
                  ),
                ],
              ),
      );

  List<Widget> _content(WeeklyData d) => [
        if (_store.error != null)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Çevrimdışı: son kaydedilen durum gösteriliyor.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ),
        if (d.round == null)
          _idle(d)
        else ...[
          _header(d, d.round!),
          const ArcadeSectionLabel('BU TURUN OYUNLARI'),
          for (final game in LeaderboardGame.values) ...[
            _gameRow(d, game),
            const SizedBox(height: 8),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: Text(
              'Her oyunda bu turdaki en iyi skorun sayılır. Oyunu yüksek '
              'skor, turu daha çok oyun alan kazanır. Eşitlikte yazı tura '
              'atılır.',
              style: TextStyle(
                  color: AppTheme.textMuted, fontSize: 12, height: 1.35),
            ),
          ),
        ],
        const ArcadeSectionLabel('KUPA RAFI'),
        _shelf(d, d.me),
        const SizedBox(height: 10),
        _shelf(d, d.other),
        if (d.history.isNotEmpty) ...[
          const ArcadeSectionLabel('GEÇMİŞ TURLAR'),
          for (final h in d.history) ...[
            _historyRow(d, h),
            const SizedBox(height: 8),
          ],
        ],
      ];

  /// Süren tur yok: sıradaki kupa; yöneticide "Turu başlat".
  Widget _idle(WeeklyData d) {
    final trophy = weeklyTrophy(d.nextTrophy);
    return Container(
      key: const ValueKey('weekly-idle'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: arcadePanel(border: trophy.color, shadow: trophy.dark),
      child: Column(
        children: [
          TrophyBadge(trophy: trophy, size: 84),
          const SizedBox(height: 12),
          Text('SIRADAKİ ÖDÜL',
              style: AppTheme.sectionLabel
                  .copyWith(fontSize: 12, color: trophy.color)),
          const SizedBox(height: 2),
          Text(trophy.name, style: AppTheme.sheetTitle.copyWith(fontSize: 23)),
          const SizedBox(height: 8),
          Text(
            d.canStart
                ? 'Tur 7 gün sürer: dört oyunun her birinde en iyi skoru '
                    'yapan o oyunu alır. Hazır olduğunda başlat.'
                : 'Yeni turu ${d.nameOf(1)} başlatacak. Başlayınca bildirim '
                    'gelir; 7 gün, dört oyun, bir kupa.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
          ),
          if (d.canStart) ...[
            const SizedBox(height: 16),
            ArcadeButton(
              key: const ValueKey('weekly-start'),
              label: 'Turu başlat',
              big: true,
              busy: _starting,
              onTap: _start,
            ),
          ],
        ],
      ),
    );
  }

  /// Bu turun kupası, kalan süre ve durum (2 – 1).
  Widget _header(WeeklyData d, WeeklyRound round) {
    final trophy = weeklyTrophy(round.trophy);
    Widget side(int id) => Expanded(
          child: Column(
            children: [
              _avatar(d, id, 44),
              const SizedBox(height: 6),
              Text(d.nameOf(id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: arcadePanel(border: trophy.color, shadow: trophy.dark),
      child: Column(
        children: [
          Row(
            children: [
              TrophyBadge(trophy: trophy, size: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BU TURUN ÖDÜLÜ',
                        style: AppTheme.sectionLabel
                            .copyWith(fontSize: 12, color: trophy.color)),
                    const SizedBox(height: 2),
                    Text(trophy.name,
                        key: const ValueKey('weekly-trophy'),
                        style: AppTheme.sheetTitle.copyWith(fontSize: 23)),
                    const SizedBox(height: 4),
                    Text(
                        '${roundRangeText(round.start, round.end)} · ${round.remaining(_store.now)} kaldı',
                        key: const ValueKey('weekly-remaining'),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              side(d.me),
              Text('${d.winsOf(d.me)} – ${d.winsOf(d.other)}',
                  key: const ValueKey('weekly-standing'),
                  style: const TextStyle(
                      fontFamily: AppTheme.pixelFont,
                      color: AppTheme.textPrimary,
                      fontSize: 40,
                      height: 1,
                      fontWeight: FontWeight.w700)),
              side(d.other),
            ],
          ),
        ],
      ),
    );
  }

  /// Oyun satırı: iki skor, önde olan altın; dokununca oyun açılır.
  Widget _gameRow(WeeklyData d, LeaderboardGame game) {
    final leader = d.leaderOf(game);
    Widget score(int id, TextAlign align) {
      final lead = leader == id;
      return Expanded(
        child: Text(_scoreText(game, d.scoreOf(game, id)),
            key: ValueKey('weekly-${game.name}-$id'),
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontFamily: AppTheme.pixelFont,
                color: lead ? _gold : AppTheme.textSecondary,
                fontSize: lead ? 20 : 17,
                fontWeight: FontWeight.w700)),
      );
    }

    return Pressable(
      key: ValueKey('weekly-row-${game.name}'),
      semanticLabel: '${game.title} oyna',
      onTap: () => _play(game),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: arcadePanel(
            border: leader == d.me
                ? _gold.withValues(alpha: .55)
                : AppTheme.border),
        child: Column(
          children: [
            Row(
              children: [
                PixelLogo(game.logo, size: 26),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(game.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800)),
                ),
                Text(
                    leader == null
                        ? (d.scoreOf(game, 1) == 0 ? 'Oynanmadı' : 'Berabere')
                        : leader == d.me
                            ? 'Öndesin'
                            : '${d.nameOf(leader)} önde',
                    style: TextStyle(
                        color: leader == d.me ? _gold : AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _avatar(d, d.me, 20),
                const SizedBox(width: 8),
                score(d.me, TextAlign.left),
                const Text('VS',
                    style: TextStyle(
                        fontFamily: AppTheme.pixelFont,
                        color: AppTheme.textMuted,
                        fontSize: 12)),
                score(d.other, TextAlign.right),
                const SizedBox(width: 8),
                _avatar(d, d.other, 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Oyuncunun kupa rafı: yedi kupa, kazanılanlar renkli.
  Widget _shelf(WeeklyData d, int player) {
    final won = d.trophiesOf(player);
    final total = d.totals[player] ?? 0;
    return Container(
      key: ValueKey('weekly-shelf-$player'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: arcadePanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(d, player, 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(d.nameOf(player),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
              Text(total == 0 ? 'Henüz kupa yok' : '$total tur kazandı',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, box) {
            const gap = 8.0;
            final n = kWeeklyTrophies.length;
            final size = math.min(56.0, (box.maxWidth - gap * (n - 1)) / n);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < n; i++)
                  Tooltip(
                    message: kWeeklyTrophies[i].name,
                    child: TrophyBadge(
                      trophy: kWeeklyTrophies[i],
                      size: size,
                      won: (won[i] ?? 0) > 0,
                      count: won[i] ?? 0,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _historyRow(WeeklyData d, WeeklyResult h) => Container(
        key: ValueKey('weekly-history-${h.id}'),
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        decoration: arcadePanel(),
        child: Row(
          children: [
            TrophyBadge(trophy: weeklyTrophy(h.trophy), size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${d.nameOf(h.winner)} kazandı${h.coin ? ' (yazı tura)' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                      '${roundRangeText(h.start, h.end)} · ${weeklyTrophy(h.trophy).name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Text(h.score,
                style: const TextStyle(
                    fontFamily: AppTheme.pixelFont,
                    color: _gold,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

/// Biten turun sonucu. Eşitlikte önce yazı tura atılır.
Future<void> showWeeklyResult(
        BuildContext context, WeeklyData data, WeeklyResult result) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .8),
      builder: (_) => Theme(
          data: AppTheme.arcade,
          child: WeeklyResultDialog(data: data, result: result)),
    );

class WeeklyResultDialog extends StatefulWidget {
  const WeeklyResultDialog(
      {super.key, required this.data, required this.result});

  final WeeklyData data;
  final WeeklyResult result;

  @override
  State<WeeklyResultDialog> createState() => _WeeklyResultDialogState();
}

enum _Stage { tie, flipping, winner }

class _WeeklyResultDialogState extends State<WeeklyResultDialog> {
  late _Stage _stage = widget.result.coin ? _Stage.tie : _Stage.winner;

  @override
  Widget build(BuildContext context) {
    final d = widget.data, r = widget.result;
    final trophy = weeklyTrophy(r.trophy);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: arcadePanel(
              color: AppTheme.bgElevated,
              border: trophy.color,
              shadow: trophy.dark,
              radius: 8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('TURUN SONUCU',
                    style: AppTheme.sectionLabel.copyWith(color: trophy.color)),
                const SizedBox(height: 2),
                Text(roundRangeText(r.start, r.end),
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12.5)),
                const SizedBox(height: 12),
                for (final g in r.detail) _detailRow(d, g.game, g.scores),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: switch (_stage) {
                    _Stage.tie => _tie(r, trophy),
                    _Stage.flipping => CoinFlip(
                        key: const ValueKey('coin-flip'),
                        data: d,
                        winner: r.winner,
                        onDone: () {
                          if (mounted) setState(() => _stage = _Stage.winner);
                        },
                      ),
                    _Stage.winner => _winner(d, r, trophy),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(WeeklyData d, LeaderboardGame game, Map<int, int> scores) {
    final mine = scores[d.me] ?? 0, theirs = scores[d.other] ?? 0;
    Widget score(int value, bool lead, TextAlign align) => SizedBox(
          width: 76,
          child: Text(_scoreText(game, value),
              textAlign: align,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: AppTheme.pixelFont,
                  color: lead ? _gold : AppTheme.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          score(mine, mine > theirs, TextAlign.right),
          const SizedBox(width: 10),
          PixelLogo(game.logo, size: 22),
          const SizedBox(width: 10),
          score(theirs, theirs > mine, TextAlign.left),
        ],
      ),
    );
  }

  Widget _tie(WeeklyResult r, WeeklyTrophy trophy) => Column(
        key: const ValueKey('weekly-tie'),
        children: [
          Text('${r.wins[1]} – ${r.wins[2]}',
              style: const TextStyle(
                  fontFamily: AppTheme.pixelFont,
                  color: AppTheme.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Berabere! ${trophy.name} için yazı tura atılacak.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.35)),
          const SizedBox(height: 16),
          ArcadeButton(
            key: const ValueKey('weekly-flip'),
            label: 'Yazı tura at!',
            big: true,
            onTap: () => setState(() => _stage = _Stage.flipping),
          ),
        ],
      );

  Widget _winner(WeeklyData d, WeeklyResult r, WeeklyTrophy trophy) {
    final mine = r.winner == d.me;
    return Column(
      key: const ValueKey('weekly-winner'),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: .3, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, s, child) => Transform.scale(scale: s, child: child),
          child: TrophyBadge(trophy: trophy, size: 96),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _avatar(d, r.winner, 26),
            const SizedBox(width: 8),
            Flexible(
              child: Text(d.nameOf(r.winner),
                  key: const ValueKey('weekly-winner-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.sheetTitle.copyWith(fontSize: 24)),
            ),
            const SizedBox(width: 10),
            Text(r.score,
                style: const TextStyle(
                    fontFamily: AppTheme.pixelFont,
                    color: _gold,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
            mine
                ? 'Tebrikler! ${trophy.name} artık senin rafında.'
                : '${trophy.name} bu sefer ${d.nameOf(r.winner)} rafında. '
                    'Rövanş yeni turda!',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14, height: 1.35)),
        const SizedBox(height: 16),
        ArcadeButton(
          key: const ValueKey('weekly-result-close'),
          label: mine ? 'Harika!' : 'Tamam',
          big: true,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Yazı tura: paranın bir yüzünde bir oyuncu, öbür yüzünde diğeri. Para
/// havaya fırlar, dönerek düşer ve [winner] yüzü üstte durur (sonucu sunucu
/// belirler; bu yalnız gösterimidir).
class CoinFlip extends StatefulWidget {
  const CoinFlip(
      {super.key,
      required this.data,
      required this.winner,
      required this.onDone});

  final WeeklyData data;
  final int winner;
  final VoidCallback onDone;

  @override
  State<CoinFlip> createState() => _CoinFlipState();
}

class _CoinFlipState extends State<CoinFlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800));
  Timer? _hold;

  /// Yarım tur sayısı: çiftse 1. oyuncunun, tekse 2. oyuncunun yüzü kalır.
  int get _halfTurns => widget.winner == 1 ? 10 : 11;

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      // Sonuç bir an görünsün.
      _hold = Timer(const Duration(milliseconds: 700), widget.onDone);
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 190,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final angle =
                Curves.easeOutCubic.transform(t) * _halfTurns * math.pi;
            // Yükselip düşer; yere değince küçük bir sekme.
            final air = t < .82
                ? math.sin(math.pi * t / .82) * 78
                : math.sin(math.pi * (t - .82) / .18) * 9;
            final face = math.cos(angle) >= 0 ? 1 : 2;
            final squash = math.max(.06, math.cos(angle).abs());
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Gölge: para yükseldikçe küçülür.
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 70 - air * .35,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16 + air,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(1, squash, 1),
                    child: _CoinFace(data: widget.data, player: face),
                  ),
                ),
                if (t == 1)
                  Positioned(
                    top: 0,
                    child: Text('${widget.data.nameOf(widget.winner)}!',
                        style: AppTheme.sheetTitle
                            .copyWith(color: _gold, fontSize: 22)),
                  ),
              ],
            );
          },
        ),
      );
}

class _CoinFace extends StatelessWidget {
  const _CoinFace({required this.data, required this.player});

  final WeeklyData data;
  final int player;

  @override
  Widget build(BuildContext context) => Container(
        width: 84,
        height: 84,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _gold,
          border: Border.all(color: const Color(0xFFC0892E), width: 4),
          boxShadow: const [
            BoxShadow(color: Color(0xFF8A5A14), offset: Offset(0, 4))
          ],
        ),
        child: _avatar(data, player, 62),
      );
}
