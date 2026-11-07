import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'film_store.dart';
import 'film_widgets.dart';

/// Arama sonucunda dizi seçilince: sezon seçilir, bölümler tek tek
/// işaretlenip listeye ayrı öğeler olarak eklenir (en fazla 10'ar).
class EpisodePicker extends StatefulWidget {
  const EpisodePicker({super.key, required this.show, required this.onBack});

  final FilmSearchResult show;
  final VoidCallback onBack;

  @override
  State<EpisodePicker> createState() => _EpisodePickerState();
}

class _EpisodePickerState extends State<EpisodePicker> {
  static const maxPerAdd = 10;

  final _store = FilmStore.instance;
  ShowInfo? _info;
  int? _season;
  List<EpisodeResult> _episodes = const [];
  final Set<int> _selected = {};
  bool _loading = true, _adding = false;
  String? _error, _message;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _loadShow();
  }

  Future<void> _loadShow() async {
    final r = await _store.show(widget.show.tmdbId);
    if (!mounted) return;
    final seasons = r.show?.seasons ?? const <ShowSeason>[];
    setState(() {
      _info = r.show;
      _error = r.error;
      _loading = false;
    });
    if (seasons.isNotEmpty) await _loadSeason(seasons.first.season);
  }

  Future<void> _loadSeason(int season) async {
    final gen = ++_generation;
    setState(() {
      _season = season;
      _episodes = const [];
      _selected.clear();
      _loading = true;
      _error = null;
      _message = null;
    });
    final r = await _store.season(widget.show.tmdbId, season);
    if (!mounted || gen != _generation) return;
    setState(() {
      _episodes = r.episodes;
      _error = r.error;
      _loading = false;
    });
  }

  void _toggle(EpisodeResult e) {
    if (e.inList || _adding) return;
    setState(() {
      _message = null;
      if (!_selected.remove(e.episode)) {
        if (_selected.length >= maxPerAdd) {
          _message = 'Tek seferde en fazla $maxPerAdd bölüm eklenir.';
        } else {
          _selected.add(e.episode);
        }
      }
    });
  }

  List<EpisodeResult> get _addable => [
        for (final e in _episodes)
          if (!e.inList) e
      ];

  void _toggleAll() {
    final addable = _addable;
    setState(() {
      _message = null;
      if (_selected.length == addable.length || _selected.length >= maxPerAdd) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(addable.take(maxPerAdd).map((e) => e.episode));
      }
    });
  }

  Future<void> _add() async {
    final season = _season;
    if (season == null || _selected.isEmpty || _adding) return;
    final picked = (_selected.toList()..sort());
    setState(() {
      _adding = true;
      _message = null;
    });
    final error = await _store.addEpisodes(widget.show.tmdbId, season, picked);
    if (!mounted) return;
    setState(() {
      _adding = false;
      if (error == null) {
        for (final e in _episodes) {
          if (picked.contains(e.episode)) e.inList = true;
        }
        _selected.clear();
      }
      _message = error ??
          '${widget.show.title}: ${picked.length} bölüm listeye eklendi 📺';
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          if (_info != null && _info!.seasons.isNotEmpty) _seasonChips(),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
              child: Text(_message!,
                  key: const ValueKey('episode-message'),
                  style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
            ),
          Expanded(child: _body()),
          _addBar(),
        ],
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 16, 8),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('episode-back'),
              tooltip: 'Aramaya dön',
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 34,
                height: 51,
                child: FilmPoster(
                    url: widget.show.posterUrl, title: widget.show.title),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.show.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sheetTitle.copyWith(fontSize: 19)),
                  Text(
                    [
                      '📺 Dizi',
                      if (widget.show.year != null) '${widget.show.year}',
                      'bölüm seç',
                    ].join(' · '),
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _seasonChips() => SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          children: [
            for (final s in _info!.seasons)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  key: ValueKey('season-${s.season}'),
                  label: Text(s.label),
                  selected: _season == s.season,
                  onSelected: (_) {
                    if (_season != s.season) _loadSeason(s.season);
                  },
                  showCheckmark: false,
                  labelStyle: TextStyle(
                      color: _season == s.season
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700),
                  selectedColor: AppTheme.accent,
                  backgroundColor: AppTheme.surface,
                  side: BorderSide(
                      color: _season == s.season
                          ? AppTheme.accent
                          : AppTheme.border,
                      width: .8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      );

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (_error != null) return _hint('😿', _error!);
    if (_info != null && _info!.seasons.isEmpty) {
      return _hint('📺', 'Bu dizinin bölüm bilgisi yok.');
    }
    if (_episodes.isEmpty) return _hint('📺', 'Bu sezonda bölüm yok.');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: _episodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _tile(_episodes[i]),
    );
  }

  Widget _hint(String emoji, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 8),
              Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );

  Widget _tile(EpisodeResult e) {
    final selected = _selected.contains(e.episode);
    final meta = [
      if (e.englishTitle != null) e.englishTitle!,
      if (e.runtime != null) runtimeText(e.runtime!),
      if (e.tmdbRating != null) 'TMDB %${(e.tmdbRating! * 10).round()}',
    ].join(' · ');
    return Material(
      color:
          selected ? AppTheme.accent.withValues(alpha: .14) : AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('episode-${e.episode}'),
        onTap: e.inList ? null : () => _toggle(e),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 54,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FilmPoster(url: e.stillUrl, title: e.title),
                      Positioned(
                        left: 4,
                        top: 4,
                        child: EpisodeBadge(code: 'B${e.episode}'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700)),
                    if (meta.isNotEmpty)
                      Text(meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (e.inList)
                const Text('Listede ✓',
                    style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700))
              else
                Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? AppTheme.accent : AppTheme.textMuted,
                    size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addBar() {
    final addable = _addable;
    if (_loading || addable.isEmpty) return const SizedBox(height: 8);
    final all =
        _selected.length == addable.length || _selected.length >= maxPerAdd;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Flexible(
            child: TextButton(
              key: const ValueKey('episode-select-all'),
              onPressed: _adding ? null : _toggleAll,
              child: Text(all ? 'Seçimi temizle' : 'Hepsini seç',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              key: const ValueKey('episode-add'),
              onPressed: _selected.isEmpty || _adding ? null : _add,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
              icon: _adding
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_rounded),
              label: Text(
                  _selected.isEmpty
                      ? 'Bölüm seç'
                      : '${_selected.length} bölümü ekle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
