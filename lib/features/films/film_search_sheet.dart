import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'film_episode_picker.dart';
import 'film_store.dart';
import 'film_widgets.dart';

/// Film ya da dizi bölümü ekleme: ad yazılır, afişli TMDB sonuçlarından film
/// seçilir; dizi seçilince sezon ve bölümler açılır.
Future<void> showFilmSearch(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.bgElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => const FractionallySizedBox(
        heightFactor: .92,
        child: FilmSearch(),
      ),
    );

class FilmSearch extends StatefulWidget {
  const FilmSearch({super.key});

  @override
  State<FilmSearch> createState() => _FilmSearchState();
}

class _FilmSearchState extends State<FilmSearch> {
  final _store = FilmStore.instance;
  final _query = TextEditingController();
  Timer? _debounce;
  List<FilmSearchResult> _results = const [];
  String? _error, _message;
  bool _searching = false;
  int _generation = 0;
  final Set<int> _adding = {};

  /// Bölüm seçimi açık olan dizi.
  FilmSearchResult? _show;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  /// Yazmayı bırakınca (450 ms) arar; eski isteklerin cevabı yok sayılır.
  void _changed(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.isEmpty) {
      _generation++;
      setState(() {
        _results = const [];
        _error = null;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(q));
  }

  Future<void> _search(String q) async {
    final gen = ++_generation;
    setState(() => _searching = true);
    final r = await _store.search(q.length > 80 ? q.substring(0, 80) : q);
    if (!mounted || gen != _generation) return;
    setState(() {
      _searching = false;
      _results = r.results;
      _error = r.error;
    });
  }

  Future<void> _add(FilmSearchResult m) async {
    if (m.isShow) {
      setState(() {
        _show = m;
        _message = null;
      });
      return;
    }
    if (m.inList || _adding.contains(m.tmdbId)) return;
    setState(() {
      _adding.add(m.tmdbId);
      _message = null;
    });
    final error = await _store.add(m.tmdbId);
    if (!mounted) return;
    setState(() {
      _adding.remove(m.tmdbId);
      if (error == null || error == 'Bu film zaten listede.') m.inList = true;
      _message = error ?? '"${m.title}" listeye eklendi 🎬';
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.fromLTRB(0, 10, 0, 12),
                decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (_show != null)
              Expanded(
                child: EpisodePicker(
                  key: ValueKey('picker-${_show!.tmdbId}'),
                  show: _show!,
                  onBack: () => setState(() => _show = null),
                ),
              )
            else ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child:
                    Text('Film ya da dizi ekle 🍿', style: AppTheme.sheetTitle),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: TextField(
                  key: const ValueKey('film-search-field'),
                  controller: _query,
                  autofocus: true,
                  maxLength: 80,
                  onChanged: _changed,
                  onSubmitted: (q) {
                    _debounce?.cancel();
                    if (q.trim().isNotEmpty) _search(q.trim());
                  },
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Film ya da dizi adı (Türkçe/İngilizce)',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textSecondary),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppTheme.accent)),
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
                  child: Text(_message!,
                      key: const ValueKey('film-search-message'),
                      style: const TextStyle(
                          color: AppTheme.accent, fontSize: 13)),
                ),
              Expanded(child: _body()),
            ],
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
              ),
            ),
          ],
        ),
      );

  Widget _body() {
    if (_error != null) return _hint('😿', _error!);
    if (_results.isEmpty) {
      return _query.text.trim().isEmpty || _searching
          ? _hint('🎞️',
              'İzlemek istediğiniz filmin ya da dizinin adını yazın.\nDizide bölümleri tek tek seçersiniz.')
          : _hint('🔍', 'Sonuç bulunamadı. Başka bir ad dene.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _tile(_results[i]),
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

  Widget _tile(FilmSearchResult m) {
    final adding = _adding.contains(m.tmdbId);
    final sub = [
      if (m.isShow) '📺 Dizi',
      if (m.englishTitle != null) m.englishTitle!,
      if (m.originalTitle.isNotEmpty && m.originalTitle != m.title)
        m.originalTitle,
      if (m.year != null) '${m.year}',
    ].join(' · ');
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('film-result-${m.tmdbId}'),
        onTap: m.inList ? null : () => _add(m),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52,
                  height: 78,
                  child: FilmPoster(url: m.posterUrl, title: m.title),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    if (sub.isNotEmpty)
                      Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12.5)),
                    if (m.tmdbRating != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text('TMDB %${(m.tmdbRating! * 10).round()}',
                            style: const TextStyle(
                                color: kTmdbGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (adding)
                const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: AppTheme.accent))
              else if (m.isShow)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.accent, size: 30),
                    if (m.listedEpisodes > 0)
                      Text('${m.listedEpisodes} bölüm\nlistede',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.success,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700)),
                  ],
                )
              else if (m.inList)
                const Text('Listede ✓',
                    style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700))
              else
                const Icon(Icons.add_circle_rounded,
                    color: AppTheme.accent, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}
