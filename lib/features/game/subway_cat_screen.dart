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
  bool _showHelp = false;

  // Zorluk dalgaları: kolay ve zor bölümler dönüşümlü gelir.
  double _waveEnds = 55;
  bool _hard = false;
  bool _lastDouble = false;

  // Dünya / kamera sabitleri
  static const double zNear = 2.0; // ölçek referansı + oyuncu düzlemi
  static const double zFar = 34.0; // doğuş mesafesi
  static const double _zP = 2.0; // oyuncunun z'si

  // Hareket durumu
  double _dist = 0; // toplam mesafe (skor)
  int _coins = 0;
  double _speed = 8;
  static const double _baseSpeed = 8;
  static const double _maxSpeed = 19;
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
    _speed = math.min(_maxSpeed, _baseSpeed + _dist * 0.025);
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
      // Dalga değişimi: kolay <-> zor bölümler
      if (_dist >= _waveEnds) {
        _hard = !_hard;
        _waveEnds = _dist + (_hard ? 55 : 48) + _rng.nextDouble() * 22;
      }
      _spawnRow(_hard);
      var gap = (_hard ? 7.0 : 10.0) + _rng.nextDouble() * (_hard ? 2.5 : 3.5);
      if (_lastDouble) gap += 3.5; // çift engelden sonra nefes payı
      _nextSpawn += gap;
    }
  }

  _Kind _randObstacle() {
    final t = _rng.nextDouble();
    return t < 0.4 ? _Kind.barrier : (t < 0.7 ? _Kind.bar : _Kind.wall);
  }

  void _addCoinRun(int lane) {
    final n = 3 + _rng.nextInt(3);
    for (var k = 0; k < n; k++) {
      _ents.add(_Ent(zFar - k * 1.5, lane, _Kind.coin));
    }
  }

  /// Bir satır engel doğurur. Asla 3 şeridi birden kapatmaz (her zaman
  /// geçilebilir). Zor dalgalarda bazen 2 şerit kapatılır ve serbest şeride
  /// yol gösteren coin dizisi konur.
  void _spawnRow(bool hard) {
    if (hard && !_lastDouble && _rng.nextDouble() < 0.4) {
      final free = _rng.nextInt(3) - 1;
      for (final ln in const [-1, 0, 1]) {
        if (ln != free) _ents.add(_Ent(zFar, ln, _randObstacle()));
      }
      _addCoinRun(free);
      _lastDouble = true;
    } else {
      final lane = _rng.nextInt(3) - 1;
      _ents.add(_Ent(zFar, lane, _randObstacle()));
      if (_rng.nextDouble() < (hard ? 0.45 : 0.8)) {
        final opts = [-1, 0, 1]..remove(lane);
        _addCoinRun(opts[_rng.nextInt(opts.length)]);
      }
      _lastDouble = false;
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
    _nextSpawn = 12; // sakin başlangıç
    _hard = false;
    _waveEnds = 55;
    _lastDouble = false;
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
              if (_phase == _Phase.ready)
                (_showHelp ? _helpOverlay() : _readyOverlay()),
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
            const Text('Subway Silly',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Engellerden kaç, coin topla, hız artar!',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13.5, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            _bigBtn('Başla', primary: true, onTap: _start),
            const SizedBox(height: 10),
            _bigBtn('Nasıl oynanır?',
                primary: false,
                onTap: () => setState(() => _showHelp = true)),
          ],
        ),
      ),
    );
  }

  Widget _helpOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: BoxDecoration(
            color: AppTheme.bgElevated,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Nasıl oynanır?',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary)),
              ),
              const SizedBox(height: 16),
              const Text('KONTROLLER',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppTheme.accent)),
              const SizedBox(height: 8),
              _howto('👈 👉', 'Sağa/sola kaydır → şerit değiştir'),
              _howto('👆', 'Yukarı kaydır → zıpla'),
              _howto('👇', 'Aşağı kaydır → eğil (kay)'),
              const SizedBox(height: 4),
              const Text('Bilgisayarda: ok tuşları / boşluk',
                  style:
                      TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
              const SizedBox(height: 18),
              const Text('ENGELLER',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppTheme.accent)),
              const SizedBox(height: 10),
              _legend(_RunnerPainter.cJump, 16, 30,
                  'Alçak engel', 'ÜZERİNDEN ATLA (yukarı)'),
              _legend(_RunnerPainter.cRoll, 8, 30,
                  'Üst kiriş', 'ALTINDAN EĞİL (aşağı)'),
              _legend(_RunnerPainter.cWall, 30, 22,
                  'Yüksek duvar', 'YANINDAN GEÇ (şerit değiştir)'),
              _legend(const Color(0xFFFFC93C), 18, 18,
                  'Coin', 'Topla → +10 puan', circle: true),
              const SizedBox(height: 8),
              const Text(
                'İpucu: bazı bölümler sakin, bazıları zorlu gelir. Yüksek '
                'duvarın üzerinden atlanmaz — mutlaka şerit değiştir!',
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 18),
              _bigBtn('Anladım', primary: true,
                  onTap: () => setState(() => _showHelp = false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(Color color, double h, double w, String name, String action,
      {bool circle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 34,
            child: Center(
              child: Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(color, Colors.white, 0.2)!,
                      Color.lerp(color, Colors.black, 0.2)!,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(circle ? w : 4),
                ),
              ),
            ),
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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

  // Eylem renk kodları (yardım ekranıyla aynı): yeşil=atla, sarı=eğil, kırmızı=geç
  static const Color cJump = Color(0xFF49C56B);
  static const Color cRoll = Color(0xFFF5B62C);
  static const Color cWall = Color(0xFFE5484D);

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
          _groundGlow(canvas, x, y, 0.8 * laneSpread * s, cJump);
          _box3D(canvas, x, y, 0.72 * laneSpread * s, 32 * s, cJump,
              stripes: true);
          break;
        case _Kind.wall:
          _groundGlow(canvas, x, y, 0.92 * laneSpread * s, cWall);
          _box3D(canvas, x, y, 0.84 * laneSpread * s, 80 * s, cWall,
              panels: 3);
          break;
        case _Kind.bar:
          _groundGlow(canvas, x, y, 0.92 * laneSpread * s, cRoll);
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

  // Engelin altına eylem rengiyle yumuşak yer parıltısı (okunabilirlik)
  void _groundGlow(Canvas canvas, double x, double baseY, double w, Color col) {
    _p
      ..style = PaintingStyle.fill
      ..shader = null
      ..color = col.withValues(alpha: 0.22);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(x, baseY), width: w * 1.15, height: w * 0.34),
        _p);
  }

  // Ön + üst + sağ yüzlü küboid (sahte 3D), gradyan + detay çizgileri/şeritleri.
  void _box3D(Canvas canvas, double cxp, double baseY, double w, double h,
      Color front,
      {int panels = 0, bool stripes = false}) {
    final depth = (w * 0.26).clamp(5.0, 24.0);
    final l = cxp - w / 2, rgt = cxp + w / 2;
    final topY = baseY - h;
    final rad = (w * 0.1).clamp(3.0, 9.0);

    // Sağ yüz
    _p
      ..style = PaintingStyle.fill
      ..shader = null
      ..color = Color.lerp(front, Colors.black, 0.4)!;
    final side = Path()
      ..moveTo(rgt, topY)
      ..lineTo(rgt + depth, topY - depth * 0.6)
      ..lineTo(rgt + depth, baseY - depth * 0.6)
      ..lineTo(rgt, baseY)
      ..close();
    canvas.drawPath(side, _p);

    // Üst yüz
    _p.color = Color.lerp(front, Colors.white, 0.28)!;
    final top = Path()
      ..moveTo(l, topY)
      ..lineTo(rgt, topY)
      ..lineTo(rgt + depth, topY - depth * 0.6)
      ..lineTo(l + depth, topY - depth * 0.6)
      ..close();
    canvas.drawPath(top, _p);

    // Ön yüz (gradyan)
    final fRect = Rect.fromLTRB(l, topY, rgt, baseY);
    _p.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(front, Colors.white, 0.14)!,
        Color.lerp(front, Colors.black, 0.26)!,
      ],
    ).createShader(fRect);
    final fr = RRect.fromRectAndCorners(fRect,
        topLeft: Radius.circular(rad), topRight: Radius.circular(rad));
    canvas.drawRRect(fr, _p);
    _p.shader = null;

    // Panel çizgileri (konteyner görünümü — duvar için)
    if (panels > 0) {
      _stroke
        ..color = Colors.black.withValues(alpha: 0.18)
        ..strokeWidth = (h * 0.012).clamp(1.0, 3.0);
      for (var i = 1; i <= panels; i++) {
        final y = topY + h * i / (panels + 1);
        canvas.drawLine(Offset(l + 3, y), Offset(rgt - 3, y), _stroke);
      }
    }

    // Tehlike şeritleri (üst bant — atlanacak alçak engel için)
    if (stripes) {
      final bandH = (h * 0.4).clamp(6.0, h);
      final band = Rect.fromLTRB(l, topY, rgt, topY + bandH);
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndCorners(band,
          topLeft: Radius.circular(rad), topRight: Radius.circular(rad)));
      _p
        ..style = PaintingStyle.fill
        ..color = Colors.black.withValues(alpha: 0.8);
      final sw = (w * 0.16).clamp(6.0, 30.0);
      for (var sx = l - bandH; sx < rgt; sx += sw * 2) {
        final p = Path()
          ..moveTo(sx, topY)
          ..lineTo(sx + sw, topY)
          ..lineTo(sx + sw + bandH, band.bottom)
          ..lineTo(sx + bandH, band.bottom)
          ..close();
        canvas.drawPath(p, _p);
      }
      canvas.restore();
    }
  }

  // Üstten geçen kiriş — altından eğilerek geçilir
  void _drawBar(Canvas canvas, double cxp, double baseY, double w, double s) {
    final l = cxp - w / 2, rgt = cxp + w / 2;
    final beamBottom = baseY - 38 * s;
    final beamTop = baseY - 70 * s;
    final postW = 7 * s;
    // Direkler
    _p
      ..style = PaintingStyle.fill
      ..shader = null
      ..color = const Color(0xFF7A5A1E);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(l, beamTop, postW, baseY - beamTop),
            Radius.circular(2 * s)),
        _p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(rgt - postW, beamTop, postW, baseY - beamTop),
            Radius.circular(2 * s)),
        _p);
    // Kiriş (gradyan amber)
    final beam = Rect.fromLTRB(l, beamTop, rgt, beamBottom);
    final br = RRect.fromRectAndRadius(beam, Radius.circular(4 * s));
    _p.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(cRoll, Colors.white, 0.18)!,
        Color.lerp(cRoll, Colors.black, 0.22)!,
      ],
    ).createShader(beam);
    canvas.drawRRect(br, _p);
    _p.shader = null;
    // Çapraz tehlike şeritleri
    _p.color = const Color(0xFF1A1208).withValues(alpha: 0.78);
    canvas.save();
    canvas.clipRRect(br);
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
