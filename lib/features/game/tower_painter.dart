part of 'tower_screen.dart';

// ═══════════════════════════ Sanat önbelleği ═══════════════════════════

/// Kule resmi, uzak katmanlar ve kat çizimi. Durumla birlikte yaşar
/// (painter her build'de yeniden oluşturulur).
class _Art {
  static const double fh = _TowerScreenState.fh;
  static const Map<String, Color> _litPalette = {'Y': Color(0xFFFFD98A)};
  static const Map<String, Color> _coolLitPalette = {'Y': Color(0xFFE2F2FF)};

  /// Cam cepheli dönemlerde ışık serin ve hafif (yoksa tüm cephe sararır).
  static double litStrength(int era) => switch (kTowerEras[era].code) {
        'de' => 0.32,
        'eu' => 0.55,
        _ => 1.0,
      };

  /// Her katın ışığı biraz farklı: bazı katlar karanlık kalır.
  static double floorLit(int index) {
    final h = (index * 2654435761) & 0xFFFF;
    if (h % 10 < 2) return 0.15;
    return 0.7 + (h % 7) * 0.05;
  }

  final Map<int, List<String>> _litRows = {};
  final Paint _img = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;
  final Paint _flat = Paint()..isAntiAlias = false;

  // ── Kule resmi ──
  // Yerleşmiş katlar 8'erli parçalar hâlinde ayrı resimlere kaydedilir; her
  // karede yalnız ekrandaki parçalar çizilir. Yeni kat yalnız kendi
  // parçasını, gece ışığı yalnız görünen parçaları yeniden kaydettirir.
  // (Eskiden tüm kule tek resimdi: her karede baştan sona oynatılıyor ve her
  // katta baştan kaydediliyordu; kule yükseldikçe oyun ağırlaşıyordu.)
  static const int segFloors = 8;
  final Map<int, ui.Picture> _segs = {};
  final Map<int, int> _segKeys = {};
  ui.Picture? _plazaPic;

  /// Yeni oyunda tüm parçalar yeniden kaydedilir.
  void invalidate() {
    for (final p in _segs.values) {
      retire(p);
    }
    _segs.clear();
    _segKeys.clear();
  }

  // ── Resimlerin bırakılması ──
  // Değiştirilen resim hemen dispose edilmez: önceki kare hâlâ onu
  // kullanıyor olabilir. Kullanıldığı kareden iki çizim sonra bırakılır
  // (aksi hâlde web'de WASM belleğinde birikip duraklamalara yol açıyordu).
  int _paints = 0;
  final List<(ui.Picture, int)> _retired = [];
  void retire(ui.Picture? p) {
    if (p != null) _retired.add((p, _paints));
  }

  void beginPaint() {
    _paints++;
    if (_retired.isEmpty) return;
    _retired.removeWhere((e) {
      if (e.$2 > _paints - 2) return false;
      e.$1.dispose();
      return true;
    });
  }

  @visibleForTesting
  int get cachedSegments => _segs.length;
  @visibleForTesting
  int get pendingDisposals => _retired.length;

  /// Son karede çizilen kule parçası sayısı ve meydanın çizilip çizilmediği.
  @visibleForTesting
  int drawnSegments = 0;
  @visibleForTesting
  bool drewPlaza = false;

  static ui.Image? skyline, hills;

  ui.Image module(int era) => SpriteBank.instance
      .of(kTowerEras[era].module, palette: kTowerEras[era].palette);

  ui.Image litModule(int era) => SpriteBank.instance.of(
      _litRows.putIfAbsent(
          era,
          () => [
                for (final r in kTowerEras[era].module)
                  r
                      .replaceAll(RegExp('[^wW]'), '.')
                      .replaceAll(RegExp('[wW]'), 'Y')
              ]),
      palette: const {'de', 'eu'}.contains(kTowerEras[era].code)
          ? _coolLitPalette
          : _litPalette);

  /// Bir katı (dünya: x0..x1, alt kenar yb) tuvale çizer. Tuval y ekseni
  /// aşağı doğrudur: dünya y'si -y olarak çizilir.
  void drawFloor(Canvas c, int era, double x0, double x1, double yb,
      {double lit = 0, bool cap = false, double whiten = 0, double? tex}) {
    final origin = tex ?? x0;
    if (x1 - x0 <= 0) return;
    lit *= litStrength(era) * floorLit((yb / fh).round());
    final e = kTowerEras[era];
    final top = -(yb + fh);
    void tiles(ui.Image img) {
      final m = img.width.toDouble();
      for (var tx = origin + ((x0 - origin) / m).floorToDouble() * m;
          tx < x1;
          tx += m) {
        final a = math.max(x0, tx), b = math.min(x1, tx + m);
        if (b <= a) continue;
        c.drawImageRect(img, Rect.fromLTWH(a - tx, 0, b - a, fh),
            Rect.fromLTWH(a, top, b - a + 0.04, fh + 0.04), _img);
      }
    }

    _img.color = const Color(0xFFFFFFFF);
    tiles(module(era));
    if (lit > 0.02) {
      _img.color = Color.fromRGBO(255, 255, 255, lit.clamp(0.0, 1.0));
      tiles(litModule(era));
      _img.color = const Color(0xFFFFFFFF);
    }
    // Kenarlar: hacim için solda ışık, sağda gölge, uçlarda kontur.
    final p = e.palette;
    final w = x1 - x0;
    _flat.color = p['H']!.withValues(alpha: 0.55);
    if (w > 3) c.drawRect(Rect.fromLTWH(x0 + 1, top + 1, 1, fh - 3), _flat);
    _flat.color = p['O']!.withValues(alpha: 0.45);
    if (w > 3) c.drawRect(Rect.fromLTWH(x1 - 2, top + 1, 1, fh - 2), _flat);
    _flat.color = p['O']!;
    c.drawRect(Rect.fromLTWH(x0, top, math.min(1, w), fh), _flat);
    c.drawRect(
        Rect.fromLTWH(x1 - math.min(1, w), top, math.min(1, w), fh), _flat);
    if (cap) {
      // Dönem sonu saçağı: iki yandan taşan kornış.
      _flat.color = p['O']!;
      c.drawRect(Rect.fromLTWH(x0 - 2, top - 0.0, w + 4, 3), _flat);
      _flat.color = p['T']!;
      c.drawRect(Rect.fromLTWH(x0 - 1.5, top, w + 3, 2), _flat);
      _flat.color = p['H']!;
      c.drawRect(Rect.fromLTWH(x0 - 1.5, top, w + 3, 1), _flat);
    }
    if (whiten > 0.01) {
      _flat.color = Colors.white.withValues(alpha: whiten.clamp(0.0, 1.0));
      c.drawRect(Rect.fromLTWH(x0, top, w, fh), _flat);
    }
  }

  /// Yerleşmiş katlar (en üstteki hariç) ve meydan; yalnız dünya
  /// yüksekliği [lo]..[hi] aralığına değen parçalar çizilir. [lit] gece
  /// pencere ışığı (16 kademede pişirilir).
  void drawTower(
      Canvas c, List<_Floor> floors, double lit, double lo, double hi) {
    drawnSegments = 0;
    // Meydanın en yüksek öğesi (bayrak direği) zeminden ~46 birim yukarıda.
    drewPlaza = lo < 60;
    if (drewPlaza) {
      c.drawPicture(_plazaPic ??= () {
        final rec = ui.PictureRecorder();
        _plaza(Canvas(rec));
        return rec.endRecording();
      }());
    }
    final settled = floors.length - 1; // en üst kat canlı çizilir
    if (settled <= 0) return;
    final litQ = (lit * 16).round();
    const segH = segFloors * fh;
    final last = (settled - 1) ~/ segFloors;
    for (var k = math.max(0, (lo / segH).floor()); k <= last; k++) {
      final y0 = k * segH;
      if (y0 > hi) break;
      final from = k * segFloors, to = math.min(settled, from + segFloors);
      final key = (to - from) * 32 + litQ;
      var pic = _segs[k];
      if (pic == null || _segKeys[k] != key) {
        retire(pic);
        final rec = ui.PictureRecorder();
        final rc = Canvas(rec);
        final l = litQ / 16;
        for (var i = from; i < to; i++) {
          final f = floors[i];
          final cap = _TowerScreenState.eraOf(i + 1) != f.era && i > 0;
          drawFloor(rc, f.era, f.x0, f.x1, i * fh,
              lit: l, cap: cap, tex: f.tex);
        }
        pic = _segs[k] = rec.endRecording();
        _segKeys[k] = key;
      }
      c.drawPicture(pic);
      drawnSegments++;
    }
  }

  /// Meydan: adliye basamakları, taş zemin, lambalar, Themis heykeli,
  /// bayrak direği ve ağaçlar.
  void _plaza(Canvas c) {
    const bw = _TowerScreenState.baseW;
    const py = -_TowerScreenState.plazaY; // tuvalde meydan çizgisi (y=+9)
    // taş zemin
    _flat.color = const Color(0xFFCBBFA8);
    c.drawRect(const Rect.fromLTWH(-1600, py, 3200, 1200), _flat);
    _flat.color = const Color(0xFFE6DCC6);
    c.drawRect(const Rect.fromLTWH(-1600, py, 3200, 1), _flat);
    _flat.color = const Color(0xFFB3A68C);
    for (var y = py + 6; y < py + 80; y += 7) {
      c.drawRect(Rect.fromLTWH(-1600, y, 3200, 1), _flat);
    }
    for (var x = -1600.0; x < 1600; x += 14) {
      for (var y = py + 1; y < py + 80; y += 14) {
        c.drawRect(Rect.fromLTWH(x + (y ~/ 7 % 2) * 7, y, 1, 6), _flat);
      }
    }
    // basamaklar (3 kademe)
    final pal = kTowerEras[0].palette;
    for (var i = 0; i < 3; i++) {
      final w = bw + 10 + (2 - i) * 10.0;
      final y = py - 3.0 * (i + 1);
      _flat.color = pal['M']!;
      c.drawRect(Rect.fromLTWH(-w / 2, y, w, 3), _flat);
      _flat.color = pal['H']!;
      c.drawRect(Rect.fromLTWH(-w / 2, y, w, 1), _flat);
      _flat.color = pal['D']!;
      c.drawRect(Rect.fromLTWH(-w / 2, y + 2, w, 1), _flat);
    }
    void sprite(List<String> rows, double cx, {bool flip = false}) {
      final img = SpriteBank.instance.of(rows);
      final w = img.width.toDouble(), h = img.height.toDouble();
      final dst = Rect.fromLTWH(cx - w / 2, py - h + 1, w, h);
      if (flip) {
        c.save();
        c.translate(cx, 0);
        c.scale(-1, 1);
        c.translate(-cx, 0);
      }
      c.drawImageRect(img, Rect.fromLTWH(0, 0, w, h), dst, _img);
      if (flip) c.restore();
    }

    _img.color = const Color(0xFFFFFFFF);
    sprite(kTwrTree, -bw / 2 - 74);
    sprite(kTwrTree, bw / 2 + 78, flip: true);
    sprite(kTwrTree, -bw / 2 - 118, flip: true);
    sprite(kTwrTree, bw / 2 + 122);
    sprite(kTwrLamp, -bw / 2 - 14);
    sprite(kTwrLamp, bw / 2 + 14);
    sprite(kTwrThemis, -bw / 2 - 40);
    // bayrak direği + Türk bayrağı
    _flat.color = const Color(0xFF5C5866);
    c.drawRect(const Rect.fromLTWH(bw / 2 + 38, py - 44, 1.5, 44), _flat);
    _flat.color = const Color(0xFFFFD36A);
    c.drawRect(const Rect.fromLTWH(bw / 2 + 37.5, py - 46, 2.5, 2), _flat);
    final flag = SpriteBank.instance.of(kTwrFlagTR);
    c.drawImageRect(flag, const Rect.fromLTWH(0, 0, 16, 11),
        const Rect.fromLTWH(bw / 2 + 39.5, py - 43, 16, 11), _img);
  }

  /// Uzak İstanbul silüeti: kubbeler, minareler, Galata.
  static ui.Image skylineImage() => skyline ??= () {
        const w = 240, h = 64;
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        final p = Paint()
          ..isAntiAlias = false
          ..color = Colors.white;
        final r = math.Random(5);
        var x = 0.0;
        while (x < w) {
          final bw = 8 + r.nextInt(12).toDouble();
          final bh = 6 + r.nextDouble() * 12;
          c.drawRect(Rect.fromLTWH(x, h - bh, bw, bh), p);
          x += bw + r.nextInt(2);
        }
        void dome(double cx, double base, double rad) {
          for (var dy = 0.0; dy < rad; dy++) {
            final half =
                math.sqrt(math.max(0, rad * rad - dy * dy)).roundToDouble();
            c.drawRect(Rect.fromLTWH(cx - half, base - dy - 1, half * 2, 1), p);
          }
          c.drawRect(Rect.fromLTWH(cx - 0.5, base - rad - 4, 1, 4), p);
        }

        void minaret(double mx, double topY) {
          c.drawRect(Rect.fromLTWH(mx - 1, topY, 2.5, h - topY), p);
          c.drawRect(Rect.fromLTWH(mx - 2, topY + 10, 4.5, 1.5), p);
          for (var i = 0; i < 6; i++) {
            c.drawRect(
                Rect.fromLTWH(mx - 1 + i * 0.2, topY - i, 2.5 - i * 0.4, 1), p);
          }
        }

        // Büyük cami
        c.drawRect(const Rect.fromLTWH(40, 44, 44, 20), p);
        dome(62, 44, 15);
        dome(44, 48, 7);
        dome(80, 48, 7);
        minaret(32, 12);
        minaret(92, 12);
        minaret(26, 22);
        minaret(98, 22);
        // Galata
        c.drawRect(const Rect.fromLTWH(146, 24, 10, 40), p);
        c.drawRect(const Rect.fromLTWH(145, 22, 12, 3), p);
        for (var i = 0; i < 10; i++) {
          c.drawRect(Rect.fromLTWH(146 + i * 0.5, 21.0 - i, 10.0 - i, 1), p);
        }
        // Küçük cami
        c.drawRect(const Rect.fromLTWH(192, 50, 24, 14), p);
        dome(204, 50, 9);
        minaret(188, 26);
        minaret(220, 26);
        return rec.endRecording().toImageSync(w, h);
      }();

  static ui.Image hillsImage() => hills ??= () {
        const w = 240, h = 40;
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        final p = Paint()
          ..isAntiAlias = false
          ..color = Colors.white;
        for (var x = 0; x < w; x++) {
          final t = x / w * math.pi * 2;
          final y = 18 + math.sin(t) * 8 + math.sin(t * 2 + 1) * 4;
          c.drawRect(
              Rect.fromLTWH(x.toDouble(), y.roundToDouble(), 1, h - y), p);
        }
        return rec.endRecording().toImageSync(w, h);
      }();
}

// ═══════════════════════════ Çizim ═══════════════════════════

class _SkyStop {
  final double at;
  final Color top, bottom;
  const _SkyStop(this.at, this.top, this.bottom);
}

class _TowerPainter extends CustomPainter {
  _TowerPainter(this.g, {required Listenable repaint})
      : super(repaint: repaint);
  final _TowerScreenState g;

  static const double fh = _TowerScreenState.fh;

  // Yükseklik (kat) → gökyüzü
  static const _sky = [
    _SkyStop(0, Color(0xFF6EC6FF), Color(0xFFD8F1FF)),
    _SkyStop(14, Color(0xFF5A8EE8), Color(0xFFFFE0B0)),
    _SkyStop(26, Color(0xFF5B3F9A), Color(0xFFFF9E8A)),
    _SkyStop(38, Color(0xFF2B1E5E), Color(0xFFB0508E)),
    _SkyStop(52, Color(0xFF0C0B2A), Color(0xFF2E2468)),
    _SkyStop(72, Color(0xFF04030E), Color(0xFF12103A)),
  ];

  static (Color, Color) skyAt(double a) {
    if (a <= _sky.first.at) return (_sky.first.top, _sky.first.bottom);
    for (var i = 0; i < _sky.length - 1; i++) {
      final s0 = _sky[i], s1 = _sky[i + 1];
      if (a <= s1.at) {
        final k = (a - s0.at) / (s1.at - s0.at);
        return (
          lerpColor(s0.top, s1.top, k),
          lerpColor(s0.bottom, s1.bottom, k)
        );
      }
    }
    return (_sky.last.top, _sky.last.bottom);
  }

  static final List<Offset> _stars = List.generate(70, (i) {
    final r = math.Random(i * 7919 + 11);
    return Offset(r.nextDouble(), r.nextDouble());
  });

  static ui.Picture? _skyPic;
  static int _skyKey = -1;

  final Paint _p = Paint()..isAntiAlias = false;
  final Paint _img = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  late double W, H, S, camY, anchorY;
  double get night => ((g.skyA - 30) / 22).clamp(0.0, 1.0);

  double sy(double wy) => anchorY + (camY - wy) * S;
  double sx(double x) => W / 2 + x * S;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    g.art.beginPaint();
    W = size.width;
    H = size.height;
    S = g.camS;
    camY = g.camY;
    anchorY = g.anchorY;

    _backdrop(canvas);
    _celestial(canvas);
    _farLayers(canvas);
    _clouds(canvas);
    _ambient(canvas);

    // ── Dünya ──
    canvas.save();
    final sh = g.shake.offset;
    // Dünya orijini tam ekran pikseline oturur: kamera kayarken sprite
    // pikselleri yuvarlama yüzünden titremez.
    canvas.translate((W / 2 + sh.dx * S).roundToDouble(),
        (anchorY + sh.dy * S + camY * S).roundToDouble());
    canvas.scale(S);

    // Görünen dünya yüksekliği (sarsıntı ve saçak payıyla).
    final pad = 2 * fh + sh.dy.abs();
    g.art.drawTower(canvas, g.floors, night, camY - (H - anchorY) / S - pad,
        camY + anchorY / S + pad);
    _topFloor(canvas);
    if (g._phase == _Phase.playing || g._phase == _Phase.ready) _mover(canvas);
    for (final c in g.chunks) {
      final cx = (c.x0 + c.x1) / 2, cy = -(c.yb + fh / 2);
      canvas.save();
      canvas.translate(cx + c.ox, cy + c.oy);
      canvas.rotate(c.rot);
      canvas.translate(-cx, -cy);
      g.art.drawFloor(canvas, c.era, c.x0, c.x1, c.yb, lit: night, tex: c.tex);
      canvas.restore();
    }
    _lampGlow(canvas);
    for (final pt in g.particles.items) {
      _p.color = pt.color.withValues(alpha: pt.t);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(pt.x, pt.y), width: pt.size, height: pt.size),
          _p);
    }
    _throne(canvas, front: false);
    _girl(canvas);
    _throne(canvas, front: true);
    canvas.restore();

    _hud(canvas);
  }

  // ── Gökyüzü (önbellekli) ──
  void _backdrop(Canvas canvas) {
    final key = (g.skyA * 4).round() * 100000 + W.round() * 100 + H.round();
    if (key != _skyKey || _skyPic == null) {
      _skyKey = key;
      g.art.retire(_skyPic);
      final (top, bottom) = skyAt(g.skyA);
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      const bands = 18;
      final p = Paint()..isAntiAlias = false;
      for (var i = 0; i < bands; i++) {
        p.color =
            lerpColor(top, bottom, math.pow(i / (bands - 1), 1.4).toDouble());
        c.drawRect(Rect.fromLTWH(0, i * H / bands, W, H / bands + 1), p);
      }
      _skyPic = rec.endRecording();
    }
    canvas.drawPicture(_skyPic!);
  }

  // ── Güneş, ay, yıldızlar, kuzey ışıkları ──
  void _celestial(Canvas canvas) {
    final a = g.skyA;
    final px = math.max(2.0, S * 0.75);
    // yıldızlar
    final starA = ((a - 30) / 20).clamp(0.0, 1.0);
    if (starA > 0.01) {
      final drift = a * fh * 0.04 * S;
      for (var i = 0; i < _stars.length; i++) {
        final st = _stars[i];
        final tw = 0.5 + 0.5 * math.sin(g.t * (1.3 + i % 5 * 0.3) + i * 2.1);
        _p.color = Colors.white.withValues(alpha: starA * (0.25 + 0.75 * tw));
        final sz = i % 7 == 0 ? px * 1.5 : px * 0.8;
        final y = (st.dy * H * 0.85 + drift) % (H * 0.85);
        canvas.drawRect(Rect.fromLTWH(st.dx * W, y, sz, sz), _p);
      }
    }
    // güneş batar
    final sunK = (a / 40).clamp(0.0, 1.0);
    if (sunK < 1) {
      final cx = W * 0.78, cy = H * (0.17 + sunK * 0.78);
      final sun =
          lerpColor(const Color(0xFFFFF6C2), const Color(0xFFFF8A5C), sunK);
      _disc(canvas, cx, cy, 26 * px / 2, sun.withValues(alpha: 0.18));
      _disc(canvas, cx, cy, 18 * px / 2, sun.withValues(alpha: 0.35));
      _disc(canvas, cx, cy, 12 * px / 2, sun);
    }
    // ay doğar
    final moonK = ((a - 34) / 26).clamp(0.0, 1.0);
    if (moonK > 0) {
      final cx = W * 0.24, cy = H * (0.95 - moonK * 0.78);
      _disc(canvas, cx, cy, 22 * px / 2,
          const Color(0xFFF4F0FF).withValues(alpha: 0.12));
      _disc(canvas, cx, cy, 11 * px / 2, const Color(0xFFF4F0FF));
      final (top, bottom) = skyAt(a);
      final k = math.pow((cy / H).clamp(0.0, 1.0), 1.4).toDouble();
      _disc(canvas, cx + 4 * px / 2, cy - 3 * px / 2, 9 * px / 2,
          lerpColor(top, bottom, k));
    }
    // kuzey ışıkları (uzay eşiği)
    final aur = ((a - 62) / 14).clamp(0.0, 1.0);
    if (aur > 0) {
      for (var b = 0; b < 3; b++) {
        final col = [
          const Color(0xFF5FF2B4),
          const Color(0xFF8E7CFF),
          const Color(0xFF5FC8F2)
        ][b];
        _p.color = col.withValues(alpha: aur * 0.16);
        final base = H * (0.18 + b * 0.09);
        final step = px * 2;
        for (var x = 0.0; x < W; x += step) {
          final y = base +
              math.sin(x / W * 5 + g.t * 0.4 + b * 1.7) * H * 0.04 +
              math.sin(x / W * 13 + g.t * 0.9) * H * 0.01;
          final hh = H * (0.05 + 0.03 * math.sin(x / W * 7 + g.t + b));
          canvas.drawRect(Rect.fromLTWH(x, y, step, hh), _p);
        }
      }
    }
  }

  void _disc(Canvas c, double cx, double cy, double r, Color col) {
    _p.color = col;
    final step = math.max(2.0, S * 0.75);
    for (var dy = -r; dy < r; dy += step) {
      final m = dy + step / 2;
      final half =
          (math.sqrt(math.max(0, r * r - m * m)) / step).round() * step;
      c.drawRect(Rect.fromLTWH(cx - half, cy + dy, half * 2, step), _p);
    }
  }

  // ── Tepeler, İstanbul silüeti, Boğaz ──
  void _farLayers(Canvas canvas) {
    final (top, bottom) = skyAt(g.skyA);
    const base = -_TowerScreenState.plazaY;
    void layer(ui.Image img, double par, double scale, Color col,
        {double drift = 0}) {
      final y = anchorY + (camY * par + base) * S;
      if (y - img.height * S * scale > H) return;
      final tw = img.width * S * scale, th = img.height * S * scale;
      _img.colorFilter = ColorFilter.mode(col, BlendMode.srcIn);
      _img.color = Colors.white;
      var x = -((W * 0.5 + drift * S) % tw) - tw;
      final src =
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      while (x < W) {
        canvas.drawImageRect(
            img, src, Rect.fromLTWH(x, y - th, tw + 0.5, th), _img);
        x += tw;
      }
      _img.colorFilter = null;
      _p.color = col;
      canvas.drawRect(Rect.fromLTWH(0, y - 0.5, W, H - y + 1), _p);
    }

    final haze = lerpColor(bottom, top, 0.25);
    layer(_Art.hillsImage(), 0.18, 1.2,
        lerpColor(haze, const Color(0xFF6A7FB0), 0.35));
    layer(_Art.skylineImage(), 0.32, 0.9,
        lerpColor(haze, const Color(0xFF3A2440), 0.45 + night * 0.3));
    // Boğaz
    final wy = anchorY + (camY * 0.5 + base) * S;
    if (wy < H + 10) {
      final water = lerpColor(lerpColor(bottom, const Color(0xFF2E6FA8), 0.55),
          const Color(0xFF141A3A), night * 0.7);
      _p.color = water;
      canvas.drawRect(Rect.fromLTWH(0, wy - 6 * S, W, H - wy + 6 * S), _p);
      _p.color = Colors.white.withValues(alpha: 0.35);
      for (var i = 0; i < 9; i++) {
        final x = (i * 97 + g.t * (8 + i % 3 * 4) * S) % (W + 40) - 20;
        final y = wy - 5 * S + (i % 3) * 2 * S;
        canvas.drawRect(Rect.fromLTWH(x, y, (6 + i % 4 * 3) * S, S * 0.6), _p);
      }
    }
  }

  // ── Bulutlar (paralaks 0.6) ──
  void _clouds(Canvas canvas) {
    final op = (1 - ((g.skyA - 48) / 14)).clamp(0.0, 1.0);
    if (op <= 0) return;
    final img = SpriteBank.instance.of(kSprCloud);
    final (_, bottom) = skyAt(g.skyA);
    final tint = lerpColor(Colors.white, bottom, 0.25 + night * 0.4);
    for (var k = 0; k < 18; k++) {
      final r = math.Random(k * 131 + 7);
      final h = 120.0 + k * 52 + r.nextDouble() * 30;
      final y = anchorY + (camY * 0.6 - h) * S;
      if (y < -60 || y > H + 20) continue;
      final w = (36 + r.nextDouble() * 34) * S;
      final speed = 3 + r.nextDouble() * 5;
      final x =
          ((r.nextDouble() * (W + w) + g.t * speed * S) % (W + w * 2)) - w;
      _img.color =
          Colors.white.withValues(alpha: op * (0.65 + r.nextDouble() * 0.3));
      _img.colorFilter = ColorFilter.mode(tint, BlendMode.modulate);
      canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromLTWH(x, y, w, w * img.height / img.width),
          _img);
    }
    _img.colorFilter = null;
  }

  // ── Kuşlar, sıcak hava balonu, uydu, kayan yıldız ──
  void _ambient(Canvas canvas) {
    final a = g.skyA;
    final px = math.max(1.5, S * 0.7);
    // kuşlar (gündüz)
    final day = (1 - a / 30).clamp(0.0, 1.0);
    if (day > 0.05) {
      for (var f = 0; f < 2; f++) {
        final h = 150.0 + f * 210;
        final baseY = anchorY + (camY * 0.7 - h) * S;
        if (baseY < -20 || baseY > H) continue;
        final cyc = (g.t * (14 + f * 5) * S + f * 400) % (W + 300) - 150;
        for (var b = 0; b < 5; b++) {
          final bx = W - cyc + (b % 2 == 0 ? b : -b) * 7 * px + b * 9 * px;
          final by = baseY + b * 3 * px + math.sin(g.t * 2 + b) * px;
          final up = ((g.t * 7 + b).floor()) % 2 == 0;
          _p.color = const Color(0xFF3A2440).withValues(alpha: 0.7 * day);
          canvas.drawRect(Rect.fromLTWH(bx, by, px, px), _p);
          final wy = up ? by - px : by + px * 0.5;
          canvas.drawRect(Rect.fromLTWH(bx - 2 * px, wy, 2 * px, px), _p);
          canvas.drawRect(Rect.fromLTWH(bx + px, wy, 2 * px, px), _p);
        }
      }
    }
    // sıcak hava balonu (~20. kat civarı)
    {
      const h = 340.0;
      final y = anchorY + (camY * 0.75 - h) * S;
      if (y > -80 && y < H + 10) {
        final x = W * 0.2 + math.sin(g.t * 0.25) * W * 0.06;
        final img = SpriteBank.instance.of(kTwrBalloon);
        _img.color = Colors.white;
        canvas.drawImageRect(
            img,
            Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
            Rect.fromLTWH(x, y + math.sin(g.t * 1.1) * 3 * S,
                img.width * S * 0.9, img.height * S * 0.9),
            _img);
      }
    }
    // uydu
    if (a > 60) {
      final k = ((a - 60) / 10).clamp(0.0, 1.0);
      final x = (g.t * 12 * S) % (W + 60) - 30;
      final y = H * 0.16 + x * 0.08;
      _p.color = const Color(0xFFB8BCC8).withValues(alpha: k);
      canvas.drawRect(Rect.fromLTWH(x, y, 3 * px, 2 * px), _p);
      _p.color = const Color(0xFF4FA3FF).withValues(alpha: k);
      canvas.drawRect(Rect.fromLTWH(x - 3 * px, y, 3 * px, 2 * px), _p);
      canvas.drawRect(Rect.fromLTWH(x + 3 * px, y, 3 * px, 2 * px), _p);
      if ((g.t * 2).floor() % 2 == 0) {
        _p.color = const Color(0xFFFF5A5A).withValues(alpha: k);
        canvas.drawRect(Rect.fromLTWH(x + px, y - px, px, px), _p);
      }
    }
    // kayan yıldız
    if (night > 0.5) {
      const period = 5.0;
      final n = (g.t / period).floor();
      final ph = (g.t % period) / 0.8;
      if (ph < 1) {
        final r = math.Random(n * 977 + 3);
        final x0 = W * (0.2 + r.nextDouble() * 0.7),
            y0 = H * (0.05 + r.nextDouble() * 0.3);
        for (var k = 0; k < 12; k++) {
          final q = ph - k * 0.03;
          if (q < 0) break;
          _p.color = Colors.white
              .withValues(alpha: night * (1 - k / 12) * (1 - ph * 0.5));
          canvas.drawRect(
              Rect.fromLTWH(x0 - q * W * 0.35, y0 + q * H * 0.12,
                  px * (k == 0 ? 1.6 : 1), px),
              _p);
        }
      }
    }
  }

  // ── En üst kat (canlı: iniş zıplaması, parlama, büyüme) ──
  void _topFloor(Canvas canvas) {
    final i = g.floors.length - 1;
    final f = g.floors[i];
    final bounce =
        i == 0 ? 0.0 : 2.4 * math.exp(-f.age * 22) * math.cos(f.age * 38);
    canvas.save();
    canvas.translate(0, -bounce);
    g.art.drawFloor(canvas, f.era, f.x0, f.x1, i * fh,
        tex: f.tex,
        lit: night,
        whiten: f.perfect ? (1 - f.age / 0.28) * 0.85 : 0);
    canvas.restore();
    // Mükemmel halkaları
    if (f.perfect && f.age < 0.55) {
      for (var k = 0; k < 2; k++) {
        final age = f.age - k * 0.1;
        if (age < 0) continue;
        final grow = age * 46;
        _p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color =
              Colors.white.withValues(alpha: (1 - age / 0.45).clamp(0.0, 1.0));
        canvas.drawRect(
            Rect.fromLTRB(f.x0 - grow, -(i * fh + fh) - grow * 0.35,
                f.x1 + grow, -(i * fh) + grow * 0.35),
            _p);
        _p.style = PaintingStyle.fill;
      }
    }
  }

  // ── Kayan kat + alttakine düşen gölgesi ──
  void _mover(Canvas canvas) {
    final era = _TowerScreenState.eraOf(g.nextFloor);
    // Kayan kat tam ekran pikseli adımlarla ilerler; deseni bloğa
    // yapışık olduğundan piksel sütunları kayarken titremez.
    final x0 = ((g.mx - g.mw / 2) * S).roundToDouble() / S;
    final x1 = x0 + g.mw;
    final tp = g.top;
    final l = math.max(x0, tp.x0), r = math.min(x1, tp.x1);
    if (r > l) {
      _p.color = Colors.black.withValues(alpha: 0.22);
      canvas.drawRect(Rect.fromLTRB(l, -g.topY, r, -g.topY + 3), _p);
    }
    g.art.drawFloor(canvas, era, x0, x1, g.topY, lit: night, tex: x0);
  }

  // ── Gece lambaları ──
  void _lampGlow(Canvas canvas) {
    if (night < 0.05) return;
    const bw = _TowerScreenState.baseW;
    const py = -_TowerScreenState.plazaY;
    for (final x in const [-bw / 2 - 14, bw / 2 + 14]) {
      for (var k = 0; k < 3; k++) {
        _p.color = const Color(0xFFFFE6A8)
            .withValues(alpha: night * (0.10 - k * 0.025));
        final r = 6.0 + k * 5;
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(x, py - 22), width: r * 2, height: r * 2),
            _p);
      }
    }
  }

  // ── Kraliçe tahtı (arka: sırtlık+minder, ön: kolçaklar+ayaklar) ──
  void _throne(Canvas canvas, {required bool front}) {
    if (!g.throneSpawned) return;
    final x = g.top.cx;
    final y = -g.throneY;
    var sxk = 1.0, syk = 1.0;
    final lt = g.throneLandT;
    if (lt >= 0) {
      final sq = math.exp(-lt * 10) * math.cos(lt * 30);
      sxk = 1 + 0.16 * sq;
      syk = 1 - 0.16 * sq;
      if (!front) {
        _p.color = Colors.black.withValues(alpha: 0.28);
        canvas.drawRect(Rect.fromLTWH(x - 16, y - 1, 32, 1.5), _p);
      }
    }
    final img =
        SpriteBank.instance.of(front ? kTwrThroneFront : kTwrThroneBack);
    final w = img.width.toDouble(), h = img.height.toDouble();
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(sxk, syk);
    _img.color = Colors.white;
    canvas.drawImageRect(img, Rect.fromLTWH(0, 0, w, h),
        Rect.fromLTWH(-w / 2, -h + 0.5, w, h), _img);
    canvas.restore();
  }

  // ── Avukat kız ──
  void _girl(Canvas canvas) {
    if (!g.girlSpawned) return;
    final x = g.top.cx;
    final y = -g.girlY;
    List<String> spr;
    var sxk = 1.0, syk = 1.0;
    if (g.landT < 0) {
      spr = (g.t * 8).floor() % 2 == 0 ? kTwrLawyerFall0 : kTwrLawyerFall1;
    } else {
      final lt = g.landT;
      final sq = math.exp(-lt * 9) * math.cos(lt * 26);
      sxk = 1 + 0.22 * sq;
      syk = 1 - 0.22 * sq;
      if (lt < 0.35) {
        spr = kTwrLawyerSitBlink;
      } else if (lt < 2.6) {
        spr = ((lt - 0.35) / 0.2).floor() % 2 == 0
            ? kTwrLawyerSitWave0
            : kTwrLawyerSitWave1;
      } else {
        spr = (lt % 3.2) < 0.13 ? kTwrLawyerSitBlink : kTwrLawyerSit;
      }
    }
    final img = SpriteBank.instance.of(spr);
    final w = img.width.toDouble(), h = img.height.toDouble();
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(sxk, syk);
    _img.color = Colors.white;
    canvas.drawImageRect(img, Rect.fromLTWH(0, 0, w, h),
        Rect.fromLTWH(-w / 2, -h + 0.5, w, h), _img);
    canvas.restore();
  }

  // ── Skor, seri göstergesi, dönem şeridi, yazılar ──
  void _hud(Canvas canvas) {
    final playing = g._phase == _Phase.playing || g._phase == _Phase.falling;
    final top = g.padTop + 50;
    if (playing) {
      final pop = 1 + Curves.easeOut.transform(g.scorePop) * 0.22;
      drawOutlinedText(canvas, '${g.score}', Offset(W / 2, top + 34), 44 * pop);
      // seri: 5 elmas (dolu olanlar mevcut seriyi gösterir); seri 5'e
      // ulaşınca hepsi parlar ve seri sürdükçe öyle kalır (her mükemmel
      // katı genişletir).
      const every = _TowerScreenState.growEvery;
      final full = towerStreakGrows(g.streak, every: every);
      final n = full ? every : g.streak;
      const d = 7.0;
      for (var i = 0; i < 5; i++) {
        final cx = W / 2 + (i - 2) * 18;
        final cy = top + 70;
        final on = full || i < n;
        final glow = full ? 0.6 + 0.4 * math.sin(g.t * 12) : 1.0;
        final path = Path()
          ..moveTo(cx, cy - d)
          ..lineTo(cx + d, cy)
          ..lineTo(cx, cy + d)
          ..lineTo(cx - d, cy)
          ..close();
        _p.color = const Color(0xFF2B1220).withValues(alpha: 0.75);
        canvas.drawPath(path.shift(const Offset(0, 1.5)), _p);
        _p.color = on
            ? const Color(0xFFFFD36A).withValues(alpha: glow)
            : Colors.white.withValues(alpha: 0.22);
        canvas.drawPath(path, _p);
        if (on) {
          _p.color = const Color(0xFFFFF3B0);
          canvas.drawRect(Rect.fromLTWH(cx - 2, cy - 4, 2, 2), _p);
        }
      }
    }
    for (final p in g.popups) {
      drawOutlinedText(canvas, p.text, Offset(p.x, p.y), p.size,
          fill: p.color, opacity: (p.life / 0.5).clamp(0.0, 1.0));
    }
    _banner(canvas);
  }

  void _banner(Canvas canvas) {
    final bt = g.bannerT;
    if (bt > 3.2) return;
    final e = kTowerEras[g.bannerEra];
    final inK = Curves.easeOutBack.transform((bt / 0.35).clamp(0.0, 1.0));
    final out = ((bt - 2.8) / 0.4).clamp(0.0, 1.0);
    final w = math.min(W - 32, 330.0);
    const h = 50.0;
    final x = (W - w) / 2;
    final y = H - 34 - h + (1 - inK) * 90 + out * 90;
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h), const Radius.circular(8));
    _p.color = const Color(0xFF2B1220).withValues(alpha: 0.86 * (1 - out));
    canvas.drawRRect(r, _p);
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFD36A).withValues(alpha: 1 - out);
    canvas.drawRRect(r, _p);
    _p.style = PaintingStyle.fill;
    final flag = SpriteBank.instance.of(e.flag);
    _img.color = Colors.white.withValues(alpha: 1 - out);
    canvas.drawImageRect(flag, const Rect.fromLTWH(0, 0, 16, 11),
        Rect.fromLTWH(x + 12, y + (h - 22) / 2, 32, 22), _img);
    _text(canvas, e.city.toUpperCase(), x + 54, y + 8, 11,
        const Color(0xFFFFD36A), 1 - out, w - 64);
    _text(canvas, e.name, x + 54, y + 24, 14.5, Colors.white, 1 - out, w - 64);
  }

  static final Map<String, TextPainter> _texts = {};

  void _text(Canvas c, String s, double x, double y, double size, Color col,
      double opacity, double maxW) {
    if (opacity <= 0.01) return;
    final key = '$s|$size|${col.toARGB32()}|$maxW';
    final tp = _texts.putIfAbsent(key, () {
      if (_texts.length > 40) _texts.remove(_texts.keys.first);
      return TextPainter(
        text: TextSpan(
            text: s,
            style: TextStyle(
                fontFamily: 'PixelifySans',
                fontSize: size,
                fontWeight: FontWeight.w700,
                color: col)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxW);
    });
    if (opacity < 0.99) {
      c.saveLayer(Rect.fromLTWH(x, y, tp.width, tp.height),
          Paint()..color = Colors.white.withValues(alpha: opacity));
      tp.paint(c, Offset(x, y));
      c.restore();
    } else {
      tp.paint(c, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _TowerPainter old) => false;
}
