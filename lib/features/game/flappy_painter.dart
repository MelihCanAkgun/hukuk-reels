part of 'flappy_cat_screen.dart';

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.rows);
  final List<String> rows;
  @override
  void paint(Canvas canvas, Size size) =>
      drawSprite(canvas, rows, Offset.zero & size);
  @override
  bool shouldRepaint(_SpritePainter old) => old.rows != rows;
}

// ═══════════════════════════ Çizim ═══════════════════════════
class _FlappyPainter extends CustomPainter {
  _FlappyPainter(this.g, {required Listenable repaint})
      : super(repaint: repaint);
  final _FlappyCatScreenState g;

  static const double vh = _FlappyCatScreenState.vh;
  static const double playH = _FlappyCatScreenState.playH;

  final Paint _p = Paint()..isAntiAlias = false;

  // Şehir katmanları (bir kez üretilir, renkleri ColorFilter ile boyanır)
  static ui.Image? _farCity, _nearCity, _nearWindows, _bushes, _hills, _trees;

  // Gökyüzü arka planı (bantlar, ufuk ışıltısı, güneş / ay) yalnız gökyüzü
  // rengi ya da genişlik değişince yeniden kaydedilir.
  static ui.Picture? _backdrop;
  static int _backdropKey = -1;
  static const double tileW = 240;
  static final List<Offset> _stars = List.generate(46, (i) {
    final r = math.Random(i * 7919 + 3);
    return Offset(r.nextDouble(), r.nextDouble() * 0.62);
  });

  static void _ensureLayers() {
    if (_farCity != null) return;
    _farCity = _city(seed: 11, minH: 34, maxH: 92, windows: false);
    _nearCity =
        _city(seed: 23, minH: 22, maxH: 64, windows: false, court: true);
    _nearWindows =
        _city(seed: 23, minH: 22, maxH: 64, windows: true, court: true);
    _bushes = _bushLayer();
    _hills = _hillLayer();
    _trees = _treeLayer();
  }

  static ui.Image _hillLayer() {
    const h = 60.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final paint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFFFFFFFF);
    // Döşemenin iki ucu aynı yükseklikte biter (dikişsiz tekrar).
    for (var x = 0; x < tileW; x++) {
      final t = x / tileW * math.pi * 2;
      final y = 26 +
          math.sin(t) * 12 +
          math.sin(t * 3 + 1) * 6 +
          math.sin(t * 5 + 2) * 2.5;
      c.drawRect(
          Rect.fromLTWH(x.toDouble(), y.roundToDouble(), 1, h - y), paint);
    }
    return rec.endRecording().toImageSync(tileW.toInt(), h.toInt());
  }

  static ui.Image _treeLayer() {
    const h = 44.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final r = math.Random(17);
    final paint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFFFFFFFF);
    var x = 8.0;
    while (x < tileW - 10) {
      final th = 10 + r.nextInt(8).toDouble(); // gövde
      final rad = 6 + r.nextDouble() * 5;
      c.drawRect(Rect.fromLTWH(x - 1, h - th, 2, th), paint);
      if (r.nextBool()) {
        // yuvarlak taç
        for (var dy = -rad; dy <= rad; dy++) {
          final half =
              math.sqrt(math.max(0, rad * rad - dy * dy)).floorToDouble();
          c.drawRect(
              Rect.fromLTWH(x - half, h - th - rad + dy, half * 2 + 1, 1),
              paint);
        }
      } else {
        // selvi
        final ch = rad * 3.2;
        for (var dy = 0.0; dy < ch; dy++) {
          final half =
              (math.sin(dy / ch * math.pi) * rad * 0.55).roundToDouble();
          c.drawRect(
              Rect.fromLTWH(x - half, h - th - dy, half * 2 + 1, 1), paint);
        }
      }
      x += 18 + r.nextInt(26);
    }
    return rec.endRecording().toImageSync(tileW.toInt(), h.toInt());
  }

  /// Gökyüzü arka planını (önbellekli) çizer.
  void _drawBackdrop(Canvas canvas, _Sky sky, double vw) {
    final key = (g.skyT * 64).round() * 4096 + vw.round();
    if (key != _backdropKey || _backdrop == null) {
      // Eski resim açıkça dispose edilmez: web'de önceki karenin katmanı
      // hâlâ ona başvuruyor olabilir; çöp toplayıcı serbest bırakır.
      _backdropKey = key;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final p = Paint()..isAntiAlias = false;
      const bands = 14;
      for (var i = 0; i < bands; i++) {
        p.color = lerpColor(sky.top, sky.bottom, i / (bands - 1));
        c.drawRect(
            Rect.fromLTWH(-8, -8 + i * (playH + 16) / bands, vw + 16,
                (playH + 16) / bands + 1),
            p);
      }
      // Ufuk ışıltısı (güneş rengine doğru, aşağıda yoğunlaşan bantlar)
      for (var i = 0; i < 6; i++) {
        p.color = sky.sun.withValues(alpha: 0.05 + i * 0.025);
        c.drawRect(
            Rect.fromLTWH(-8, playH - 120 + i * 16, vw + 16, 120 - i * 16), p);
      }
      // Güneş / ay: iki hale + gövde
      final bx = vw * 0.76, by = 42.0;
      p.color = sky.sun.withValues(alpha: 0.10);
      _circle(c, p, bx, by, 30);
      p.color = sky.sun.withValues(alpha: 0.18);
      _circle(c, p, bx, by, 22);
      p.color = sky.sun;
      _circle(c, p, bx, by, 14);
      if (sky.moon) {
        p.color = lerpColor(sky.top, sky.bottom, 0.15).withValues(alpha: 0.92);
        _circle(c, p, bx + 7, by - 5, 11);
      } else {
        // güneş: hafif parlak çekirdek
        p.color = const Color(0xFFFFFFFF).withValues(alpha: 0.35);
        _circle(c, p, bx - 3, by - 3, 6);
      }
      _backdrop = rec.endRecording();
    }
    canvas.drawPicture(_backdrop!);
  }

  static void _circle(Canvas c, Paint p, double cx, double cy, double r) {
    for (var dy = -r; dy < r; dy += 1) {
      final half = math
          .sqrt(math.max(0, r * r - (dy + 0.5) * (dy + 0.5)))
          .roundToDouble();
      c.drawRect(Rect.fromLTWH(cx - half, cy + dy, half * 2, 1), p);
    }
  }

  /// Sahneye canlılık katan, durumsuz (zamanın fonksiyonu) küçük öğeler:
  /// gündüz kuşlar, alacakaranlıkta uçuşan pembe yapraklar, gece kayan
  /// yıldız ve ateş böcekleri.
  void _ambient(Canvas canvas, _Sky sky, double vw, {required bool front}) {
    final t = g.t;
    final day = (1 - sky.stars).clamp(0.0, 1.0);
    final m = g.skyT % 4;
    final dusk = (1 - math.min(m, 4 - m)).clamp(0.0, 1.0);
    if (!front) {
      // Kuşlar
      if (day > 0.05) {
        for (var i = 0; i < 4; i++) {
          final bx = (vw + 40) - ((t * (14 + i * 3) + i * 113) % (vw + 80));
          final by = 26 + i * 13 + math.sin(t * 1.3 + i * 2) * 4;
          final up = ((t * 6 + i * 0.7).floor()) % 2 == 0;
          _p.color = const Color(0xFF3A2440).withValues(alpha: 0.55 * day);
          canvas.drawRect(Rect.fromLTWH(bx, by, 1, 1), _p);
          final wy = up ? by - 1 : by + 1;
          canvas.drawRect(Rect.fromLTWH(bx - 2, wy, 2, 1), _p);
          canvas.drawRect(Rect.fromLTWH(bx + 1, wy, 2, 1), _p);
        }
      }
      // Kayan yıldız (6 saniyede bir, kısa)
      if (sky.stars > 0.5) {
        const period = 6.0;
        final n = (t / period).floor();
        final ph = (t % period) / 0.7;
        if (ph < 1) {
          final rr = math.Random(n * 977 + 13);
          final sx = vw * (0.15 + rr.nextDouble() * 0.6);
          final sy = 10 + rr.nextDouble() * 50;
          for (var k = 0; k < 10; k++) {
            final q = ph - k * 0.035;
            if (q < 0) break;
            _p.color = Colors.white
                .withValues(alpha: sky.stars * (1 - k / 10) * (1 - ph * 0.6));
            canvas.drawRect(
                Rect.fromLTWH(sx - q * 70, sy + q * 32, k == 0 ? 2 : 1, 1), _p);
          }
        }
      }
      return;
    }
    // Ateş böcekleri (gece, çalıların üstünde)
    if (sky.stars > 0.3) {
      for (var i = 0; i < 9; i++) {
        final fx =
            (i * 53 + math.sin(t * 0.7 + i) * 14 - g.scroll * 0.55) % (vw + 10);
        final fy = playH - 12 - (math.sin(t * 1.1 + i * 2) + 1) * 14;
        final a = sky.stars * (0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 3 + i)));
        _p.color = const Color(0xFFFFF59A).withValues(alpha: a * 0.25);
        canvas.drawRect(Rect.fromLTWH(fx - 1.5, fy - 1.5, 4, 4), _p);
        _p.color = const Color(0xFFFFF59A).withValues(alpha: a);
        canvas.drawRect(Rect.fromLTWH(fx, fy, 1, 1), _p);
      }
    }
    // Pembe yapraklar (alacakaranlık)
    if (dusk > 0.05) {
      for (var i = 0; i < 10; i++) {
        final py = (i * 37 + t * (9 + (i % 4) * 3)) % (playH + 10) - 5;
        final px = (vw + 20) -
            ((i * 61 + t * (16 + (i % 3) * 5) + g.scroll * 0.2) % (vw + 30)) +
            math.sin(t * 2 + i) * 5;
        _p.color =
            (i.isEven ? const Color(0xFFFFB3CF) : const Color(0xFFFFE3EC))
                .withValues(alpha: 0.8 * dusk);
        final flip = ((t * 3 + i).floor()) % 2 == 0;
        canvas.drawRect(Rect.fromLTWH(px, py, flip ? 2 : 1, flip ? 1 : 2), _p);
      }
    }
  }

  /// Sanal birimde (1 px = 1 birim) şehir silüeti ya da yalnız pencereleri.
  static ui.Image _city(
      {required int seed,
      required double minH,
      required double maxH,
      required bool windows,
      bool court = false}) {
    const h = 110.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final paint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFFFFFFFF);
    final r = math.Random(seed);
    var x = 0.0;
    while (x < tileW) {
      if (!court && x > 150 && x < 160) {
        // Galata kulesi: gövde, seyir balkonu, konik külah
        const cx = 156.0, cw = 13.0, ch = 70.0;
        if (!windows) {
          c.drawRect(const Rect.fromLTWH(cx, h - ch, cw, ch), paint);
          c.drawRect(const Rect.fromLTWH(cx - 2, h - ch - 3, cw + 4, 3), paint);
          c.drawRect(const Rect.fromLTWH(cx, h - ch - 9, cw, 6), paint);
          for (var i = 0; i < 14; i++) {
            final half = (cw / 2) * (1 - i / 14);
            c.drawRect(
                Rect.fromLTWH(cx + cw / 2 - half, h - ch - 10 - i, half * 2, 1),
                paint);
          }
          c.drawRect(
              const Rect.fromLTWH(cx + cw / 2 - 0.5, h - ch - 28, 1, 4), paint);
        }
        x = cx + cw + 3;
        continue;
      }
      if (court && x > 92 && x < 100) {
        // Adliye: basamaklı alınlık + sütunlar
        const cx = 96.0, cw = 52.0, ch = 40.0;
        if (!windows) {
          c.drawRect(const Rect.fromLTWH(cx, h - ch, cw, ch), paint);
          for (var i = 0; i < 7; i++) {
            c.drawRect(
                Rect.fromLTWH(
                    cx - 3 + i * 4, h - ch - 3 - i * 2, cw + 6 - i * 8, 2),
                paint);
          }
          c.drawRect(const Rect.fromLTWH(cx - 4, h - ch - 3, cw + 8, 3), paint);
        } else {
          for (var i = 0; i < 6; i++) {
            c.drawRect(
                Rect.fromLTWH(cx + 5 + i * 8, h - ch + 4, 3, ch - 8), paint);
          }
          c.drawRect(const Rect.fromLTWH(cx + 22, h - ch - 12, 8, 4), paint);
        }
        x = cx + cw + 4;
        continue;
      }
      final w = 14 + r.nextInt(18).toDouble();
      final bh = minH + r.nextDouble() * (maxH - minH);
      if (!windows) {
        c.drawRect(Rect.fromLTWH(x, h - bh, w, bh), paint);
        if (r.nextDouble() < 0.3) {
          c.drawRect(Rect.fromLTWH(x + w / 2 - 1, h - bh - 6, 2, 6), paint);
        }
      } else {
        for (var wy = h - bh + 4; wy < h - 6; wy += 6) {
          for (var wx = x + 3; wx < x + w - 3; wx += 5) {
            if (r.nextDouble() < 0.42) {
              c.drawRect(Rect.fromLTWH(wx, wy, 2, 3), paint);
            }
          }
        }
      }
      x += w + 1 + r.nextInt(4);
    }
    return rec.endRecording().toImageSync(tileW.toInt(), h.toInt());
  }

  static ui.Image _bushLayer() {
    const h = 20.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final r = math.Random(5);
    final paint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFFFFFFFF);
    for (var x = -6.0; x < tileW + 6; x += 9 + r.nextInt(8)) {
      final rad = 7 + r.nextDouble() * 6;
      // piksel daire
      for (var dy = -rad; dy <= 0; dy++) {
        final half =
            math.sqrt(math.max(0, rad * rad - dy * dy)).floorToDouble();
        c.drawRect(Rect.fromLTWH(x - half, h + dy - 1, half * 2, 1), paint);
      }
    }
    c.drawRect(const Rect.fromLTWH(0, h - 2, tileW, 2), paint);
    return rec.endRecording().toImageSync(tileW.toInt(), h.toInt());
  }

  void _tiled(Canvas canvas, ui.Image img, double offset, double y, double vw,
      Color color) {
    // Fırça rengi önceki çizimden (yıldız, kuş…) kalmış yarı saydam bir
    // renk olabilir; görüntü onun alfasıyla çizilir ve kare kare yanıp
    // söner. Her zaman tam opak başla.
    _p.color = const Color(0xFFFFFFFF);
    _p.colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    _p.filterQuality = FilterQuality.none;
    final w = img.width.toDouble();
    final src = Rect.fromLTWH(0, 0, w, img.height.toDouble());
    var x = -(offset % w);
    while (x < vw) {
      canvas.drawImageRect(
          img, src, Rect.fromLTWH(x, y, w, img.height.toDouble()), _p);
      x += w;
    }
    _p.colorFilter = null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _ensureLayers();
    final s = size.height / vh;
    final vw = size.width / s;
    final sky = g.sky;

    canvas.save();
    final sh = g.shake.offset;
    canvas.translate(sh.dx * s, sh.dy * s);
    canvas.scale(s);

    // ── Gökyüzü ──
    _drawBackdrop(canvas, sky, vw);
    // Yıldızlar
    if (sky.stars > 0.02) {
      for (var i = 0; i < _stars.length; i++) {
        final st = _stars[i];
        final tw = 0.5 + 0.5 * math.sin(g.t * 2 + i * 1.7);
        _p.color = Colors.white.withValues(alpha: sky.stars * (0.3 + 0.7 * tw));
        final sz = i % 5 == 0 ? 2.0 : 1.0;
        canvas.drawRect(
            Rect.fromLTWH(
                (st.dx * vw - g.scroll * 0.02) % vw, st.dy * playH, sz, sz),
            _p);
      }
    }
    _ambient(canvas, sky, vw, front: false);
    // Bulutlar
    for (var i = 0; i < 4; i++) {
      final cw = 28.0 * (1 + (i % 2) * 0.4);
      final x =
          (vw + 60) - ((g.scroll * (0.08 + i * 0.03) + i * 97) % (vw + 90));
      final y = 24.0 + (i * 37) % 70;
      drawSprite(canvas, kSprCloud, Rect.fromLTWH(x - 30, y, cw, cw * 12 / 28),
          opacity: 0.55 + (1 - sky.stars) * 0.35);
    }
    // Tepeler + şehir + ağaçlar
    _tiled(canvas, _hills!, g.scroll * 0.06, playH - 74, vw,
        lerpColor(sky.far, sky.bottom, 0.45));
    _tiled(canvas, _farCity!, g.scroll * 0.12, playH - 110 + 4, vw, sky.far);
    _tiled(canvas, _nearCity!, g.scroll * 0.3 + 60, playH - 110 + 14, vw,
        sky.near);
    _tiled(canvas, _nearWindows!, g.scroll * 0.3 + 60, playH - 110 + 14, vw,
        sky.window.withValues(alpha: 0.35 + sky.stars * 0.6));
    _tiled(canvas, _trees!, g.scroll * 0.42 + 30, playH - 44, vw,
        lerpColor(const Color(0xFF16704F), sky.near, 0.55));
    _tiled(canvas, _bushes!, g.scroll * 0.55, playH - 20, vw,
        lerpColor(const Color(0xFF1E8A63), sky.near, 0.35));

    _ambient(canvas, sky, vw, front: true);

    // ── Borular ──
    for (final p in g.pipes) {
      final gy = p.gapY(g.t);
      final top = gy - p.gap / 2, bot = gy + p.gap / 2;
      const pw = _FlappyCatScreenState.pipeW;
      const cw = _FlappyCatScreenState.capW;
      const ch = _FlappyCatScreenState.capH;
      drawSprite(canvas, kSprPipeBody,
          Rect.fromLTRB(p.x, -10, p.x + pw, top - ch + 0.5));
      drawSprite(canvas, kSprPipeCap,
          Rect.fromLTWH(p.x - (cw - pw) / 2, top - ch, cw, ch));
      drawSprite(canvas, kSprPipeBody,
          Rect.fromLTRB(p.x, bot + ch - 0.5, p.x + pw, playH + 1));
      drawSprite(
          canvas, kSprPipeCap, Rect.fromLTWH(p.x - (cw - pw) / 2, bot, cw, ch));
      if (p.amp > 0) {
        // Hareketli boru uyarı ışığı
        final on = (g.t * 4).floor() % 2 == 0;
        _p.color = on ? const Color(0xFFFFD36A) : const Color(0xFFC0892E);
        canvas.drawRect(Rect.fromLTWH(p.x + pw / 2 - 1.5, top - 7, 3, 3), _p);
        canvas.drawRect(Rect.fromLTWH(p.x + pw / 2 - 1.5, bot + 4, 3, 3), _p);
      }
    }
    // ── Altın balıklar ──
    for (final f in g.fish) {
      final bob = math.sin(g.t * 4 + f.x * 0.05) * 2.5;
      final fr = (g.t * 5).floor() % 2 == 0 ? kSprGoldFish0 : kSprGoldFish1;
      _p.color = const Color(0xFFFFE08A).withValues(alpha: 0.22);
      _pixelCircle(canvas, f.x, f.y + bob, 9);
      drawSprite(
          canvas,
          fr,
          Rect.fromCenter(
              center: Offset(f.x, f.y + bob), width: 15, height: 8));
    }

    // ── Zemin ──
    const gy = playH;
    const tile = kSprGroundTile;
    final tw = tile.first.length.toDouble();
    final th = tile.length.toDouble();
    var x = -(g.scroll % tw);
    while (x < vw) {
      drawSprite(canvas, tile, Rect.fromLTWH(x, gy, tw + 0.05, th));
      x += tw;
    }
    _p.color = const Color(0xFFD9A066);
    canvas.drawRect(Rect.fromLTWH(-8, gy + th, vw + 16, vh - gy - th + 8), _p);
    _p.color = const Color(0xFFC0892E);
    canvas.drawRect(Rect.fromLTWH(-8, gy + th, vw + 16, 1), _p);

    // ── Parçacıklar ──
    for (final pt in g.particles.items) {
      _p.color = pt.color.withValues(alpha: pt.t);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(pt.x, pt.y), width: pt.size, height: pt.size),
          _p);
    }

    // ── Kedi ──
    final blink = g.invuln > 0 && (g.t * 12).floor() % 2 == 0;
    if (!blink) {
      canvas.save();
      canvas.translate(g.catX, g.catY);
      canvas.rotate(g.angle);
      // 40×40 sprite; gövde merkezi sprite içinde (24, 22)
      drawSprite(canvas, g.catSprite, const Rect.fromLTWH(-24, -22, 40, 40));
      canvas.restore();
    }

    // ── Puan yazıları ──
    for (final p in g.popups) {
      drawOutlinedText(canvas, p.text, Offset(p.x, p.y), 11,
          fill: const Color(0xFFFFE08A), opacity: (p.life / 0.8).clamp(0, 1));
    }
    canvas.restore();

    // ── Skor (ekran koordinatı) ──
    if (g._phase == _Phase.playing || g._phase == _Phase.dying) {
      final pop = 1 + Curves.easeOut.transform(g.scorePop) * 0.25;
      drawOutlinedText(canvas, '${g.score}',
          Offset(size.width / 2, size.height * 0.17), 20 * s * pop);
    }

    // ── Çarpma flaşı ──
    if (g.flash > 0) {
      _p.color = Colors.white.withValues(alpha: g.flash * 0.7);
      canvas.drawRect(Offset.zero & size, _p);
    }
  }

  void _pixelCircle(Canvas canvas, double cx, double cy, double r) {
    for (var dy = -r; dy < r; dy += 1) {
      final half = math
          .sqrt(math.max(0, r * r - (dy + 0.5) * (dy + 0.5)))
          .roundToDouble();
      canvas.drawRect(Rect.fromLTWH(cx - half, cy + dy, half * 2, 1), _p);
    }
  }

  @override
  bool shouldRepaint(covariant _FlappyPainter old) => false;
}
