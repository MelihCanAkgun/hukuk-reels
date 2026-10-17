part of 'subway_cat_screen.dart';

// ═══════════════════════════ Çizim ═══════════════════════════

/// Dörtgenleri renkleriyle biriktirip tek `drawVertices` ile çizer.
/// Tamponlar tiplidir ve yeniden kullanılır: kare başına liste ayırmaz.
class _QuadBatch {
  Float32List _pos = Float32List(12 * 512);
  Int32List _col = Int32List(6 * 512);
  int _n = 0;

  void quad(Offset a, Offset b, Offset c, Offset d, Color color) {
    if ((_n + 1) * 12 > _pos.length) {
      _pos = Float32List(_pos.length * 2)..setAll(0, _pos);
      _col = Int32List(_col.length * 2)..setAll(0, _col);
    }
    final p = _pos, i = _n * 12;
    p[i] = a.dx;
    p[i + 1] = a.dy;
    p[i + 2] = b.dx;
    p[i + 3] = b.dy;
    p[i + 4] = c.dx;
    p[i + 5] = c.dy;
    p[i + 6] = a.dx;
    p[i + 7] = a.dy;
    p[i + 8] = c.dx;
    p[i + 9] = c.dy;
    p[i + 10] = d.dx;
    p[i + 11] = d.dy;
    final v = color.toARGB32(), j = _n * 6;
    _col.fillRange(j, j + 6, v);
    _n++;
  }

  void flush(Canvas canvas, Paint paint) {
    if (_n == 0) return;
    // Köşe renkleri boya alfasıyla çarpılır: önceki çizimden kalan yarı
    // saydam renk sahneyi titretmesin.
    paint
      ..color = const Color(0xFFFFFFFF)
      ..shader = null
      ..colorFilter = null;
    final v = ui.Vertices.raw(
      ui.VertexMode.triangles,
      Float32List.sublistView(_pos, 0, _n * 12),
      colors: Int32List.sublistView(_col, 0, _n * 6),
    );
    canvas.drawVertices(v, BlendMode.dst, paint);
    v.dispose();
    _n = 0;
  }
}

class _RunnerPainter extends CustomPainter {
  final _SubwayCatScreenState g;
  _RunnerPainter(this.g, {required Listenable repaint})
      : super(repaint: repaint);

  final Paint _p = Paint()..isAntiAlias = true;
  final Paint _flat = Paint()..isAntiAlias = false;
  final _QuadBatch _batch = _QuadBatch();

  late double W, H, f, horizonY, camX, camY, camZ, nearZ;

  static const Color fog = Color(0xFFB5577E);
  static const Color skyTop = Color(0xFF2A1430);
  static const Color skyMid = Color(0xFF6E2C5C);
  static const Color gravel = Color(0xFF3B2638);
  static const Color gravelFar = Color(0xFF6B3858);

  ui.Shader? _skySh, _groundSh;
  Size _shSize = Size.zero;
  static ui.Image? _skyline, _midline, _midWindows;
  static final List<Offset> _stars = List.generate(40, (i) {
    final r = math.Random(i * 31 + 7);
    return Offset(r.nextDouble(), r.nextDouble());
  });

  // _entities için yeniden kullanılan listeler
  final List<_Ob> _vis = [], _trains = [];
  final Map<_Ob, double> _keys = Map.identity();

  double _d(double z) => z - camZ;
  Offset _pt(double x, double y, double z) {
    final d = _d(z);
    return Offset(W / 2 + (x - camX) * f / d, horizonY + (camY - y) * f / d);
  }

  double _fogT(double z) =>
      ((z - 22) / (_SubwayCatScreenState.zFar - 22)).clamp(0.0, 1.0);
  Color _fogged(Color c, double z) => lerpColor(c, fog, _fogT(z) * 0.85);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    W = size.width;
    H = size.height;
    // Geniş (yatay) ekranda yükseklik azdır: sahne yakınlaştırılır ve ufuk
    // yukarı alınır ki kedi ve raylar dikeydeki kadar büyük kalsın.
    final wide = ((W / H - 0.8) / 0.5).clamp(0.0, 1.0);
    f = math.min(H * (0.6 + 0.25 * wide), W * 1.05);
    horizonY = H * (0.27 - 0.05 * wide);
    camX = g.camX;
    camY = g.camY;
    camZ = -_SubwayCatScreenState.camDist;
    nearZ = camZ + 0.35;

    canvas.save();
    final sh = g.shake.offset;
    canvas.translate(sh.dx * f, sh.dy * f);
    _sky(canvas, size);
    _ground(canvas);
    _scenery(canvas);
    _entities(canvas);
    _particles(canvas);
    canvas.restore();

    if (g.flash > 0) {
      _flat.color = g.flashColor.withValues(alpha: g.flash * 0.45);
      canvas.drawRect(Offset.zero & size, _flat);
    }
    // Hız çizgileri (hızlıyken kenarlarda)
    final sp = ((g.speed - 15) / 7).clamp(0.0, 1.0);
    if (sp > 0 && g._phase == _Phase.playing) {
      _flat.color = Colors.white.withValues(alpha: 0.10 * sp);
      for (var i = 0; i < 8; i++) {
        final yy = (i * 97 + g.animT * 900) % H;
        final xx = i.isEven ? W * 0.04 : W * 0.93;
        canvas.drawRect(Rect.fromLTWH(xx, yy, 2, 40 + 30 * sp), _flat);
      }
    }
  }

  // ── Gökyüzü + uzak silüet ──
  void _sky(Canvas canvas, Size size) {
    if (_shSize != size || _skySh == null) {
      _shSize = size;
      _groundSh = ui.Gradient.linear(
          Offset(0, horizonY), Offset(0, H), [gravelFar, gravel], [0, 0.35]);
      _skySh = ui.Gradient.linear(Offset.zero, Offset(0, horizonY + 2), [
        skyTop,
        skyMid,
        fog,
      ], [
        0,
        0.6,
        1
      ]);
    }
    _flat.shader = _skySh;
    canvas.drawRect(Rect.fromLTWH(-20, -20, W + 40, horizonY + 22), _flat);
    _flat.shader = null;
    // Yıldızlar (göğün üst yarısında, hafif parıltı)
    for (var i = 0; i < _stars.length; i++) {
      final st = _stars[i];
      final tw = 0.5 + 0.5 * math.sin(g.animT * 1.7 + i * 2.3);
      _flat.color = Colors.white.withValues(alpha: 0.15 + 0.55 * tw);
      final sz = i % 6 == 0 ? 2.0 : 1.2;
      final sx = (st.dx * (W + 40) - camX * 2) % (W + 40) - 20;
      canvas.drawRect(Rect.fromLTWH(sx, st.dy * horizonY * 0.6, sz, sz), _flat);
    }
    // Güneş (ufka yakın, halkalı)
    final sun = Offset(W * 0.72 - camX * 4, horizonY * 0.66);
    _p.color = const Color(0xFFFFB3CF).withValues(alpha: 0.16);
    canvas.drawCircle(sun, H * 0.13, _p);
    _p.color = const Color(0xFFFFD9E6).withValues(alpha: 0.28);
    canvas.drawCircle(sun, H * 0.085, _p);
    _p.color = const Color(0xFFFFE3EC);
    canvas.drawCircle(sun, H * 0.055, _p);
    // Güneşin önünden geçen ince bulut şeritleri
    _flat.color = skyMid.withValues(alpha: 0.75);
    for (var i = 0; i < 3; i++) {
      final cw = W * (0.22 + i * 0.08);
      final cx = (W * (0.2 + i * 0.37) - g.dist * (0.4 + i * 0.15) - camX * 6) %
              (W + cw) -
          cw / 2;
      canvas.drawRect(
          Rect.fromLTWH(cx, horizonY * (0.52 + i * 0.12), cw, H * 0.006 + i),
          _flat);
    }

    _skyline ??= _makeSkyline(42, 200, 50, windows: false);
    _midline ??= _makeSkyline(7, 160, 34, windows: false);
    _midWindows ??= _makeSkyline(7, 160, 34, windows: true);
    _layer(canvas, _skyline!, H * 0.0028, g.dist * 0.6 + camX * 30,
        const Color(0xFF8E3F6E));
    // Yakın silüet: koyu binalar + sıcak pencereler
    final midScroll = g.dist * 1.1 + camX * 45;
    _layer(canvas, _midline!, H * 0.0034, midScroll, const Color(0xFF5A2550));
    _layer(canvas, _midWindows!, H * 0.0034, midScroll,
        const Color(0xFFFFC98A).withValues(alpha: 0.75));
  }

  void _layer(
      Canvas canvas, ui.Image img, double scale, double scroll, Color color) {
    final tw = img.width * scale;
    final th = img.height * scale;
    final src =
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    var x0 = -(scroll % tw) - tw;
    _flat.colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    _flat.filterQuality = FilterQuality.none;
    _flat.color = Colors.white;
    while (x0 < W) {
      canvas.drawImageRect(
          img, src, Rect.fromLTWH(x0, horizonY - th + 1, tw + 0.5, th), _flat);
      x0 += tw;
    }
    _flat.colorFilter = null;
  }

  /// Beyaz bina silüeti ya da ([windows]) yalnız aynı binaların pencereleri;
  /// aynı tohumla iki katman birebir örtüşür.
  static ui.Image _makeSkyline(int seed, int w, int h,
      {required bool windows}) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final paint = Paint()
      ..isAntiAlias = false
      ..color = Colors.white;
    final r = math.Random(seed);
    final rw = math.Random(seed * 13 + 1); // pencereler ayrı: silüet aynı kalır
    var x = 0.0;
    while (x < w) {
      final bw = 8 + r.nextInt(14).toDouble();
      final bh = 12 + r.nextDouble() * (h - 16);
      final antenna = r.nextDouble() < 0.25;
      if (!windows) {
        c.drawRect(Rect.fromLTWH(x, h - bh, bw, bh), paint);
        if (antenna) {
          c.drawRect(Rect.fromLTWH(x + bw / 2 - 0.5, h - bh - 6, 1, 6), paint);
        }
      } else {
        for (var wy = h - bh + 3; wy < h - 3; wy += 4) {
          for (var wx = x + 2; wx < x + bw - 2; wx += 3) {
            if (rw.nextDouble() < 0.3) {
              c.drawRect(Rect.fromLTWH(wx, wy, 1, 2), paint);
            }
          }
        }
      }
      x += bw + r.nextInt(3);
    }
    return rec.endRecording().toImageSync(w, h);
  }

  // ── Zemin, raylar, traversler ──
  void _ground(Canvas canvas) {
    _flat.shader = _groundSh;
    canvas.drawRect(
        Rect.fromLTWH(-20, horizonY, W + 40, H - horizonY + 20), _flat);
    _flat.shader = null;

    const zf = _SubwayCatScreenState.zFar;
    // Şerit yatakları
    for (final l in const [-1.0, 0.0, 1.0]) {
      _batch.quad(_pt(l - 0.48, 0, nearZ), _pt(l + 0.48, 0, nearZ),
          _pt(l + 0.48, 0, zf), _pt(l - 0.48, 0, zf), const Color(0xFF2C1A2A));
    }
    // Traversler
    const step = 0.9;
    final off = g.dist % step;
    for (var z = zf - (zf % step) - off; z > nearZ; z -= step) {
      final z1 = z + 0.28;
      final c = _fogged(const Color(0xFF5A3A2C), z);
      for (final l in const [-1.0, 0.0, 1.0]) {
        _batch.quad(_pt(l - 0.4, 0, z), _pt(l + 0.4, 0, z), _pt(l + 0.4, 0, z1),
            _pt(l - 0.4, 0, z1), c);
      }
    }
    _batch.flush(canvas, _flat..color = Colors.white);
    // Raylar (parlak üst + gölge)
    for (final l in const [-1.0, 0.0, 1.0]) {
      for (final s in const [-0.27, 0.27]) {
        _batch.quad(
            _pt(l + s - 0.035, 0.03, nearZ),
            _pt(l + s + 0.035, 0.03, nearZ),
            _pt(l + s + 0.035, 0.03, zf),
            _pt(l + s - 0.035, 0.03, zf),
            const Color(0xFFB8BCC8));
      }
    }
    _batch.flush(canvas, _flat);
  }

  // ── Yan binalar / duvarlar ──
  void _scenery(Canvas canvas) {
    const seg = 6.0;
    final off = g.dist % seg;
    final segIndex0 = (g.dist / seg).floor();
    const zf = _SubwayCatScreenState.zFar;
    // Uzaktan yakına
    final starts = <double>[];
    for (var z = zf - (zf % seg) - off; z > nearZ - seg; z -= seg) {
      starts.add(z);
    }
    for (final z0 in starts) {
      final idx = segIndex0 + ((z0 + off) / seg).round();
      for (final side in const [-1.0, 1.0]) {
        final hash =
            ((idx * 73856093) ^ (side > 0 ? 19349663 : 83492791)) & 0x7fffffff;
        final h = 1.6 + (hash % 7) * 0.35;
        final xw = side * 2.15;
        final za = math.max(z0, nearZ), zb = z0 + seg - 0.15;
        if (zb <= nearZ) continue;
        const palette = [
          Color(0xFF7A3B6A),
          Color(0xFF5E2F63),
          Color(0xFF8C4A6E),
          Color(0xFF4E2A5A),
        ];
        final base = palette[hash % 4];
        final cz = (za + zb) / 2;
        // Bina dolu bir blok: derinlik [depth] kadar dışarı uzanır.
        const depth = 2.6;
        final xo = xw + side * depth;
        // Kameraya bakan uç yüz (kısa komşunun üstünden / ara sokaktan
        // görünür). Yakın düzlemin arkasındaysa çizilmez.
        if (z0 > nearZ + 0.2) {
          final capC = lerpColor(base, const Color(0xFF1A0A14), 0.32);
          _batch.quad(_pt(xw, 0, z0), _pt(xo, 0, z0), _pt(xo, h, z0),
              _pt(xw, h, z0), _fogged(capC, z0));
          // uç yüzün pencereleri (iki sütun)
          final lit = (hash >> 11) & 0xFF;
          for (var r = 0; r < (h / 0.55).floor() - 1; r++) {
            for (var k = 0; k < 2; k++) {
              final wx0 = xw + side * (0.55 + k * 1.0);
              final wx1 = wx0 + side * 0.5;
              final wy0 = 0.45 + r * 0.55, wy1 = wy0 + 0.32;
              final on = ((lit >> ((r * 2 + k) % 8)) & 1) == 1;
              final wc = on ? const Color(0xFFE8BE78) : const Color(0xFF22142A);
              _batch.quad(_pt(wx0, wy0, z0), _pt(wx1, wy0, z0),
                  _pt(wx1, wy1, z0), _pt(wx0, wy1, z0), _fogged(wc, z0));
            }
          }
          // uç yüzün parapet çizgisi
          _batch.quad(
              _pt(xw, h - 0.1, z0),
              _pt(xo, h - 0.1, z0),
              _pt(xo, h, z0),
              _pt(xw, h, z0),
              _fogged(lerpColor(base, Colors.white, 0.18), z0));
        }
        // Çatı (yalnız kameradan alçaksa üstten görünür)
        if (h < camY - 0.05) {
          _batch.quad(
              _pt(xw, h, za),
              _pt(xw, h, zb),
              _pt(xo, h, zb),
              _pt(xo, h, za),
              _fogged(lerpColor(base, const Color(0xFF2B1220), 0.15), cz));
          // çatı kenarı (raya bakan parapet üstü)
          _batch.quad(
              _pt(xw, h, za),
              _pt(xw, h, zb),
              _pt(xw + side * 0.18, h, zb),
              _pt(xw + side * 0.18, h, za),
              _fogged(lerpColor(base, Colors.white, 0.3), cz));
          // çatı üstü kutu (su deposu / klima) bazı binalarda
          if (hash % 3 == 0) {
            final bz0 = math.max(z0 + 1.6, nearZ + 0.2), bz1 = z0 + 3.2;
            if (bz1 > bz0) {
              final bx0 = xw + side * 0.9, bx1 = xw + side * 1.6;
              const bh = 0.45;
              final bc = lerpColor(base, const Color(0xFF1A0A14), 0.2);
              _batch.quad(
                  _pt(bx0, h, bz0),
                  _pt(bx1, h, bz0),
                  _pt(bx1, h + bh, bz0),
                  _pt(bx0, h + bh, bz0),
                  _fogged(bc, bz0));
              _batch.quad(
                  _pt(bx0, h, bz0),
                  _pt(bx0, h, bz1),
                  _pt(bx0, h + bh, bz1),
                  _pt(bx0, h + bh, bz0),
                  _fogged(lerpColor(base, Colors.white, 0.1), bz0));
              _batch.quad(
                  _pt(bx0, h + bh, bz0),
                  _pt(bx1, h + bh, bz0),
                  _pt(bx1, h + bh, bz1),
                  _pt(bx0, h + bh, bz1),
                  _fogged(lerpColor(base, Colors.white, 0.22), bz0));
            }
          }
        }
        // Duvar yüzü (raya bakan)
        _batch.quad(_pt(xw, 0, za), _pt(xw, 0, zb), _pt(xw, h, zb),
            _pt(xw, h, za), _fogged(base, cz));
        // duvarın üst parapet bandı
        _batch.quad(
            _pt(xw, h - 0.12, za),
            _pt(xw, h - 0.12, zb),
            _pt(xw, h, zb),
            _pt(xw, h, za),
            _fogged(lerpColor(base, Colors.white, 0.22), cz));
        // Pencereler
        final lit = (hash >> 3) & 0xFF;
        for (var r = 0; r < (h / 0.55).floor() - 1; r++) {
          for (var k = 0; k < 3; k++) {
            final wz0 = z0 + 0.6 + k * 1.8, wz1 = wz0 + 1.0;
            if (wz0 < nearZ) continue;
            final wy0 = 0.45 + r * 0.55, wy1 = wy0 + 0.32;
            final on = ((lit >> ((r * 3 + k) % 8)) & 1) == 1;
            final wc = on ? const Color(0xFFFFD98A) : const Color(0xFF2B1A33);
            _batch.quad(_pt(xw, wy0, wz0), _pt(xw, wy0, wz1), _pt(xw, wy1, wz1),
                _pt(xw, wy1, wz0), _fogged(wc, wz0));
          }
        }
        // Neon tabela (bazı binalarda; pembe / turkuaz, yumuşak halelı)
        if (hash % 5 == 1 && z0 + 1.05 > nearZ + 0.1) {
          final neon = (hash >> 5).isEven
              ? const Color(0xFFFF6FB5)
              : const Color(0xFF5FF2E4);
          final blink = (hash % 3 == 0) && ((g.animT * 2.5 + idx) % 4) < 0.35;
          final ny0 = h - 0.78, ny1 = h - 0.38;
          final nz0 = z0 + 1.2, nz1 = z0 + 4.4;
          _batch.quad(
              _pt(xw, ny0 - 0.12, nz0 - 0.15),
              _pt(xw, ny0 - 0.12, nz1 + 0.15),
              _pt(xw, ny1 + 0.12, nz1 + 0.15),
              _pt(xw, ny1 + 0.12, nz0 - 0.15),
              _fogged(neon, cz).withValues(alpha: blink ? 0.08 : 0.28));
          _batch.quad(
              _pt(xw, ny0, nz0),
              _pt(xw, ny0, nz1),
              _pt(xw, ny1, nz1),
              _pt(xw, ny1, nz0),
              _fogged(blink ? const Color(0xFF3A2440) : neon, cz));
          _batch.quad(
              _pt(xw, ny0 + 0.1, nz0 + 0.3),
              _pt(xw, ny0 + 0.1, nz1 - 0.3),
              _pt(xw, ny1 - 0.1, nz1 - 0.3),
              _pt(xw, ny1 - 0.1, nz0 + 0.3),
              _fogged(blink ? const Color(0xFF2B1A33) : Colors.white, cz)
                  .withValues(alpha: 0.7));
        }
        // Peron kenarı (sarı şerit)
        _batch.quad(
            _pt(side * 1.62, 0.01, za),
            _pt(side * 1.62, 0.01, zb),
            _pt(side * 1.7, 0.01, zb),
            _pt(side * 1.7, 0.01, za),
            _fogged(const Color(0xFFD9B04F), cz));
      }
    }
    _batch.flush(canvas, _flat);
    _lampsAndGantries(canvas);
  }

  /// Peron lambaları (zemine sıcak ışık havuzu) ve raylar üzerinde
  /// katener direkleri + teller. Hepsi trenlerin dışında / üstünde
  /// kaldığı için varlıklardan önce çizilir.
  void _lampsAndGantries(Canvas canvas) {
    const zf = _SubwayCatScreenState.zFar;
    const metal = Color(0xFF3A2440);
    // Teller (her şeridin üstünde, kameraya çok yakın kısım ekran dışında)
    final wz0 = camZ + 1.2;
    for (final l in const [-1.0, 0.0, 1.0]) {
      _batch.quad(_pt(l - 0.012, 4.15, wz0), _pt(l + 0.012, 4.15, wz0),
          _pt(l + 0.012, 4.15, zf), _pt(l - 0.012, 4.15, zf), metal);
    }
    // Katener direkleri (24 birimde bir)
    const gStep = 24.0;
    for (var z = zf - (zf % gStep) - g.dist % gStep;
        z > nearZ + 0.4;
        z -= gStep) {
      final c = _fogged(metal, z);
      for (final sd in const [-1.0, 1.0]) {
        _batch.quad(_pt(sd * 1.85 - 0.06, 0, z), _pt(sd * 1.85 + 0.06, 0, z),
            _pt(sd * 1.85 + 0.06, 4.45, z), _pt(sd * 1.85 - 0.06, 4.45, z), c);
      }
      _batch.quad(_pt(-1.91, 4.3, z), _pt(1.91, 4.3, z), _pt(1.91, 4.45, z),
          _pt(-1.91, 4.3 + 0.15, z), c);
      for (final l in const [-1.0, 0.0, 1.0]) {
        _batch.quad(_pt(l - 0.02, 4.15, z), _pt(l + 0.02, 4.15, z),
            _pt(l + 0.02, 4.3, z), _pt(l - 0.02, 4.3, z), c);
      }
    }
    // Lambalar (12 birimde bir, direklerin arasında; iki yanda sırayla)
    const lStep = 12.0;
    final lampOff = (g.dist + 6) % lStep;
    final lampIdx0 = ((g.dist + 6) / lStep).floor();
    for (var z = zf - (zf % lStep) - lampOff; z > nearZ + 0.4; z -= lStep) {
      final idx = lampIdx0 + ((z + lampOff) / lStep).round();
      final sd = idx.isEven ? -1.0 : 1.0;
      final lx = sd * 1.95;
      // ışık havuzu: kameraya yaklaşırken söner ve asla yakın düzlemin
      // arkasına taşmaz (taşarsa izdüşüm patlar, ekranı dev bir ışık
      // huzmesi kaplar).
      final glow = _lampGlow(z);
      if (glow > 0.01) {
        final pz0 = math.max(z - 1.1, nearZ + 0.6);
        _batch.quad(
            _pt(sd * 1.1, 0.006, pz0),
            _pt(sd * 2.1, 0.006, pz0),
            _pt(sd * 2.1, 0.006, z + 1.1),
            _pt(sd * 1.1, 0.006, z + 1.1),
            const Color(0xFFFFC98A).withValues(alpha: 0.16 * glow));
      }
      final c = _fogged(metal, z);
      _batch.quad(_pt(lx - 0.035, 0, z), _pt(lx + 0.035, 0, z),
          _pt(lx + 0.035, 2.5, z), _pt(lx - 0.035, 2.5, z), c);
      _batch.quad(_pt(lx, 2.44, z), _pt(lx - sd * 0.45, 2.44, z),
          _pt(lx - sd * 0.45, 2.5, z), _pt(lx, 2.5, z), c);
      _batch.quad(
          _pt(lx - sd * 0.47, 2.36, z),
          _pt(lx - sd * 0.3, 2.36, z),
          _pt(lx - sd * 0.3, 2.44, z),
          _pt(lx - sd * 0.47, 2.44, z),
          _fogged(const Color(0xFFFFF0C8), z));
    }
    _batch.flush(canvas, _flat);
    // Lamba haleleri
    for (var z = zf - (zf % lStep) - lampOff; z > nearZ + 0.4; z -= lStep) {
      final idx = lampIdx0 + ((z + lampOff) / lStep).round();
      final sd = idx.isEven ? -1.0 : 1.0;
      final c = _pt(sd * 1.95 - sd * 0.385, 2.36, z);
      final glow = _lampGlow(z);
      if (glow <= 0.01) continue;
      _p.color = const Color(0xFFFFD9A0).withValues(alpha: 0.22 * glow);
      canvas.drawCircle(c, 0.32 * f / _d(z), _p);
    }
  }

  /// Lamba ışığının görünürlüğü: uzakta sis, yakında (kameraya ~3 birim
  /// kala) yumuşakça söner.
  double _lampGlow(double z) =>
      (1 - _fogT(z)) * ((_d(z) - 1.2) / 2.5).clamp(0.0, 1.0);

  // ── Varlıklar (uzaktan yakına) ──
  void _entities(Canvas canvas) {
    // Oyuncunun yanından geçen trenler oyuncudan önce çizilir (önündeymiş
    // gibi sıralanır); kameraya oyuncudan yakın nesneler ondan sonra.
    double trainKey(_Ob t) => t.z < 0 && t.z + t.len > 0 ? 0.001 : t.z;
    final visible = _vis..clear();
    final trains = _trains..clear();
    for (final o in g.obs) {
      if (o.dead || o.z >= _SubwayCatScreenState.zFar) continue;
      visible.add(o);
      if (o.isTrain) trains.add(o);
    }
    // Çatıdaki coin / güçlendirmeler bulundukları trenden hemen SONRA
    // çizilir; yoksa trenin ön yüzü ve çatısı onları örter.
    final keys = _keys..clear();
    for (final o in visible) {
      var k = o.isTrain ? trainKey(o) : o.z;
      if (!o.isTrain && o.z >= 0 && o.y >= _SubwayCatScreenState.trainH * 0.8) {
        for (final t in trains) {
          if ((t.x - o.x).abs() < 0.3 && o.z >= t.z && o.z <= t.z + t.len) {
            k = trainKey(t) - 1e-4;
            break;
          }
        }
      }
      keys[o] = k;
    }
    double key(_Ob o) => keys[o]!;
    final list = visible..sort((a, b) => key(b).compareTo(key(a)));
    var playerDrawn = false;
    for (final o in list) {
      if (!playerDrawn && key(o) < 0) {
        _player(canvas);
        playerDrawn = true;
      }
      switch (o.k) {
        case _K.train:
          _train(canvas, o);
          break;
        case _K.barrier:
          _billboard(canvas, kSprBarrier, o.x, 0, o.z, 0.95);
          break;
        case _K.bar:
          _billboard(canvas, kSprHighBar, o.x, 0, o.z, 0.95);
          break;
        case _K.coin:
          final fr = const [
            kSprCoin0,
            kSprCoin1,
            kSprCoin2,
            kSprCoin3,
            kSprCoin4,
            kSprCoin5
          ][((g.animT * 12 + o.z * 0.7).floor()) % 6];
          _billboard(canvas, fr, o.x, o.y - 0.16, o.z, 0.32);
          break;
        case _K.magnet:
        case _K.sneaker:
        case _K.double:
          final spr = o.k == _K.magnet
              ? kSprMagnet
              : o.k == _K.sneaker
                  ? kSprSneaker
                  : kSprDouble;
          final bob = math.sin(g.animT * 4) * 0.08;
          final c = _pt(o.x, o.y + bob, o.z);
          final r = 0.38 * f / _d(o.z);
          _p.color = const Color(0xFFB48CFF)
              .withValues(alpha: 0.3 + 0.15 * math.sin(g.animT * 6));
          canvas.drawCircle(c, r, _p);
          _billboard(canvas, spr, o.x, o.y + bob - 0.22, o.z, 0.5);
          break;
      }
    }
    if (!playerDrawn) _player(canvas);
    _guard(canvas);
  }

  /// Zemine oturan sprite: genişlik [w] dünya birimi, en-boy oranı korunur.
  void _billboard(
      Canvas canvas, List<String> spr, double x, double y, double z, double w) {
    if (z <= nearZ + 0.1) return;
    final img = SpriteBank.instance.of(spr);
    final h = w * img.height / img.width;
    final bl = _pt(x - w / 2, y, z);
    final tr = _pt(x + w / 2, y + h, z);
    final ft = _fogT(z);
    drawSprite(canvas, spr, Rect.fromLTRB(bl.dx, tr.dy, tr.dx, bl.dy),
        tint: fog.withValues(alpha: ft * 0.85));
  }

  void _train(Canvas canvas, _Ob o) {
    final l = o.x;
    final z0 = math.max(o.z, nearZ), z1 = o.z + o.len;
    if (z1 <= nearZ) return;
    const h = _SubwayCatScreenState.trainH, hw = _SubwayCatScreenState.trainHW;
    const skins = [
      [Color(0xFFFF80AB), Color(0xFFD63F78), Color(0xFFFFC2D6)],
      [Color(0xFF4FA3FF), Color(0xFF2A5BA8), Color(0xFFA9D6FF)],
      [Color(0xFF45D6A0), Color(0xFF1E8A63), Color(0xFFA8F0D0)],
    ];
    final sk = skins[o.skin % 3];
    final zc = (z0 + math.min(z1, _SubwayCatScreenState.zFar)) / 2;

    // Yan yüz (kameraya bakan taraf)
    if ((l - camX).abs() > hw * 0.6) {
      final sx = l < camX ? l + hw : l - hw;
      final zEnd = math.min(z1, _SubwayCatScreenState.zFar);
      _batch.quad(_pt(sx, 0.05, z0), _pt(sx, 0.05, zEnd), _pt(sx, h, zEnd),
          _pt(sx, h, z0), _fogged(sk[1], zc));
      // pencere şeridi
      _batch.quad(_pt(sx, 0.62, z0), _pt(sx, 0.62, zEnd), _pt(sx, 0.92, zEnd),
          _pt(sx, 0.92, z0), _fogged(const Color(0xFF2A5BA8), zc));
      for (var zz = o.z + 1.0; zz < zEnd; zz += 2.2) {
        if (zz < nearZ) continue;
        _batch.quad(
            _pt(sx, 0.64, zz),
            _pt(sx, 0.64, zz + 1.4),
            _pt(sx, 0.9, zz + 1.4),
            _pt(sx, 0.9, zz),
            _fogged(const Color(0xFFA9D6FF), zz));
      }
      // beyaz bant
      _batch.quad(_pt(sx, 0.45, z0), _pt(sx, 0.45, zEnd), _pt(sx, 0.52, zEnd),
          _pt(sx, 0.52, z0), _fogged(Colors.white, zc));
      // tekerlek gölgesi
      _batch.quad(_pt(sx, 0.0, z0), _pt(sx, 0.0, zEnd), _pt(sx, 0.12, zEnd),
          _pt(sx, 0.12, z0), _fogged(const Color(0xFF2B1220), zc));
    }
    // Çatı
    if (camY > h) {
      final zEnd = math.min(z1, _SubwayCatScreenState.zFar);
      _batch.quad(_pt(l - hw, h, z0), _pt(l + hw, h, z0), _pt(l + hw, h, zEnd),
          _pt(l - hw, h, zEnd), _fogged(sk[2], zc));
      _batch.quad(
          _pt(l - 0.12, h + 0.001, z0),
          _pt(l + 0.12, h + 0.001, z0),
          _pt(l + 0.12, h + 0.001, zEnd),
          _pt(l - 0.12, h + 0.001, zEnd),
          _fogged(const Color(0xFFB8BCC8), zc));
    }
    _batch.flush(canvas, _flat);

    // Ön yüz (sprite)
    if (o.z > nearZ && o.z < _SubwayCatScreenState.zFar) {
      final spr =
          const [kSprTrainPink, kSprTrainBlue, kSprTrainMint][o.skin % 3];
      final bl = _pt(l - hw - 0.02, 0, o.z);
      final tr = _pt(l + hw + 0.02, h, o.z);
      final rect = Rect.fromLTRB(bl.dx, tr.dy, tr.dx, bl.dy);
      drawSprite(canvas, spr, rect,
          tint: fog.withValues(alpha: _fogT(o.z) * 0.85));
      if (o.vz > 0) {
        // Hareketli tren: yanıp sönen farlar
        final on = (g.animT * 8).floor() % 2 == 0;
        if (on) {
          _p.color = const Color(0xFFFFF3B0).withValues(alpha: 0.85);
          final r = rect.width * 0.09;
          canvas.drawCircle(
              Offset(
                  rect.left + rect.width * 0.13, rect.top + rect.height * 0.68),
              r,
              _p);
          canvas.drawCircle(
              Offset(rect.right - rect.width * 0.13,
                  rect.top + rect.height * 0.68),
              r,
              _p);
        }
      }
    }
    if (o.ramp) _ramp(canvas, o);
  }

  /// Rampa trenin önünde, kameraya trenden yakındır: trenin ön yüzünden
  /// SONRA çizilir ki ön yüzü örtsün (aksi hâlde rampa saydam görünür).
  void _ramp(Canvas canvas, _Ob o) {
    final l = o.x;
    const h = _SubwayCatScreenState.trainH, hw = _SubwayCatScreenState.trainHW;
    if (o.ramp &&
        o.z - _SubwayCatScreenState.rampLen < _SubwayCatScreenState.zFar) {
      final ra = math.max(o.z - _SubwayCatScreenState.rampLen, nearZ);
      if (o.z > nearZ) {
        final ha = h * (1 - (o.z - ra) / _SubwayCatScreenState.rampLen);
        final rc = _fogged(const Color(0xFFC0892E), o.z);
        // yan üçgen (yakın taraf) — yüzeyden önce
        final sx = l < camX ? l + hw : l - hw;
        _batch.quad(_pt(sx, 0, ra), _pt(sx, 0, o.z), _pt(sx, h, o.z),
            _pt(sx, ha, ra), _fogged(const Color(0xFF7F5418), o.z));
        _batch.quad(_pt(l - hw, ha, ra), _pt(l + hw, ha, ra),
            _pt(l + hw, h, o.z), _pt(l - hw, h, o.z), rc);
        // basamak şeritleri
        for (var k = 1; k < 6; k++) {
          final zz = o.z - _SubwayCatScreenState.rampLen * k / 6;
          if (zz <= ra) continue;
          final hh = h * (1 - (o.z - zz) / _SubwayCatScreenState.rampLen);
          _batch.quad(
              _pt(l - hw, hh, zz),
              _pt(l + hw, hh, zz),
              _pt(l + hw, hh, zz + 0.12),
              _pt(l - hw, hh, zz + 0.12),
              _fogged(const Color(0xFF7F5418), zz));
        }
        _batch.flush(canvas, _flat);
      }
    }
  }

  void _player(Canvas canvas) {
    final blink = g.invuln > 0 && (g.animT * 12).floor() % 2 == 0;
    // Gölge
    final shC = _pt(g.x, g.support, 0);
    final sw = 0.5 * f / _d(0) * (1 - ((g.y - g.support) / 3).clamp(0.0, 0.6));
    _p.color = Colors.black.withValues(alpha: 0.35);
    canvas.drawOval(
        Rect.fromCenter(center: shC, width: sw, height: sw * 0.3), _p);
    if (blink) return;

    List<String> spr;
    if (g._phase == _Phase.dying || g._phase == _Phase.over) {
      spr = kSprRunnerSlide;
    } else if (g.sliding) {
      spr = kSprRunnerSlide;
    } else if (!g.grounded) {
      spr = kSprRunnerJump;
    } else {
      spr = const [
        kSprRunner0,
        kSprRunner1,
        kSprRunner2,
        kSprRunner3
      ][((g.dist * 1.6).floor()) % 4];
    }
    const w = 0.66;
    const hgt = w * 28 / 22;
    final bl = _pt(g.x - w / 2, g.y, 0);
    final tr = _pt(g.x + w / 2, g.y + hgt, 0);
    final rect = Rect.fromLTRB(bl.dx, tr.dy, tr.dx, bl.dy);
    final lean = ((g.lane - g.x) * 0.35).clamp(-0.3, 0.3);
    canvas.save();
    canvas.translate(rect.bottomCenter.dx, rect.bottomCenter.dy);
    canvas.rotate(lean);
    if (g._phase == _Phase.dying) {
      canvas.rotate(math.min(1.2, g.deathT * 3) * (g.x >= 0 ? -1 : 1) * 0.5);
    }
    canvas.translate(-rect.bottomCenter.dx, -rect.bottomCenter.dy);
    drawSprite(canvas, spr, rect);
    canvas.restore();
    // Mıknatıs halkası
    if (g.magnetT > 0) {
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFED343D)
            .withValues(alpha: 0.35 + 0.25 * math.sin(g.animT * 10));
      canvas.drawCircle(rect.center, rect.height * 0.7, _p);
      _p.style = PaintingStyle.fill;
    }
    if (g.sneakerT > 0 && g.grounded) {
      _p.color = const Color(0xFFFF80AB).withValues(alpha: 0.5);
      canvas.drawCircle(rect.bottomCenter, rect.width * 0.15, _p);
    }
  }

  void _guard(Canvas canvas) {
    if (g.guardZ < -3.2) return;
    final z = g.guardZ;
    if (_d(z) < 0.5) return;
    final spr = ((g.animT * 8).floor() % 2 == 0) ? kSprGuard0 : kSprGuard1;
    const w = 0.7;
    const hgt = w * 30 / 22;
    final bl = _pt(g.guardX - w / 2 + 0.25, 0, z);
    final tr = _pt(g.guardX + w / 2 + 0.25, hgt, z);
    drawSprite(canvas, spr, Rect.fromLTRB(bl.dx, tr.dy, tr.dx, bl.dy));
  }

  void _particles(Canvas canvas) {
    for (final p in g.parts) {
      if (_d(p.z) < 0.4) continue;
      final c = _pt(p.x, p.y, p.z);
      final s = p.size * f / _d(p.z);
      _flat.color = p.color.withValues(alpha: (p.life / p.max).clamp(0.0, 1.0));
      canvas.drawRect(Rect.fromCenter(center: c, width: s, height: s), _flat);
    }
  }

  @override
  bool shouldRepaint(covariant _RunnerPainter old) => false;
}
