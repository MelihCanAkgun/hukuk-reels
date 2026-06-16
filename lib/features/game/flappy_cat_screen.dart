import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../core/services/progress_service.dart';
import 'revive_overlay.dart';

/// Profilden açılan mini oyun: "Flappy Silly Cat".
/// Dokunarak kediyi zıplat, borulardaki boşluklardan geç.
class FlappyCatScreen extends StatefulWidget {
  const FlappyCatScreen({super.key});

  @override
  State<FlappyCatScreen> createState() => _FlappyCatScreenState();
}

enum _GameState { ready, playing, over }

class _Pipe {
  double x;
  final double gapY;
  bool scored = false;
  _Pipe(this.x, this.gapY);
}

class _FlappyCatScreenState extends State<FlappyCatScreen>
    with SingleTickerProviderStateMixin {
  // ── Fizik / ölçü sabitleri ──
  static const double _gravity = 1500; // px/s²
  static const double _flapV = -430; // zıplama hızı
  static const double _speed = 165; // boru hızı px/s
  static const double _catD = 48; // kedi çapı
  static const double _pipeW = 66;
  static const double _gap = 200; // boşluk yüksekliği
  static const double _groundH = 64;
  static const double _interval = 230; // borular arası yatay mesafe

  final _rng = Random();
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  double _w = 0, _h = 0;
  double _catX = 0, _catY = 0, _catVel = 0;
  double _t = 0;
  final List<_Pipe> _pipes = [];
  int _score = 0;
  bool _newRecord = false;
  DateTime _overAt = DateTime.fromMillisecondsSinceEpoch(0);
  _GameState _state = _GameState.ready;

  // Soru karşılığı tek seferlik ekstra can
  bool _reviveUsed = false;
  bool _reviving = false;

  double get _playH => _h - _groundH;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.0
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || _w == 0) return;
    _update(dt > 0.05 ? 0.05 : dt); // büyük sıçramaları sınırla
  }

  void _update(double dt) {
    _t += dt;
    if (_state == _GameState.ready) {
      // Hafif süzülme animasyonu
      setState(() => _catY = _playH / 2 - _catD / 2 + sin(_t * 3) * 8);
      return;
    }
    if (_state != _GameState.playing) return; // over: dondur

    _catVel += _gravity * dt;
    _catY += _catVel * dt;

    for (final p in _pipes) {
      p.x -= _speed * dt;
    }
    if (_pipes.isEmpty || _pipes.last.x <= _w - _interval) _spawnPipe();
    _pipes.removeWhere((p) => p.x + _pipeW < 0);

    for (final p in _pipes) {
      if (!p.scored && p.x + _pipeW < _catX) {
        p.scored = true;
        _score++;
        HapticFeedback.selectionClick();
      }
    }

    if (_catY < 0) {
      _catY = 0;
      _catVel = 0;
    }
    if (_catY + _catD >= _playH) {
      _gameOver();
      return;
    }
    final hit = Rect.fromLTWH(_catX + 7, _catY + 7, _catD - 14, _catD - 14);
    for (final p in _pipes) {
      final top = Rect.fromLTWH(p.x, 0, _pipeW, p.gapY - _gap / 2);
      final bot = Rect.fromLTWH(
          p.x, p.gapY + _gap / 2, _pipeW, _playH - (p.gapY + _gap / 2));
      if (hit.overlaps(top) || hit.overlaps(bot)) {
        _gameOver();
        return;
      }
    }
    setState(() {});
  }

  void _spawnPipe() {
    const margin = 58.0;
    final minY = _gap / 2 + margin;
    final maxY = _playH - _gap / 2 - margin;
    final gapY = maxY <= minY ? _playH / 2 : minY + _rng.nextDouble() * (maxY - minY);
    _pipes.add(_Pipe(_w, gapY));
  }

  void _flap() {
    if (_state == _GameState.over) {
      if (_reviving) return; // revive katmanı açıkken dokunuş restart etmesin
      // Ölüm dokunuşu oyunu hemen yeniden başlatmasın.
      if (DateTime.now().difference(_overAt) <
          const Duration(milliseconds: 700)) {
        return;
      }
      _restart();
      return;
    }
    if (_state == _GameState.ready) _state = _GameState.playing;
    _catVel = _flapV;
    HapticFeedback.lightImpact();
  }

  void _gameOver() {
    // Bu oyunda revive hakkı kalmadıysa önce "devam et?" sorusunu sun.
    if (!_reviveUsed) {
      _state = _GameState.over;
      _reviving = true;
      HapticFeedback.mediumImpact();
      setState(() {});
      return;
    }
    _finishGame();
  }

  void _finishGame() {
    _state = _GameState.over;
    _reviving = false;
    _overAt = DateTime.now();
    HapticFeedback.heavyImpact();
    ProgressService.instance.submitFlappyScore(_score).then((rec) {
      if (mounted && rec) setState(() => _newRecord = true);
    });
    setState(() {});
  }

  /// Doğru cevap: ekstra can yakıldı, kedi ortalanır, önündeki yakın borular
  /// temizlenir ve oyun devam eder.
  void _doRevive() {
    setState(() {
      _reviveUsed = true;
      _reviving = false;
      _catY = _playH / 2 - _catD / 2;
      _catVel = 0;
      _pipes.removeWhere((p) => p.x + _pipeW > _catX - 40 && p.x < _catX + 260);
      _state = _GameState.playing;
    });
  }

  void _giveUp() => _finishGame();

  void _restart() {
    setState(() {
      _state = _GameState.ready;
      _catY = _playH / 2 - _catD / 2;
      _catVel = 0;
      _pipes.clear();
      _score = 0;
      _t = 0;
      _newRecord = false;
      _reviveUsed = false;
      _reviving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final best = ProgressService.instance.flappyHigh;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: LayoutBuilder(
        builder: (context, c) {
          _w = c.maxWidth;
          _h = c.maxHeight;
          _catX = _w * 0.28;
          final tilt = (_catVel / 620).clamp(-0.5, 1.3);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _flap,
            child: Stack(
              children: [
                // ── Gökyüzü ──
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3A1E30), Color(0xFF1C0E17)],
                      ),
                    ),
                  ),
                ),

                // ── Borular ──
                for (final p in _pipes) ..._pipePair(p),

                // ── Zemin ──
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _groundH,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE0567F), Color(0xFF9B2F50)],
                      ),
                      border: Border(
                        top: BorderSide(color: Color(0xFFFFB6C1), width: 3),
                      ),
                    ),
                  ),
                ),

                // ── Kedi ──
                Positioned(
                  left: _catX,
                  top: _catY,
                  child: Transform.rotate(
                    angle: tilt,
                    child: _cat(),
                  ),
                ),

                // ── Skor (oynarken) ──
                if (_state == _GameState.playing)
                  Positioned(
                    top: c.maxHeight * 0.10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '$_score',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Color(0xFF9B2F50), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Üst bar ──
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 14, 4),
                      child: Row(
                        children: [
                          _circleBtn(Icons.arrow_back_rounded,
                              () => Navigator.of(context).maybePop()),
                          const SizedBox(width: 6),
                          const Text('🐱', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          const Text(
                            'Flappy Silly Cat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🏆',
                                    style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 5),
                                Text(
                                  '$best',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Başlangıç katmanı ──
                if (_state == _GameState.ready) _readyOverlay(),

                // ── Devam et? (soru karşılığı ekstra can) ──
                if (_state == _GameState.over && _reviving)
                  ReviveOverlay(onRevive: _doRevive, onGiveUp: _giveUp),

                // ── Oyun bitti katmanı ──
                if (_state == _GameState.over && !_reviving) _overOverlay(best),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cat() {
    return Container(
      width: _catD,
      height: _catD,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        image: const DecorationImage(
          image: AssetImage('assets/images/SHINY_Cuh.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.6),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  List<Widget> _pipePair(_Pipe p) {
    final topH = p.gapY - _gap / 2;
    final botTop = p.gapY + _gap / 2;
    return [
      Positioned(
        left: p.x,
        top: 0,
        width: _pipeW,
        height: topH < 0 ? 0 : topH,
        child: _pipe(capAtBottom: true),
      ),
      Positioned(
        left: p.x,
        top: botTop,
        width: _pipeW,
        height: (_playH - botTop).clamp(0, _h),
        child: _pipe(capAtBottom: false),
      ),
    ];
  }

  Widget _pipe({required bool capAtBottom}) {
    final radius = capAtBottom
        ? const BorderRadius.vertical(bottom: Radius.circular(12))
        : const BorderRadius.vertical(top: Radius.circular(12));
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFF9FC1), Color(0xFFD9477A), Color(0xFFB23461)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: radius,
        border: Border.all(color: const Color(0xFF7A2243), width: 2),
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
      child: Align(
        alignment: const Alignment(0, 0.45),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '👆 Uçurmak için dokun',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Borulardaki boşluklardan geç!',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overOverlay(int best) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
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
            Text(_newRecord ? '🎉' : '😹', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text(
              _newRecord ? 'Yeni Rekor!' : 'Oyun Bitti',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _scoreBox('Skor', '$_score', AppTheme.accent),
                const SizedBox(width: 14),
                _scoreBox('Rekor', '$best', AppTheme.success),
              ],
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: _restart,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppTheme.pinkGradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Tekrar Oyna',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'Profile Dön',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBox(String label, String value, Color color) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
