import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/services/progress_service.dart';

/// Subway Surfers tarzı sahte-perspektif (2.5D) sonsuz koşu oyunu.
/// Silly cat 3 şeritte koşar; kaydır = şerit değiştir, yukarı = zıpla,
/// aşağı = eğil. Engellerden kaç, coin topla, hız giderek artar.
///
/// Performans: tüm sahne tek bir [CustomPainter] ile çizilir ve yalnızca
/// bir [Listenable] (kare sayacı) ile yeniden boyanır — her karede tüm
/// widget ağacı değil, sadece tuval güncellenir.
class SubwayCatScreen extends StatefulWidget {
  const SubwayCatScreen({super.key});

  @override
  State<SubwayCatScreen> createState() => _SubwayCatScreenState();
}

enum _Phase { ready, playing, over }

enum _Kind { barrier, bar, wall, coin }

class _Ent {
  double z;
  double pz;
  final int lane;
  final _Kind kind;
  bool dead = false;
  _Ent(this.z, this.lane, this.kind) : pz = z;
}

class _SubwayCatScreenState extends State<SubwayCatScreen>
    with SingleTickerProviderStateMixin {
  // ── Çizimi yöneten kare sayacı (setState yerine sadece tuvali boyar) ──
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration? _last;

  final _rng = math.Random();
  ui.Image? _catImg;

  _Phase _phase = _Phase.ready;
  bool _newRecord = false;

  // Dünya / kamera sabitleri
  static const double zNear = 2.0; // ölçek referansı + oyuncu düzlemi
  static const double zFar = 34.0; // doğuş mesafesi
  static const double _zP = 2.0; // oyuncunun z'si

  // Hareket durumu
  double _dist = 0; // toplam mesafe (skor)
  int _coins = 0;
  double _speed = 8;
  static const double _baseSpeed = 8;
  static const double _maxSpeed = 21;
  static const double _spawnGap = 9; // satırlar arası z mesafesi
  double _nextSpawn = 0;

  int _lane = 0; // hedef şerit (-1,0,1)
  double _laneX = 0; // yumuşak ara değer

  // Zıplama
  bool _jumping = false;
  double _jumpY = 0;
  double _jumpVel = 0;
  static const double _jumpV0 = 820;
  static const double _gravity = 2600;
  static const double _clearH = 24; // engeli aşmak için gereken yükseklik

  // Eğilme (kayma)
  bool _rolling = false;
  double _rollT = 0;
  static const double _rollDur = 0.55;

  final List<_Ent> _ents = [];

  // Kaydırma jesti
  Offset _panStart = Offset.zero;
  bool _acted = false;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadImg();
    _ticker = createTicker(_tick)..start();
  }

  Future<void> _loadImg() async {
    try {
      final data = await rootBundle.load('assets/images/SHINY_Cuh.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _catImg = frame.image);
    } catch (_) {/* görsel yüklenmezse pembe daire ile oynanır */}
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ───────────────────────── Oyun döngüsü ─────────────────────────
  void _tick(Duration now) {
    final last = _last;
    _last = now;
    if (last == null) return;
    final dt = (now - last).inMicroseconds / 1e6;
    if (dt <= 0) return;
    if (_phase == _Phase.playing) _update(dt.clamp(0.0, 0.05));
    _frame.value++;
  }

  void _update(double dt) {
    _speed = math.min(_maxSpeed, _baseSpeed + _dist * 0.03);
    final move = _speed * dt;
    _dist += move;

    _laneX += (_lane - _laneX) * math.min(1.0, dt * 12);

    if (_jumping) {
      _jumpVel -= _gravity * dt;
      _jumpY += _jumpVel * dt;
      if (_jumpY <= 0) {
        _jumpY = 0;
        _jumping = false;
      }
    }
    if (_rolling) {
      _rollT -= dt;
      if (_rollT <= 0) _rolling = false;
    }

    for (final e in _ents) {
      e.pz = e.z;
      e.z -= move;
    }

    for (final e in _ents) {
      if (e.dead) continue;
      if (e.pz > _zP && e.z <= _zP) {
        final sameLane = (_laneX - e.lane).abs() < 0.55;
        if (e.kind == _Kind.coin) {
          if (sameLane) {
            e.dead = true;
            _coins++;
            HapticFeedback.selectionClick();
          }
        } else if (sameLane) {
          bool safe;
          switch (e.kind) {
            case _Kind.barrier:
              safe = _jumpY > _clearH;
              break;
            case _Kind.bar:
              safe = _rolling;
              break;
            case _Kind.wall:
              safe = false;
              break;
            case _Kind.coin:
              safe = true;
              break;
          }
          if (!safe) {
            _crash();
            return;
          }
        }
      }
    }
    _ents.removeWhere((e) => e.dead || e.z < 0.8);

    while (_dist > _nextSpawn) {
      _spawnRow();
      _nextSpawn += _spawnGap;
    }
  }

  void _spawnRow() {
    final lane = _rng.nextInt(3) - 1;
    final t = _rng.nextDouble();
    final kind =
        t < 0.4 ? _Kind.barrier : (t < 0.7 ? _Kind.bar : _Kind.wall);
    _ents.add(_Ent(zFar, lane, kind));
    // Boş şeritlerden birine coin dizisi
    if (_rng.nextDouble() < 0.65) {
      final free = [-1, 0, 1]..remove(lane);
      final cl = free[_rng.nextInt(free.length)];
      final n = 3 + _rng.nextInt(3);
      for (var k = 0; k < n; k++) {
        _ents.add(_Ent(zFar - k * 1.5, cl, _Kind.coin));
      }
    }
  }

  void _crash() {
    _phase = _Phase.over;
    HapticFeedback.heavyImpact();
    ProgressService.instance.submitSubwayScore(_finalScore).then((rec) {
      if (mounted && rec) setState(() => _newRecord = true);
    });
    setState(() {});
  }

  int get _finalScore => _dist.floor() + _coins * 10;

  // ───────────────────────── Kontroller ─────────────────────────
  void _start() {
    _dist = 0;
    _coins = 0;
    _speed = _baseSpeed;
    _nextSpawn = _spawnGap;
    _lane = 0;
    _laneX = 0;
    _jumping = false;
    _jumpY = 0;
    _rolling = false;
    _rollT = 0;
    _ents.clear();
    _newRecord = false;
    _last = null;
    setState(() => _phase = _Phase.playing);
    _focus.requestFocus();
  }

  void _move(int dir) {
    _lane = (_lane + dir).clamp(-1, 1);
  }

  void _jump() {
    if (_jumping || _rolling) return;
    _jumping = true;
    _jumpVel = _jumpV0;
    HapticFeedback.lightImpact();
  }

  void _roll() {
    if (_rolling || _jumping) return;
    _rolling = true;
    _rollT = _rollDur;
    HapticFeedback.lightImpact();
  }

  void _onPanDown(DragDownDetails d) {
    _panStart = d.localPosition;
    _acted = false;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_phase != _Phase.playing || _acted) return;
    final v = d.localPosition - _panStart;
    const th = 22.0;
    if (v.dx.abs() > v.dy.abs()) {
      if (v.dx > th) {
        _move(1);
        _acted = true;
      } else if (v.dx < -th) {
        _move(-1);
        _acted = true;
      }
    } else {
      if (v.dy < -th) {
        _jump();
        _acted = true;
      } else if (v.dy > th) {
        _roll();
        _acted = true;
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
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
      _roll();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
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
            if (_phase == _Phase.ready) _start();
          },
          onPanDown: _onPanDown,
          onPanUpdate: _onPanUpdate,
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _RunnerPainter(this, repaint: _frame),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _topBar(best),
                    const Spacer(),
                  ],
                ),
              ),
              if (_phase == _Phase.ready) _readyOverlay(),
              if (_phase == _Phase.over) _overOverlay(best),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(int best) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 4),
      child: Row(
        children: [
          _circleBtn(Icons.arrow_back_rounded,
              () => Navigator.of(context).maybePop()),
          const Spacer(),
          ValueListenableBuilder<int>(
            valueListenable: _frame,
            builder: (_, __, ___) => Row(
              children: [
                _pill('🏃 ${_dist.floor()}'),
                const SizedBox(width: 8),
                _pill('🪙 $_coins'),
              ],
            ),
          ),
          const Spacer(),
          _circleBtn(Icons.emoji_events_rounded, () {}),
          const SizedBox(width: 6),
          Text('$best',
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      );

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
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

  Widget _readyOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 34),
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐱', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 8),
            const Text('Silly Cat Koşusu',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            _howto('👈👉', 'Kaydır: şerit değiştir'),
            _howto('👆', 'Yukarı kaydır: zıpla'),
            _howto('👇', 'Aşağı kaydır: eğil / kay'),
            const SizedBox(height: 6),
            const Text('(Bilgisayarda ok tuşları)',
                style:
                    TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
            const SizedBox(height: 18),
            _bigBtn('Başla', primary: true, onTap: _start),
          ],
        ),
      ),
    );
  }

  Widget _howto(String e, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 42,
                child: Text(e,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16))),
            const SizedBox(width: 8),
            Text(t,
                style: const TextStyle(
                    fontSize: 13.5, color: AppTheme.textSecondary)),
          ],
        ),
      );

  Widget _overOverlay(int best) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_newRecord ? '🎉' : '🙀', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text(_newRecord ? 'Yeni Rekor!' : 'Yakalandın!',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _scoreBox('Skor', '$_finalScore', AppTheme.accent),
                const SizedBox(width: 12),
                _scoreBox('🪙', '$_coins', AppTheme.success),
                const SizedBox(width: 12),
                _scoreBox('Rekor', '$best', AppTheme.textSecondary),
              ],
            ),
            const SizedBox(height: 22),
            _bigBtn('Tekrar Oyna', primary: true, onTap: _start),
            const SizedBox(height: 10),
            _bigBtn('Profile Dön',
                primary: false,
                onTap: () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
    );
  }

  Widget _bigBtn(String label,
      {required bool primary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: primary ? AppTheme.pinkGradient : null,
          color: primary ? null : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(15),
          border: primary ? null : Border.all(color: AppTheme.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: primary ? Colors.white : AppTheme.textSecondary,
                fontSize: primary ? 16 : 15,
                fontWeight: primary ? FontWeight.w800 : FontWeight.w700)),
      ),
    );
  }

  Widget _scoreBox(String label, String value, Color color) => Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      );
}

// ═══════════════════════════ Çizim ═══════════════════════════
class _RunnerPainter extends CustomPainter {
  final _SubwayCatScreenState g;
  _RunnerPainter(this.g, {required Listenable repaint}) : super(repaint: repaint);

  // Tekrar kullanılan boyalar (kare başına tahsis yok)
  final Paint _p = Paint()..isAntiAlias = true;
  final Paint _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke;

  late double W, H, horizonY, groundY, cx, laneSpread;
  static const double roadHalf = 1.55;

  double _s(double z) => _SubwayCatScreenState.zNear / z;
  double _px(double z, double lane) => cx + lane * laneSpread * _s(z);
  double _py(double z) => horizonY + (groundY - horizonY) * _s(z);

  @override
  void paint(Canvas canvas, Size size) {
    W = size.width;
    H = size.height;
    horizonY = H * 0.28;
    groundY = H * 0.96;
    cx = W / 2;
    laneSpread = W * 0.31;

    _drawSky(canvas);
    _drawRoad(canvas);
    _drawEntities(canvas);
    _drawPlayer(canvas);
  }

  void _drawSky(Canvas canvas) {
    // Gökyüzü (alacakaranlık pembe)
    _p
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2A1430), Color(0xFF5A2A4A), Color(0xFF8A3D5E)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, W, horizonY + 4))
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, W, horizonY + 4), _p);
    _p.shader = null;

    // Ay / güneş
    _p.color = const Color(0xFFFFD9E6).withValues(alpha: 0.85);
    canvas.drawCircle(Offset(W * 0.74, horizonY * 0.45), horizonY * 0.20, _p);
    _p.color = const Color(0xFFFFB0CE).withValues(alpha: 0.18);
    canvas.drawCircle(Offset(W * 0.74, horizonY * 0.45), horizonY * 0.34, _p);

    // Sürüklenen bulutlar (parallaks)
    final drift = (g._dist * 6) % (W + 160) - 80;
    _p.color = Colors.white.withValues(alpha: 0.07);
    _cloud(canvas, W - drift, horizonY * 0.35, horizonY * 0.5);
    _cloud(canvas, (W * 1.6 - drift) % (W + 160) - 80, horizonY * 0.6,
        horizonY * 0.4);
  }

  void _cloud(Canvas canvas, double x, double y, double r) {
    canvas.drawCircle(Offset(x, y), r * 0.5, _p);
    canvas.drawCircle(Offset(x + r * 0.4, y + r * 0.1), r * 0.38, _p);
    canvas.drawCircle(Offset(x - r * 0.4, y + r * 0.1), r * 0.34, _p);
  }

  void _drawRoad(Canvas canvas) {
    final nL = _px(_SubwayCatScreenState.zNear, -roadHalf);
    final nR = _px(_SubwayCatScreenState.zNear, roadHalf);
    final fL = _px(_SubwayCatScreenState.zFar, -roadHalf);
    final fR = _px(_SubwayCatScreenState.zFar, roadHalf);
    final fy = _py(_SubwayCatScreenState.zFar);
    final ny = _py(_SubwayCatScreenState.zNear);

    // Yol zemini
    final road = Path()
      ..moveTo(nL, ny)
      ..lineTo(nR, ny)
      ..lineTo(fR, fy)
      ..lineTo(fL, fy)
      ..close();
    _p
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF241726), Color(0xFF160D18)],
      ).createShader(Rect.fromLTWH(0, fy, W, groundY - fy));
    canvas.drawPath(road, _p);
    _p.shader = null;

    // Yol kenarı bantları
    _stroke
      ..color = AppTheme.accent.withValues(alpha: 0.55)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(nL, ny), Offset(fL, fy), _stroke);
    canvas.drawLine(Offset(nR, ny), Offset(fR, fy), _stroke);

    // Şerit ayraçları (-0.5, 0.5)
    _stroke
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 2;
    for (final b in const [-0.5, 0.5]) {
      canvas.drawLine(
        Offset(_px(_SubwayCatScreenState.zNear, b.toDouble()), ny),
        Offset(_px(_SubwayCatScreenState.zFar, b.toDouble()), fy),
        _stroke,
      );
    }

    // Kayan enine çizgiler (hız hissi)
    const step = 2.4;
    final off = g._dist % step;
    _stroke.color = Colors.white.withValues(alpha: 0.06);
    for (var i = 1; i < 18; i++) {
      final z = _SubwayCatScreenState.zNear + i * step - off;
      if (z <= _SubwayCatScreenState.zNear) continue;
      if (z >= _SubwayCatScreenState.zFar) break;
      final y = _py(z);
      _stroke.strokeWidth = (3 * _s(z)).clamp(0.5, 3);
      canvas.drawLine(
          Offset(_px(z, -roadHalf), y), Offset(_px(z, roadHalf), y), _stroke);
    }
  }

  void _drawEntities(Canvas canvas) {
    // Uzaktan yakına: önce uzaktakiler çizilsin
    final list = List<_Ent>.from(g._ents)..sort((a, b) => b.z.compareTo(a.z));
    for (final e in list) {
      if (e.z <= 1.0 || e.z >= _SubwayCatScreenState.zFar) continue;
      final s = _s(e.z);
      final x = _px(e.z, e.lane.toDouble());
      final y = _py(e.z);
      switch (e.kind) {
        case _Kind.coin:
          _drawCoin(canvas, x, y - 30 * s, 15 * s, e.lane);
          break;
        case _Kind.barrier:
          _drawBox(canvas, x, y, 0.72 * laneSpread * s, 30 * s,
              const Color(0xFFFF7A59), const Color(0xFFB23A28));
          break;
        case _Kind.wall:
          _drawBox(canvas, x, y, 0.82 * laneSpread * s, 74 * s,
              const Color(0xFF7C6CFF), const Color(0xFF4632B0));
          break;
        case _Kind.bar:
          _drawBar(canvas, x, y, 0.86 * laneSpread * s, s);
          break;
      }
    }
  }

  void _drawCoin(Canvas canvas, double x, double y, double r, int lane) {
    final spin = 0.35 + 0.65 * (math.sin(g._dist * 3 + lane * 1.7)).abs();
    final rect = Rect.fromCenter(center: Offset(x, y), width: 2 * r * spin, height: 2 * r);
    _p
      ..style = PaintingStyle.fill
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF3B0), Color(0xFFFFC93C), Color(0xFFE39A0E)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawOval(rect, _p);
    _p.shader = null;
    _stroke
      ..color = const Color(0xFFFFE9A8)
      ..strokeWidth = (1.5 * (r / 15)).clamp(0.6, 2);
    canvas.drawOval(rect.deflate(r * 0.18), _stroke);
  }

  // Önden + üstten yüzlü kutu (sahte 3D)
  void _drawBox(Canvas canvas, double cxp, double baseY, double w, double h,
      Color front, Color dark) {
    final depth = w * 0.28;
    final l = cxp - w / 2, rgt = cxp + w / 2;
    final topY = baseY - h;
    // Üst yüz (paralelkenar)
    _p
      ..style = PaintingStyle.fill
      ..color = Color.lerp(front, Colors.white, 0.18)!;
    final top = Path()
      ..moveTo(l, topY)
      ..lineTo(rgt, topY)
      ..lineTo(rgt - depth, topY - depth * 0.7)
      ..lineTo(l - depth, topY - depth * 0.7)
      ..close();
    canvas.drawPath(top, _p);
    // Ön yüz
    _p.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [front, dark],
    ).createShader(Rect.fromLTRB(l, topY, rgt, baseY));
    final r = Radius.circular((w * 0.08).clamp(2, 8));
    canvas.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTRB(l, topY, rgt, baseY),
            topLeft: r, topRight: r),
        _p);
    _p.shader = null;
  }

  // Üstten geçen kiriş — altından eğilerek geçilir
  void _drawBar(Canvas canvas, double cxp, double baseY, double w, double s) {
    final l = cxp - w / 2, rgt = cxp + w / 2;
    final beamBottom = baseY - 40 * s;
    final beamTop = baseY - 72 * s;
    // Direkler
    _p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF3A2A12);
    canvas.drawRect(Rect.fromLTWH(l, beamTop, 6 * s, baseY - beamTop), _p);
    canvas.drawRect(
        Rect.fromLTWH(rgt - 6 * s, beamTop, 6 * s, baseY - beamTop), _p);
    // Tehlike şeritli kiriş
    final beam = Rect.fromLTRB(l, beamTop, rgt, beamBottom);
    _p.color = const Color(0xFFFFC93C);
    canvas.drawRRect(
        RRect.fromRectAndRadius(beam, Radius.circular(3 * s)), _p);
    _p.color = const Color(0xFF1A1208).withValues(alpha: 0.8);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(beam, Radius.circular(3 * s)));
    final sw = 12 * s;
    for (var sx = l - beam.height; sx < rgt; sx += sw * 2) {
      final p = Path()
        ..moveTo(sx, beamTop)
        ..lineTo(sx + sw, beamTop)
        ..lineTo(sx + sw + beam.height, beamBottom)
        ..lineTo(sx + beam.height, beamBottom)
        ..close();
      canvas.drawPath(p, _p);
    }
    canvas.restore();
  }

  void _drawPlayer(Canvas canvas) {
    final baseY = _py(_zP());
    final sx = _px(_zP(), g._laneX);
    final grounded = g._jumpY <= 0.5;
    final bob = grounded && g._phase == _Phase.playing
        ? math.sin(g._dist * 7) * 2.5
        : 0.0;

    // Gölge
    final shA = (0.36 * (1 - g._jumpY / 150)).clamp(0.08, 0.36);
    final shW = (52 - g._jumpY * 0.12).clamp(28, 52).toDouble();
    _p
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: shA);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(sx, baseY + 4), width: shW, height: shW * 0.28),
        _p);

    // Kedi gövdesi
    var rw = 30.0, rh = 30.0;
    if (g._rolling) {
      rw = 36;
      rh = 18;
    }
    final cy = baseY - rh - g._jumpY + bob;
    final dst = Rect.fromCenter(center: Offset(sx, cy), width: rw * 2, height: rh * 2);

    final img = g._catImg;
    if (img != null) {
      canvas.save();
      final clip = Path()..addOval(dst);
      canvas.clipPath(clip);
      final src = Rect.fromLTWH(
          0, 0, img.width.toDouble(), img.height.toDouble());
      _p.color = Colors.white;
      canvas.drawImageRect(img, src, dst, _p);
      canvas.restore();
    } else {
      _p.color = AppTheme.accent;
      canvas.drawOval(dst, _p);
    }
    // Pembe çerçeve
    _stroke
      ..color = AppTheme.accent
      ..strokeWidth = 3;
    canvas.drawOval(dst, _stroke);
  }

  double _zP() => _SubwayCatScreenState._zP;

  @override
  bool shouldRepaint(covariant _RunnerPainter old) => false;
}
