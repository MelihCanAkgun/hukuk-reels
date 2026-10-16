import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/sfx_service.dart';
import '../../core/widgets/pixel_logo.dart';
import '../reels/widgets/music_button.dart';
import 'arcade/arcade_kit.dart';
import 'game_pause_overlay.dart';
import 'revive_overlay.dart';

/// "Adliye Kulesi": kat kat adalet sarayı yükseltme oyunu (Stack türü).
///
/// Kayan kat doğru anda bırakılır; alttaki katın dışında kalan kısım
/// kesilip düşer, kule giderek incelir. Art arda 5 mükemmel yerleşim katı
/// biraz genişletir. Hız yükseldikçe artar; her 8 katta bir başka ülkenin
/// adalet sarayının mimarisine geçilir. Oyun bitince kule baştan sona
/// gösterilir ve tepeye cüppeli bir avukat kız iner.
///
/// Dünya birimi = sprite pikseli; kat [kTowerFloorPx] birim yüksekliğinde.
/// Kule (yerleşmiş katlar + meydan) bir [ui.Picture]'a kaydedilir ve yalnız
/// yeni kat eklenince yeniden kaydedilir; her karede yalnız kayan kat,
/// düşen parçalar, gökyüzü ve efektler çizilir.
class TowerScreen extends StatefulWidget {
  const TowerScreen({super.key});

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

enum _Phase { ready, playing, falling, over }

class _Floor {
  double x0, x1;
  final int era;
  double age = 0;
  bool perfect;
  _Floor(this.x0, this.x1, this.era, {this.perfect = false});
  double get w => x1 - x0;
  double get cx => (x0 + x1) / 2;
}

/// Kesilip düşen parça: kesildiği yerdeki dikdörtgen + öteleme/dönme.
class _Chunk {
  final double x0, x1, yb;
  final int era;
  double ox = 0, oy = 0, vx, vy = 0, rot = 0, vr;
  _Chunk(this.x0, this.x1, this.yb, this.era, this.vx, this.vr);
}

class _Popup {
  final String text;
  final Color color;
  final double size;
  double x, y, life;
  _Popup(this.text, this.x, this.y, this.color, this.size) : life = 1.1;
}

class _TowerScreenState extends State<TowerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ── Dünya ölçüleri ──
  static const double fh = 16; // kat yüksekliği (= kTowerFloorPx)
  static const double baseW = 96;
  static const double viewW = 200; // en dar ekranda görünen genişlik
  static const double plazaY = -9; // meydan seviyesi (basamakların altı)
  static const int floorsPerEra = 8;
  static const int growEvery = 5;
  static const double growBy = 12;

  final _rng = math.Random();
  late final Ticker _ticker;
  Duration? _last;
  double _acc = 0;
  final ValueNotifier<int> _frame = ValueNotifier(0);
  final art = _Art();

  bool _paused = false;
  _Phase _phase = _Phase.ready;
  bool _reviveUsed = false;
  bool _reviving = false;
  bool _newRecord = false;
  bool _overShown = false;

  // Ekran (layout'ta güncellenir)
  double screenW = 390, screenH = 844, padTop = 0;
  double get s => math.min(screenW / viewW, screenH / 360);
  double get anchorY => screenH * 0.38;

  // Kule
  final List<_Floor> floors = [];
  final List<_Chunk> chunks = [];
  final List<_Popup> popups = [];
  final particles = ParticleSystem();
  final shake = Shake();

  // Kayan kat
  double mx = 0, mw = baseW, u = 0;
  bool fromLeft = true;

  // Seri / skor
  int streak = 0, maxStreak = 0, perfects = 0;
  double scorePop = 0;
  int get score => floors.length - 1;

  // Büyüme animasyonu (en üst kat)
  double growT = 1, g0a = 0, g1a = 0, g0b = 0, g1b = 0;

  // Kamera
  double camY = 0, camS = 1, skyA = 0;
  double t = 0;

  // Dönem şeridi
  int bannerEra = 0;
  double bannerT = 99;

  // Final
  double fallT = 0; // kaçırılan katın düşüş süresi
  double finT = -1; // final zaman çizelgesi (<0: yok)
  double camY0 = 0, camS0 = 1; // finale girerken kamera
  double girlY = 0, girlVy = 0, landT = -1;
  bool girlSpawned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SfxService.instance.init();
    _resetWorld();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void didChangeMetrics() {
    if (_phase == _Phase.playing) _pause();
  }

  void _pause() {
    if (_paused) return;
    _ticker.stop();
    _last = null;
    _acc = 0;
    setState(() => _paused = true);
  }

  void _resume() {
    if (WidgetsBinding.instance.lifecycleState != null &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _last = null;
    _acc = 0;
    setState(() => _paused = false);
    _ticker.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  // ───────────────────────── Kurallar ─────────────────────────
  static int eraOf(int floor) =>
      floor <= 0 ? 0 : ((floor - 1) ~/ floorsPerEra) % kTowerEras.length;

  double get topY => floors.length * fh;
  _Floor get top => floors.last;
  int get nextFloor => floors.length;
  double get speed => math.min(235, 80 + score * 2.4);
  double get tolerance => math.max(1.7, 3.4 - score * 0.025);
  double get range => math.max(viewW * 0.56, mw * 0.5 + 64);

  /// Kamera yüksekliği: kule kısa iken meydan ekranın altında kalır.
  double get camTarget {
    final minCam = (screenH * 0.8 - anchorY) / s + plazaY;
    return math.max(topY + fh, minCam);
  }

  void _resetWorld() {
    floors
      ..clear()
      ..add(_Floor(-baseW / 2, baseW / 2, 0));
    chunks.clear();
    popups.clear();
    particles.clear();
    shake.reset();
    streak = maxStreak = perfects = 0;
    growT = 1;
    mw = baseW;
    fromLeft = true;
    u = 0;
    _placeMover();
    art.invalidate();
    camY = camTarget;
    camS = s;
    skyA = camY / fh;
    finT = -1;
    fallT = 0;
    girlSpawned = false;
    landT = -1;
    bannerT = 99;
    _overShown = false;
  }

  void _placeMover() {
    u = fromLeft ? 0 : 1;
    _updateMover(0);
  }

  void _updateMover(double dt) {
    final r = range;
    final v = _phase == _Phase.ready ? 45.0 : speed;
    u = (u + dt * v / (2 * r)) % 2;
    final lin = -r + 2 * r * (u < 1 ? u : 2 - u);
    final sine = -r * math.cos(math.pi * u);
    // Yükseldikçe hareket ortada hızlanan (sinüs) bir ritme kayar.
    final e = ((score - 18) / 30).clamp(0.0, 0.65);
    mx = top.cx + lin + (sine - lin) * e;
  }

  // ───────────────────────── Döngü ─────────────────────────
  void _tick(Duration now) {
    final last = _last;
    _last = now;
    if (last == null) return;
    final dt = (now - last).inMicroseconds / 1e6;
    if (dt <= 0) return;
    _acc += math.min(dt, 0.05);
    const step = 1 / 120;
    while (_acc >= step) {
      _update(step);
      _acc -= step;
    }
    _frame.value++;
  }

  void _update(double dt) {
    t += dt;
    shake.update(dt);
    particles.update(dt);
    scorePop = math.max(0, scorePop - dt * 4);
    bannerT += dt;
    for (final f in floors) {
      f.age += dt;
    }
    if (growT < 1) {
      growT = math.min(1, growT + dt / 0.35);
      final k = Curves.easeOutBack.transform(growT);
      top
        ..x0 = g0a + (g0b - g0a) * k
        ..x1 = g1a + (g1b - g1a) * k;
      if (growT >= 1) art.invalidate();
    }
    for (final c in chunks) {
      c.vy += 900 * dt;
      c.ox += c.vx * dt;
      c.oy += c.vy * dt;
      c.rot += c.vr * dt;
    }
    chunks.removeWhere((c) => c.oy > 1400 / math.max(0.2, camS / s));
    for (final p in popups) {
      p.life -= dt;
      p.y -= 34 * dt;
    }
    popups.removeWhere((p) => p.life <= 0);

    switch (_phase) {
      case _Phase.ready:
      case _Phase.playing:
        _updateMover(dt);
        camY += (camTarget - camY) * math.min(1, dt * 5);
        camS += (s - camS) * math.min(1, dt * 5);
        skyA = camY / fh;
        return;
      case _Phase.falling:
        fallT += dt;
        if (fallT > 0.95 && !_reviving && finT < 0) _onMissSettled();
        return;
      case _Phase.over:
        _finale(dt);
        return;
    }
  }

  // ───────────────────────── Yerleştirme ─────────────────────────
  void _drop() {
    if (_paused) return;
    if (_phase == _Phase.ready) {
      setState(() => _phase = _Phase.playing);
      fromLeft = true;
      _placeMover();
      _showBanner(eraOf(1));
      return;
    }
    if (_phase == _Phase.over) {
      // Final sürerken dokunmak gösterimi hızlandırır.
      if (finT >= 0 && finT < 2.6 && topY > 220) finT = 2.6;
      return;
    }
    if (_phase != _Phase.playing) return;
    if (growT < 1) {
      // Büyüme animasyonu sürerken bırakılırsa animasyonu hemen bitir.
      growT = 1;
      top
        ..x0 = g0b
        ..x1 = g1b;
    }

    final tp = top;
    final l = math.max(mx - mw / 2, tp.x0);
    final r = math.min(mx + mw / 2, tp.x1);
    final overlap = r - l;
    final delta = mx - tp.cx;
    final era = eraOf(nextFloor);
    final yb = topY;

    if (overlap <= 0.5) {
      _miss(era);
      return;
    }
    late _Floor f;
    if (delta.abs() <= tolerance) {
      // ── Mükemmel ──
      f = _Floor(tp.x0, tp.x1, era, perfect: true);
      floors.add(f);
      streak++;
      perfects++;
      maxStreak = math.max(maxStreak, streak);
      SfxService.instance.perfect(streak);
      HapticFeedback.mediumImpact();
      _sparkle(f, 18);
      final sx = _sx(f.cx), sy = _sy(yb + fh) - 10;
      popups.add(_Popup(streak >= 2 ? 'MÜKEMMEL x$streak' : 'MÜKEMMEL', sx, sy,
          const Color(0xFFFFE08A), 16));
      if (streak % growEvery == 0 && f.w < baseW - 0.5) {
        _grow(f);
        popups.add(
            _Popup('KAT GENİŞLEDİ!', sx, sy + 22, const Color(0xFFB8F5D8), 13));
      }
    } else {
      // ── Kesildi ──
      f = _Floor(l, r, era);
      floors.add(f);
      streak = 0;
      final rightSide = delta > 0;
      final c0 = rightSide ? r : mx - mw / 2;
      final c1 = rightSide ? mx + mw / 2 : l;
      if (c1 - c0 > 0.3) {
        chunks.add(_Chunk(c0, c1, yb, era, (rightSide ? 1 : -1) * 26,
            (rightSide ? 1 : -1) * (1.2 + _rng.nextDouble())));
        _crumble(rightSide ? r : l, yb, rightSide ? 1 : -1, era);
      }
      SfxService.instance.slice();
      HapticFeedback.lightImpact();
      shake.kick(1.2, 0.15);
    }
    SfxService.instance.stack(score);
    scorePop = 1;
    mw = f.w;
    art.invalidate();
    _dust(f);
    // Yeni kayan kat
    fromLeft = !fromLeft;
    _placeMover();
    if (eraOf(nextFloor) != era) {
      _showBanner(eraOf(nextFloor));
      SfxService.instance.era();
    }
    setState(() {});
  }

  void _grow(_Floor f) {
    final w = math.min(baseW, f.w + growBy);
    g0a = f.x0;
    g1a = f.x1;
    g0b = f.cx - w / 2;
    g1b = f.cx + w / 2;
    growT = 0;
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) SfxService.instance.grow();
    });
    for (var i = 0; i < 2; i++) {
      final side = i == 0 ? g0b : g1b;
      particles.burst(side, -(topY - fh / 2), 10,
          const [Color(0xFFB8F5D8), Color(0xFFFFFFFF), Color(0xFFFFE08A)],
          speed: 70, life: 0.7, size: 2, gravity: 60);
    }
    mw = w;
  }

  void _miss(int era) {
    chunks.add(_Chunk(mx - mw / 2, mx + mw / 2, topY, era,
        (mx > top.cx ? 1 : -1) * 30, (mx > top.cx ? 1 : -1) * 1.6));
    streak = 0;
    fallT = 0;
    shake.kick(3, 0.3);
    SfxService.instance.miss();
    HapticFeedback.heavyImpact();
    setState(() => _phase = _Phase.falling);
  }

  void _onMissSettled() {
    if (!_reviveUsed) {
      setState(() => _reviving = true);
      return;
    }
    _startFinale();
  }

  void _doRevive() {
    setState(() {
      _reviveUsed = true;
      _reviving = false;
      _phase = _Phase.playing;
      chunks.clear();
      mw = top.w;
      fromLeft = !fromLeft;
      _placeMover();
    });
  }

  void _giveUp() {
    setState(() => _reviving = false);
    _startFinale();
  }

  void _startFinale() {
    _phase = _Phase.over;
    finT = 0;
    camY0 = camY;
    camS0 = camS;
    girlSpawned = false;
    landT = -1;
    ProgressService.instance.submitTowerScore(score).then((rec) {
      if (!mounted) return;
      if (rec) setState(() => _newRecord = true);
    });
    setState(() {});
  }

  bool get _longTower => topY > 220;

  void _finale(double dt) {
    finT += dt;
    final hh = screenH;
    final endS = s * 1.3; // finalde kıza biraz yaklaş
    final endCam = topY + (hh * 0.36 - anchorY) / endS;
    double ease(double x) => Curves.easeInOutCubic.transform(x.clamp(0.0, 1.0));
    double girlAt;
    if (_longTower) {
      final fitS = math.min(s, hh * 0.7 / (topY - plazaY + 50));
      final mid = (topY + plazaY) / 2 + 6;
      final fitCam = mid + (hh * 0.52 - anchorY) / fitS;
      if (finT < 1.4) {
        final k = ease(finT / 1.4);
        camS = camS0 + (fitS - camS0) * k;
        camY = camY0 + (fitCam - camY0) * k;
      } else if (finT < 2.6) {
        camS = fitS;
        camY = fitCam;
      } else {
        final k = ease((finT - 2.6) / 1.0);
        camS = fitS + (endS - fitS) * k;
        camY = fitCam + (endCam - fitCam) * k;
      }
      girlAt = 3.3;
    } else {
      final k = ease(finT / 0.7);
      camS = camS0 + (endS - camS0) * k;
      camY = camY0 + (endCam - camY0) * k;
      girlAt = 0.5;
    }
    if (finT >= girlAt && !girlSpawned) {
      girlSpawned = true;
      girlY = camY + (anchorY + 40) / camS; // ekranın üstünden
      girlVy = -60;
    }
    if (girlSpawned && landT < 0) {
      girlVy = math.max(-520, girlVy - 700 * dt);
      girlY += girlVy * dt;
      if (finT % 0.05 < dt) {
        particles.burst(top.cx, -(girlY + 26), 1,
            const [Color(0xFFFFE08A), Color(0xFFFFFFFF)],
            speed: 14, life: 0.5, size: 1.5);
      }
      if (girlY <= topY) {
        girlY = topY;
        landT = 0;
        SfxService.instance.girl();
        HapticFeedback.mediumImpact();
        shake.kick(1.5, 0.18);
        particles.burst(top.cx, -topY, 14,
            const [Color(0xFFFFFFFF), Color(0xFFE4E0EA), Color(0xFFFFE08A)],
            speed: 55,
            life: 0.55,
            size: 2,
            gravity: 120,
            angle: -math.pi / 2,
            spread: 2.6);
      }
    }
    if (landT >= 0) {
      landT += dt;
      if (landT > 1.0 && !_overShown) {
        _overShown = true;
        if (_newRecord || score >= 25) SfxService.instance.medal();
        setState(() {});
      }
    }
  }

  void _restart() {
    setState(() {
      _phase = _Phase.ready;
      _reviveUsed = false;
      _reviving = false;
      _newRecord = false;
      _resetWorld();
    });
  }

  // ───────────────────────── Efektler ─────────────────────────
  double _sx(double x) => screenW / 2 + x * camS;
  double _sy(double wy) => anchorY + (camY - wy) * camS;

  void _sparkle(_Floor f, int n) {
    particles.burst(f.cx, -(topY - fh / 2), n,
        const [Color(0xFFFFFFFF), Color(0xFFFFE08A), Color(0xFFFFF3B0)],
        speed: 80, life: 0.6, size: 2, spread: math.pi * 2);
  }

  void _dust(_Floor f) {
    for (final x in [f.x0, f.x1]) {
      particles.burst(
          x, -(topY - fh), 5, const [Color(0xFFE4E0EA), Color(0xFFB8BCC8)],
          speed: 30,
          life: 0.45,
          size: 2,
          gravity: 40,
          angle: x < f.cx ? math.pi : 0,
          spread: 1.2);
    }
  }

  void _crumble(double x, double yb, int dir, int era) {
    final pal = kTowerEras[era].palette;
    particles.burst(x, -(yb + fh / 2), 12, [pal['M']!, pal['D']!, pal['L']!],
        speed: 60,
        life: 0.8,
        size: 2.2,
        gravity: 420,
        angle: dir > 0 ? 0 : math.pi,
        spread: 1.6);
  }

  void _showBanner(int era) {
    bannerEra = era;
    bannerT = 0;
  }

  // ───────────────────────── Test yardımcıları ─────────────────────────
  @visibleForTesting
  String get phaseName => _phase.name;

  /// Testlerde: kayan kat hizalandığında bırakır ([miss] ise tamamen
  /// dışarıdayken).
  @visibleForTesting
  void autopilot({bool miss = false}) {
    if (_phase == _Phase.ready) return _drop();
    if (_phase != _Phase.playing) return;
    final d = mx - top.cx;
    if (miss) {
      if (d.abs() > top.w / 2 + mw / 2 + 2) _drop();
      return;
    }
    if (d.abs() <= math.max(tolerance * 0.9, speed / 125)) _drop();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.space ||
        k == LogicalKeyboardKey.arrowDown ||
        k == LogicalKeyboardKey.enter) {
      _drop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ───────────────────────── Arayüz ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final best = ProgressService.instance.towerHigh;
    padTop = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: LayoutBuilder(builder: (context, c) {
          if (c.maxWidth > 0 && c.maxHeight > 0) {
            final changed =
                (screenW - c.maxWidth).abs() + (screenH - c.maxHeight).abs() >
                    1;
            screenW = c.maxWidth;
            screenH = c.maxHeight;
            if (changed && _phase == _Phase.ready) {
              camY = camTarget;
              camS = s;
            }
          }
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _drop(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: ClipRect(
                      child: CustomPaint(
                          painter: _TowerPainter(this, repaint: _frame)),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(bottom: false, child: _topBar(best)),
                ),
                if (_phase == _Phase.ready) _readyOverlay(),
                if (_reviving)
                  ReviveOverlay(onRevive: _doRevive, onGiveUp: _giveUp),
                if (_phase == _Phase.over && _overShown) _overOverlay(best),
                if (_paused) GamePauseOverlay(onResume: _resume),
              ],
            ),
          );
        }),
      ),
    );
  }

  static const _pixelFont = 'PixelifySans';

  Widget _topBar(int best) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 14, 4),
      child: Row(
        children: [
          _circleBtn(
              Icons.arrow_back_rounded, () => Navigator.of(context).maybePop()),
          const SizedBox(width: 6),
          const PixelLogo(kLogoAdliyeKulesi, size: 24),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Adliye Kulesi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: _pixelFont,
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(color: Color(0xFF2B1220), blurRadius: 4)],
              ),
            ),
          ),
          MusicButton(onOpen: _pause),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PixelLogo(kLogoTrophy, size: 15),
                const SizedBox(width: 5),
                Text('$best',
                    style: const TextStyle(
                        fontFamily: _pixelFont,
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _readyOverlay() {
    return IgnorePointer(
      child: Column(
        children: [
          const Spacer(flex: 3),
          const Text('Adliye Kulesi',
              style: TextStyle(
                fontFamily: _pixelFont,
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFE08A),
                shadows: [
                  Shadow(color: Color(0xFF2B1220), offset: Offset(3, 3)),
                  Shadow(color: Color(0xFF2B1220), offset: Offset(-2, -2)),
                ],
              )),
          const SizedBox(height: 6),
          const Text('Dünyanın adalet saraylarını kat kat yükselt',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Color(0xFF2B1220), blurRadius: 6)])),
          const Spacer(flex: 6),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2B1220).withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Başlamak için dokun',
                    style: TextStyle(
                        fontFamily: _pixelFont,
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(
                    'Katı tam üstüne bırak. Art arda 5 mükemmel\n'
                    'yerleşim katı genişletir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _overOverlay(int best) {
    final era = kTowerEras[eraOf(score)];
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 460),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Transform.translate(
              offset: Offset(0, (1 - v) * 160),
              child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
          child: GestureDetector(
            onTap: () {}, // panel dokunuşu kuleye geçmesin
            child: Container(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: const Color(0xFFF4E3C1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2B1220), width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF2B1220), offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_newRecord ? 'Yeni Rekor!' : 'Kule Tamamlandı',
                      style: const TextStyle(
                        fontFamily: _pixelFont,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD63F78),
                      )),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PixelLogo(era.flag, size: 18, palette: kArcadePalette),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('${era.city} · ${era.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8A5A3A))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _stat('KAT', '$score')),
                      Expanded(child: _stat('EN İYİ', '$best')),
                      Expanded(child: _stat('MÜKEMMEL', '$perfects')),
                      Expanded(child: _stat('SERİ', '$maxStreak')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _btn('Tekrar Oyna', primary: true, onTap: _restart),
                  const SizedBox(height: 8),
                  _btn('Oyunlara Dön',
                      primary: false,
                      onTap: () => Navigator.of(context).maybePop()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        children: [
          Text(label,
              maxLines: 1,
              style: const TextStyle(
                  fontFamily: _pixelFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC0892E))),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    fontFamily: _pixelFont,
                    fontSize: 26,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2B1220))),
          ),
        ],
      );

  Widget _btn(String label,
      {required bool primary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? const Color(0xFFFF80AB) : const Color(0xFFE2C998),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2B1220), width: 2.5),
          boxShadow: const [
            BoxShadow(color: Color(0xFF2B1220), offset: Offset(0, 3)),
          ],
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: _pixelFont,
                color: primary ? Colors.white : const Color(0xFF2B1220),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                shadows: primary
                    ? const [
                        Shadow(color: Color(0xFF8E2350), offset: Offset(1, 2))
                      ]
                    : null)),
      ),
    );
  }
}

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

  ui.Picture? tower;
  int _towerKey = -1;
  void invalidate() => _towerKey = -1;

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
      {double lit = 0, bool cap = false, double whiten = 0}) {
    if (x1 - x0 <= 0) return;
    lit *= litStrength(era) * floorLit((yb / fh).round());
    final e = kTowerEras[era];
    final top = -(yb + fh);
    void tiles(ui.Image img) {
      final m = img.width.toDouble();
      for (var tx = (x0 / m).floorToDouble() * m; tx < x1; tx += m) {
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

  /// Yerleşmiş katlar (en üstteki hariç) + meydan; gerekirse yeniden
  /// kaydeder. [lit] gece pencere ışığı (16 kademede pişirilir).
  ui.Picture towerPicture(List<_Floor> floors, double lit) {
    final litQ = (lit * 16).round();
    final key = floors.length * 32 + litQ;
    if (tower != null && key == _towerKey) return tower!;
    _towerKey = key;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    _plaza(c);
    final l = litQ / 16;
    for (var i = 0; i < floors.length - 1; i++) {
      final f = floors[i];
      final cap = _TowerScreenState.eraOf(i + 1) != f.era && i > 0;
      drawFloor(c, f.era, f.x0, f.x1, i * fh, lit: l, cap: cap);
    }
    // Eski resim dispose edilmez (web'de önceki kare kullanıyor olabilir).
    tower = rec.endRecording();
    return tower!;
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
    canvas.translate(W / 2 + sh.dx * S, anchorY + sh.dy * S);
    canvas.scale(S);
    canvas.translate(0, camY);

    canvas.drawPicture(g.art.towerPicture(g.floors, night));
    _topFloor(canvas);
    if (g._phase == _Phase.playing || g._phase == _Phase.ready) _mover(canvas);
    for (final c in g.chunks) {
      final cx = (c.x0 + c.x1) / 2, cy = -(c.yb + fh / 2);
      canvas.save();
      canvas.translate(cx + c.ox, cy + c.oy);
      canvas.rotate(c.rot);
      canvas.translate(-cx, -cy);
      g.art.drawFloor(canvas, c.era, c.x0, c.x1, c.yb, lit: night);
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
    _girl(canvas);
    canvas.restore();

    _hud(canvas);
  }

  // ── Gökyüzü (önbellekli) ──
  void _backdrop(Canvas canvas) {
    final key = (g.skyA * 4).round() * 100000 + W.round() * 100 + H.round();
    if (key != _skyKey || _skyPic == null) {
      _skyKey = key;
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
        lit: night, whiten: f.perfect ? (1 - f.age / 0.28) * 0.85 : 0);
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
    final x0 = g.mx - g.mw / 2, x1 = g.mx + g.mw / 2;
    final tp = g.top;
    final l = math.max(x0, tp.x0), r = math.min(x1, tp.x1);
    if (r > l) {
      _p.color = Colors.black.withValues(alpha: 0.22);
      canvas.drawRect(Rect.fromLTRB(l, -g.topY, r, -g.topY + 3), _p);
    }
    g.art.drawFloor(canvas, era, x0, x1, g.topY, lit: night);
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
        spr = kTwrLawyerBlink;
      } else if (lt < 2.6) {
        spr = ((lt - 0.35) / 0.2).floor() % 2 == 0
            ? kTwrLawyerWave0
            : kTwrLawyerWave1;
      } else {
        spr = (lt % 3.2) < 0.13 ? kTwrLawyerBlink : kTwrLawyerStand;
      }
    }
    final img = SpriteBank.instance.of(spr);
    final w = img.width.toDouble(), h = img.height.toDouble();
    // gölge
    if (g.landT >= 0) {
      _p.color = Colors.black.withValues(alpha: 0.25);
      canvas.drawRect(Rect.fromLTWH(x - 7, y - 1, 14, 1.5), _p);
    }
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
      // seri: 5 elmas (dolu olanlar mevcut seriyi gösterir)
      final n = g.streak % _TowerScreenState.growEvery;
      final full = g.streak > 0 && n == 0;
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
