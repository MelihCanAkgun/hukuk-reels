import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/arcade_title.dart';
import '../../core/widgets/pixel_logo.dart';
import '../../core/widgets/pressable.dart';
import 'film_detail_sheet.dart';
import 'film_reviews.dart';
import 'film_roulette.dart';
import 'film_store.dart';
import 'film_swipe.dart';
import 'film_widgets.dart';

const _superColor = Color(0xFF4FA3FF);
const _passColor = Color(0xFF9C98A6);

/// "Ortak karar" ekranı: başlat → kaydır → (diğerini bekle) → eşleşmeler.
/// Sağa kaydır beğen, sola geç, yukarı süper beğen (oturumda bir kez);
/// alttaki düğmeler aynı işi yapar.
class FilmSwipeScreen extends StatelessWidget {
  const FilmSwipeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Theme(data: AppTheme.arcade, child: const _SwipeView());
}

class _SwipeView extends StatefulWidget {
  const _SwipeView();

  @override
  State<_SwipeView> createState() => _SwipeViewState();
}

class _SwipeViewState extends State<_SwipeView> {
  final _store = SwipeStore.instance;
  Timer? _poll;

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _store.changes.addListener(_changed);
    _store.load();
    // Diğer oyuncu bitirince sonuç kendiliğinden gelsin.
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      final s = _store.session;
      if (mounted && s != null && s.isOpen && s.mineDone && !_store.sending) {
        _store.load();
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _store.changes.removeListener(_changed);
    super.dispose();
  }

  Future<void> _start() async {
    await _store.start();
    if (mounted && _store.error != null) _toast(_store.error!);
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.bgElevated,
        title: const Text('Seçim iptal edilsin mi?'),
        content: const Text('İkinizin de bu turdaki oyları silinir.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('İptal et')),
        ],
      ),
    );
    if (ok == true) await _store.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final s = _store.session;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              ArcadeTitleBar(
                title: 'Ortak Karar',
                logo: kLogoHeart,
                actions: [
                  if (s != null && s.isOpen)
                    IconButton(
                      key: const ValueKey('swipe-cancel'),
                      tooltip: 'Seçimi iptal et',
                      onPressed: _cancel,
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.textSecondary),
                    ),
                ],
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _body(s),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(SwipeSession? s) {
    if (!_store.loaded) {
      return const CircularProgressIndicator(color: AppTheme.accent);
    }
    if (s == null) return _intro();
    if (s.isDone) return _results(s);
    if (s.mineDone) return _waiting(s);
    return SwipeDeck(
      key: ValueKey('deck-${s.id}'),
      session: s,
      sending: _store.sending,
      error: _store.error,
      onVote: _store.vote,
      onRetry: _store.flush,
    );
  }

  Widget _intro({String? note}) => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PixelLogo(kLogoHeart, size: 64),
            const SizedBox(height: 18),
            Text(note ?? 'Bu akşam ne izlesek?',
                textAlign: TextAlign.center,
                style: AppTheme.sheetTitle.copyWith(fontSize: 24)),
            const SizedBox(height: 10),
            const Text(
              'Listenizden ve birkaç yeni öneriden 15 filmlik kısa bir deste '
              'hazırlanır. İkiniz de kendi zamanında kaydırır: sağa beğen, '
              'sola geç, yukarı süper beğen. İkinizin de beğendikleri '
              'eşleşme olur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14.5, height: 1.45),
            ),
            if (_store.error != null) ...[
              const SizedBox(height: 12),
              Text(_store.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
            ],
            const SizedBox(height: 22),
            ArcadeButton(
              key: const ValueKey('swipe-start'),
              label: 'Seçimi başlat',
              big: true,
              busy: _store.busy,
              onTap: _start,
            ),
          ],
        ),
      );

  Widget _waiting(SwipeSession s) {
    final liked = [
      for (final c in s.cards)
        if ((s.votes[c.pos] ?? SwipeVote.pass) != SwipeVote.pass) c
    ];
    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _store.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
        children: [
          const Center(child: PixelLogo(kLogoHeart, size: 52)),
          const SizedBox(height: 14),
          Text('Seçimini yaptın!',
              key: const ValueKey('swipe-waiting'),
              textAlign: TextAlign.center,
              style: AppTheme.sheetTitle.copyWith(fontSize: 23)),
          const SizedBox(height: 8),
          Text(
            _store.sending
                ? 'Oyların gönderiliyor…'
                : '${_store.nameOf(_store.other)} bekleniyor '
                    '(${s.otherCount}/${s.total}). Bitirince eşleşmeler '
                    'burada görünecek ve bildirim gelecek.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14.5, height: 1.4),
          ),
          if (_store.sending && _store.error != null) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: _store.flush,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Bağlantı yok. Tekrar dene'),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text('BEĞENDİKLERİN (${liked.length})', style: AppTheme.sectionLabel),
          const SizedBox(height: 10),
          for (final c in liked) ...[
            _matchRow(c, superLike: s.votes[c.pos] == SwipeVote.superLike),
            const SizedBox(height: 8),
          ],
          if (liked.isEmpty)
            const Text('Bu turda hiçbirini beğenmedin.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _results(SwipeSession s) {
    final matches = s.matches ?? const <SwipeCard>[];
    if (matches.isEmpty) {
      return _intro(note: 'Bu sefer eşleşme çıkmadı 😅');
    }
    final films = [
      for (final m in matches)
        if (m.filmId != null && FilmStore.instance.byId(m.filmId!) != null)
          FilmStore.instance.byId(m.filmId!)!
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        Text(
            matches.length == 1
                ? 'Eşleşme var! 🎉'
                : '${matches.length} filmde eşleştiniz! 🎉',
            key: const ValueKey('swipe-result-title'),
            textAlign: TextAlign.center,
            style: AppTheme.sheetTitle.copyWith(fontSize: 24)),
        const SizedBox(height: 4),
        const Text('İkinizin de beğendikleri. Dokununca detayı açılır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5)),
        const SizedBox(height: 16),
        for (final (i, m) in matches.indexed) ...[
          _matchRow(m, top: i == 0, supers: m.supers),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        if (films.length > 1) ...[
          OutlinedButton.icon(
            key: const ValueKey('swipe-roll'),
            onPressed: () async {
              final film = await showFilmRoulette(context, films);
              if (film != null && mounted) {
                await showFilmDetail(context, film.id);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              minimumSize: const Size.fromHeight(46),
              side: const BorderSide(color: AppTheme.border, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            icon: const PixelLogo(kDiceSprite, size: 18),
            label: const Text('Aralarından zar at',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
        ],
        ArcadeButton(
          key: const ValueKey('swipe-again'),
          label: 'Yeni seçim başlat',
          big: true,
          busy: _store.busy,
          onTap: _start,
        ),
      ],
    );
  }

  /// Sonuç / beğeni satırı: küçük afiş, ad ve süper beğeni işaretleri.
  Widget _matchRow(SwipeCard c,
      {bool top = false, List<int> supers = const [], bool superLike = false}) {
    final filmId = c.filmId;
    final inList = filmId != null && FilmStore.instance.byId(filmId) != null;
    return Pressable(
      key: ValueKey('swipe-match-${c.pos}'),
      semanticLabel: c.title,
      onTap: inList ? () => showFilmDetail(context, filmId) : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: arcadePanel(
          border: top ? AppTheme.accent : AppTheme.border,
          shadow: top ? const Color(0xFF8C1D4A) : const Color(0xFF0B0408),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                width: top ? 62 : 46,
                height: top ? 93 : 69,
                child: FilmPoster(url: c.posterUrl('w154'), title: ''),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (top)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('EN İYİ EŞLEŞME',
                          style: AppTheme.sectionLabel
                              .copyWith(fontSize: 11, color: AppTheme.accent)),
                    ),
                  Text(c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: top ? 17 : 15,
                          height: 1.2,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(c.episodeLabel ?? c.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12.5)),
                  if (supers.isNotEmpty || superLike) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: _superColor, size: 16),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                              superLike
                                  ? 'Süper beğendin'
                                  : supers.length == 2
                                      ? 'İkiniz de süper beğendi!'
                                      : '${_store.nameOf(supers.first)} süper beğendi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _superColor,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (inList)
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Kaydırılan deste. Üstteki kart parmağı izler; bırakınca ya yerine döner
/// ya da oy yönüne uçar. Alttaki kart hazır bekler ve afişleri önceden
/// yüklenir, böylece geçişte boş kart görünmez.
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.session,
    required this.onVote,
    this.sending = false,
    this.error,
    this.onRetry,
  });

  final SwipeSession session;
  final void Function(int pos, SwipeVote vote) onVote;
  final bool sending;
  final String? error;
  final VoidCallback? onRetry;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fly = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220));
  Offset _drag = Offset.zero, _from = Offset.zero, _to = Offset.zero;

  /// Uçuş bitince verilecek oy; null: kart yerine dönüyor.
  SwipeVote? _flying;
  int? _precached;

  SwipeSession get _s => widget.session;

  @override
  void initState() {
    super.initState();
    _fly.addListener(() {
      setState(() => _drag =
          Offset.lerp(_from, _to, Curves.easeOut.transform(_fly.value))!);
    });
    _fly.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      final vote = _flying, card = _s.next;
      _flying = null;
      _drag = Offset.zero;
      if (vote != null && card != null) widget.onVote(card.pos, vote);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precache();
  }

  @override
  void didUpdateWidget(SwipeDeck old) {
    super.didUpdateWidget(old);
    _precache();
  }

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  /// Sıradaki üç kartın afişi önceden iner.
  void _precache() {
    final next = _s.next;
    if (next == null || _precached == next.pos) return;
    _precached = next.pos;
    for (final c in _s.cards.where((c) => c.pos > next.pos).take(3)) {
      final url = c.posterUrl();
      if (url != null) {
        precacheImage(NetworkImage(url), context, onError: (_, __) {});
      }
    }
  }

  void _release(Size size, Velocity velocity) {
    final v = velocity.pixelsPerSecond;
    final SwipeVote? vote;
    if (_drag.dy < -size.height * .16 && _drag.dy.abs() > _drag.dx.abs() ||
        v.dy < -900 && v.dy.abs() > v.dx.abs()) {
      vote = _s.superUsed ? null : SwipeVote.superLike;
    } else if (_drag.dx > size.width * .28 || v.dx > 800) {
      vote = SwipeVote.like;
    } else if (_drag.dx < -size.width * .28 || v.dx < -800) {
      vote = SwipeVote.pass;
    } else {
      vote = null;
    }
    _animate(vote, size);
  }

  void _animate(SwipeVote? vote, Size size) {
    if (_fly.isAnimating || _s.next == null) return;
    _flying = vote;
    _from = _drag;
    _to = switch (vote) {
      null => Offset.zero,
      SwipeVote.like => Offset(size.width * 1.4, _drag.dy),
      SwipeVote.pass => Offset(-size.width * 1.4, _drag.dy),
      SwipeVote.superLike => Offset(_drag.dx, -size.height * 1.3),
    };
    _fly.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final card = _s.next;
    if (card == null) return const SizedBox.shrink();
    final after = _s.cards.where((c) => c.pos > card.pos).firstOrNull;
    final voted = _s.votes.length;
    return LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      // Sürükleme oranı: -1 sol, +1 sağ; yukarı için ayrı.
      final dx = (_drag.dx / (size.width * .28)).clamp(-1.0, 1.0);
      final up = _drag.dy.abs() > _drag.dx.abs()
          ? (-_drag.dy / (size.height * .16)).clamp(0.0, 1.0)
          : 0.0;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
            child: Row(
              children: [
                Text('${voted + 1} / ${_s.total}',
                    key: const ValueKey('swipe-progress'),
                    style: const TextStyle(
                        fontFamily: AppTheme.pixelFont,
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: voted / _s.total,
                      minHeight: 6,
                      backgroundColor: AppTheme.surfaceHigh,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
                if (widget.error != null && widget.sending) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Oylar gönderilemedi; dokun, tekrar dene',
                    child: GestureDetector(
                      key: const ValueKey('swipe-retry'),
                      onTap: widget.onRetry,
                      child: const Icon(Icons.cloud_off_rounded,
                          color: AppTheme.textMuted, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (after != null)
                    Transform.scale(
                      scale: .94 + .06 * math.max(dx.abs(), up),
                      child: RepaintBoundary(
                          child: _SwipeCardView(
                              key: ValueKey('under-${after.pos}'),
                              card: after)),
                    ),
                  GestureDetector(
                    key: const ValueKey('swipe-card'),
                    onPanUpdate: _fly.isAnimating
                        ? null
                        : (d) => setState(() => _drag += d.delta),
                    onPanEnd: _fly.isAnimating
                        ? null
                        : (d) => _release(size, d.velocity),
                    child: Transform.translate(
                      offset: _drag,
                      child: Transform.rotate(
                        angle: _drag.dx / size.width * .35,
                        child: RepaintBoundary(
                          child: _SwipeCardView(
                            key: ValueKey('card-${card.pos}'),
                            card: card,
                            top: true,
                            like: dx > 0 && up == 0 ? dx : 0,
                            pass: dx < 0 && up == 0 ? -dx : 0,
                            superLike: _s.superUsed ? 0 : up,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _button('swipe-pass', Icons.close_rounded, _passColor, 'Geç',
                    () => _animate(SwipeVote.pass, size)),
                _button(
                    'swipe-super',
                    Icons.star_rounded,
                    _superColor,
                    _s.superUsed ? 'Süper beğeni kullanıldı' : 'Süper beğen',
                    _s.superUsed
                        ? null
                        : () => _animate(SwipeVote.superLike, size),
                    small: true),
                _button('swipe-like', Icons.favorite_rounded, AppTheme.accent,
                    'Beğen', () => _animate(SwipeVote.like, size)),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _button(
      String key, IconData icon, Color color, String label, VoidCallback? onTap,
      {bool small = false}) {
    final d = small ? 52.0 : 64.0;
    final enabled = onTap != null;
    return Pressable(
      key: ValueKey(key),
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: enabled ? color : AppTheme.border, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0xFF0B0408), offset: Offset(3, 3))
          ],
        ),
        child: Icon(icon,
            color: enabled ? color : AppTheme.textMuted, size: small ? 26 : 32),
      ),
    );
  }
}

/// Tek kart: afiş, altta koyu şerit üstünde ad ve bilgiler; sürüklerken
/// köşede "BEĞEN / GEÇ / SÜPER" damgası belirir.
class _SwipeCardView extends StatelessWidget {
  const _SwipeCardView({
    super.key,
    required this.card,
    this.like = 0,
    this.pass = 0,
    this.superLike = 0,
    this.top = false,
  });

  final SwipeCard card;

  /// En üstteki (sürüklenen) kart.
  final bool top;
  final double like, pass, superLike;

  @override
  Widget build(BuildContext context) {
    final rating = card.imdbRating ?? card.tmdbRating;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF0B0408), offset: Offset(4, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FilmPoster(url: card.posterUrl(), title: card.title),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 34, 14, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00170B12),
                    Color(0xE6170B12),
                    Color(0xFF170B12)
                  ],
                  stops: [0, .32, 1],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _tag(card.suggested ? 'YENİ ÖNERİ' : 'LİSTENİZDEN',
                          card.suggested ? _superColor : AppTheme.accent),
                      if (rating != null) ...[
                        const SizedBox(width: 6),
                        _tag('★ ${rating.toStringAsFixed(1)}', kImdbYellow),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  if (card.episodeLabel != null)
                    Text(card.episodeLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  Text(card.title,
                      key: top ? const ValueKey('swipe-title') : null,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: AppTheme.pixelFont,
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          height: 1.1,
                          fontWeight: FontWeight.w700)),
                  if (card.meta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(card.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                  if (card.overview.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(card.overview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                            height: 1.35)),
                  ],
                ],
              ),
            ),
          ),
          if (like > 0)
            _stamp('BEĞEN', AppTheme.accent, Alignment.topLeft, -.2, like),
          if (pass > 0) _stamp('GEÇ', _passColor, Alignment.topRight, .2, pass),
          if (superLike > 0)
            _stamp('SÜPER', _superColor, Alignment.center, 0, superLike),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xCC170B12),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(text,
            style: TextStyle(
                fontFamily: AppTheme.pixelFont,
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: .4)),
      );

  Widget _stamp(String text, Color color, Alignment alignment, double angle,
          double opacity) =>
      Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: angle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xCC170B12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color, width: 3),
                ),
                child: Text(text,
                    style: TextStyle(
                        fontFamily: AppTheme.pixelFont,
                        color: color,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ),
            ),
          ),
        ),
      );
}

/// İzle sekmesindeki şerit: oturumun durumuna göre çağrı ("Sıra sende!",
/// "Eşleşmeler hazır!") ve kaydırma ekranına giriş.
class SwipeBanner extends StatelessWidget {
  const SwipeBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final store = FilmStore.instance;
    final s = store.swipe;
    final (String text, bool hot) = switch (s) {
      null => ('Ortak karar: kaydırın, eşleşeni izleyin', false),
      _ when s.myTurn => (
          s.startedBy == store.me && s.mine == 0
              ? 'Seçimi başlattın: kaydırmaya başla'
              : s.mine == 0
                  ? '${store.nameOf(s.startedBy)} seçim başlattı: sıra sende!'
                  : 'Kaydırmaya devam et (${s.mine}/${s.total})',
          true
        ),
      _ when s.isOpen => (
          '${store.nameOf(3 - (store.me ?? 1))} bekleniyor…',
          false
        ),
      _ => ('Ortak karar: eşleşmeleri gör ya da yeni tur başlat', false),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Pressable(
        key: const ValueKey('swipe-banner'),
        semanticLabel: text,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          decoration: BoxDecoration(
            gradient: hot ? AppTheme.pinkGradient : null,
            color: hot ? null : AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: hot ? const Color(0xFFFFC2D8) : AppTheme.border,
                width: 1.5),
          ),
          child: Row(
            children: [
              const PixelLogo(kLogoHeart, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(text,
                    key: const ValueKey('swipe-banner-text'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: hot ? Colors.white : AppTheme.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: hot ? Colors.white : AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
