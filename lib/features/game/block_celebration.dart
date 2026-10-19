import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/pixel_text.dart';

/// Presentation only: ranks never change the scoring or block generator.
class BlockCelebrationData {
  final String title;
  final int combo, points;
  final Color color;
  final bool legendary;
  const BlockCelebrationData(this.title, this.combo, this.points, this.color,
      {this.legendary = false});

  factory BlockCelebrationData.forClear(
      {required int combo,
      required int lines,
      required int points,
      required bool allClear}) {
    if (combo >= 6 || lines >= 4) {
      return BlockCelebrationData('SSS', combo, points, const Color(0xFFFFD568),
          legendary: true);
    }
    if (allClear) {
      return BlockCelebrationData(
          'PERFECT!', combo, points, const Color(0xFF80F8EE));
    }
    if (combo >= 4 || lines >= 3) {
      return BlockCelebrationData(
          'SUPER!', combo, points, const Color(0xFFCFA0FF));
    }
    return BlockCelebrationData(
        'COMBO!', combo, points, const Color(0xFF8CCBFF));
  }
}

/// Paint-only celebration. It never intercepts a drag or locks the game.
class BlockCelebration extends StatefulWidget {
  final BlockCelebrationData data;
  final bool compact;
  const BlockCelebration({super.key, required this.data, this.compact = false});
  @override
  State<BlockCelebration> createState() => _BlockCelebrationState();
}

class _BlockCelebrationState extends State<BlockCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // Görüntü ~30 kare/sn değişir; ekran 60/120 Hz yenilense de yalnız kare
  // değişince yeniden çizilir.
  final _frame = ValueNotifier<int>(0);
  bool _finished = false;
  _CelebrationPainter? _painter;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..addListener(() => _frame.value =
          _CelebrationPainter.frameAt(_controller.value, _controller.duration!))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _finished = true);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _frame.dispose();
    _painter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      _painter?.dispose();
      _painter = null;
      return const SizedBox.shrink();
    }
    final reduced = MediaQuery.disableAnimationsOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (_painter == null ||
        _painter!.data != widget.data ||
        _painter!.compact != widget.compact ||
        _painter!.reducedMotion != reduced ||
        _painter!.dpr != dpr) {
      _painter?.dispose();
      _painter = _CelebrationPainter(_controller, _frame, widget.data,
          reducedMotion: reduced,
          compact: widget.compact,
          dpr: dpr,
          duration: _controller.duration!);
    }
    return IgnorePointer(
        child: Semantics(
      label:
          '${widget.data.title}, kombo ${widget.data.combo}, ${widget.data.points} puan',
      child: RepaintBoundary(
          child: CustomPaint(
        painter: _painter,
        child: const SizedBox.expand(),
      )),
    ));
  }
}

/// Piksel-art ödül yazısı. Hareket 30 kare/sn adımlarla ilerler (retro
/// his): basamaklı büyüme, harf dalgası, kare parçacıklar, kırpışan
/// yıldızlar ve sonunda yanıp sönerek kaybolma.
class _CelebrationPainter extends CustomPainter {
  final Animation<double> animation;
  final ValueListenable<int> frames;
  final BlockCelebrationData data;
  final bool reducedMotion, compact;
  final double dpr;
  final Duration duration;
  late final PixelTextLayout _title, _combo, _points;
  late final bool _perfect = data.title == 'PERFECT!';
  late final bool _wave = data.legendary || data.title == 'SUPER!';
  _CelebrationPainter(this.animation, this.frames, this.data,
      {required this.reducedMotion,
      required this.compact,
      required this.dpr,
      required this.duration})
      : super(repaint: reducedMotion ? null : frames) {
    _title = PixelTextLayout(data.title, color: data.color);
    _combo = PixelTextLayout('KOMBO ×${data.combo}', color: data.color);
    _points = PixelTextLayout('+${data.points}', color: _gold);
  }

  static const _gold = Color(0xFFFFD568);
  static const _rainbow = [_gold, Color(0xFFFF7EB6), Color(0xFF80F8EE)];
  static const _plate = Color(0xFF162645);
  // Basamaklı giriş: küçük → taşkın → yerine otur (kare kare).
  static const _pop = [0.6, 1.1, 1.0];

  static int frameAt(double t, Duration duration) =>
      (t * duration.inMilliseconds / 33).floor(); // ~30 kare/sn

  // Yazı ve levha bir kez görüntüye çizilir; her karede yalnız bu
  // görüntüler kopyalanır (yüzlerce küçük karelik yolu yeniden çizmek
  // iPhone'da sarsıntıyla birlikte takılmaya yol açıyordu).
  final Map<int, ui.Image> _letterImages = {};
  ui.Image? _plateImage;
  double _cachedTitlePx = 0, _cachedDetailPx = 0;
  final _imagePaint = Paint()..filterQuality = FilterQuality.none;

  void dispose() {
    for (final image in _letterImages.values) {
      image.dispose();
    }
    _letterImages.clear();
    _plateImage?.dispose();
    _plateImage = null;
  }

  void _prepare(double titlePx, double detailPx) {
    if (titlePx == _cachedTitlePx && detailPx == _cachedDetailPx) return;
    dispose();
    _cachedTitlePx = titlePx;
    _cachedDetailPx = detailPx;
    final u = detailPx, plateUnits = _combo.width + 3 + _points.width + 4;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    _plateAt(canvas, Offset.zero, u);
    final picture = recorder.endRecording();
    _plateImage = picture.toImageSync(
        ((plateUnits + 1) * u * dpr).ceil(), (15 * u * dpr).ceil());
    picture.dispose();
  }

  /// [tint] -1: harfin kendi rengi, 0..2: SSS'in gökkuşağı renkleri.
  ui.Image _letter(int i, int tint) => _letterImages.putIfAbsent(
      i * 4 + tint + 1,
      () => _title.letterImage(i, _cachedTitlePx, dpr,
          tint: tint < 0 ? null : _rainbow[tint]));

  void _image(Canvas canvas, ui.Image image, Offset at) {
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        at & Size(image.width / dpr, image.height / dpr),
        _imagePaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = reducedMotion ? 1.0 : animation.value;
    final frame = reducedMotion ? 999 : frameAt(t, duration);
    // Son %30'da yanıp sönerek çıkar; piksel oyunlarında solma olmaz.
    if (!reducedMotion && t >= 1) return;
    if (!reducedMotion && t > .7 && frame.isOdd) return;

    final titlePx = max(
        2.0,
        min(size.width * .55 / _title.width, data.legendary ? 6.0 : 4.0)
                .floorToDouble() *
            (compact ? 1 : 1.5));
    final plateUnits = _combo.width + 3 + _points.width + 4;
    final detailPx =
        max(1.0, min(2.0, (size.width * .82 / plateUnits).floorToDouble()));
    final titleW = _title.width * titlePx,
        titleH = PixelTextLayout.height * titlePx;
    final plateW = plateUnits * detailPx, plateH = 14 * detailPx;
    final badgeH = titleH + 2 * detailPx + plateH;
    final rise = reducedMotion ? 0.0 : min(frame ~/ 5, 3) * titlePx * .5;
    final cy = (size.height * (compact ? .2 : .42) - rise)
        .clamp(badgeH / 2 + 4, max(badgeH / 2 + 4, size.height - badgeH / 2));
    final center = Offset((size.width / 2).roundToDouble(), cy.roundToDouble());
    _prepare(titlePx, detailPx);

    if (!reducedMotion) {
      _flash(canvas, size, frame);
      _burst(canvas, center, size, t, titlePx);
    }

    final scale = reducedMotion ? 1.0 : _pop[min(frame, _pop.length - 1)];
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    final top = (-badgeH / 2).roundToDouble();
    final left = (-titleW / 2).roundToDouble();
    for (var i = 0; i < _title.letterCount; i++) {
      final lift = _wave && !reducedMotion && sin(frame * .7 - i * 1.3) > .2;
      final tint = data.legendary && !reducedMotion
          ? (i + frame ~/ 4) % _rainbow.length
          : -1;
      _image(
          canvas,
          _letter(i, tint),
          Offset(left + _title.letterBox(i).left * titlePx,
              top - (lift ? titlePx : 0)));
    }
    _image(canvas, _plateImage!,
        Offset((-plateW / 2).roundToDouble(), top + titleH + 2 * detailPx));
    canvas.restore();

    if (!reducedMotion) {
      _sparkles(canvas, center, max(titleW, plateW) + titlePx * 2, badgeH,
          frame, max(2, titlePx * .5));
    }
  }

  /// Çentikli köşeli piksel levha: "KOMBO ×N  +puan".
  void _plateAt(Canvas canvas, Offset o, double u) {
    final w = (_combo.width + 3 + _points.width + 4) * u, h = 14 * u;
    final paint = Paint()..isAntiAlias = false;
    void notched(Rect r, Color color) {
      paint.color = color;
      canvas.drawRect(
          Rect.fromLTRB(r.left + u, r.top, r.right - u, r.bottom), paint);
      canvas.drawRect(
          Rect.fromLTRB(r.left, r.top + u, r.right, r.bottom - u), paint);
    }

    final outer = o & Size(w, h);
    notched(outer.shift(Offset(u, u)), const Color(0xFF070B18));
    notched(outer, Color.lerp(data.color, const Color(0xFF000000), .35)!);
    final inner = outer.deflate(u);
    notched(inner, _plate);
    paint.color = Color.lerp(_plate, data.color, .22)!;
    canvas.drawRect(
        Rect.fromLTWH(inner.left + u, inner.top, inner.width - 2 * u, u),
        paint);
    _combo.paint(canvas, o + Offset(2 * u, 2 * u), u);
    _points.paint(canvas, o + Offset((2 + _combo.width + 3) * u, 2 * u), u);
  }

  /// Büyük anlarda tahtayı bir an renge boyar (2-3 kare).
  void _flash(Canvas canvas, Size size, int frame) {
    if (!(data.legendary || _perfect) || frame > 1) return;
    final alpha = const [.26, .14, .05][frame];
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Color.lerp(data.color, const Color(0xFFFFFFFF), .5)!
              .withValues(alpha: alpha));
  }

  /// Merkezden saçılan kare parçacıklar + genişleyen piksel elmas halka.
  void _burst(Canvas canvas, Offset c, Size size, double t, double titlePx) {
    final cell = max(2.0, (titlePx * .6).roundToDouble());
    final reach = size.width * (compact ? .3 : .36);
    final paint = Paint()..isAntiAlias = false;
    Offset snap(Offset p) => Offset((p.dx / cell).roundToDouble() * cell,
        (p.dy / cell).roundToDouble() * cell);

    // Halka: elmasın kenarları boyunca aralıklı kareler.
    final ringT = (t / .35).clamp(0.0, 1.0);
    if (ringT < 1) {
      final r = reach * .3 + reach * .7 * Curves.easeOut.transform(ringT);
      final steps = max(8, (r / cell / 1.5).floor());
      paint.color = data.color.withValues(alpha: 1 - ringT * .6);
      for (var side = 0; side < 4; side++) {
        final a = side * pi / 2, b = a + pi / 2;
        for (var k = 0; k < steps; k += 2) {
          final f = k / steps;
          final p = c +
              Offset(cos(a) * (1 - f) + cos(b) * f,
                      sin(a) * (1 - f) + sin(b) * f) *
                  r;
          canvas.drawRect(snap(p) & Size(cell, cell), paint);
        }
      }
    }

    final count = data.legendary ? 18 : (_perfect ? 14 : 10);
    for (var i = 0; i < count; i++) {
      final life = .5 + (i % 4) * .1;
      final lt = t / life;
      if (lt >= 1 || (lt > .75 && (t * 60).floor().isOdd)) continue;
      final angle = i * 2 * pi / count + (i * 0.37) % .5;
      final dist =
          reach * (.45 + (i * 7 % 5) * .12) * Curves.easeOutCubic.transform(lt);
      final p = c +
          Offset(cos(angle) * dist, sin(angle) * dist + reach * .35 * lt * lt);
      final s = cell * (i % 3 == 0 ? 2 : 1);
      paint.color = switch (i % 3) {
        0 => const Color(0xFFFFFFFF),
        1 => data.color,
        _ => data.legendary ? _gold : Color.lerp(data.color, _plate, .3)!,
      };
      canvas.drawRect(snap(p) & Size(s, s), paint);
    }
  }

  /// Yazının çevresinde sırayla kırpışan artı biçimli yıldızlar.
  void _sparkles(
      Canvas canvas, Offset c, double w, double h, int frame, double u) {
    final paint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFFFFFFFF);
    final count = data.legendary ? 6 : 4;
    for (var i = 0; i < count; i++) {
      final phase = (frame + i * 3) % 8;
      if (phase >= 5) continue;
      final arm = const [0, 1, 2, 1, 0][phase].toDouble();
      final side = i.isEven ? -1 : 1;
      final p = c +
          Offset(side * (w / 2 + u * (2 + (i * 5) % 4)),
              -h / 2 + (i * 0.37 % 1) * h);
      final o = Offset(
          (p.dx / u).roundToDouble() * u, (p.dy / u).roundToDouble() * u);
      canvas.drawRect(o & Size(u, u), paint);
      for (var k = 1; k <= arm; k++) {
        for (final d in const [
          Offset(1, 0),
          Offset(-1, 0),
          Offset(0, 1),
          Offset(0, -1)
        ]) {
          canvas.drawRect((o + d * (k * u)) & Size(u, u), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) =>
      old.data != data ||
      old.reducedMotion != reducedMotion ||
      old.compact != compact ||
      old.dpr != dpr;
}
