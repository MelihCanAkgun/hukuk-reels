import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../core/services/audio_service.dart';
import '../reels/screens/reels_screen.dart';

/// Açılış kapısı: "Kendine Güveniyor musun?"
///
/// "Evet 🥰" tıklanabilir ve teste geçirir.
/// "Hayır 😟" yaklaşınca ayakları çıkar ve kaçar — asla tıklanamaz.
class ConfidenceGateScreen extends StatefulWidget {
  const ConfidenceGateScreen({super.key});

  @override
  State<ConfidenceGateScreen> createState() => _ConfidenceGateScreenState();
}

class _ConfidenceGateScreenState extends State<ConfidenceGateScreen>
    with TickerProviderStateMixin {
  static const double _btnW = 148;
  static const double _btnH = 56;
  static const double _gap = 18;
  static const double _fleeThreshold = 78; // imleç bu kadar yaklaşınca kaçar

  final _rng = Random();
  late final AnimationController _legCtrl;

  double _w = 0;
  double _h = 0;
  double? _noLeft;
  double? _noTop;
  bool _hasFled = false;
  int _escapeCount = 0;

  static const _taunts = [
    'Hayır 😟',
    'Yakalayamazsın 😝',
    'Nereye? 🏃',
    'Boşuna 😆',
    'Pes et 😎',
    'Hâlâ mı? 🙄',
  ];

  @override
  void initState() {
    super.initState();
    _legCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _legCtrl.dispose();
    super.dispose();
  }

  // ── Geometri yardımcıları ──
  double get _pairTop => _h * 0.60;
  double get _evetLeft => _w / 2 - _btnW - _gap / 2;
  Rect get _evetRect => Rect.fromLTWH(_evetLeft, _pairTop, _btnW, _btnH);
  Rect get _titleRect => Rect.fromLTWH(0, _h * 0.14, _w, _h * 0.30);
  Rect get _noRect =>
      Rect.fromLTWH(_noLeft ?? 0, _noTop ?? 0, _btnW, _btnH);

  void _ensureInit() {
    _noLeft ??= _w / 2 + _gap / 2;
    _noTop ??= _pairTop;
  }

  double _distToRect(Offset p, Rect r) {
    final dx = p.dx < r.left
        ? r.left - p.dx
        : (p.dx > r.right ? p.dx - r.right : 0.0);
    final dy = p.dy < r.top
        ? r.top - p.dy
        : (p.dy > r.bottom ? p.dy - r.bottom : 0.0);
    return sqrt(dx * dx + dy * dy);
  }

  bool _rectOk(Rect r) {
    if (r.left < 12 || r.top < _h * 0.10) return false;
    if (r.right > _w - 12 || r.bottom > _h - 88) return false;
    if (r.overlaps(_evetRect.inflate(14))) return false;
    if (r.overlaps(_titleRect)) return false;
    return true;
  }

  void _flee(Offset pointer) {
    Rect? best;
    double bestDist = -1;
    for (var i = 0; i < 36; i++) {
      final left = 12 + _rng.nextDouble() * (_w - _btnW - 24);
      final top = _h * 0.12 + _rng.nextDouble() * (_h * 0.76 - _btnH);
      final cand = Rect.fromLTWH(left, top, _btnW, _btnH);
      if (!_rectOk(cand)) continue;
      final d = _distToRect(pointer, cand);
      if (d > bestDist) {
        bestDist = d;
        best = cand;
      }
    }
    best ??= Rect.fromLTWH(
      12 + _rng.nextDouble() * (_w - _btnW - 24),
      _h * 0.14 + _rng.nextDouble() * (_h * 0.5),
      _btnW,
      _btnH,
    );
    setState(() {
      _noLeft = best!.left;
      _noTop = best.top;
      _hasFled = true;
      _escapeCount++;
    });
    HapticFeedback.selectionClick();
  }

  void _maybeFlee(Offset localPointer) {
    if (_distToRect(localPointer, _noRect) < _fleeThreshold) {
      _flee(localPointer);
    }
  }

  void _onEvet() {
    HapticFeedback.mediumImpact();
    AudioService.instance.start();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const ReelsScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _w = constraints.maxWidth;
              _h = constraints.maxHeight;
              _ensureInit();

              return Listener(
                behavior: HitTestBehavior.translucent,
                // Yalnızca fare ile yaklaşınca kaç (web). Dokunmatikte "Hayır"
                // kendi onTapDown'ıyla kaçar; burada global onPointerDown
                // KULLANMIYORUZ ki Evet'e dokunmayı engellemesin.
                onPointerHover: (e) => _maybeFlee(e.localPosition),
                child: Stack(
                  children: [
                    // ── Başlık bloğu ──
                    Positioned(
                      top: _h * 0.16,
                      left: 24,
                      right: 24,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: AppTheme.accent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'MEDENİ USUL HUKUKU · FİNAL',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Kendine Güveniyor musun?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── EVET (sabit, tıklanabilir) ──
                    Positioned(
                      left: _evetLeft,
                      top: _pairTop,
                      child: _EvetButton(
                        width: _btnW,
                        height: _btnH,
                        onTap: _onEvet,
                      ),
                    ),

                    // ── HAYIR (kaçan) ──
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutBack,
                      left: _noLeft,
                      top: _noTop,
                      child: _NoButton(
                        width: _btnW,
                        height: _btnH,
                        label: _taunts[_escapeCount % _taunts.length],
                        showLegs: _hasFled,
                        legAnim: _legCtrl,
                        // Dokununca da kaçsın; tıklama asla "gerçekleşmez".
                        onTapDown: (global, local) => _flee(local),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tıklanabilir "Evet" butonu.
class _EvetButton extends StatefulWidget {
  final double width;
  final double height;
  final VoidCallback onTap;
  const _EvetButton({
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  State<_EvetButton> createState() => _EvetButtonState();
}

class _EvetButtonState extends State<_EvetButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C8CFF), Color(0xFF8A6CFF)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'Evet 🥰',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kaçan "Hayır" butonu (ayaklı).
class _NoButton extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final bool showLegs;
  final Animation<double> legAnim;
  final void Function(Offset global, Offset local) onTapDown;

  const _NoButton({
    required this.width,
    required this.height,
    required this.label,
    required this.showLegs,
    required this.legAnim,
    required this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => onTapDown(d.globalPosition, d.localPosition),
      onPanStart: (d) => onTapDown(d.globalPosition, d.localPosition),
      // onTap bilinçli olarak yok: "Hayır" hiçbir zaman seçilemez.
      child: SizedBox(
        width: width,
        height: height + 18,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Ayaklar (butonun altından çıkar)
            if (showLegs)
              Positioned(
                bottom: 0,
                child: AnimatedBuilder(
                  animation: legAnim,
                  builder: (context, _) {
                    final swing = (legAnim.value - 0.5) * 0.9;
                    return SizedBox(
                      width: width * 0.5,
                      height: 20,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          _leg(-18, swing),
                          _leg(18, -swing),
                        ],
                      ),
                    );
                  },
                ),
              ),
            // Buton gövdesi
            Container(
              width: width,
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leg(double dx, double swing) {
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Transform.rotate(
        angle: swing,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Container(
              width: 11,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
