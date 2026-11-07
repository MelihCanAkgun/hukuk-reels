import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/pixel_logo.dart';
import 'film_store.dart';
import 'film_widgets.dart';

/// "Bu akşam ne izlesek? 🎲": afişler hızla döner, yavaşlar ve bir filmde
/// durur. Seçilen film döner (detayı açmak için); vazgeçilirse null.
Future<Film?> showFilmRoulette(BuildContext context, List<Film> pool,
        {Random? random}) =>
    showDialog<Film>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .7),
      builder: (_) => FilmRoulette(pool: pool, random: random),
    );

class FilmRoulette extends StatefulWidget {
  const FilmRoulette({super.key, required this.pool, this.random});

  final List<Film> pool;
  final Random? random;

  @override
  State<FilmRoulette> createState() => _FilmRouletteState();
}

class _FilmRouletteState extends State<FilmRoulette> {
  late final Random _random = widget.random ?? Random();
  Timer? _timer;
  int _index = 0, _step = 0;
  bool _done = false;

  static const _steps = 22;

  @override
  void initState() {
    super.initState();
    _spin();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _spin() {
    _timer?.cancel();
    setState(() {
      _step = 0;
      _done = false;
      _index = _random.nextInt(widget.pool.length);
    });
    _next();
  }

  /// Her adım biraz daha uzun sürer (60 ms → ~420 ms): çark yavaşlıyor.
  void _next() {
    if (_step >= _steps || widget.pool.length == 1) {
      setState(() => _done = true);
      return;
    }
    final t = _step / _steps;
    _timer = Timer(Duration(milliseconds: (60 + 360 * t * t).round()), () {
      if (!mounted) return;
      setState(() {
        _step++;
        // Art arda aynı afiş gelmesin (tek film yoksa).
        var n = _random.nextInt(widget.pool.length);
        if (n == _index) n = (n + 1) % widget.pool.length;
        _index = n;
      });
      _next();
    });
  }

  @override
  Widget build(BuildContext context) {
    final film = widget.pool[_index];
    return Dialog(
      backgroundColor: AppTheme.bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PixelLogo(kDiceSprite, size: 24),
                SizedBox(width: 8),
                Flexible(
                  child:
                      Text('Bu akşam ne izlesek?', style: AppTheme.sheetTitle),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: _done
                    ? [
                        BoxShadow(
                            color: AppTheme.accent.withValues(alpha: .55),
                            blurRadius: 24,
                            spreadRadius: 2)
                      ]
                    : const [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 170,
                  height: 255,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 90),
                    child: FilmPoster(
                        key: ValueKey(film.id),
                        url: film.posterUrl(),
                        title: film.title),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (film.isEpisode)
              Text('📺 ${film.showTitle ?? 'Dizi'} · ${film.episodeCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: _done ? AppTheme.accent : AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            Text(
              film.title,
              key: const ValueKey('roulette-title'),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: _done ? AppTheme.textPrimary : AppTheme.textMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 20,
              child: _done
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RatingBadges(film: film),
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('roulette-again'),
                    onPressed: _done && widget.pool.length > 1 ? _spin : null,
                    child: const Text('Tekrar 🎲'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('roulette-pick'),
                    onPressed:
                        _done ? () => Navigator.of(context).pop(film) : null,
                    child: const Text('Bunu izleyelim!'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
