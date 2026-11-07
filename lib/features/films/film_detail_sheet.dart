import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/link_bridge.dart';
import 'film_reviews.dart';
import 'film_store.dart';
import 'film_widgets.dart';

/// Film ya da bölüm detayı (pembe bir Letterboxd sayfası gibi): bulanık afiş
/// zemini üstünde afiş ve başlık, nerede izlenir, bağlantılar, "İzledik ✓",
/// iki kişinin yarım kalpli puanı, yorumları, beğenileri ve yanıtları.
/// [reviewsFirst] (puan tablosundan açılınca) incelemeleri başlığın hemen
/// altına alır.
Future<void> showFilmDetail(BuildContext context, int filmId,
        {bool reviewsFirst = false}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.bgElevated,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .94,
        minChildSize: .5,
        maxChildSize: 1,
        builder: (_, scroll) => FilmDetail(
            filmId: filmId,
            scrollController: scroll,
            reviewsFirst: reviewsFirst),
      ),
    );

class FilmDetail extends StatefulWidget {
  const FilmDetail({
    super.key,
    required this.filmId,
    this.scrollController,
    this.reviewsFirst = false,
  });

  final int filmId;
  final ScrollController? scrollController;
  final bool reviewsFirst;

  @override
  State<FilmDetail> createState() => _FilmDetailState();
}

class _FilmDetailState extends State<FilmDetail> {
  final _store = FilmStore.instance;
  int _halves = 0;
  String _comment = '';
  bool _busy = false, _editing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _store.changes.addListener(_changed);
    _resetRating();
  }

  @override
  void dispose() {
    _store.changes.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    if (_store.byId(widget.filmId) == null) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {});
  }

  void _resetRating() {
    final mine = _store.myRating(widget.filmId);
    _halves = mine?.halves ?? 0;
    _comment = mine?.comment ?? '';
    _editing = mine == null;
  }

  Future<void> _run(Future<String?> Function() action, {String? done}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final error = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = error ?? done;
    });
  }

  void _showError(String error) {
    if (mounted) setState(() => _message = error);
  }

  void _open(String url) {
    if (!openExternal(url)) {
      setState(() => _message = 'Bağlantı yalnız web uygulamasında açılır.');
    }
  }

  Future<void> _confirmDelete(Film film) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Listeden çıkarılsın mı?'),
        content: Text('"${film.title}" ve puanları silinecek.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Vazgeç')),
          TextButton(
              key: const ValueKey('film-delete-confirm'),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Çıkar',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok == true) await _run(() => _store.delete(film.id));
  }

  @override
  Widget build(BuildContext context) {
    final film = _store.byId(widget.filmId);
    if (film == null) return const SizedBox(height: 200);
    final reviews = [
      const SizedBox(height: 18),
      film.isWatched ? _watched(film) : _watchButton(film),
      if (_message != null) ...[
        const SizedBox(height: 12),
        Text(_message!,
            key: const ValueKey('film-message'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.accent, fontSize: 14)),
      ],
    ];
    final info = [
      const SizedBox(height: 18),
      _providers(film),
      if (film.stillUrl != null) ...[
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: FilmPoster(url: film.stillUrl, title: film.title),
          ),
        ),
      ],
      if (film.overview.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(film.overview,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14.5, height: 1.45)),
      ],
      const SizedBox(height: 14),
      _links(film),
      const SizedBox(height: 14),
      _added(film),
    ];
    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.zero,
      children: [
        _hero(film),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.reviewsFirst) ...[
                ...reviews,
                ...info
              ] else ...[
                ...info,
                ...reviews
              ],
              const SizedBox(height: 22),
              Center(
                child: TextButton.icon(
                  key: const ValueKey('film-delete'),
                  onPressed: _busy ? null : () => _confirmDelete(film),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppTheme.danger),
                  label: const Text('Listeden çıkar',
                      style: TextStyle(color: AppTheme.danger)),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Film ve dizi bilgileri TMDB\'den, IMDb puanı OMDb\'den alınır.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Üst bölüm: bulanık, kararan afiş zemini; solda çerçeveli afiş, sağda
  /// başlık ve künye.
  Widget _hero(Film film) {
    final backdrop = film.stillUrl ?? film.posterUrl('w342');
    return Stack(
      children: [
        if (backdrop != null)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                  sigmaX: 14, sigmaY: 14, tileMode: TileMode.decal),
              child: Opacity(
                opacity: .55,
                child: FilmPoster(url: backdrop, title: film.title),
              ),
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.bgElevated.withValues(alpha: .25),
                  AppTheme.bgElevated.withValues(alpha: .8),
                  AppTheme.bgElevated,
                ],
                stops: const [0, .6, 1],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2)),
              ),
              _header(film),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(Film film) {
    final meta = [
      if (film.year != null) '${film.year}',
      if (film.runtime != null) runtimeText(film.runtime!),
    ].join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 118,
          height: 177,
          decoration: arcadePanel(
              border: const Color(0xFFFFC2D8),
              shadow: const Color(0xFF8C1D4A),
              radius: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: FilmPoster(url: film.posterUrl('w500'), title: film.title),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (film.isEpisode) ...[
                Text(
                  '📺 ${film.showTitle ?? 'Dizi'}',
                  key: const ValueKey('film-show-title'),
                  style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  film.season == 0
                      ? 'Özel bölüm ${film.episode}'
                      : '${film.season}. Sezon ${film.episode}. Bölüm',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
              ],
              Text(film.title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(color: Color(0xFF8C1D4A), offset: Offset(2, 2))
                      ])),
              if (film.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(film.subtitle!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(meta,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
              ],
              if (film.genres.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final g in film.genres)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color: AppTheme.accent.withValues(alpha: .5)),
                        ),
                        child: Text(g.toUpperCase(),
                            style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 11,
                                letterSpacing: .6,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              RatingBadges(film: film, large: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _providers(Film film) => Container(
        padding: const EdgeInsets.all(12),
        decoration: arcadePanel(),
        child: film.providers.isEmpty
            ? const Text('📺 Türkiye\'de abonelik platformlarında görünmüyor.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEREDE İZLENİR?',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      for (final p in film.providers)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ProviderLogos(providers: [p], size: 26),
                            Text(p.name,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
      );

  Widget _links(Film film) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (film.imdbUrl != null)
            _linkButton('IMDb', kImdbYellow, () => _open(film.imdbUrl!)),
          if (film.letterboxdUrl != null)
            _linkButton('Letterboxd', const Color(0xFF40BCF4),
                () => _open(film.letterboxdUrl!)),
          _linkButton('TMDB', kTmdbGreen, () => _open(film.tmdbUrl)),
        ],
      );

  Widget _linkButton(String label, Color color, VoidCallback onTap) =>
      OutlinedButton.icon(
        key: ValueKey('film-link-$label'),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: .7), width: 1.5),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      );

  Widget _added(Film film) => Row(
        children: [
          PlayerAvatar(id: film.addedBy, size: 22, ring: false),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_store.nameOf(film.addedBy)} ekledi · '
              '${agoText(film.added, DateTime.now())}',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      );

  Widget _watchButton(Film film) => ArcadeButton(
        key: const ValueKey('film-watched'),
        label: 'İzledik ✓',
        big: true,
        busy: _busy,
        onTap: () => _run(() => _store.setWatched(film.id, true),
            done: 'İzlendi olarak işaretlendi. Puanını ver! 🍿'),
      );

  Widget _watched(Film film) {
    final others = [
      for (final r in _store.ratingsOf(film.id))
        if (r.player != _store.me) r
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          decoration: arcadePanel(
            color: AppTheme.success.withValues(alpha: .12),
            border: AppTheme.success.withValues(alpha: .55),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${dateText(film.watched!)} tarihinde izlendi'
                  '${film.watchedBy == null ? '' : ' · ${_store.nameOf(film.watchedBy)} işaretledi'}',
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13),
                ),
              ),
              TextButton(
                key: const ValueKey('film-unwatch'),
                onPressed: _busy
                    ? null
                    : () => _run(() => _store.setWatched(film.id, false)),
                child: const Text('Geri al'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Puanlarımız',
            style: TextStyle(
                fontFamily: AppTheme.pixelFont,
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _myRating(film),
        for (final r in others) ...[
          const SizedBox(height: 12),
          ReviewCard(film: film, rating: r, onError: _showError),
        ],
        if (others.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${_store.players.entries.where((e) => e.key != _store.me).map((e) => e.value).firstOrNull ?? 'Diğer oyuncu'} henüz puan vermedi.',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13.5),
          ),
        ],
      ],
    );
  }

  Future<void> _editComment() async {
    final text = await showTextComposer(
      context,
      title: 'Yorumun',
      initial: _comment,
      hint: 'Nasıldı? Kısa bir yorum…',
      action: 'Tamam',
      allowEmpty: true,
    );
    if (text != null && mounted) setState(() => _comment = text);
  }

  Widget _myRating(Film film) {
    final me = _store.me;
    final mine = _store.myRating(film.id);
    if (me != null && mine != null && !_editing) {
      return ReviewCard(
        film: film,
        rating: mine,
        onError: _showError,
        trailing: IconButton(
          key: const ValueKey('film-rate-edit'),
          tooltip: 'Düzenle',
          onPressed: () => setState(() {
            _resetRating();
            _editing = true;
          }),
          icon: const Icon(Icons.edit_rounded,
              size: 18, color: AppTheme.textSecondary),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration:
          arcadePanel(border: AppTheme.accent, shadow: const Color(0xFF8C1D4A)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('SENİN PUANIN',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600)),
              ),
              Text(_halves == 0 ? '–' : heartsText(_halves),
                  key: const ValueKey('film-rate-value'),
                  style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          Center(
            child: HeartRow(
                halves: _halves,
                size: 40,
                onChanged: (v) => setState(() => _halves = v)),
          ),
          const Center(
            child: Text('Kalbin sol yarısı: yarım kalp',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5)),
          ),
          const SizedBox(height: 12),
          InkWell(
            key: const ValueKey('film-comment'),
            onTap: _editComment,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _comment.isEmpty ? 'Yorum yaz (isteğe bağlı)' : _comment,
                      style: TextStyle(
                          color: _comment.isEmpty
                              ? AppTheme.textMuted
                              : AppTheme.textPrimary,
                          fontSize: 14.5,
                          height: 1.3),
                    ),
                  ),
                  const Icon(Icons.edit_note_rounded,
                      color: AppTheme.textMuted, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (mine != null)
                TextButton(
                  onPressed: () => setState(_resetRating),
                  child: const Text('Vazgeç',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              const SizedBox(width: 6),
              ArcadeButton(
                key: const ValueKey('film-rate-save'),
                label: 'Kaydet',
                busy: _busy,
                onTap: _halves == 0
                    ? null
                    : () async {
                        await _run(
                            () => _store.rate(film.id, _halves, _comment),
                            done: 'Puanın kaydedildi 💗');
                        if (mounted && _store.myRating(film.id) != null) {
                          setState(() => _editing = false);
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
