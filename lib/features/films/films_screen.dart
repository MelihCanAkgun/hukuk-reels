import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/avatar_sync.dart';
import '../../core/services/social_bridge.dart';
import '../../core/widgets/readable_width.dart';
import 'film_detail_sheet.dart';
import 'film_roulette.dart';
import 'film_search_sheet.dart';
import 'film_store.dart';
import 'film_widgets.dart';

enum FilmSort { added, imdb, runtime }

enum FilmLength { short, medium, long }

const _sortLabels = {
  FilmSort.added: 'Eklenme',
  FilmSort.imdb: 'IMDb puanı',
  FilmSort.runtime: 'Süre',
};

const _lengthLabels = {
  FilmLength.short: '90 dk altı',
  FilmLength.medium: '90–120 dk',
  FilmLength.long: '120 dk üstü',
};

/// Liste filtreleri (tür, süre, ekleyen, platform) ve sıralama.
class FilmFilter {
  const FilmFilter({
    this.watched = false,
    this.sort = FilmSort.added,
    this.genre,
    this.length,
    this.addedBy,
    this.platform,
  });

  final bool watched;
  final FilmSort sort;
  final String? genre, platform;
  final FilmLength? length;
  final int? addedBy;

  bool get narrowed =>
      genre != null || length != null || addedBy != null || platform != null;

  FilmFilter copy({
    bool? watched,
    FilmSort? sort,
    String? Function()? genre,
    FilmLength? Function()? length,
    int? Function()? addedBy,
    String? Function()? platform,
  }) =>
      FilmFilter(
        watched: watched ?? this.watched,
        sort: sort ?? this.sort,
        genre: genre == null ? this.genre : genre(),
        length: length == null ? this.length : length(),
        addedBy: addedBy == null ? this.addedBy : addedBy(),
        platform: platform == null ? this.platform : platform(),
      );

  FilmFilter cleared() => FilmFilter(watched: watched, sort: sort);
}

bool _lengthMatches(int? runtime, FilmLength l) {
  if (runtime == null) return false;
  return switch (l) {
    FilmLength.short => runtime < 90,
    FilmLength.medium => runtime >= 90 && runtime <= 120,
    FilmLength.long => runtime > 120,
  };
}

/// Sekmeye, filtrelere ve sıralamaya göre filmler. İzlenenlerde "Eklenme"
/// sıralaması izlenme tarihine göredir (en yeni önce).
List<Film> filterFilms(List<Film> films, FilmFilter f) {
  final out = [
    for (final film in films)
      if (film.isWatched == f.watched &&
          (f.genre == null || film.genres.contains(f.genre)) &&
          (f.length == null || _lengthMatches(film.runtime, f.length!)) &&
          (f.addedBy == null || film.addedBy == f.addedBy) &&
          (f.platform == null ||
              film.providers.any((p) => p.name == f.platform)))
        film
  ];
  int byDate(Film a, Film b) =>
      f.watched ? b.watched!.compareTo(a.watched!) : b.added.compareTo(a.added);
  out.sort(switch (f.sort) {
    FilmSort.added => byDate,
    FilmSort.imdb => (a, b) {
        final c = (b.imdbRating ?? b.tmdbRating ?? -1)
            .compareTo(a.imdbRating ?? a.tmdbRating ?? -1);
        return c != 0 ? c : byDate(a, b);
      },
    FilmSort.runtime => (a, b) {
        final c = (a.runtime ?? 1 << 20).compareTo(b.runtime ?? 1 << 20);
        return c != 0 ? c : byDate(a, b);
      },
  });
  return out;
}

/// Filmler sekmesi: ikimizin ortak izleme listesi.
class FilmsScreen extends StatefulWidget {
  const FilmsScreen({super.key});

  @override
  State<FilmsScreen> createState() => _FilmsScreenState();
}

class _FilmsScreenState extends State<FilmsScreen> {
  final _store = FilmStore.instance;
  FilmFilter _filter = const FilmFilter();

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _store.changes.addListener(_changed);
    _store.refresh(force: true);
    // Kartlardaki ekleyen fotoğrafları: diğer oyuncunun fotoğrafı yalnız
    // eşitlemeyle iner (sıralama ya da profil hiç açılmamış olabilir).
    socialCall('state').then(AvatarSync.instance.sync);
  }

  @override
  void didUpdateWidget(FilmsScreen old) {
    super.didUpdateWidget(old);
    // Sekmeye dönüldü: diğer kişi film eklemiş olabilir.
    _store.refresh();
  }

  @override
  void dispose() {
    _store.changes.removeListener(_changed);
    super.dispose();
  }

  Future<void> _roll() async {
    final pool = filterFilms(_store.films, _filter.copy(watched: false));
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Zar için önce izleyeceklerinize film ekleyin 🍿')));
      return;
    }
    final film = await showFilmRoulette(context, pool);
    if (film != null && mounted) await showFilmDetail(context, film.id);
  }

  @override
  Widget build(BuildContext context) {
    final films = filterFilms(_store.films, _filter);
    final toWatch = _store.films.where((f) => !f.isWatched).length;
    final watched = _store.films.length - toWatch;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      floatingActionButton: _store.connected
          ? FloatingActionButton.extended(
              key: const ValueKey('film-add'),
              onPressed: () => showFilmSearch(context),
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Film ekle',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topBar(),
              if (_store.connected) ...[
                _tabs(toWatch, watched),
                _chips(),
              ],
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.accent,
                  onRefresh: () => _store.refresh(force: true),
                  child: _content(films),
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
                'Film Listemiz',
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
            if (_store.connected) DiceButton(onTap: _roll),
          ],
        ),
      );

  Widget _tabs(int toWatch, int watched) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border, width: .8),
          ),
          child: Row(
            children: [
              _tab('İzleyeceklerimiz ($toWatch)', false),
              _tab('İzlediklerimiz ($watched)', true),
            ],
          ),
        ),
      );

  Widget _tab(String label, bool watched) {
    final selected = _filter.watched == watched;
    return Expanded(
      child: GestureDetector(
        key: ValueKey(watched ? 'films-watched-tab' : 'films-towatch-tab'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _filter = _filter.copy(watched: watched)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.pinkGradient : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  Widget _chips() {
    final genres = {for (final f in _store.films) ...f.genres}.toList()..sort();
    final platforms = {
      for (final f in _store.films) ...f.providers.map((p) => p.name)
    }.toList()
      ..sort();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        children: [
          _chip(
            key: 'sort',
            icon: Icons.swap_vert_rounded,
            label: _sortLabels[_filter.sort]!,
            active: false,
            onTap: () => _pick<FilmSort>(
                'Sırala',
                {for (final e in _sortLabels.entries) e.key: e.value},
                _filter.sort,
                (v) => _filter.copy(sort: v ?? FilmSort.added),
                allowNone: false),
          ),
          if (_filter.narrowed)
            _chip(
              key: 'clear',
              icon: Icons.close_rounded,
              label: 'Temizle',
              active: false,
              onTap: () => setState(() => _filter = _filter.cleared()),
            ),
          _chip(
            key: 'genre',
            label: _filter.genre ?? 'Tür',
            active: _filter.genre != null,
            onTap: () => _pick<String>('Tür', {for (final g in genres) g: g},
                _filter.genre, (v) => _filter.copy(genre: () => v)),
          ),
          _chip(
            key: 'length',
            label: _filter.length == null
                ? 'Süre'
                : _lengthLabels[_filter.length]!,
            active: _filter.length != null,
            onTap: () => _pick<FilmLength>('Süre', _lengthLabels,
                _filter.length, (v) => _filter.copy(length: () => v)),
          ),
          _chip(
            key: 'adder',
            label: _filter.addedBy == null
                ? 'Ekleyen'
                : _store.nameOf(_filter.addedBy),
            active: _filter.addedBy != null,
            onTap: () => _pick<int>('Ekleyen', _store.players, _filter.addedBy,
                (v) => _filter.copy(addedBy: () => v)),
          ),
          _chip(
            key: 'platform',
            label: _filter.platform ?? 'Platform',
            active: _filter.platform != null,
            onTap: () => _pick<String>(
                'Platform',
                {for (final p in platforms) p: p},
                _filter.platform,
                (v) => _filter.copy(platform: () => v)),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String key,
    required String label,
    required bool active,
    required VoidCallback onTap,
    IconData? icon,
  }) =>
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ActionChip(
          key: ValueKey('film-chip-$key'),
          onPressed: onTap,
          avatar: icon == null
              ? null
              : Icon(icon, size: 16, color: AppTheme.textSecondary),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (icon == null && key != 'clear')
                const Icon(Icons.arrow_drop_down_rounded, size: 18),
            ],
          ),
          labelStyle: TextStyle(
              color: active ? Colors.white : AppTheme.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700),
          backgroundColor: active ? AppTheme.accent : AppTheme.surface,
          side: BorderSide(
              color: active ? AppTheme.accent : AppTheme.border, width: .8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      );

  /// Seçenek listesi; "Hepsi" filtreyi kaldırır.
  Future<void> _pick<T>(String title, Map<T, String> options, T? current,
      FilmFilter Function(T? value) apply,
      {bool allowNone = true}) async {
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$title seçeneği için önce listeye film ekleyin.')));
      return;
    }
    final picked = await showModalBottomSheet<({T? value})>(
      context: context,
      backgroundColor: AppTheme.bgElevated,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (c) => ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * .7),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ),
            if (allowNone)
              _option(c, 'Hepsi', current == null, () => (value: null)),
            for (final e in options.entries)
              _option(c, e.value, current == e.key, () => (value: e.key)),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _filter = apply(picked.value));
    }
  }

  Widget _option<R>(
          BuildContext c, String label, bool selected, R Function() value) =>
      ListTile(
        key: ValueKey('film-option-$label'),
        title: Text(label,
            style: TextStyle(
                color: selected ? AppTheme.accent : AppTheme.textPrimary,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
        trailing: selected
            ? const Icon(Icons.check_rounded, color: AppTheme.accent)
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => Navigator.pop(c, value()),
      );

  Widget _content(List<Film> films) {
    final gutter = readableGutter(context, maxWidth: 1100);
    if (!_store.loaded) {
      return _scrollable(const Center(
          child: CircularProgressIndicator(color: AppTheme.accent)));
    }
    if (!_store.connected) {
      return _scrollable(_message(
        '🎬',
        _store.error ??
            'Film listesi ikinizin ortak listesi. Açmak için Profil\'den '
                'oyuncu kodunla bağlan.',
      ));
    }
    if (films.isEmpty) {
      return _scrollable(_filter.narrowed
          ? _message('🔍', 'Bu filtrelere uyan film yok.',
              action: TextButton(
                onPressed: () => setState(() => _filter = _filter.cleared()),
                child: const Text('Filtreleri temizle'),
              ))
          : _filter.watched
              ? _message('🍿',
                  'Henüz birlikte izlediğiniz film yok.\nİzlediğinizde filme dokunup "İzledik ✓"e basın.')
              : _message('💌', 'Listeniz boş. İlk filmi ekleyin!',
                  action: FilledButton.icon(
                    onPressed: () => showFilmSearch(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Film ekle'),
                  )));
    }
    return LayoutBuilder(builder: (context, box) {
      const gap = 12.0;
      final width = box.maxWidth - 2 * gutter;
      final columns = math.max(2, (width / 190).floor());
      final itemWidth = (width - gap * (columns - 1)) / columns;
      return CustomScrollView(
        primary: true,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_store.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 8),
                child: Text('Çevrimdışı: son kaydedilen liste gösteriliyor.',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                mainAxisExtent: itemWidth * 1.5 + FilmCard.infoHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => FilmCard(
                  film: films[i],
                  onTap: () => showFilmDetail(context, films[i].id),
                ),
                childCount: films.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 100),
              child: Text(
                'Film bilgileri ve afişler TMDB\'den, IMDb puanı OMDb\'den.\n'
                'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Boş/hata durumunda da aşağı çekip yenileme çalışsın.
  Widget _scrollable(Widget child) => LayoutBuilder(
        builder: (context, box) => ListView(
          primary: true,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight * .8),
              child: Center(child: child),
            ),
          ],
        ),
      );

  Widget _message(String emoji, String text, {Widget? action}) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 10),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14.5,
                    height: 1.4)),
            if (action != null) ...[const SizedBox(height: 14), action],
          ],
        ),
      );
}
