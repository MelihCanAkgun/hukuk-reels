import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/pixel_logo.dart';
import '../../core/widgets/pressable.dart';
import '../profile/profile_avatar.dart';
import 'film_store.dart';
import '../../core/services/engine_bridge.dart';

const kImdbYellow = Color(0xFFF5C518);
const kTmdbGreen = Color(0xFF01D277);

/// "Bu akşam ne izlesek?" düğmesinin piksel zarı.
const kDiceSprite = [
  '.kkkkkkkkkk.',
  'kWWWWWWWWWWk',
  'kWqqWWWWqqWk',
  'kWqqWWWWqqWk',
  'kWWWWWWWWWWk',
  'kWWWWqqWWWWk',
  'kWWWWqqWWWWk',
  'kWWWWWWWWWWk',
  'kWqqWWWWqqWk',
  'kWqqWWWWqqWk',
  'kWWWWWWWWWWk',
  '.kkkkkkkkkk.',
];

/// Oyuncunun profil fotoğrafı: kendimizse profildeki fotoğraf, diğer
/// oyuncuysa eşitlenen fotoğrafı (ikisi de yoksa baş harf).
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar(
      {super.key, required this.id, required this.size, this.ring = true});

  final int id;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final store = FilmStore.instance;
    return id == store.me
        ? ProfileAvatar(size: size, ring: ring)
        : PeerAvatar(id: id, name: store.nameOf(id), size: size, ring: ring);
  }
}

/// Afiş; yoksa ya da yüklenemezse film şeridi deseni ve baş harf.
class FilmPoster extends StatelessWidget {
  const FilmPoster({super.key, required this.url, required this.title});

  final String? url;
  final String title;

  @override
  Widget build(BuildContext context) {
    // Küçük kutuda (arama sonucu) yalnız 🎬, büyükte film adıyla.
    final placeholder = LayoutBuilder(
      builder: (_, box) => Container(
        color: AppTheme.surfaceHigh,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: box.maxHeight < 120
            ? const FittedBox(child: Text('🎬', style: TextStyle(fontSize: 26)))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎬', style: TextStyle(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 3,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
    final u = url;
    if (u == null) return placeholder;
    // Afiş kutunun piksel genişliğinde çözülür: liste kaydırırken büyük
    // dokular taşınmaz, bellek ve çözme süresi azalır.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (_, box) => Image.network(
        u,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        cacheWidth: box.maxWidth.isFinite && box.maxWidth > 0
            ? decodeWidth(box.maxWidth * dpr)
            : null,
        errorBuilder: (_, __, ___) => placeholder,
        frameBuilder: (_, child, frame, sync) => sync || frame != null
            ? child
            : Container(color: AppTheme.surfaceHigh),
      ),
    );
  }
}

/// IMDb ⭐ 8.8 ve TMDB %84 rozetleri.
class RatingBadges extends StatelessWidget {
  const RatingBadges({super.key, required this.film, this.large = false});

  final Film film;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final imdb = film.imdbRating, tmdb = film.tmdbRating;
    if (imdb == null && tmdb == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (imdb != null)
          _Badge(
              label: 'IMDb',
              value: '⭐ ${imdb.toStringAsFixed(1)}',
              color: kImdbYellow,
              ink: Colors.black,
              large: large),
        if (tmdb != null)
          _Badge(
              label: 'TMDB',
              value: '%${(tmdb * 10).round()}',
              color: kTmdbGreen,
              ink: const Color(0xFF032541),
              large: large),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.label,
      required this.value,
      required this.color,
      required this.ink,
      required this.large});

  final String label, value;
  final Color color, ink;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 13.0 : 10.5;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 8 : 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .55), width: .8),
      ),
      child: Text.rich(
        TextSpan(children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3)),
              child: Text(label,
                  style: TextStyle(
                      color: ink,
                      fontSize: size - 1.5,
                      fontWeight: FontWeight.w900,
                      height: 1.25)),
            ),
          ),
          TextSpan(text: value),
        ]),
        style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: size,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Platform logoları (TMDB, Türkiye abonelik platformları).
class ProviderLogos extends StatelessWidget {
  const ProviderLogos(
      {super.key, required this.providers, this.size = 20, this.max = 3});

  final List<FilmProvider> providers;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in providers.take(max))
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: p.name,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(size * .25),
                  child: SizedBox.square(
                    dimension: size,
                    child: p.logoUrl == null
                        ? Container(
                            color: AppTheme.surfaceHigh,
                            alignment: Alignment.center,
                            child: Text(p.name.characters.first,
                                style: TextStyle(
                                    fontSize: size * .5,
                                    color: AppTheme.textPrimary)),
                          )
                        : Image.network(p.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: AppTheme.surfaceHigh)),
                  ),
                ),
              ),
            ),
        ],
      );
}

/// Arcade can kalbi (10×9 piksel). Sol yarı ve sağ yarı ayrı dolar: yarım
/// kalp sol yarısı pembe, sağ yarısı boş görünür.
const _heartSprite = [
  '.kkk..kkk.',
  'kwwrk.krrk',
  'kwrrrkrrdk',
  'krrrrrrrdk',
  'krrrrrrrdk',
  '.krrrrrdk.',
  '..krrrdk..',
  '...krdk...',
  '....kk....',
];

const _heartFull = {
  'k': Color(0xFF6E0F35),
  'w': Color(0xFFFFE0EC),
  'r': Color(0xFFFF5C95),
  'd': Color(0xFFC7245F),
};
const _heartEmpty = {
  'k': Color(0xFF6B4A5C),
  'w': Color(0xFF3F2635),
  'r': Color(0xFF2E1825),
  'd': Color(0xFF24121C),
};

/// Tek piksel kalp: [fill] 0 boş, 1 yarım (sol yarı), 2 dolu.
class PixelHeart extends StatelessWidget {
  const PixelHeart({super.key, this.fill = 2, this.size = 16});

  final int fill;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size * .9,
        child: CustomPaint(painter: _HeartPainter(fill)),
      );
}

class _HeartPainter extends CustomPainter {
  const _HeartPainter(this.fill);
  final int fill;

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.width / 10;
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < _heartSprite.length; y++) {
      final row = _heartSprite[y];
      for (var x = 0; x < row.length; x++) {
        final ch = row[x];
        if (ch == '.') continue;
        final full = fill >= 2 || (fill == 1 && x < 5);
        paint.color = (full ? _heartFull : _heartEmpty)[ch]!;
        canvas.drawRect(
            Rect.fromLTWH(x * px, y * px, px + .35, px + .35), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HeartPainter old) => old.fill != fill;
}

/// 5 piksel kalp; [halves] yarım kalp cinsinden puan (0–10). [onChanged]
/// verilirse kalbin sol yarısına dokunmak yarım, sağ yarısına dokunmak tam
/// puan verir; parmağı kaydırarak da seçilir.
class HeartRow extends StatelessWidget {
  const HeartRow(
      {super.key, required this.halves, this.onChanged, this.size = 16});

  final int halves;
  final ValueChanged<int>? onChanged;
  final double size;

  static const _gap = .22;

  @override
  Widget build(BuildContext context) {
    final step = size * (1 + _gap);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) SizedBox(width: size * _gap),
          PixelHeart(
            key: ValueKey('heart-${i + 1}'),
            size: size,
            fill: (halves - i * 2).clamp(0, 2),
          ),
        ],
      ],
    );
    final change = onChanged;
    if (change == null) return row;
    int at(double dx) {
      final i = (dx / step).floor().clamp(0, 4);
      final inHeart = (dx - i * step) / size;
      return (i * 2 + (inHeart < .5 ? 1 : 2)).clamp(1, 10);
    }

    void pick(double dx) {
      final v = at(dx);
      if (v != halves) change(v);
    }

    return Semantics(
      slider: true,
      label: 'Puan',
      value: '${heartsText(halves)} kalp',
      increasedValue: '${heartsText((halves + 1).clamp(1, 10))} kalp',
      decreasedValue: '${heartsText((halves - 1).clamp(1, 10))} kalp',
      onIncrease: () => change((halves + 1).clamp(1, 10)),
      onDecrease: () => change((halves - 1).clamp(1, 10)),
      child: GestureDetector(
        key: const ValueKey('heart-picker'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => pick(d.localPosition.dx),
        onHorizontalDragStart: (d) => pick(d.localPosition.dx),
        onHorizontalDragUpdate: (d) => pick(d.localPosition.dx),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: row,
        ),
      ),
    );
  }
}

/// Küçük puan rozeti: piksel kalp ve "3,5".
class HeartScore extends StatelessWidget {
  const HeartScore({super.key, required this.halves, this.size = 12});

  final int halves;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixelHeart(size: size, fill: halves >= 2 ? 2 : 1),
          SizedBox(width: size * .3),
          Text(heartsText(halves),
              style: TextStyle(
                  fontFamily: AppTheme.pixelFont,
                  color: AppTheme.textPrimary,
                  fontSize: size + 1,
                  height: 1,
                  fontWeight: FontWeight.w700)),
        ],
      );
}

/// Izgaradaki film/bölüm kartı: afiş üstte (platformlar, ekleyen ve bölümde
/// "S3:B1" üzerinde), bilgiler altta. İzlenenlerde iki kişinin kalp puanı
/// görünür.
class FilmCard extends StatelessWidget {
  const FilmCard({super.key, required this.film, required this.onTap});

  final Film film;
  final VoidCallback onTap;

  /// Kart yüksekliği = afiş (2:3) + bu bilgi alanı.
  static const infoHeight = 112.0;

  @override
  Widget build(BuildContext context) {
    final store = FilmStore.instance;
    final meta = [
      if (film.isEpisode)
        film.showTitle ?? 'Dizi'
      else if (film.year != null)
        '${film.year}',
      if (film.runtime != null) runtimeText(film.runtime!),
    ].join(' · ');
    return Pressable(
      key: ValueKey('film-${film.id}'),
      onTap: onTap,
      pressedScale: .97,
      child: Container(
        clipBehavior: Clip.antiAlias,
        // Arcade kart: köşeli, kalın çerçeve, yumuşatılmamış sert gölge.
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: film.isWatched
                  ? AppTheme.accent.withValues(alpha: .55)
                  : AppTheme.border,
              width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0xFF0B0408), offset: Offset(3, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FilmPoster(url: film.posterUrl(), title: film.title),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x99000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: PlayerAvatar(id: film.addedBy, size: 24),
                  ),
                  if (film.providers.isNotEmpty)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: ProviderLogos(providers: film.providers),
                    ),
                  if (film.isWatched)
                    const Positioned(
                      top: 6,
                      left: 6,
                      child: _WatchedTag(),
                    ),
                  if (film.episodeCode != null)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: EpisodeBadge(code: film.episodeCode!),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      film.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13.5,
                          height: 1.2,
                          fontWeight: FontWeight.w700),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11.5)),
                    ],
                    const Spacer(),
                    SizedBox(
                      height: 20,
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: RatingBadges(film: film),
                      ),
                    ),
                    const SizedBox(height: 4),
                    film.isWatched ? _hearts(store) : _addedLine(store),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addedLine(FilmStore store) => Text(
        '${store.nameOf(film.addedBy)} ekledi · '
        '${agoText(film.added, DateTime.now())}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
      );

  Widget _hearts(FilmStore store) {
    final rs = store.ratingsOf(film.id);
    if (rs.isEmpty) {
      return const Text('Puan bekliyor 🍿',
          maxLines: 1,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11));
    }
    return Row(
      children: [
        for (final r in rs) ...[
          PlayerAvatar(id: r.player, size: 15, ring: false),
          const SizedBox(width: 3),
          HeartScore(halves: r.halves, size: 11),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

/// Afişin köşesindeki "S3:B1" etiketi (piksel yazı).
class EpisodeBadge extends StatelessWidget {
  const EpisodeBadge({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(6, 2, 6, 3),
        decoration: BoxDecoration(
          color: const Color(0xE6140C14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.accent.withValues(alpha: .7)),
        ),
        child: Text(code,
            style: const TextStyle(
                fontFamily: AppTheme.pixelFont,
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      );
}

class _WatchedTag extends StatelessWidget {
  const _WatchedTag();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('İzledik ✓',
            style: TextStyle(
                color: Color(0xFF07291C),
                fontSize: 10.5,
                fontWeight: FontWeight.w800)),
      );
}

/// Pixel zar düğmesi ("Bu akşam ne izlesek?").
class DiceButton extends StatelessWidget {
  const DiceButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        key: const ValueKey('film-dice'),
        onTap: onTap,
        semanticLabel: 'Bu akşam ne izlesek?',
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 11, 6),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accent.withValues(alpha: .5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PixelLogo(kDiceSprite, size: 22),
              SizedBox(width: 6),
              Text('Ne izlesek?',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}
