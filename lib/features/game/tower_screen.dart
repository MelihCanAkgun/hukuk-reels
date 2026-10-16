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
import 'game_leaderboard.dart';
import 'game_pause_overlay.dart';
import 'revive_overlay.dart';
import 'tower_rules.dart';
import '../../core/widgets/pressable.dart';

part 'tower_painter.dart';

/// "Adliye Kulesi": kat kat adalet sarayı yükseltme oyunu (Stack türü).
///
/// Kayan kat doğru anda bırakılır; alttaki katın dışında kalan kısım
/// kesilip düşer, kule giderek incelir. Art arda 5 mükemmel yerleşimden
/// sonra seri sürdükçe her mükemmel yerleşim katı biraz genişletir. Hız yükseldikçe artar; her 8 katta bir başka ülkenin
/// adalet sarayının mimarisine geçilir. Oyun bitince kule baştan sona
/// gösterilir ve tepeye cüppeli bir avukat kız iner.
///
/// Dünya birimi = sprite pikseli; kat [kTowerFloorPx] birim yüksekliğinde.
/// Kule (yerleşmiş katlar + meydan) 8 katlık parçalar hâlinde [ui.Picture]'lara
/// kaydedilir; her karede yalnız ekrandaki parçalar, kayan kat, düşen
/// parçalar, gökyüzü ve efektler çizilir. Kule ne kadar yükselirse yükselsin
/// kare maliyeti sabit kalır.
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

  /// Cephe deseninin başlangıç x'i: desen bloğa yapışıktır (blokla
  /// birlikte kayar), dünyaya değil.
  final double tex;
  _Floor(this.x0, this.x1, this.era, {this.perfect = false, double? tex})
      : tex = tex ?? x0;
  double get w => x1 - x0;
  double get cx => (x0 + x1) / 2;
}

/// Kesilip düşen parça: kesildiği yerdeki dikdörtgen + öteleme/dönme.
class _Chunk {
  final double x0, x1, yb;
  final int era;
  double ox = 0, oy = 0, vx, vy = 0, rot = 0, vr;
  final double tex;
  _Chunk(this.x0, this.x1, this.yb, this.era, this.vx, this.vr, this.tex);
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
  // Kraliçe tahtı: önce o düşer, kız sonra üstüne oturur.
  double throneY = 0, throneVy = 0, throneLandT = -1;
  bool throneSpawned = false;

  /// Kız sprite'ının alt kenarı, tahta oturduğunda kat üstünden bu kadar
  /// yukarıda kalır (kalça çizgisi = minder üstü).
  static const double seatLift = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SfxService.instance.init();
    LeaderboardGame.tower.syncLocalBest().ignore();
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
  double get speed => towerSpeed(score);
  double get tolerance => towerTolerance(score);
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
    throneSpawned = false;
    throneLandT = -1;
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
    // Yaş yalnız en üst katın animasyonunda kullanılır.
    top.age += dt;
    if (growT < 1) {
      growT = math.min(1, growT + dt / 0.35);
      final k = Curves.easeOutBack.transform(growT);
      top
        ..x0 = g0a + (g0b - g0a) * k
        ..x1 = g1a + (g1b - g1a) * k;
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
    final drop = resolveTowerDrop(
        moverCx: mx,
        moverW: mw,
        topX0: tp.x0,
        topX1: tp.x1,
        tolerance: tolerance);
    final era = eraOf(nextFloor);
    final yb = topY;

    if (drop.kind == TowerDropKind.miss) {
      _miss(era);
      return;
    }
    late _Floor f;
    if (drop.kind == TowerDropKind.perfect) {
      // ── Mükemmel ──
      // Mükemmel: kat (deseniyle) alttakine oturur, sütunlar hizalanır.
      f = _Floor(tp.x0, tp.x1, era, perfect: true, tex: tp.tex);
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
      if (towerStreakGrows(streak, every: growEvery) && f.w < baseW - 0.5) {
        _grow(f);
        popups.add(
            _Popup('KAT GENİŞLEDİ!', sx, sy + 22, const Color(0xFFB8F5D8), 13));
      }
    } else {
      // ── Kesildi ──
      // Kesilen kat, kayarken görünen desenini aynen korur.
      f = _Floor(drop.x0, drop.x1, era, tex: mx - mw / 2);
      floors.add(f);
      streak = 0;
      final dir = drop.rightSide ? 1 : -1;
      if (drop.hasChunk) {
        chunks.add(_Chunk(drop.chunk0, drop.chunk1, yb, era, dir * 26.0,
            dir * (1.2 + _rng.nextDouble()), mx - mw / 2));
        _crumble(drop.rightSide ? drop.x1 : drop.x0, yb, dir, era);
      }
      SfxService.instance.slice();
      HapticFeedback.lightImpact();
      shake.kick(1.2, 0.15);
    }
    SfxService.instance.stack(score);
    scorePop = 1;
    // Genişleme animasyonu sürüyorsa sıradaki kat hedef genişlikte gelir.
    mw = growT < 1 ? g1b - g0b : f.w;
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

  void _grow(_Floor f, {double by = growBy}) {
    final w = towerGrownWidth(f.w, baseW, by);
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
    chunks.add(_Chunk(
        mx - mw / 2,
        mx + mw / 2,
        topY,
        era,
        (mx > top.cx ? 1 : -1) * 30,
        (mx > top.cx ? 1 : -1) * 1.6,
        mx - mw / 2));
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
      // İkinci şans: son kat belirgin şekilde genişler (en az +24 ya da
      // %50), devam etmek kolaylaşsın.
      final f = top;
      final by = math.max(24.0, f.w * 0.5);
      if (f.w < baseW - 0.5 && floors.length > 1) {
        _grow(f, by: by);
        popups.add(_Popup('KAT GENİŞLEDİ!', _sx(f.cx), _sy(topY) - 12,
            const Color(0xFFB8F5D8), 14));
      }
      mw = math.min(baseW, f.w + by);
      if (floors.length <= 1) mw = top.w;
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
    throneSpawned = false;
    throneLandT = -1;
    LeaderboardGame.tower.report(score).ignore();
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
    if (finT >= girlAt && !throneSpawned) {
      throneSpawned = true;
      throneY = camY + (anchorY + 70) / camS; // ekranın üstünden
      throneVy = -80;
    }
    if (throneSpawned && throneLandT < 0) {
      throneVy = math.max(-640, throneVy - 900 * dt);
      throneY += throneVy * dt;
      if (throneY <= topY) {
        throneY = topY;
        throneLandT = 0;
        SfxService.instance.stack(0);
        HapticFeedback.heavyImpact();
        shake.kick(2.6, 0.24);
        particles.burst(top.cx, -topY, 18,
            const [Color(0xFFFFFFFF), Color(0xFFE4E0EA), Color(0xFFFFD36A)],
            speed: 70,
            life: 0.6,
            size: 2,
            gravity: 140,
            angle: -math.pi / 2,
            spread: 2.8);
      }
    }
    if (throneLandT >= 0) throneLandT += dt;
    if (throneLandT >= 0.45 && !girlSpawned) {
      girlSpawned = true;
      girlY = camY + (anchorY + 40) / camS;
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
      final seat = topY + seatLift;
      if (girlY <= seat) {
        girlY = seat;
        landT = 0;
        SfxService.instance.girl();
        HapticFeedback.mediumImpact();
        shake.kick(1.2, 0.15);
        particles.burst(top.cx, -(topY + 16), 10,
            const [Color(0xFFFFE08A), Color(0xFFFFFFFF), Color(0xFFE85A8A)],
            speed: 45,
            life: 0.55,
            size: 1.6,
            gravity: 100,
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

  /// Testlerde: soruyu doğru bilmiş gibi ikinci şansı başlatır.
  @visibleForTesting
  void debugRevive() => _doRevive();

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

  void _openLeaderboard() {
    _pause();
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const GameLeaderboard(game: LeaderboardGame.tower)));
  }

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
          _circleBtn(Icons.leaderboard_rounded, _openLeaderboard,
              label: 'İkimizin sıralaması'),
          const SizedBox(width: 6),
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

  Widget _circleBtn(IconData icon, VoidCallback onTap,
      {String label = 'Oyunlara dön'}) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
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
                    'Katı tam üstüne bırak. 5 mükemmelden sonra\n'
                    'seri sürdükçe kat her seferinde genişler.',
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
    return Pressable(
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
