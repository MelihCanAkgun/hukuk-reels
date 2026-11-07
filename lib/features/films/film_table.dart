import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'film_detail_sheet.dart';
import 'film_reviews.dart';
import 'film_store.dart';
import 'film_widgets.dart';

/// Puan tablomuz: izlendi işaretli bütün film ve bölümler, yanlarında
/// ikimizin ayrı ayrı verdiği kalpler. Son eklenen ya da en yüksek puan
/// sırası; satıra dokununca yorumlar ve yanıtlarla birlikte detay açılır.
class FilmTable extends StatefulWidget {
  const FilmTable({super.key, required this.gutter});

  final double gutter;

  @override
  State<FilmTable> createState() => _FilmTableState();
}

class _FilmTableState extends State<FilmTable> {
  final _store = FilmStore.instance;
  bool _byScore = false;

  static const _cell = 64.0;

  @override
  Widget build(BuildContext context) {
    final rows = _store.table(byScore: _byScore);
    final players = _store.players.keys.toList()..sort();
    final g = widget.gutter;
    return CustomScrollView(
      primary: true,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(g, 4, g, 10),
            child: _summary(rows, players),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(g, 0, g, 10),
            child: _sortToggle(),
          ),
        ),
        if (rows.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(36),
              child: Text(
                'Tablo boş. Bir film izleyip "İzledik ✓" deyin, puanlarınız burada yan yana dursun 🍿',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14.5, height: 1.4),
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(g, 0, g, 0),
              child: _headerRow(players),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(g, 0, g, 0),
            sliver: SliverList.builder(
              itemCount: rows.length,
              itemBuilder: (context, i) => _row(rows[i], i, players),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }

  Widget _summary(List<FilmTableRow> rows, List<int> players) {
    final films = rows.where((r) => !r.film.isEpisode).length;
    final episodes = rows.length - films;
    String avg(int p) {
      final mine = [
        for (final r in rows)
          if (r.ratings[p] != null) r.ratings[p]!.halves
      ];
      if (mine.isEmpty) return '–';
      final a = mine.reduce((x, y) => x + y) / mine.length / 2;
      return a.toStringAsFixed(1).replaceAll('.', ',');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: arcadePanel(
        color: AppTheme.surface,
        border: AppTheme.accent.withValues(alpha: .7),
        shadow: const Color(0xFF8C1D4A),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${rows.length}',
                    key: const ValueKey('film-table-count'),
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    '${[
                      if (films > 0) '$films film',
                      if (episodes > 0) '$episodes bölüm',
                      if (rows.isEmpty) 'yapım',
                    ].join(' · ')} izledik',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          for (final p in players)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                children: [
                  PlayerAvatar(id: p, size: 30, ring: false),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PixelHeart(size: 12),
                      const SizedBox(width: 4),
                      Text(avg(p),
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Text('ortalama',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sortToggle() => Container(
        padding: const EdgeInsets.all(3),
        decoration: arcadePanel(color: AppTheme.bgElevated),
        child: Row(
          children: [
            _sortTab('Son eklenen', false),
            _sortTab('En yüksek puan', true),
          ],
        ),
      );

  Widget _sortTab(String label, bool byScore) {
    final on = _byScore == byScore;
    return Expanded(
      child: GestureDetector(
        key: ValueKey(byScore ? 'film-table-score' : 'film-table-recent'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _byScore = byScore),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: on ? AppTheme.pinkGradient : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: on ? Colors.white : AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _headerRow(List<int> players) => Container(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.accent, width: 2)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 30,
              child: Text('#',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ),
            const Expanded(
              child: Text('YAPIM',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      letterSpacing: 1)),
            ),
            for (final p in players)
              SizedBox(
                width: _cell,
                child: Text(_store.nameOf(p).toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        letterSpacing: .6)),
              ),
          ],
        ),
      );

  Widget _row(FilmTableRow row, int i, List<int> players) {
    final film = row.film;
    final talk =
        _store.ratingsOf(film.id).where((r) => r.comment.isNotEmpty).length +
            _store.replies.where((r) => r.film == film.id).length;
    final top = _byScore && i < 3 && row.average != null;
    return InkWell(
      key: ValueKey('film-table-${film.id}'),
      onTap: () => showFilmDetail(context, film.id, reviewsFirst: true),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        decoration: BoxDecoration(
          color: i.isOdd ? AppTheme.surface.withValues(alpha: .45) : null,
          border: const Border(
              bottom: BorderSide(color: AppTheme.border, width: .8)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                  _byScore
                      ? '${i + 1}'
                      : '${film.watched!.day.toString().padLeft(2, '0')}\n'
                          '${_months[film.watched!.month - 1]}',
                  style: TextStyle(
                      color: top ? AppTheme.accent : AppTheme.textSecondary,
                      fontSize: _byScore ? (top ? 20 : 16) : 12,
                      height: 1.1,
                      fontWeight: FontWeight.w700)),
            ),
            Container(
              width: 40,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                    color: top ? AppTheme.accent : AppTheme.border, width: 1.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: FilmPoster(url: film.posterUrl('w154'), title: ''),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (film.isEpisode)
                    Text('${film.showTitle ?? 'Dizi'} · ${film.episodeCode}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.accent, fontSize: 11.5)),
                  Text(film.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          height: 1.15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                      [
                        if (film.year != null) '${film.year}',
                        if (talk > 0) '💬 $talk',
                      ].join('  '),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            for (final p in players)
              SizedBox(
                width: _cell,
                child: Center(
                  child: row.ratings[p] == null
                      ? const Text('–',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 16))
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HeartScore(
                                key: ValueKey('film-table-${film.id}-$p'),
                                halves: row.ratings[p]!.halves,
                                size: 14),
                            const SizedBox(height: 4),
                            _MiniHearts(halves: row.ratings[p]!.halves),
                          ],
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _months = [
  'OCA', 'ŞUB', 'MAR', 'NİS', 'MAY', 'HAZ', //
  'TEM', 'AĞU', 'EYL', 'EKİ', 'KAS', 'ARA',
];

/// Hücredeki 5 küçük kalp (yarımlar dahil).
class _MiniHearts extends StatelessWidget {
  const _MiniHearts({required this.halves});
  final int halves;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(right: 1.5),
              child: PixelHeart(size: 9, fill: (halves - i * 2).clamp(0, 2)),
            ),
        ],
      );
}
