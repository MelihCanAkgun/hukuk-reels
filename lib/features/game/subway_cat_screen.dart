import 'dart:math' as math;
import 'dart:typed_data';
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

part 'subway_painter.dart';

/// Subway Surfers tarzı 3 şeritli sonsuz koşu: "Subway Silly".
///
/// Gerçek perspektif projeksiyonlu 2.5D sahne: kamera kedinin arkasında ve
/// yukarısında. Trenler uzun ve katıdır — önden çarpmak oyunu bitirir, yandan
/// sürtünmek tökezletir (ikinci tökezlemede bekçi yakalar). Rampalı trenlerin
/// üzerine çıkılır. Güçlendirmeler: mıknatıs, süper zıplama, 2x puan.
///
/// Performans: sahne tek [CustomPainter]; raylar, traversler ve binalar
/// tek `drawVertices` çağrısında toplu çizilir, sprite'lar önbellekli
/// [ui.Image]'lardır. Her kare yalnız tuvali boyar.
class SubwayCatScreen extends StatefulWidget {
  const SubwayCatScreen({super.key});

  @override
  State<SubwayCatScreen> createState() => _SubwayCatScreenState();
}

enum _Phase { ready, playing, dying, over }

enum _K { train, barrier, bar, coin, magnet, sneaker, double }

class _Ob {
  double z, pz;
  double x, y;
  final double len;
  final _K k;
  final bool ramp;
  final double vz; // trenin kendi hızı (oyuncuya doğru)
  final int skin;
  bool dead = false;
  _Ob(this.k, this.x, this.z,
      {this.len = 0, this.ramp = false, this.vz = 0, this.skin = 0, this.y = 0})
      : pz = z;
  bool get isTrain => k == _K.train;
  bool get isPower => k == _K.magnet || k == _K.sneaker || k == _K.double;
}

class _P3 {
  double x, y, z, vx, vy, vz, life;
  final double max, size;
  final Color color;
  _P3(this.x, this.y, this.z, this.vx, this.vy, this.vz, this.life, this.size,
      this.color)
      : max = life;
}

class _SubwayCatScreenState extends State<SubwayCatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ── Dünya sabitleri ──
  static const double camDist = 3.4;
  static const double camYBase = 2.3;
  static const double zFar = 72;
  static const double trainH = 1.15;
  static const double trainHW = 0.42;
  static const double rampLen = 3.4;
  static const double barrierH = 0.42;
  static const double barLow = 0.70, barHigh = 1.04;
  static const double standH = 0.75, slideH = 0.32;
  static const double gravity = 30;
  static const double jumpH = 0.98, superJumpH = 2.1;
  static const double slideDur = 0.62;
  static const double laneSpeed = 9; // birim/s

  bool _paused = false;
  double _acc = 0;
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  /// Üst çubuk / güç çubuğu yalnız gösterdikleri değerler değişince
  /// yeniden kurulur (her karede değil).
  final ValueNotifier<int> _hud = ValueNotifier<int>(0);
  int _hudSig() => Object.hash(
      finalScore,
      coins,
      doubleT > 0,
      (magnetT * 4).ceil(),
      (sneakerT * 4).ceil(),
      (doubleT * 4).ceil(),
      chaseT > 0 && _phase == _Phase.playing);
  late final Ticker _ticker;
  Duration? _last;
  final _rng = math.Random();

  _Phase _phase = _Phase.ready;
  bool _newRecord = false;
  bool _showHelp = false;
  bool _reviveUsed = false;
  bool _reviving = false;
  bool _caught = false;

  // Koşu
  double dist = 0, score = 0, animT = 0, speed = 10;
  int coins = 0;
  int coinStreak = 0;
  double coinStreakT = 0;

  // Oyuncu
  int lane = 0, prevLane = 0;
  double x = 0, y = 0, vy = 0;
  bool sliding = false;
  double slideT = 0;
  bool slideQueued = false;
  double jumpBuffer = 0;
  bool grounded = true;
  double support = 0;
  double invuln = 0;
  double stumbleCd = 0;

  // Bekçi
  double chaseT = 0; // > 0: bekçi peşte
  double guardZ = -4.5;
  double guardX = 0;

  // Güçlendirmeler (kalan süre)
  double magnetT = 0, sneakerT = 0, doubleT = 0;
  double get mult => doubleT > 0 ? 2 : 1;

  // Kamera
  double camX = 0, camY = camYBase;
  final shake = Shake();
  double flash = 0;
  Color flashColor = Colors.white;
  double deathT = 0;

  final List<_Ob> obs = [];
  final List<_P3> parts = [];

  // Üretici
  double _nextChunk = 0;
  int _safe = 0;
  double _nextPower = 180;

  // Jest
  Offset _panStart = Offset.zero;
  bool _acted = false;
  final FocusNode _focus = FocusNode();

  @visibleForTesting
  bool godMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SfxService.instance.init();
    LeaderboardGame.subway.syncLocalBest().ignore();
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
    _focus.requestFocus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _frame.dispose();
    _hud.dispose();
    _focus.dispose();
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
    _hud.value = _hudSig();
  }

  void _update(double dt) {
    animT += dt;
    shake.update(dt);
    flash = math.max(0, flash - dt * 3);
    _updateParts(dt);
    switch (_phase) {
      case _Phase.ready:
        // Menüde yavaşça ilerleyen sahne
        dist += 4 * dt;
        for (final o in obs) {
          o.pz = o.z;
          o.z -= 4 * dt;
        }
        _spawnAhead();
        _cleanup();
        return;
      case _Phase.dying:
        _dying(dt);
        return;
      case _Phase.over:
        return;
      case _Phase.playing:
        _run(dt);
    }
  }

  void _run(double dt) {
    speed = math.min(22, 10 + dist * 0.0075);
    final move = speed * dt;
    dist += move;
    score += move * mult;
    invuln = math.max(0, invuln - dt);
    stumbleCd = math.max(0, stumbleCd - dt);
    jumpBuffer = math.max(0, jumpBuffer - dt);
    coinStreakT = math.max(0, coinStreakT - dt);
    if (coinStreakT == 0) coinStreak = 0;
    _tickPowers(dt);

    // Bekçi
    if (chaseT > 0) {
      chaseT -= dt;
      guardZ += (-1.45 - guardZ) * math.min(1, dt * 3);
    } else {
      guardZ += (-5 - guardZ) * math.min(1, dt * 1.5);
    }
    guardX += (x - guardX) * math.min(1, dt * 4);

    // Yanal hareket
    final tx = lane.toDouble();
    final d = tx - x;
    x += d.sign * math.min(d.abs(), laneSpeed * dt);

    for (final o in obs) {
      o.pz = o.z;
      o.z -= move + o.vz * dt;
    }

    // Dikey fizik + zemin
    support = _supportAt(x);
    if (grounded) {
      if (support > y - 0.3 && support >= y) {
        y = support; // rampada tırmanma
      } else if (support < y - 0.02) {
        grounded = false; // trenin sonundan düştü
        vy = 0;
      }
    }
    if (!grounded) {
      vy -= gravity * dt;
      y += vy * dt;
      if (y <= support && vy <= 0) {
        final hard = vy < -9;
        y = support;
        vy = 0;
        grounded = true;
        if (hard) {
          SfxService.instance.land();
          _dust(4);
        }
        if (slideQueued) {
          slideQueued = false;
          _startSlide();
        } else if (jumpBuffer > 0) {
          jumpBuffer = 0;
          _jump();
        }
      }
    }
    if (sliding) {
      slideT -= dt;
      if (slideT <= 0) sliding = false;
    }

    if (!godMode && invuln == 0 && _collide()) return;
    _collect(dt);
    _cleanup();
    _spawnAhead();

    // Kamera
    camX += (x * 0.78 - camX) * math.min(1, dt * 7);
    final cy = camYBase + math.max(0, y) * 0.55;
    camY += (cy - camY) * math.min(1, dt * 4);
  }

  void _tickPowers(double dt) {
    void tick(double t, void Function(double) set) {
      if (t <= 0) return;
      final n = t - dt;
      if (n <= 0) SfxService.instance.powerDown();
      set(math.max(0, n));
    }

    tick(magnetT, (v) => magnetT = v);
    tick(sneakerT, (v) => sneakerT = v);
    tick(doubleT, (v) => doubleT = v);
  }

  /// [px] konumunda, oyuncu düzleminde (z = 0) zeminin yüksekliği.
  double _supportAt(double px) {
    var h = 0.0;
    for (final o in obs) {
      if (!o.isTrain || (o.x - px).abs() > trainHW + 0.05) continue;
      if (o.z <= 0.2 && o.z + o.len >= -0.2) {
        h = math.max(h, trainH);
      } else if (o.ramp && o.z > 0 && o.z - rampLen <= 0) {
        h = math.max(h, trainH * (1 - o.z / rampLen));
      }
    }
    return h;
  }

  /// true → oyun bitti (ölüm başladı).
  bool _collide() {
    final h = sliding ? slideH : standH;
    for (final o in obs) {
      if (o.dead) continue;
      switch (o.k) {
        case _K.train:
          if ((o.x - x).abs() > trainHW + 0.22) continue;
          if (o.z > 0.25 || o.z + o.len < -0.25) continue;
          if (y >= trainH - 0.2) continue; // çatıda
          // Rampadan çıkarken trenin önü: y zaten yüksek
          final frontal = o.pz > 0.25 - 1e-6 && o.z <= 0.25;
          if (frontal || (o.x - x).abs() < 0.3) {
            _die(train: true);
            return true;
          }
          if (stumbleCd == 0) _stumble();
          break;
        case _K.barrier:
          if ((o.x - x).abs() > 0.55) continue;
          if (!(o.pz > 0 && o.z <= 0)) continue;
          if (y < barrierH - 0.04) {
            _die(train: false);
            return true;
          }
          break;
        case _K.bar:
          if ((o.x - x).abs() > 0.55) continue;
          if (!(o.pz > 0 && o.z <= 0)) continue;
          if (y + h > barLow && y < barHigh) {
            _die(train: false);
            return true;
          }
          break;
        default:
          break;
      }
    }
    return false;
  }

  void _stumble() {
    stumbleCd = 0.6;
    SfxService.instance.stumble();
    HapticFeedback.mediumImpact();
    shake.kick(0.06, 0.25);
    flash = 0.5;
    flashColor = const Color(0xFFFF9A3C);
    final back = prevLane;
    prevLane = lane;
    lane = back;
    if (chaseT > 0) {
      _caught = true;
      _die(train: false);
      return;
    }
    chaseT = 7;
  }

  void _collect(double dt) {
    final midY = y + (sliding ? slideH : standH) * 0.55;
    for (final o in obs) {
      if (o.dead) continue;
      if (o.k == _K.coin && magnetT > 0 && o.z < 11 && o.z > -0.6) {
        final k = math.min(1.0, dt * 9);
        o.x += (x - o.x) * k;
        o.y += (midY - o.y) * k;
        o.z += (0 - o.z) * math.min(1.0, dt * 5);
      }
      if (o.k == _K.coin || o.isPower) {
        if ((o.x - x).abs() < 0.5 &&
            o.z < 0.55 &&
            o.z > -0.5 &&
            (o.y - midY).abs() < 0.75) {
          o.dead = true;
          if (o.k == _K.coin) {
            coins++;
            coinStreak++;
            coinStreakT = 0.6;
            score += 10 * mult;
            SfxService.instance.coin(coinStreak);
            _sparkle(o.x, o.y, o.z, const [
              Color(0xFFFFD36A),
              Color(0xFFFFF3B0),
            ]);
          } else {
            _power(o.k);
            _sparkle(
                o.x,
                o.y,
                o.z,
                const [
                  Color(0xFFB48CFF),
                  Color(0xFFFFFFFF),
                  Color(0xFFFF80AB),
                ],
                n: 22);
          }
        }
      }
    }
  }

  void _power(_K k) {
    SfxService.instance.power();
    HapticFeedback.mediumImpact();
    flash = 0.4;
    flashColor = const Color(0xFFB48CFF);
    switch (k) {
      case _K.magnet:
        magnetT = 10;
        break;
      case _K.sneaker:
        sneakerT = 10;
        break;
      case _K.double:
        doubleT = 15;
        break;
      default:
        break;
    }
  }

  void _cleanup() {
    obs.removeWhere((o) => o.dead || o.z + o.len < -camDist - 1);
  }

  // ───────────────────────── Üretici ─────────────────────────
  void _spawnAhead() {
    while (_nextChunk - dist < zFar) {
      final z0 = _nextChunk - dist;
      _nextChunk += _chunk(z0);
    }
  }

  List<int> get _others => [-1, 0, 1]..remove(_safe);

  /// Bir parça üretir; uzunluğunu döndürür. Her z'de en az bir şerit
  /// (güvenli şerit) trensizdir; güvenli şerit yalnız tren olmayan
  /// boşluklarda, en fazla bir şerit kayar.
  double _chunk(double z0) {
    final p = (dist / 1600).clamp(0.0, 1.0);
    // Bazen güvenli şerit komşuya kayar (parça başında treni yok).
    if (_rng.nextDouble() < 0.35) {
      final opts = [_safe - 1, _safe + 1].where((l) => l.abs() <= 1).toList();
      _safe = opts[_rng.nextInt(opts.length)];
    }
    final r = _rng.nextDouble();
    if (dist < 30 && z0 < 30) {
      _coinLine(_safe.toDouble(), z0 + 4, 5);
      return 14;
    }
    if (r < 0.36) return _chunkBarriers(z0, p);
    if (r < 0.80) return _chunkTrains(z0, p);
    return _chunkTriple(z0);
  }

  double _chunkBarriers(double z0, double p) {
    final n = 1 + (_rng.nextDouble() < 0.3 + p * 0.4 ? 1 : 0);
    final lanes = [-1, 0, 1]..shuffle(_rng);
    for (var i = 0; i < n; i++) {
      final l = lanes[i].toDouble();
      final kind = _rng.nextBool() ? _K.barrier : _K.bar;
      final z = z0 + 5 + i * (4 + _rng.nextDouble() * 3);
      obs.add(_Ob(kind, l, z));
      if (kind == _K.barrier && _rng.nextDouble() < 0.6) {
        _coinArc(l, z);
      }
    }
    final free = lanes.length > n ? lanes[n] : _safe;
    _coinLine(free.toDouble(), z0 + 3, 4 + _rng.nextInt(3));
    _maybePower(free.toDouble(), z0 + 12);
    return 16 - p * 3;
  }

  double _chunkTrains(double z0, double p) {
    final lanes = _others..shuffle(_rng);
    final count = _rng.nextDouble() < 0.45 + p * 0.35 ? 2 : 1;
    var maxEnd = 0.0;
    var rampDone = false;
    for (var i = 0; i < count; i++) {
      final l = lanes[i].toDouble();
      final len = 9 + _rng.nextDouble() * (6 + p * 8);
      final start = z0 + 4 + _rng.nextDouble() * 4;
      // Hareketli tren: şeritte önünde hiçbir şey yoksa
      final moving = dist > 350 &&
          !rampDone &&
          _rng.nextDouble() < 0.18 + p * 0.2 &&
          obs.every((o) => (o.x - l).abs() > 0.1 || o.z > start + len + 2);
      final ramp = !moving && !rampDone && _rng.nextDouble() < 0.55;
      if (ramp) rampDone = true;
      obs.add(_Ob(_K.train, l, start,
          len: len,
          ramp: ramp,
          vz: moving ? 6 + p * 4 : 0,
          skin: _rng.nextInt(3)));
      if (ramp) {
        _coinLine(l, start + 1, (len / 1.6).floor(), y: trainH + 0.5);
        if (_rng.nextDouble() < 0.4) {
          _maybePower(l, start + len * 0.6, y: trainH + 0.5, force: true);
        }
      }
      if (!moving) maxEnd = math.max(maxEnd, start + len - z0);
    }
    // Güvenli şeritte bazen zıplanacak / kayılacak engel
    if (_rng.nextDouble() < 0.25 + p * 0.4) {
      final z = z0 + 6 + _rng.nextDouble() * math.max(1, maxEnd - 8);
      obs.add(_Ob(_rng.nextBool() ? _K.barrier : _K.bar, _safe.toDouble(), z));
      _coinLine(_safe.toDouble(), z0 + 3, 3);
    } else {
      _coinLine(_safe.toDouble(), z0 + 4, 5 + _rng.nextInt(4));
    }
    return math.max(16, maxEnd + 9);
  }

  double _chunkTriple(double z0) {
    final kind = _rng.nextBool() ? _K.barrier : _K.bar;
    final z = z0 + 6;
    for (final l in const [-1.0, 0.0, 1.0]) {
      obs.add(_Ob(kind, l, z));
    }
    if (kind == _K.barrier) {
      _coinArc(_safe.toDouble(), z);
    } else {
      _coinLine(_safe.toDouble(), z - 1.5, 3, y: 0.3);
    }
    return 14;
  }

  void _coinLine(double l, double z, int n, {double y = 0.45}) {
    for (var i = 0; i < n; i++) {
      obs.add(_Ob(_K.coin, l, z + i * 1.6, y: y));
    }
  }

  void _coinArc(double l, double zc) {
    // Zıplama yayı: engelin üstünden geçen coin dizisi
    for (var i = -3; i <= 3; i++) {
      final t = i / 3.5;
      obs.add(_Ob(_K.coin, l, zc + i * 1.0, y: 0.45 + (1 - t * t) * 0.6));
    }
  }

  void _maybePower(double l, double z, {double y = 0.55, bool force = false}) {
    if (!force && dist + z < _nextPower) return;
    _nextPower = dist + z + 260 + _rng.nextDouble() * 160;
    const kinds = [_K.magnet, _K.sneaker, _K.double];
    obs.add(_Ob(kinds[_rng.nextInt(3)], l, z, y: y));
  }

  // ───────────────────────── Ölüm / Devam ─────────────────────────
  void _die({required bool train}) {
    _phase = _Phase.dying;
    deathT = 0;
    shake.kick(train ? 0.14 : 0.09, 0.45);
    flash = 1;
    flashColor = train ? Colors.white : const Color(0xFFFF6B6B);
    SfxService.instance.crash();
    HapticFeedback.heavyImpact();
    _sparkle(
        x,
        y + 0.5,
        0.2,
        const [
          Color(0xFF9C98A6),
          Color(0xFFE4E0EA),
          Color(0xFFFF80AB),
        ],
        n: 26);
    setState(() {});
  }

  void _dying(double dt) {
    deathT += dt;
    guardZ += ((_caught ? -0.6 : -1.45) - guardZ) * math.min(1, dt * 4);
    guardX += (x - guardX) * math.min(1, dt * 4);
    if (!grounded) {
      vy -= gravity * dt;
      y = math.max(support, y + vy * dt);
    }
    if (deathT > 0.95) {
      _phase = _Phase.over;
      if (!_reviveUsed) {
        _reviving = true;
        setState(() {});
      } else {
        _finishGame();
      }
    }
  }

  void _finishGame() {
    _phase = _Phase.over;
    _reviving = false;
    LeaderboardGame.subway.report(finalScore).ignore();
    ProgressService.instance.submitSubwayScore(finalScore).then((rec) {
      if (!mounted) return;
      if (rec) {
        setState(() => _newRecord = true);
        SfxService.instance.medal();
      }
    });
    setState(() {});
  }

  /// Doğru cevap: ekstra can; yakındaki engeller temizlenir, koşu sürer.
  void _doRevive() {
    setState(() {
      _reviveUsed = true;
      _reviving = false;
      _caught = false;
      obs.removeWhere((o) => o.z < 30);
      chaseT = 0;
      lane = prevLane = x.round().clamp(-1, 1);
      x = lane.toDouble();
      support = 0;
      grounded = y <= 0.01;
      vy = 0;
      sliding = false;
      invuln = 2;
      _phase = _Phase.playing;
      _last = null;
    });
    _focus.requestFocus();
  }

  void _giveUp() => _finishGame();

  int get finalScore => score.floor();

  void _resetWorld() {
    dist = 0;
    score = 0;
    coins = 0;
    coinStreak = 0;
    speed = 10;
    lane = prevLane = 0;
    x = y = vy = 0;
    camX = 0;
    camY = camYBase;
    grounded = true;
    sliding = slideQueued = false;
    support = 0;
    invuln = 0;
    chaseT = 0;
    guardZ = -5;
    magnetT = sneakerT = doubleT = 0;
    obs.clear();
    parts.clear();
    _nextChunk = 10;
    _safe = 0;
    _nextPower = 160;
    _caught = false;
    shake.reset();
    _spawnAhead();
  }

  // ───────────────────────── Kontroller ─────────────────────────
  void _start() {
    _resetWorld();
    // Başlangıçta önü açık olsun
    obs.removeWhere((o) => o.z < 16);
    _newRecord = false;
    _reviveUsed = false;
    _reviving = false;
    _last = null;
    setState(() => _phase = _Phase.playing);
    _focus.requestFocus();
  }

  void _move(int dir) {
    final n = (lane + dir).clamp(-1, 1);
    if (n == lane) {
      // Kenara çarpma: hafif sarsıntı
      shake.kick(0.03, 0.12);
      return;
    }
    prevLane = lane;
    lane = n;
    SfxService.instance.swoosh();
  }

  void _jump() {
    if (!grounded) {
      jumpBuffer = 0.16;
      return;
    }
    sliding = false;
    grounded = false;
    final h = sneakerT > 0 ? superJumpH : jumpH;
    vy = math.sqrt(2 * gravity * h);
    SfxService.instance.jump();
    HapticFeedback.lightImpact();
    _dust(3);
  }

  void _down() {
    if (!grounded) {
      vy = math.min(vy, -16); // hızlı iniş
      slideQueued = true;
      return;
    }
    _startSlide();
  }

  void _startSlide() {
    sliding = true;
    slideT = slideDur;
    SfxService.instance.slide();
    HapticFeedback.lightImpact();
    _dust(5);
  }

  void _onPanDown(DragDownDetails d) {
    _panStart = d.localPosition;
    _acted = false;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_paused || _phase != _Phase.playing || _acted) return;
    final v = d.localPosition - _panStart;
    const th = 18.0;
    if (v.distance < th) return;
    _acted = true;
    if (v.dx.abs() > v.dy.abs()) {
      _move(v.dx > 0 ? 1 : -1);
    } else if (v.dy < 0) {
      _jump();
    } else {
      _down();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (_paused) return KeyEventResult.ignored;
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (_phase == _Phase.ready &&
        (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.enter)) {
      _start();
      return KeyEventResult.handled;
    }
    if (_phase != _Phase.playing) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      _move(-1);
    } else if (k == LogicalKeyboardKey.arrowRight ||
        k == LogicalKeyboardKey.keyD) {
      _move(1);
    } else if (k == LogicalKeyboardKey.arrowUp ||
        k == LogicalKeyboardKey.keyW ||
        k == LogicalKeyboardKey.space) {
      _jump();
    } else if (k == LogicalKeyboardKey.arrowDown ||
        k == LogicalKeyboardKey.keyS) {
      _down();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// Ekran görüntüsü / test için: sahneyi başlatır ve ilerletir.
  @visibleForTesting
  void debugStart({bool god = true}) {
    godMode = god;
    _start();
  }

  // ───────────────────────── Parçacıklar ─────────────────────────
  void _sparkle(double px, double py, double pz, List<Color> colors,
      {int n = 10}) {
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final v = 1.5 + _rng.nextDouble() * 2.5;
      parts.add(_P3(
          px,
          py,
          pz,
          math.cos(a) * v,
          math.sin(a) * v + 1.5,
          (_rng.nextDouble() - 0.5) * 2,
          0.35 + _rng.nextDouble() * 0.3,
          0.05 + _rng.nextDouble() * 0.04,
          colors[_rng.nextInt(colors.length)]));
    }
    if (parts.length > 260) parts.removeRange(0, parts.length - 260);
  }

  void _dust(int n) {
    for (var i = 0; i < n; i++) {
      parts.add(_P3(
          x + (_rng.nextDouble() - 0.5) * 0.4,
          support + 0.02,
          0,
          (_rng.nextDouble() - 0.5) * 1.6,
          0.6 + _rng.nextDouble(),
          -speed * 0.3,
          0.3 + _rng.nextDouble() * 0.2,
          0.06,
          const Color(0xFFCDB8C8)));
    }
  }

  void _updateParts(double dt) {
    for (final p in parts) {
      p.life -= dt;
      p.vy -= 6 * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.z += p.vz * dt;
    }
    parts.removeWhere((p) => p.life <= 0);
  }

  // ───────────────────────── Arayüz ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final best = ProgressService.instance.subwayHigh;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_paused && _phase == _Phase.ready && !_showHelp) _start();
          },
          onPanDown: _onPanDown,
          onPanUpdate: _onPanUpdate,
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  // Sahne kenarlardan taşar (sarsıntı payı, yakın dörtgenler);
                  // kırpılmazsa geri dönüş kaydırmasında ana ekranın üstünde
                  // bir an görünür.
                  child: ClipRect(
                    child: CustomPaint(
                      painter: _RunnerPainter(this, repaint: _frame),
                    ),
                  ),
                ),
              ),
              // Başlangıç paneli üst barın altında kalır: geri, sıralama ve
              // müzik düğmeleri oyun başlamadan da kullanılabilir.
              if (_phase == _Phase.ready)
                (_showHelp ? _helpOverlay() : _readyOverlay()),
              SafeArea(
                child: Column(
                  children: [
                    _topBar(best),
                    if (_phase == _Phase.playing || _phase == _Phase.dying)
                      _powerBar(),
                    const Spacer(),
                  ],
                ),
              ),
              if (_phase == _Phase.over && _reviving)
                ReviveOverlay(onRevive: _doRevive, onGiveUp: _giveUp),
              if (_phase == _Phase.over && !_reviving) _overOverlay(best),
              if (_paused) GamePauseOverlay(onResume: _resume),
            ],
          ),
        ),
      ),
    );
  }

  static const _pixel = TextStyle(
      fontFamily: 'PixelifySans',
      color: Colors.white,
      fontWeight: FontWeight.w700,
      shadows: [Shadow(color: Color(0xFF2B1220), offset: Offset(1.5, 1.5))]);

  void _openLeaderboard() {
    _pause();
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const GameLeaderboard(game: LeaderboardGame.subway)));
  }

  Widget _topBar(int best) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
      child: Row(
        children: [
          _circleBtn(
              Icons.arrow_back_rounded, () => Navigator.of(context).maybePop()),
          const SizedBox(width: 8),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: _hud,
              builder: (_, __, ___) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      _pill(Text(finalScore.toString().padLeft(5, '0'),
                          style: _pixel.copyWith(fontSize: 17))),
                      const SizedBox(width: 6),
                      _pill(Row(mainAxisSize: MainAxisSize.min, children: [
                        const PixelLogo(kSprCoin0,
                            size: 15, palette: kArcadePalette),
                        const SizedBox(width: 5),
                        Text('$coins', style: _pixel.copyWith(fontSize: 16)),
                      ])),
                      if (doubleT > 0) ...[
                        const SizedBox(width: 6),
                        _pill(Text('x2',
                            style: _pixel.copyWith(
                                fontSize: 16, color: const Color(0xFFDCC8FF)))),
                      ],
                    ],
                  )),
            ),
          ),
          _circleBtn(Icons.leaderboard_rounded, _openLeaderboard,
              label: 'İkimizin sıralaması'),
          const SizedBox(width: 6),
          MusicButton(onOpen: _pause),
          const SizedBox(width: 8),
          _pill(Row(mainAxisSize: MainAxisSize.min, children: [
            const PixelLogo(kLogoTrophy, size: 15),
            const SizedBox(width: 5),
            Text('$best', style: _pixel.copyWith(fontSize: 14)),
          ])),
        ],
      ),
    );
  }

  Widget _powerBar() {
    return ValueListenableBuilder<int>(
      valueListenable: _hud,
      builder: (_, __, ___) {
        final items = <Widget>[
          if (magnetT > 0) _powerChip(kSprMagnet, magnetT / 10),
          if (sneakerT > 0) _powerChip(kSprSneaker, sneakerT / 10),
          if (doubleT > 0) _powerChip(kSprDouble, doubleT / 15),
          if (chaseT > 0 && _phase == _Phase.playing)
            _pill(Text('Bekçi peşinde!',
                style: _pixel.copyWith(
                    fontSize: 13, color: const Color(0xFFFFD36A)))),
        ];
        if (items.isEmpty) return const SizedBox(height: 4);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
          child: Row(children: [
            for (final w in items) ...[w, const SizedBox(width: 6)],
          ]),
        );
      },
    );
  }

  Widget _powerChip(List<String> sprite, double frac) => Container(
        padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2B1220).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          PixelLogo(sprite, size: 18, palette: kArcadePalette),
          const SizedBox(width: 6),
          SizedBox(
            width: 38,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: frac.clamp(0.0, 1.0),
                backgroundColor: Colors.white12,
                color: frac < 0.25
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFFB48CFF),
              ),
            ),
          ),
        ]),
      );

  Widget _pill(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF2B1220).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: child,
      );

  Widget _circleBtn(IconData icon, VoidCallback onTap,
          {String label = 'Oyunlara dön'}) =>
      Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  Widget _panel({required Widget child}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1430),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFF80AB), width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0xFF12060E), offset: Offset(0, 6)),
          ],
        ),
        child: child,
      );

  Widget _readyOverlay() {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
          child: _panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PixelLogo(kLogoSubwaySilly, size: 64),
            const SizedBox(height: 8),
            Text('Subway Silly', style: _pixel.copyWith(fontSize: 30)),
            const SizedBox(height: 8),
            const Text(
                'Trenlerden kaç, rampalardan tırman, coin topla — bekçiye yakalanma!',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13.5, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            _bigBtn('Başla', primary: true, onTap: _start),
            const SizedBox(height: 10),
            _bigBtn('Nasıl oynanır?',
                primary: false, onTap: () => setState(() => _showHelp = true)),
          ],
        ),
      )),
    );
  }

  Widget _helpOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: _panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Text('Nasıl oynanır?',
                      style: _pixel.copyWith(fontSize: 24))),
              const SizedBox(height: 14),
              _section('KONTROLLER'),
              _howto('👈 👉', 'Sağa/sola kaydır → şerit değiştir'),
              _howto('👆', 'Yukarı kaydır → zıpla'),
              _howto('👇', 'Aşağı kaydır → kay (havadayken: hızlı in)'),
              const Text('Bilgisayarda: ok tuşları / WASD / boşluk',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
              const SizedBox(height: 14),
              _section('ENGELLER'),
              _legend(kSprBarrier, 'Bariyer', 'Üzerinden ZIPLA'),
              _legend(kSprHighBar, 'Tabela', 'Altından KAY'),
              _legend(kSprTrainPink, 'Tren',
                  'Şerit değiştir ya da rampadan çatısına tırman'),
              const SizedBox(height: 10),
              _section('TOPLA'),
              _legend(kSprCoin0, 'Coin', '+10 puan'),
              _legend(kSprMagnet, 'Mıknatıs', 'Coin\'leri çeker (10 sn)'),
              _legend(kSprSneaker, 'Süper zıplama',
                  'Trenlerin üstüne zıpla (10 sn)'),
              _legend(kSprDouble, '2x', 'Puanlar iki katı (15 sn)'),
              const SizedBox(height: 8),
              const Text(
                'Trenin yanına sürtünürsen tökezlersin ve bekçi peşine düşer. '
                'Bekçi peşindeyken tekrar tökezlersen yakalanırsın!',
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              _bigBtn('Anladım',
                  primary: true,
                  onTap: () => setState(() => _showHelp = false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: _pixel.copyWith(
                fontSize: 13,
                letterSpacing: 0.8,
                color: AppTheme.accent,
                shadows: const [])),
      );

  Widget _legend(List<String> sprite, String name, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 40,
              height: 32,
              child: Center(
                  child: PixelLogo(sprite, size: 30, palette: kArcadePalette))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                Text(action,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _howto(String e, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
                width: 52,
                child: Text(e,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(t,
                  style: const TextStyle(
                      fontSize: 13.5, color: AppTheme.textSecondary)),
            ),
          ],
        ),
      );

  Widget _overOverlay(int best) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, v, child) =>
            Transform.scale(scale: 0.7 + 0.3 * v, child: child),
        child: _panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 64,
                child: PixelLogo(_caught ? kSprGuard0 : kSprRunnerSlide,
                    size: 60, palette: kArcadePalette),
              ),
              const SizedBox(height: 8),
              Text(
                  _newRecord
                      ? 'Yeni Rekor!'
                      : (_caught ? 'Bekçi yakaladı!' : 'Çarptın!'),
                  style: _pixel.copyWith(fontSize: 28)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: _scoreBox('Skor', '$finalScore', AppTheme.accent)),
                  const SizedBox(width: 8),
                  Expanded(
                      child:
                          _scoreBox('Coin', '$coins', const Color(0xFFFFD36A))),
                  const SizedBox(width: 8),
                  Expanded(
                      child:
                          _scoreBox('Rekor', '$best', AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              Text('${dist.floor()} m koştun',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppTheme.textMuted)),
              const SizedBox(height: 18),
              _bigBtn('Tekrar Oyna', primary: true, onTap: _start),
              const SizedBox(height: 10),
              _bigBtn('Profile Dön',
                  primary: false,
                  onTap: () => Navigator.of(context).maybePop()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigBtn(String label,
      {required bool primary, required VoidCallback onTap}) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? const Color(0xFFFF80AB) : const Color(0xFF3D2140),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF12060E), width: 2.5),
          boxShadow: const [
            BoxShadow(color: Color(0xFF12060E), offset: Offset(0, 3)),
          ],
        ),
        child: Text(label,
            style: _pixel.copyWith(
                fontSize: 18,
                color: primary ? Colors.white : AppTheme.textSecondary,
                shadows: primary
                    ? const [
                        Shadow(color: Color(0xFF8E2350), offset: Offset(1, 2))
                      ]
                    : const [])),
      ),
    );
  }

  Widget _scoreBox(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C0E17),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            FittedBox(
              child: Text(value,
                  style: _pixel
                      .copyWith(fontSize: 22, color: color, shadows: const [])),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      );
}
