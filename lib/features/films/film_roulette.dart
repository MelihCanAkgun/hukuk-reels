import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/pixel_logo.dart';
import 'film_reviews.dart';
import 'film_store.dart';
import 'film_widgets.dart';

/// "Bu akşam ne izlesek? 🎲": slot makinesi gibi afiş şeridi hızla döner,
/// yavaşlar ve bir yapımda durur. "Bunu izleyelim!" seçilen yapımı döndürür
/// (detayı açmak için); "Tekrar karıştır" yeniden döndürür; sağ üstteki ✕
/// ya da dışarı dokunmak hiçbir şey yapmadan kapatır (null).
Future<Film?> showFilmRoulette(BuildContext context, List<Film> pool,
        {Random? random}) =>
    showDialog<Film>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .75),
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

  Film _at(int offset) {
    final n = widget.pool.length;
    return widget.pool[((_index + offset) % n + n) % n];
  }

  @override
  Widget build(BuildContext context) {
    final film = widget.pool[_index];
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: arcadePanel(
            color: AppTheme.bgElevated,
            border: AppTheme.accent,
            shadow: const Color(0xFF8C1D4A),
            radius: 8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(),
                _reel(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: _info(film),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: _actions(film),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppTheme.border, width: 1.5)),
        ),
        child: Row(
          children: [
            const PixelLogo(kDiceSprite, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bu akşam ne izlesek?',
                      style: AppTheme.sheetTitle.copyWith(fontSize: 19)),
                  Text('${widget.pool.length} yapım arasından',
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('roulette-close'),
              tooltip: 'Kapat',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded,
                  color: AppTheme.textSecondary, size: 24),
            ),
          ],
        ),
      );

  /// Ortada büyük afiş, iki yanda soluk komşular; altta piksel ok.
  Widget _reel() {
    final film = widget.pool[_index];
    final sides = widget.pool.length >= 3;
    Widget side(Film f, Alignment a) => Align(
          alignment: a,
          child: Opacity(
            opacity: .28,
            child: Container(
              width: 92,
              height: 138,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.border, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 90),
                  child: FilmPoster(
                      key: ValueKey(f.id), url: f.posterUrl('w154'), title: ''),
                ),
              ),
            ),
          ),
        );
    return Container(
      height: 270,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: .9,
          colors: [
            AppTheme.accent.withValues(alpha: _done ? .22 : .08),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (sides) ...[
            side(_at(-1), const Alignment(-.95, 0)),
            side(_at(1), const Alignment(.95, 0)),
          ],
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 150,
            height: 225,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: _done ? const Color(0xFFFFC2D8) : AppTheme.border,
                  width: 2),
              boxShadow: [
                const BoxShadow(color: Color(0xFF0B0408), offset: Offset(4, 4)),
                if (_done)
                  BoxShadow(
                      color: AppTheme.accent.withValues(alpha: .6),
                      blurRadius: 28,
                      spreadRadius: 2),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 90),
                transitionBuilder: (c, a) => SlideTransition(
                  position:
                      Tween(begin: const Offset(0, -.25), end: Offset.zero)
                          .animate(a),
                  child: FadeTransition(opacity: a, child: c),
                ),
                child: FilmPoster(
                    key: ValueKey(film.id),
                    url: film.posterUrl(),
                    title: film.title),
              ),
            ),
          ),
          if (_done)
            Positioned(
              top: 14,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .4, end: 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.elasticOut,
                builder: (_, s, child) =>
                    Transform.scale(scale: s, child: child),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppTheme.pinkGradient,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFFFC2D8)),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF8C1D4A), offset: Offset(2, 2))
                    ],
                  ),
                  child: const Text('SEÇİLDİ!',
                      style: TextStyle(
                          fontFamily: AppTheme.pixelFont,
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          const Positioned(bottom: 2, child: _Pointer()),
        ],
      ),
    );
  }

  Widget _info(Film film) {
    final store = FilmStore.instance;
    final meta = [
      if (film.year != null) '${film.year}',
      if (film.runtime != null) runtimeText(film.runtime!),
      ...film.genres.take(2),
    ].join(' · ');
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _done ? 1 : .45,
      child: Column(
        children: [
          if (film.isEpisode)
            Text('📺 ${film.showTitle ?? 'Dizi'} · ${film.episodeCode}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          Text(
            film.title,
            key: const ValueKey('roulette-title'),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontFamily: AppTheme.pixelFont,
                color: AppTheme.textPrimary,
                fontSize: 22,
                height: 1.15,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(_done ? meta : 'Karıştırılıyor…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: _done
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RatingBadges(film: film),
                        ),
                      ),
                      if (film.providers.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ProviderLogos(
                            providers: film.providers.take(3).toList(),
                            size: 22),
                      ],
                    ],
                  )
                : null,
          ),
          if (_done) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlayerAvatar(id: film.addedBy, size: 18, ring: false),
                const SizedBox(width: 6),
                Text('${store.nameOf(film.addedBy)} eklemişti',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actions(Film film) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArcadeButton(
            key: const ValueKey('roulette-pick'),
            label: 'Bunu izleyelim!',
            big: true,
            onTap: _done ? () => Navigator.of(context).pop(film) : null,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('roulette-again'),
            onPressed: _done && widget.pool.length > 1 ? _spin : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              minimumSize: const Size.fromHeight(46),
              side: const BorderSide(color: AppTheme.border, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            icon: const PixelLogo(kDiceSprite, size: 18),
            label: const Text('Tekrar karıştır',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      );
}

/// Seçimi gösteren piksel ok (yukarı bakan üçgen).
class _Pointer extends StatelessWidget {
  const _Pointer();

  @override
  Widget build(BuildContext context) => const SizedBox(
      width: 22, height: 12, child: CustomPaint(painter: _PointerPainter()));
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.width / 11;
    final paint = Paint()
      ..isAntiAlias = false
      ..color = AppTheme.accent;
    final h = size.height / 6;
    for (var row = 0; row < 6; row++) {
      canvas.drawRect(
          Rect.fromLTWH((5 - row) * px, row * h, (2 * row + 1) * px, h + .35),
          paint);
    }
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}
