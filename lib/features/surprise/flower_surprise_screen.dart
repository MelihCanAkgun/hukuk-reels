import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/services/audio_service.dart';
import '../reels/widgets/music_button.dart';
import 'bouquet_sprite.dart';
import 'pixel_font.dart';

/// Daktilo efektiyle yazılan sürpriz mesajı.
const String kFlowerMessage =
    'Seni Seviyorum Ve Seni Çok Özledim Güzel Sevgilim';

/// Mesajın ekrandaki satırları (birleşince [kFlowerMessage] olur).
const List<String> kFlowerMessageLines = [
  'Seni Seviyorum Ve',
  'Seni Çok Özledim',
  'Güzel Sevgilim',
];

/// Sürpriz sırasında arkada çalan parça.
const String kFlowerSong = 'assets/audio/Wildflower.m4a';

/// Zaman çizelgesi (saniye). Katmanların açılış zamanları bouquet_sprite'ta.
class _T {
  static const pop = 0.16;
  static final double grown = kBouquetLayers
          .map((l) => l.start + l.dur)
          .reduce(max) +
      pop +
      0.05;
  static double get burst => grown - 0.15;
  static const burstDur = 0.9;
  static double get butterfly => grown + 0.5;
  static double get message => grown + 0.9;
  static const perChar = 0.075;
  static double get messageEnd =>
      message + (kFlowerMessageLines.join(' ').length) * perChar;
}

class _Px {
  final int x, y;
  final Color c;
  final double born;
  const _Px(this.x, this.y, this.c, this.born);
}

class _Heart {
  final Offset p0, v;
  final double born, size;
  const _Heart(this.p0, this.v, this.born, this.size);
}

/// Pixel art buket sürprizi: kağıt sarılır, yeşillikler çıkar, çiçekler
/// ortadan dışa piksel piksel açılır, fiyonk bağlanır, kelebek gelir, mesaj
/// harf harf yazılır. Bukete dokununca kalpler çıkar. Ekran her açılışta
/// animasyonu baştan oynatır.
class FlowerSurpriseScreen extends StatefulWidget {
  const FlowerSurpriseScreen({super.key});

  @override
  State<FlowerSurpriseScreen> createState() => _FlowerSurpriseScreenState();
}

class _FlowerSurpriseScreenState extends State<FlowerSurpriseScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _clock = ValueNotifier<double>(0);
  final _scene = _Scene();
  double _offset = 0;
  bool _reducedChecked = false;
  bool _hintShown = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final t = _offset + elapsed.inMicroseconds / 1e6;
      _clock.value = t;
      _scene.t = t;
      final showHint = t > _T.messageEnd + 0.6;
      if (showHint != _hintShown) setState(() => _hintShown = showHint);
    })
      ..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_reducedChecked) {
      _reducedChecked = true;
      // Hareket azaltma açıksa büyüme animasyonunu atla, son hâli göster.
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _offset = _T.messageEnd + 1;
        _scene.t = _offset;
        _clock.value = _offset;
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    _scene.dispose();
    AudioService.instance.endSpecial();
    super.dispose();
  }

  void _onTap(TapDownDetails d) {
    final onFlower = _scene.hitsBloom(d.localPosition);
    _scene.burstHearts(d.localPosition, onFlower ? 12 : 7);
    if (onFlower) {
      _scene.squish();
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    _scene.padding = pad;
    return Scaffold(
      backgroundColor: const Color(0xFF12081A),
      body: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              label: '$kFlowerMessage. Pixel art bir çiçek buketi.',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _onTap,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _FlowerPainter(_scene, _clock),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: pad.top + 4,
            left: 6,
            right: 10,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFFF8EBF2)),
                ),
                const Spacer(),
                const MusicButton(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: pad.bottom + 14,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _hintShown ? 1 : 0,
                duration: const Duration(milliseconds: 900),
                child: const Text(
                  'bukete dokun 💗',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFC8A9B9),
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sahne durumu + çizim yardımcıları. Ticker yalnızca [t]'yi ilerletir;
/// her şey zamandan analitik olarak hesaplanır.
class _Scene {
  double t = 0;
  EdgeInsets padding = EdgeInsets.zero;

  // Yerleşim (paint sırasında hesaplanır).
  double cs = 6; // çiçek piksel boyu
  Offset origin = Offset.zero; // çiçek ızgarasının sol üstü
  double ts = 3; // yazı piksel boyu
  double textTop = 0;
  Size size = Size.zero;

  double _squishAt = -10;
  final List<_Heart> hearts = [];
  final _rng = Random();

  late final List<_Px> pixels = _buildPixels();

  ui.Picture? _pic;
  double _picCs = -1;

  static final _stars = List.generate(46, (i) {
    final r = Random(i * 7919 + 3);
    return (r.nextDouble(), r.nextDouble() * 0.62, r.nextDouble() * 6.28,
        0.7 + r.nextDouble() * 1.8, r.nextDouble() < 0.18);
  });
  // Buketin üzerinde yanıp sönen parıltılar (hücre koordinatı).
  static final _sparkles = List.generate(16, (i) {
    final r = Random(i * 104729 + 11);
    final a = r.nextDouble() * 2 * pi;
    final d = sqrt(r.nextDouble());
    return (32 + cos(a) * d * 30, 31 + sin(a) * d * 24, r.nextDouble() * 1.8);
  });
  static final _fireflies = List.generate(9, (i) {
    final r = Random(i * 31337 + 5);
    return (r.nextDouble() * 64, 4 + r.nextDouble() * 70,
        r.nextDouble() * 6.28, 0.25 + r.nextDouble() * 0.35);
  });
  static final _fallers = List.generate(10, (i) {
    final r = Random(i * 7121 + 17);
    return (r.nextDouble(), 0.35 + r.nextDouble() * 0.45,
        r.nextDouble() * 1.0, r.nextDouble() * 6.28);
  });

  void dispose() {
    _pic?.dispose();
  }

  // ── Piksel listesi (çizim sırasıyla) ──
  static List<_Px> _buildPixels() {
    final out = <_Px>[];
    for (final l in kBouquetLayers) {
      final layer = <(int, int, String)>[];
      for (var r = 0; r < l.rows.length; r++) {
        final row = l.rows[r];
        for (var c = 0; c < row.length; c++) {
          if (row[c] != '.') layer.add((l.left + c, l.top + r, row[c]));
        }
      }
      var maxD = 0.5;
      for (final (x, y, _) in layer) {
        maxD = max(maxD, sqrt(pow(x + 0.5 - l.cx, 2) + pow(y + 0.5 - l.cy, 2)));
      }
      final bottom = l.top + l.rows.length;
      for (final (x, y, ch) in layer) {
        final k = l.mode == 1
            ? (bottom - y) / l.rows.length
            : sqrt(pow(x + 0.5 - l.cx, 2) + pow(y + 0.5 - l.cy, 2)) / maxD;
        out.add(_Px(x, y, kBouquetPalette[ch]!,
            l.start + k.clamp(0.0, 1.0) * l.dur));
      }
    }
    return out;
  }

  // ── Etkileşim ──
  Offset get _bloomCentre => origin + Offset(32 * cs, (31 + _headBob) * cs);

  bool hitsBloom(Offset p) =>
      t > 1.5 && (p - _bloomCentre).distance < 32 * cs;

  void squish() {
    _squishAt = t;
  }

  void burstHearts(Offset at, int n) {
    hearts.removeWhere((h) => t - h.born > 1.8);
    if (hearts.length > 60) return;
    for (var i = 0; i < n; i++) {
      final a = -pi / 2 + (_rng.nextDouble() - 0.5) * 1.9;
      final speed = 90 + _rng.nextDouble() * 170;
      hearts.add(_Heart(
        at,
        Offset(cos(a) * speed, sin(a) * speed),
        t + _rng.nextDouble() * 0.08,
        0.75 + _rng.nextDouble() * 0.6,
      ));
    }
  }

  double get _headBob {
    if (t < _T.grown + 0.8) return 0;
    return ((t - _T.grown) * 0.75) % 1.0 < 0.5 ? 0 : -1;
  }

  // ── Yerleşim ──
  EdgeInsets laidOutPadding = EdgeInsets.zero;

  void layout(Size s) {
    size = s;
    laidOutPadding = padding;
    final maxLine = kFlowerMessageLines
        .map((l) => pixelLineWidth('$l ♥'))
        .reduce(max);
    ts = ((s.width - 32) / (maxLine + 1)).floorToDouble().clamp(2.0, 5.0);
    final textH = kFlowerMessageLines.length * 14 * ts;
    final top = padding.top + 54;
    final bottom = padding.bottom + 40;
    final availH = s.height - top - bottom - textH - 18;
    cs = min((s.width - 16) / kBouquetW, availH / kBouquetH)
        .floorToDouble()
        .clamp(2.0, 16.0);
    final fw = kBouquetW * cs, fh = kBouquetH * cs;
    final used = fh + 18 + textH;
    final free = max(0.0, s.height - top - bottom - used);
    final y0 = (top + free * 0.42).roundToDouble();
    origin = Offset(((s.width - fw) / 2).roundToDouble(), y0);
    textTop = (y0 + fh + 18).roundToDouble();
  }
}

class _FlowerPainter extends CustomPainter {
  _FlowerPainter(this.s, Listenable repaint) : super(repaint: repaint);
  final _Scene s;

  static final _p = Paint()..isAntiAlias = false;
  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    if (size != s.size || s.padding != s.laidOutPadding) {
      s.layout(size);
    }
    final t = s.t;
    _sky(canvas, size, t);
    _stars(canvas, size, t);
    _moon(canvas, size, t);
    _glow(canvas, t);
    _fireflies(canvas, t);
    _flower(canvas, t);
    _burst(canvas, t);
    _sparkles(canvas, t);
    _butterfly(canvas, t);
    _fallingPetals(canvas, size, t);
    _message(canvas, size, t);
    _hearts(canvas, t);
    // Açılışta kısa beyaz parlama.
    final flash = t - _T.burst;
    if (flash > 0 && flash < 0.6) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = _white.withValues(alpha: 0.16 * (1 - flash / 0.6)));
    }
  }

  // ── Arka plan ──
  void _sky(Canvas c, Size size, double t) {
    final rect = Offset.zero & size;
    c.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF140C33), Color(0xFF2A1240), Color(0xFF170B12)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  void _stars(Canvas c, Size size, double t) {
    final px = max(2.0, (s.cs * 0.5).roundToDouble());
    for (final (fx, fy, ph, sp, bright) in _Scene._stars) {
      final a = (0.25 + 0.75 * (0.5 + 0.5 * sin(t * sp + ph))) *
          (t < 0.6 ? t / 0.6 : 1);
      final x = (fx * size.width / px).floorToDouble() * px;
      final y = ((s.padding.top + fy * size.height) / px).floorToDouble() * px;
      _p.color = const Color(0xFFFFF4FA).withValues(alpha: a);
      c.drawRect(Rect.fromLTWH(x, y, px, px), _p);
      if (bright && a > 0.7) {
        _p.color = const Color(0xFFFFC4DA).withValues(alpha: (a - 0.7) / 0.3);
        for (final o in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
          c.drawRect(Rect.fromLTWH(x + o.$1 * px, y + o.$2 * px, px, px), _p);
        }
      }
    }
  }

  void _moon(Canvas c, Size size, double t) {
    final px = max(2.0, (s.cs * 0.75).roundToDouble());
    final cx = size.width - 46 - 5 * px;
    final cy = s.padding.top + 64 + 5 * px;
    c.drawCircle(
        Offset(cx, cy),
        10 * px,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFF1B8).withValues(alpha: 0.18),
            const Color(0x00FFF1B8),
          ]).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: 10 * px)));
    for (var y = -5; y <= 5; y++) {
      for (var x = -5; x <= 5; x++) {
        final inMoon = (x + 0.5) * (x + 0.5) + (y + 0.5) * (y + 0.5) <= 25;
        final inBite =
            (x - 1.6) * (x - 1.6) + (y + 1.4) * (y + 1.4) <= 18;
        if (!inMoon || inBite) continue;
        _p.color = (x + y < -2)
            ? const Color(0xFFFFF7D6)
            : const Color(0xFFF5D77A);
        c.drawRect(
            Rect.fromLTWH(((cx + x * px) / px).floorToDouble() * px,
                ((cy + y * px) / px).floorToDouble() * px, px, px),
            _p);
      }
    }
  }

  void _glow(Canvas c, double t) {
    final k = ((t - 1.5) / 2.5).clamp(0.0, 1.0);
    if (k <= 0) return;
    final centre = s.origin + Offset(32 * s.cs, 30 * s.cs);
    final pulse = 0.85 + 0.15 * sin(t * 1.6);
    final r = 42 * s.cs * pulse;
    c.drawCircle(
      centre,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFF80AB).withValues(alpha: 0.28 * k),
          const Color(0xFFFF80AB).withValues(alpha: 0.08 * k),
          const Color(0x00FF80AB),
        ], stops: const [0, 0.55, 1])
            .createShader(Rect.fromCircle(center: centre, radius: r)),
    );
  }

  void _fireflies(Canvas c, double t) {
    final k = ((t - 2.0) / 2.0).clamp(0.0, 1.0);
    if (k <= 0) return;
    final cs = s.cs;
    for (final (fx, fy, ph, sp) in _Scene._fireflies) {
      final x = fx + sin(t * sp + ph) * 5;
      final y = fy + cos(t * sp * 0.8 + ph) * 4;
      final blink = 0.5 + 0.5 * sin(t * 2.4 + ph * 3);
      final o = s.origin + Offset(x.roundToDouble() * cs, y.roundToDouble() * cs);
      c.drawCircle(
          o + Offset(cs / 2, cs / 2),
          cs * 1.6,
          Paint()
            ..color =
                const Color(0xFFE8FF8A).withValues(alpha: 0.22 * blink * k));
      _p.color = const Color(0xFFF4FFB8).withValues(alpha: (0.4 + 0.6 * blink) * k);
      c.drawRect(Rect.fromLTWH(o.dx, o.dy, cs, cs), _p);
    }
  }

  // ── Çiçek ──
  void _cell(Canvas c, double ox, double oy, double cs, _Px p, double t) {
    final age = t - p.born;
    if (age < 0) return;
    if (age >= _T.pop) {
      _p.color = p.c;
      c.drawRect(Rect.fromLTWH(ox + p.x * cs, oy + p.y * cs, cs, cs), _p);
      return;
    }
    final k = age / _T.pop;
    final scale = Curves.easeOutBack.transform(k).clamp(0.0, 1.25);
    _p.color = Color.lerp(_white, p.c, k)!;
    final w = cs * scale;
    c.drawRect(
        Rect.fromLTWH(ox + p.x * cs + (cs - w) / 2,
            oy + p.y * cs + (cs - w) / 2, w, w),
        _p);
  }

  ui.Picture _record(List<_Px> pixels, double cs) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    for (final p in pixels) {
      _p.color = p.c;
      c.drawRect(Rect.fromLTWH(p.x * cs, p.y * cs, cs, cs), _p);
    }
    return rec.endRecording();
  }

  void _flower(Canvas c, double t) {
    final cs = s.cs;
    final o = s.origin;
    final grown = t >= _T.grown;
    if (grown && s._picCs != cs) {
      s._pic?.dispose();
      s._pic = _record(s.pixels, cs);
      s._picCs = cs;
    }

    // Hafif zıplama, dokununca esneme, fiyonk bağlanınca tek "boing".
    final bob = s._headBob * cs;
    final sq = t - s._squishAt;
    var sx = 1.0, sy = 1.0;
    if (sq >= 0 && sq < 0.7) {
      final w = exp(-5.5 * sq) * cos(sq * 18);
      sx = 1 + 0.05 * w;
      sy = 1 - 0.05 * w;
    }
    final bl = t - _T.grown;
    if (bl >= 0 && bl < 0.6) {
      final w = exp(-6 * bl) * sin(bl * 16);
      sx *= 1 + 0.04 * w;
      sy *= 1 + 0.04 * w;
    }
    c.save();
    c.translate(0, bob);
    final pivot = Offset(o.dx + 32 * cs, o.dy + kBouquetH * cs);
    c.translate(pivot.dx, pivot.dy);
    c.scale(sx, sy);
    c.translate(-pivot.dx, -pivot.dy);
    if (grown) {
      c.translate(o.dx, o.dy);
      c.drawPicture(s._pic!);
    } else {
      for (final p in s.pixels) {
        _cell(c, o.dx, o.dy, cs, p, t);
      }
    }
    c.restore();
  }

  void _burst(Canvas c, double t) {
    final k = (t - _T.burst) / _T.burstDur;
    if (k < 0 || k > 1) return;
    final cs = s.cs;
    final centre = s.origin + Offset(32 * cs, 32 * cs);
    final r = Curves.easeOutCubic.transform(k) * 38 * cs;
    final a = 1 - k;
    for (var i = 0; i < 24; i++) {
      final ang = i * 2 * pi / 24 + k * 0.6;
      final p = centre + Offset(cos(ang) * r, sin(ang) * r);
      final sx = (p.dx / cs).floorToDouble() * cs;
      final sy = (p.dy / cs).floorToDouble() * cs;
      _p.color = (i.isEven ? const Color(0xFFFFF3A6) : const Color(0xFFFFC4DA))
          .withValues(alpha: a);
      c.drawRect(Rect.fromLTWH(sx, sy, cs, cs), _p);
      if (i % 3 == 0) {
        _p.color = _white.withValues(alpha: a * 0.8);
        c.drawRect(Rect.fromLTWH(sx - cs, sy, cs, cs), _p);
        c.drawRect(Rect.fromLTWH(sx + cs, sy, cs, cs), _p);
        c.drawRect(Rect.fromLTWH(sx, sy - cs, cs, cs), _p);
        c.drawRect(Rect.fromLTWH(sx, sy + cs, cs, cs), _p);
      }
    }
  }

  void _sparkles(Canvas c, double t) {
    if (t < _T.grown) return;
    final cs = s.cs;
    final o = s.origin;
    for (final (x, y, ph) in _Scene._sparkles) {
      final u = ((t - _T.grown + ph) % 1.8) / 1.8; // 0..1
      // 0: yok, 1: nokta, 2: artı, 3: büyük artı
      final stage = u < 0.15
          ? 1
          : u < 0.3
              ? 2
              : u < 0.45
                  ? 3
                  : u < 0.6
                      ? 2
                      : u < 0.72
                          ? 1
                          : 0;
      if (stage == 0) continue;
      final bx = o.dx + x.roundToDouble() * cs;
      final by = o.dy + y.roundToDouble() * cs;
      _p.color = _white;
      c.drawRect(Rect.fromLTWH(bx, by, cs, cs), _p);
      if (stage >= 2) {
        _p.color = const Color(0xFFFFF3A6);
        for (var d = 1; d <= stage - 1; d++) {
          c.drawRect(Rect.fromLTWH(bx - d * cs, by, cs, cs), _p);
          c.drawRect(Rect.fromLTWH(bx + d * cs, by, cs, cs), _p);
          c.drawRect(Rect.fromLTWH(bx, by - d * cs, cs, cs), _p);
          c.drawRect(Rect.fromLTWH(bx, by + d * cs, cs, cs), _p);
        }
      }
    }
  }

  static const _wing = [
    '....e.e....',
    '.oo..e..oo.',
    'oLLo.e.oLLo',
    'oLlloeollLo',
    '.olllelllo.',
    '.oLloeolLo.',
    '..oo.e.oo..',
  ];
  static const _wingPal = {
    'e': Color(0xFF2B1220),
    'o': Color(0xFF2A4F8F),
    'L': Color(0xFFD6F0FF),
    'l': Color(0xFF7EC3FF),
  };

  void _butterfly(Canvas c, double t) {
    final u = t - _T.butterfly;
    if (u < 0) return;
    final cs = s.cs;
    // Buketin üstünde sonsuz (∞) biçimli uçuş.
    final px = 32 + 24 * sin(u * 0.5);
    final py = 3 + 5 * sin(u * 1.0);
    double x = px, y = py;
    if (u < 2.2) {
      final k = Curves.easeOut.transform(u / 2.2);
      x = ui.lerpDouble(-16, px, k)!;
      y = ui.lerpDouble(30, py, k)!;
    }
    final flap = 0.3 + 0.7 * cos(u * 11).abs();
    final bx = s.origin.dx + x.roundToDouble() * cs;
    final by = s.origin.dy + y.roundToDouble() * cs;
    for (var r = 0; r < _wing.length; r++) {
      final row = _wing[r];
      for (var k = 0; k < row.length; k++) {
        final ch = row[k];
        if (ch == '.') continue;
        final dx = k - 5;
        final fx = (dx * flap).round();
        _p.color = _wingPal[ch]!;
        c.drawRect(Rect.fromLTWH(bx + fx * cs, by + r * cs, cs, cs), _p);
      }
    }
  }

  void _fallingPetals(Canvas c, Size size, double t) {
    final start = _T.grown + 1.0;
    if (t < start) return;
    final cs = max(2.0, (s.cs * 0.75).roundToDouble());
    final fade = ((t - start) / 1.5).clamp(0.0, 1.0);
    for (final (fx, sp, ph, sw) in _Scene._fallers) {
      final span = size.height + 40;
      final y = ((t - start) * sp * 60 + ph * span) % span - 20;
      final x = fx * size.width + sin(t * 1.3 + sw) * 18;
      final sxp = (x / cs).floorToDouble() * cs;
      final syp = (y / cs).floorToDouble() * cs;
      final flip = sin(t * 2 + sw) > 0;
      _p.color = kBouquetPalette['g']!.withValues(alpha: 0.85 * fade);
      c.drawRect(Rect.fromLTWH(sxp, syp, cs, cs), _p);
      _p.color = kBouquetPalette['e']!.withValues(alpha: 0.85 * fade);
      c.drawRect(Rect.fromLTWH(sxp + (flip ? cs : -cs), syp, cs, cs), _p);
      c.drawRect(Rect.fromLTWH(sxp, syp + cs, cs, cs), _p);
    }
  }

  // ── Daktilo mesajı ──
  void _message(Canvas c, Size size, double t) {
    if (t < _T.message) return;
    final ts = s.ts;
    final shown = ((t - _T.message) / _T.perChar).floor();
    var index = 0;
    double cursorX = -1, cursorY = 0;
    const colors = [Color(0xFFFFE6F0), Color(0xFFFFE6F0), Color(0xFFFF9EC4)];
    const shadow = Color(0xFF7A2350);
    for (var li = 0; li < kFlowerMessageLines.length; li++) {
      final last = li == kFlowerMessageLines.length - 1;
      final line = kFlowerMessageLines[li];
      final full = last ? '$line ♥' : line;
      final lw = pixelLineWidth(full);
      var x = ((size.width - lw * ts) / 2 / ts).floorToDouble() * ts;
      final y = s.textTop + li * 14 * ts;
      for (final ch in line.split('')) {
        final born = _T.message + index * _T.perChar;
        final g = kPixelGlyphs[ch] ?? kPixelGlyphs[' ']!;
        if (index < shown || t >= born) {
          _glyph(c, g, x, y, ts, colors[li], shadow, t - born);
          cursorX = x + (g.first.length + kGlyphSpacing) * ts;
          cursorY = y;
        }
        x += (g.first.length + kGlyphSpacing) * ts;
        index++;
      }
      if (last) {
        // Mesaj bitince atan kalp.
        final hb = _T.messageEnd + 0.25;
        if (t >= hb) {
          final beat = 1 + 0.12 * max(0.0, sin((t - hb) * 5.2)).toDouble();
          final g = kPixelGlyphs['♥']!;
          final hx = x + (kPixelGlyphs[' ']!.first.length + kGlyphSpacing) * ts;
          final w = g.first.length * ts;
          c.save();
          c.translate(hx + w / 2, y + 5 * ts);
          c.scale(beat);
          c.translate(-(hx + w / 2), -(y + 5 * ts));
          _glyph(c, g, hx, y, ts, const Color(0xFFFF4F86), shadow, t - hb);
          c.restore();
        }
      }
      index++; // satırlar arası boşluk (birleşik mesajdaki ' ')
    }
    // Yanıp sönen imleç.
    final typing = t < _T.messageEnd + 1.2;
    if (typing && cursorX >= 0 && (t * 2.2) % 1 < 0.6) {
      _p.color = const Color(0xFFFF9EC4);
      c.drawRect(Rect.fromLTWH(cursorX, cursorY + 2 * ts, ts, 7 * ts), _p);
    }
  }

  void _glyph(Canvas c, List<String> g, double x, double y, double ts,
      Color col, Color shadow, double age) {
    final k = (age / 0.12).clamp(0.0, 1.0);
    final lift = (1 - k) * 2 * ts;
    for (var pass = 0; pass < 2; pass++) {
      _p.color = pass == 0
          ? shadow.withValues(alpha: k)
          : Color.lerp(_white, col, k)!;
      final off = pass == 0 ? ts : 0.0;
      for (var r = 0; r < g.length; r++) {
        final row = g[r];
        for (var q = 0; q < row.length; q++) {
          if (row.codeUnitAt(q) != 35) continue; // '#'
          c.drawRect(
              Rect.fromLTWH(x + q * ts + off, y + r * ts + off - lift, ts, ts),
              _p);
        }
      }
    }
  }

  // ── Dokunma kalpleri ──
  static const _heart = [
    '.DD.DD.',
    'DRrDrrD',
    'DrrrrrD',
    '.DrrrD.',
    '..DrD..',
    '...D...',
  ];
  static const _heartPal = {
    'D': Color(0xFF8E1F4A),
    'R': Color(0xFFFFC2D6),
    'r': Color(0xFFFF4F86),
  };

  void _hearts(Canvas c, double t) {
    for (final h in s.hearts) {
      final age = t - h.born;
      if (age < 0 || age > 1.6) continue;
      final pos = h.p0 +
          h.v * age +
          Offset(sin(age * 7 + h.p0.dx) * 6, -40 * age * age);
      final a = age > 1.0 ? 1 - (age - 1.0) / 0.6 : 1.0;
      final pop = Curves.easeOutBack.transform((age / 0.2).clamp(0.0, 1.0));
      final px = max(2.0, (s.cs * 0.55 * h.size).roundToDouble()) * pop;
      if (px <= 0.3) continue;
      final ox = pos.dx.roundToDouble() - 3.5 * px;
      final oy = pos.dy.roundToDouble() - 3 * px;
      for (var r = 0; r < _heart.length; r++) {
        final row = _heart[r];
        for (var k = 0; k < row.length; k++) {
          final ch = row[k];
          if (ch == '.') continue;
          _p.color = _heartPal[ch]!.withValues(alpha: a.clamp(0.0, 1.0));
          c.drawRect(Rect.fromLTWH(ox + k * px, oy + r * px, px, px), _p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter old) => old.s != s;
}
