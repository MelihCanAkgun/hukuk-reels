import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/link_bridge.dart';
import 'film_store.dart';
import 'film_widgets.dart';

/// Film detayı: büyük afiş, özet, nerede izlenir, IMDb/Letterboxd bağlantıları,
/// "İzledik ✓", iki kişinin kalp puanı ve yorumu, listeden çıkarma.
Future<void> showFilmDetail(BuildContext context, int filmId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.bgElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .92,
        minChildSize: .5,
        maxChildSize: 1,
        builder: (_, scroll) =>
            FilmDetail(filmId: filmId, scrollController: scroll),
      ),
    );

class FilmDetail extends StatefulWidget {
  const FilmDetail({super.key, required this.filmId, this.scrollController});

  final int filmId;
  final ScrollController? scrollController;

  @override
  State<FilmDetail> createState() => _FilmDetailState();
}

class _FilmDetailState extends State<FilmDetail> {
  final _store = FilmStore.instance;
  final _comment = TextEditingController();
  int _hearts = 0;
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
    _comment.dispose();
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
    _hearts = mine?.hearts ?? 0;
    _comment.text = mine?.comment ?? '';
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
    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
          18, 10, 18, 24 + MediaQuery.viewInsetsOf(context).bottom),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
                color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        _header(film),
        const SizedBox(height: 16),
        _providers(film),
        if (film.overview.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(film.overview,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.45)),
        ],
        const SizedBox(height: 14),
        _links(film),
        const SizedBox(height: 14),
        _added(film),
        const SizedBox(height: 18),
        film.isWatched ? _watched(film) : _watchButton(film),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!,
              key: const ValueKey('film-message'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
        ],
        const SizedBox(height: 18),
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
          'Film bilgileri ve afişler TMDB\'den, IMDb puanı OMDb\'den alınır.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 116,
            height: 174,
            child: FilmPoster(url: film.posterUrl('w500'), title: film.title),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(film.title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 21,
                      height: 1.2,
                      fontWeight: FontWeight.w800)),
              if (film.subtitle != null) ...[
                const SizedBox(height: 3),
                Text(film.subtitle!,
                    style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontStyle: FontStyle.italic)),
              ],
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(meta,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
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
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(g,
                            style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 11.5,
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
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: .8),
        ),
        child: film.providers.isEmpty
            ? const Text('📺 Türkiye\'de abonelik platformlarında görünmüyor.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nerede izlenir?',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
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
                                    fontSize: 13,
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
          _linkButton('Letterboxd', const Color(0xFF40BCF4),
              () => _open(film.letterboxdUrl)),
          _linkButton('TMDB', kTmdbGreen, () => _open(film.tmdbUrl)),
        ],
      );

  Widget _linkButton(String label, Color color, VoidCallback onTap) =>
      OutlinedButton.icon(
        key: ValueKey('film-link-$label'),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: .6)),
          visualDensity: VisualDensity.compact,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _watchButton(Film film) => SizedBox(
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.pinkGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: FilledButton(
            key: const ValueKey('film-watched'),
            onPressed: _busy
                ? null
                : () => _run(() => _store.setWatched(film.id, true),
                    done: 'İzlendi olarak işaretlendi. Puanını ver! 🍿'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white))
                : const Text('İzledik ✓',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
          ),
        ),
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
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.success.withValues(alpha: .45)),
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
        const SizedBox(height: 16),
        const Text('Puanlarımız',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _myRating(film),
        for (final r in others) ...[
          const SizedBox(height: 10),
          _ratingTile(r.player, r.hearts, r.comment),
        ],
        if (others.isEmpty) ...[
          const SizedBox(height: 10),
          Text(
            '${_store.players.entries.where((e) => e.key != _store.me).map((e) => e.value).firstOrNull ?? 'Diğer oyuncu'} henüz puan vermedi.',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _ratingTile(int player, int hearts, String comment,
          {Widget? trailing}) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: .8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlayerAvatar(id: player, size: 30, ring: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(_store.nameOf(player),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      HeartRow(value: hearts, size: 15),
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(comment,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13.5,
                            height: 1.35)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );

  Widget _myRating(Film film) {
    final me = _store.me;
    final mine = _store.myRating(film.id);
    if (me != null && mine != null && !_editing) {
      return _ratingTile(me, mine.hearts, mine.comment,
          trailing: IconButton(
            key: const ValueKey('film-rate-edit'),
            tooltip: 'Düzenle',
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit_rounded,
                size: 18, color: AppTheme.textSecondary),
          ));
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Senin puanın',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          HeartRow(
              value: _hearts,
              size: 30,
              onChanged: (v) => setState(() => _hearts = v)),
          const SizedBox(height: 6),
          TextField(
            key: const ValueKey('film-comment'),
            controller: _comment,
            maxLength: 140,
            maxLines: 2,
            minLines: 1,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Kısa bir yorum (isteğe bağlı)',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.bgElevated,
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const ValueKey('film-rate-save'),
              onPressed: _busy || _hearts == 0
                  ? null
                  : () async {
                      await _run(
                          () => _store.rate(film.id, _hearts,
                              _comment.text.replaceAll('\n', ' ').trim()),
                          done: 'Puanın kaydedildi 💗');
                      if (mounted && _store.myRating(film.id) != null) {
                        setState(() => _editing = false);
                      }
                    },
              child: const Text('Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}
