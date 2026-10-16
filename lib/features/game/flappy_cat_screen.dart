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
import '../../core/widgets/pressable.dart';

part 'flappy_painter.dart';

/// Profilden açılan mini oyun: "Flappy Silly Cat".
///
/// Dünya 256 birim yüksekliğinde sanal bir tuvaldir; ekran ne olursa olsun
/// fizik ve zorluk aynı kalır, piksel sprite'lar tek ölçekle büyütülür.
/// Tüm sahne tek bir [CustomPainter] ile çizilir; her kare yalnız tuvali
/// yeniden boyar (setState yalnız katman değişimlerinde).
class FlappyCatScreen extends StatefulWidget {
  const FlappyCatScreen({super.key});

  @override
  State<FlappyCatScreen> createState() => _FlappyCatScreenState();
}

enum _Phase { ready, playing, dying, over }

class _Pipe {
  double x;
  final double baseGapY;
  final double gap;
  final double amp; // hareketli borularda dikey salınım genliği
  final double freq;
  final double phase;
  bool scored = false;
  _Pipe(this.x, this.baseGapY, this.gap,
      {this.amp = 0, this.freq = 0, this.phase = 0});
  double gapY(double t) =>
      amp == 0 ? baseGapY : baseGapY + math.sin(t * freq + phase) * amp;
}

class _Fish {
  double x;
  final double y;
  bool taken = false;
  _Fish(this.x, this.y);
}

class _Popup {
  double x, y, life;
  final String text;
  _Popup(this.x, this.y, this.text) : life = 0.8;
}

/// Gökyüzü paletleri: alacakaranlık → gece → şafak → gündüz (skorla döner).
class _Sky {
  final Color top, bottom, far, near, window, sun;
  final double stars; // yıldız görünürlüğü
  final bool moon;
  const _Sky(this.top, this.bottom, this.far, this.near, this.window, this.sun,
      this.stars, this.moon);
}

const _skies = [
  _Sky(Color(0xFF3A1E50), Color(0xFFFF8FB1), Color(0xFF8C4C86),
      Color(0xFF5A2A5E), Color(0xFFFFE08A), Color(0xFFFFE3EC), 0.35, true),
  _Sky(Color(0xFF0B0820), Color(0xFF34205A), Color(0xFF2E2350),
      Color(0xFF1C1534), Color(0xFFFFD86B), Color(0xFFF4F0FF), 1.0, true),
  _Sky(Color(0xFF5A6BD0), Color(0xFFFFC09E), Color(0xFF9A82C4),
      Color(0xFF6C5A9A), Color(0xFFFFE9B0), Color(0xFFFFF2B0), 0.0, false),
  _Sky(Color(0xFF4FB2FF), Color(0xFFD4F1FF), Color(0xFF9CC9E8),
      Color(0xFF6E9CC4), Color(0xFFBFE6FF), Color(0xFFFFF6C2), 0.0, false),
];

class _FlappyCatScreenState extends State<FlappyCatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ── Dünya ölçüleri (sanal birim) ──
  static const double vh = 256; // dünya yüksekliği
  static const double groundH = 30;
  static const double playH = vh - groundH;

  // ── Fizik ──
  static const double gravity = 1250; // birim/s²
  static const double flapV = -270; // tepe ≈ 29 birim, 0.22 s
  static const double maxFall = 400;
  static const double catR = 7.2; // çarpışma yarıçapı
  static const double pipeW = 26;
  static const double capW = 30;
  static const double capH = 11;
  static const double spacing = 106;

  final _rng = math.Random();
  late final Ticker _ticker;
  Duration? _last;
  double _acc = 0;
  final ValueNotifier<int> _frame = ValueNotifier(0);

  bool _paused = false;
  _Phase _phase = _Phase.ready;
  bool _resumeHover = false; // ekstra candan sonra dokununca devam

  double vw = 160; // ekran genişliği (sanal birim) — layout'ta güncellenir
  double get catX => math.min(vw * 0.3, 92);

  double catY = playH / 2, vy = 0, angle = 0;
  double flapT = 1; // son kanat çırpmadan beri (s)
  double t = 0; // oyun saati
  double scroll = 0; // toplam kaydırma (paralaks)
  double deadT = 0;
  double flash = 0;
  double scorePop = 0;
  double invuln = 0;

  final List<_Pipe> pipes = [];
  final List<_Fish> fish = [];
  final List<_Popup> popups = [];
  final particles = ParticleSystem();
  final shake = Shake();

  int score = 0;
  int fishCount = 0;
  bool _newRecord = false;
  DateTime _overAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool _reviveUsed = false;
  bool _reviving = false;

  // Gökyüzü geçişi
  double skyT = 0; // 0..4 arası sürekli değer
  _Sky get sky {
    final i = skyT.floor() % 4, j = (i + 1) % 4;
    final f = Curves.easeInOut.transform(skyT - skyT.floor());
    final a = _skies[i], b = _skies[j];
    return _Sky(
      lerpColor(a.top, b.top, f),
      lerpColor(a.bottom, b.bottom, f),
      lerpColor(a.far, b.far, f),
      lerpColor(a.near, b.near, f),
      lerpColor(a.window, b.window, f),
      lerpColor(a.sun, b.sun, f),
      a.stars + (b.stars - a.stars) * f,
      f < 0.5 ? a.moon : b.moon,
    );
  }

  double get speed => 78 + math.min(score, 60) * 0.35;
  double get gapSize => math.max(58, 72 - score * 0.3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SfxService.instance.init();
    LeaderboardGame.flappy.syncLocalBest().ignore();
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
    flapT += dt;
    flash = math.max(0, flash - dt * 4);
    scorePop = math.max(0, scorePop - dt * 4);
    invuln = math.max(0, invuln - dt);
    shake.update(dt);
    particles.update(dt);
    for (final p in popups) {
      p.life -= dt;
      p.y -= 26 * dt;
    }
    popups.removeWhere((p) => p.life <= 0);
    // Gökyüzü hedefine yumuşak geçiş
    final target = (score ~/ 12).toDouble();
    if (skyT < target) skyT = math.min(target, skyT + dt * 0.5);

    switch (_phase) {
      case _Phase.ready:
        scroll += 40 * dt;
        catY = playH * 0.45 + math.sin(t * 3.2) * 4;
        angle = 0;
        return;
      case _Phase.playing:
        if (_resumeHover) {
          catY = playH * 0.45 + math.sin(t * 3.2) * 4;
          return;
        }
        _play(dt);
        return;
      case _Phase.dying:
        _dying(dt);
        return;
      case _Phase.over:
        return;
    }
  }

  void _play(double dt) {
    vy = math.min(maxFall, vy + gravity * dt);
    catY += vy * dt;
    final targetAngle = vy < 0 ? -0.42 : math.min(1.45, vy / maxFall * 1.7);
    angle += (targetAngle - angle) * math.min(1, dt * (vy < 0 ? 18 : 6));

    final move = speed * dt;
    scroll += move;
    for (final p in pipes) {
      p.x -= move;
    }
    for (final f in fish) {
      f.x -= move;
    }
    if (pipes.isEmpty) {
      _spawn(vw + 30);
    } else if (pipes.last.x < vw + 20) {
      _spawn(pipes.last.x + spacing);
    }
    pipes.removeWhere((p) => p.x + capW < -10);
    fish.removeWhere((f) => f.x < -20 || f.taken);

    for (final p in pipes) {
      if (!p.scored && p.x + pipeW / 2 < catX) {
        p.scored = true;
        score++;
        scorePop = 1;
        SfxService.instance.point();
        HapticFeedback.selectionClick();
      }
    }
    for (final f in fish) {
      if (!f.taken && (f.x - catX).abs() < 12 && (f.y - catY).abs() < 11) {
        f.taken = true;
        score++;
        fishCount++;
        scorePop = 1;
        popups.add(_Popup(f.x, f.y - 8, '+1'));
        particles.burst(f.x, f.y, 14,
            const [Color(0xFFFFD36A), Color(0xFFFFF3B0), Color(0xFFFFFFFF)],
            speed: 70, life: 0.5, size: 2.2);
        SfxService.instance.coin(fishCount);
        HapticFeedback.lightImpact();
      }
    }

    if (catY < -24) {
      catY = -24;
      vy = 0;
    }
    if (catY + catR >= playH) {
      catY = playH - catR;
      _hit(ground: true);
      return;
    }
    if (invuln > 0) return;
    for (final p in pipes) {
      final g = p.gapY(t);
      final top = g - p.gap / 2, bot = g + p.gap / 2;
      final rects = [
        Rect.fromLTRB(p.x, -400, p.x + pipeW, top - capH),
        Rect.fromLTRB(p.x - (capW - pipeW) / 2, top - capH,
            p.x + pipeW + (capW - pipeW) / 2, top),
        Rect.fromLTRB(p.x - (capW - pipeW) / 2, bot,
            p.x + pipeW + (capW - pipeW) / 2, bot + capH),
        Rect.fromLTRB(p.x, bot + capH, p.x + pipeW, playH),
      ];
      for (final r in rects) {
        if (_circleHits(r)) {
          _hit(ground: false);
          return;
        }
      }
    }
  }

  bool _circleHits(Rect r) {
    final cx = catX.clamp(r.left, r.right);
    final cy = catY.clamp(r.top, r.bottom);
    final dx = catX - cx, dy = catY - cy;
    return dx * dx + dy * dy < catR * catR;
  }

  void _spawn(double x) {
    final gap = gapSize;
    const margin = 26.0;
    final minY = gap / 2 + margin + capH;
    final maxY = playH - gap / 2 - margin - capH;
    var gy = minY + _rng.nextDouble() * (maxY - minY);
    // Ardışık boşluklar arasında makul fark (adil zorluk)
    if (pipes.isNotEmpty) {
      final prev = pipes.last.baseGapY;
      gy = gy.clamp(prev - 88, prev + 88);
    }
    double amp = 0, freq = 0;
    if (score >= 15 &&
        _rng.nextDouble() < math.min(0.45, 0.2 + score * 0.006)) {
      amp = math.min(
          14 + _rng.nextDouble() * 12, math.min(gy - minY, maxY - gy) + 10);
      amp = math.max(0, amp);
      freq = 1.1 + _rng.nextDouble() * 0.8;
    }
    pipes.add(_Pipe(x, gy, gap,
        amp: amp, freq: freq, phase: _rng.nextDouble() * math.pi * 2));
    // Altın balık iki borunun arasında
    if (pipes.length > 1 && _rng.nextDouble() < 0.28) {
      final prev = pipes[pipes.length - 2];
      final fy = ((prev.baseGapY + gy) / 2 + (_rng.nextDouble() - 0.5) * 30)
          .clamp(30.0, playH - 30);
      fish.add(_Fish(x - spacing / 2 + pipeW / 2, fy));
    }
  }

  void _hit({required bool ground}) {
    _phase = _Phase.dying;
    deadT = 0;
    flash = 1;
    shake.kick(5, 0.35);
    SfxService.instance.hit();
    HapticFeedback.heavyImpact();
    particles.burst(
        catX,
        catY,
        18,
        const [
          Color(0xFF9C98A6),
          Color(0xFFE4E0EA),
          Color(0xFFFFFFFF),
          Color(0xFFFF80AB),
        ],
        speed: 90,
        life: 0.7,
        size: 2.4,
        gravity: 260);
    if (ground) {
      vy = 0;
      deadT = 0.35; // yere çarptıysa düşüş yok
    } else {
      vy = -120;
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted && _phase == _Phase.dying) SfxService.instance.fall();
      });
    }
    setState(() {});
  }

  void _dying(double dt) {
    deadT += dt;
    if (catY + catR < playH) {
      vy = math.min(maxFall * 1.2, vy + gravity * 1.3 * dt);
      catY = math.min(playH - catR, catY + vy * dt);
      angle += (1.57 - angle) * math.min(1, dt * 8);
      if (catY + catR >= playH) {
        shake.kick(3, 0.2);
        particles.burst(
            catX, playH, 10, const [Color(0xFFD9A066), Color(0xFF8A5A3A)],
            speed: 60,
            life: 0.5,
            size: 2,
            gravity: 200,
            angle: -math.pi / 2,
            spread: 2.2);
      }
    } else if (deadT > 0.75) {
      _gameOver();
    }
  }

  void _gameOver() {
    if (!_reviveUsed) {
      _phase = _Phase.over;
      _reviving = true;
      setState(() {});
      return;
    }
    _finishGame();
  }

  void _finishGame() {
    _phase = _Phase.over;
    _reviving = false;
    _overAt = DateTime.now();
    LeaderboardGame.flappy.report(score).ignore();
    ProgressService.instance.submitFlappyScore(score).then((rec) {
      if (!mounted) return;
      if (rec) setState(() => _newRecord = true);
      if (rec || score >= 10) SfxService.instance.medal();
    });
    setState(() {});
  }

  /// Doğru cevap: ekstra can; kedi ortalanır, önündeki borular temizlenir,
  /// dokununca kaldığı yerden devam edilir.
  void _doRevive() {
    setState(() {
      _reviveUsed = true;
      _reviving = false;
      catY = playH * 0.45;
      vy = 0;
      angle = 0;
      pipes.removeWhere((p) => p.x + capW > catX - 40 && p.x < catX + 200);
      fish.clear();
      _phase = _Phase.playing;
      _resumeHover = true;
      invuln = 1.2;
    });
  }

  void _giveUp() => _finishGame();

  void _restart() {
    setState(() {
      _phase = _Phase.ready;
      catY = playH * 0.45;
      vy = 0;
      angle = 0;
      pipes.clear();
      fish.clear();
      popups.clear();
      particles.clear();
      shake.reset();
      score = 0;
      fishCount = 0;
      t = 0;
      skyT = 0;
      _newRecord = false;
      _reviveUsed = false;
      _reviving = false;
      _resumeHover = false;
    });
  }

  void _flap() {
    if (_paused) return;
    if (_phase == _Phase.over) {
      if (_reviving) return;
      if (DateTime.now().difference(_overAt) <
          const Duration(milliseconds: 700)) {
        return;
      }
      _restart();
      return;
    }
    if (_phase == _Phase.dying) return;
    if (_phase == _Phase.ready) setState(() => _phase = _Phase.playing);
    if (_resumeHover) setState(() => _resumeHover = false);
    vy = flapV;
    flapT = 0;
    particles.burst(
        catX - 10, catY + 2, 4, const [Color(0xFFFFFFFF), Color(0xFFE4E0EA)],
        speed: 40, life: 0.45, size: 2, angle: math.pi * 0.85, spread: 1.0);
    SfxService.instance.flap();
    HapticFeedback.lightImpact();
  }

  /// Testlerde ve demo görüntülerinde kediyi sıradaki boşluğa yönlendirir.
  @visibleForTesting
  void autopilot() {
    if (_phase == _Phase.ready) return _flap();
    if (_phase != _Phase.playing || _resumeHover) return;
    final next = pipes.where((p) => p.x + pipeW > catX - catR).toList();
    final target = next.isEmpty ? playH * 0.5 : next.first.gapY(t) + 13;
    if (catY > target && vy > -40) _flap();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.space ||
        k == LogicalKeyboardKey.arrowUp ||
        k == LogicalKeyboardKey.keyW ||
        k == LogicalKeyboardKey.enter) {
      _flap();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Tek bir kanat çırpışı (dokunuşla başlar): yukarıdan aşağı vuruş,
  /// sonra kanat yukarı toparlanır.
  static const _stroke = [
    kSprFlappyCatUpMid,
    kSprFlappyCatMid,
    kSprFlappyCatDownMid,
    kSprFlappyCatDown,
    kSprFlappyCatDown,
    kSprFlappyCatDownMid,
    kSprFlappyCatMid,
    kSprFlappyCatUpMid,
    kSprFlappyCatUp,
  ];
  static const double _strokeFrame = 0.036;

  List<String> get catSprite {
    if (_phase == _Phase.dying || _phase == _Phase.over) {
      return kSprFlappyCatDead;
    }
    // Menüde ve "devam etmek için dokun" beklerken sakin, sürekli çırpış
    final hovering = _phase == _Phase.ready || _resumeHover;
    final i = hovering
        ? ((t % 0.6) / 0.6 * _stroke.length).floor()
        : (flapT / _strokeFrame).floor();
    if (i < _stroke.length) return _stroke[i];
    if (vy > 200) return kSprFlappyCatUp; // dalışta kanatlar yukarıda
    return kSprFlappyCatMid; // süzülme
  }

  // ───────────────────────── Arayüz ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final best = ProgressService.instance.flappyHigh;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: LayoutBuilder(builder: (context, c) {
          vw = c.maxHeight <= 0 ? 160 : c.maxWidth / (c.maxHeight / vh);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _flap(),
            // Katmanlar ne kadar dar olursa olsun sahne tüm ekranı kaplar.
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    // Gökyüzü / zemin kenarlardan taşar; kırpılmazsa geri
                    // dönüş kaydırmasında ana ekranın üstünde bir an görünür.
                    child: ClipRect(
                      child: CustomPaint(
                          painter: _FlappyPainter(this, repaint: _frame)),
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
                if (_resumeHover && _phase == _Phase.playing)
                  _hint('Devam etmek için dokun'),
                if (_phase == _Phase.over && _reviving)
                  ReviveOverlay(onRevive: _doRevive, onGiveUp: _giveUp),
                if (_phase == _Phase.over && !_reviving) _overOverlay(best),
                if (_paused) GamePauseOverlay(onResume: _resume),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _openLeaderboard() {
    _pause();
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const GameLeaderboard(game: LeaderboardGame.flappy)));
  }

  Widget _topBar(int best) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 14, 4),
      child: Row(
        children: [
          _circleBtn(
              Icons.arrow_back_rounded, () => Navigator.of(context).maybePop()),
          const SizedBox(width: 6),
          const PixelLogo(kLogoFlappyCat, size: 24),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Flappy Silly Cat',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'PixelifySans',
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
                        fontFamily: 'PixelifySans',
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

  Widget _hint(String text) => IgnorePointer(
        child: Align(
          alignment: const Alignment(0, 0.42),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2B1220).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(text,
                style: const TextStyle(
                    fontFamily: 'PixelifySans',
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      );

  Widget _readyOverlay() {
    return IgnorePointer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          const Text('Hazır mısın?',
              style: TextStyle(
                fontFamily: 'PixelifySans',
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFE08A),
                shadows: [
                  Shadow(color: Color(0xFF2B1220), offset: Offset(3, 3)),
                  Shadow(color: Color(0xFF2B1220), offset: Offset(-2, -2)),
                ],
              )),
          const Spacer(flex: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2B1220).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Uçmak için dokun',
                    style: TextStyle(
                        fontFamily: 'PixelifySans',
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Borulardan geç, altın balıkları kap!',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  List<String>? get _medal {
    if (score >= 40) return kSprMedalPlatinum;
    if (score >= 30) return kSprMedalGold;
    if (score >= 20) return kSprMedalSilver;
    if (score >= 10) return kSprMedalBronze;
    return null;
  }

  Widget _overOverlay(int best) {
    final medal = _medal;
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (context, v, child) => Transform.translate(
            offset: Offset(0, (1 - v) * 120),
            child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 34),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
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
              Text(_newRecord ? 'Yeni Rekor!' : 'Oyun Bitti',
                  style: const TextStyle(
                    fontFamily: 'PixelifySans',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD63F78),
                  )),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 74,
                    height: 82,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2C998),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: const Color(0xFFC0892E), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: medal == null
                        ? const Text('Madalya\n10 puanda',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF8A5A3A)))
                        : CustomPaint(
                            size: const Size(56, 63),
                            painter: _SpritePainter(medal)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _stat('SKOR', '$score'),
                        const SizedBox(height: 6),
                        _stat('EN İYİ', '$best'),
                        if (fishCount > 0) ...[
                          const SizedBox(height: 6),
                          _stat('BALIK', '$fishCount'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _btn('Tekrar Oyna', primary: true, onTap: _restart),
              const SizedBox(height: 10),
              _btn('Profile Dön',
                  primary: false,
                  onTap: () => Navigator.of(context).maybePop()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'PixelifySans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC0892E))),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'PixelifySans',
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B1220))),
        ],
      );

  Widget _btn(String label,
      {required bool primary, required VoidCallback onTap}) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                fontFamily: 'PixelifySans',
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
