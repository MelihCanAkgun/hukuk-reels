import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────
/// iOS Safari "Ana Ekrana Ekle" Yönlendirme Banner'ı
///
/// Kullanıcıya adım adım görsel talimat verir:
/// 1. Alt bardaki Paylaş (Share) ikonuna bas
/// 2. "Ana Ekrana Ekle" (Add to Home Screen) seçeneğini bul
/// 3. "Ekle" butonuna bas
///
/// Banner kapatıldığında Hive'a kaydedilir, bir daha gösterilmez.
/// ──────────────────────────────────────────────────
class IosInstallBanner extends StatefulWidget {
  final VoidCallback onDismiss;

  const IosInstallBanner({super.key, required this.onDismiss});

  @override
  State<IosInstallBanner> createState() => _IosInstallBannerState();
}

class _IosInstallBannerState extends State<IosInstallBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Kısa gecikme sonrası yukarı kayarak göster
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: bottomPadding + 70, // BottomNav üstünde
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF6D00).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Başlık ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white10),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6D00).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.install_mobile,
                        color: Color(0xFFFF6D00),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Uygulamayı Yükle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _dismiss,
                      icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),

              // ── Adımlar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    _StepRow(
                      stepNumber: 1,
                      icon: Icons.ios_share,
                      text: 'Alt bardaki Paylaş',
                      highlight: '(Share)',
                      trailingText: 'ikonuna dokunun',
                    ),
                    const SizedBox(height: 14),
                    _StepRow(
                      stepNumber: 2,
                      icon: Icons.add_box_outlined,
                      text: 'Listeden',
                      highlight: '"Ana Ekrana Ekle"',
                      trailingText: "seçin",
                    ),
                    const SizedBox(height: 14),
                    _StepRow(
                      stepNumber: 3,
                      icon: Icons.check_circle_outline,
                      text: 'Sağ üstteki',
                      highlight: '"Ekle"',
                      trailingText: 'butonuna basın',
                    ),
                  ],
                ),
              ),

              // ── Alt bilgi ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off,
                        color: Colors.greenAccent.withValues(alpha: 0.7), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Yükledikten sonra internet olmadan da kullanabilirsiniz!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Alt ok işareti (paylaş butonunu işaret eder) ──
              CustomPaint(
                size: const Size(24, 12),
                painter: _TrianglePainter(color: const Color(0xFF1E1E2E)),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int stepNumber;
  final IconData icon;
  final String text;
  final String highlight;
  final String trailingText;

  const _StepRow({
    required this.stepNumber,
    required this.icon,
    required this.text,
    required this.highlight,
    required this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Adım numarası
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6D00).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                color: Color(0xFFFF6D00),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // İkon
        Icon(icon, color: Colors.white60, size: 20),
        const SizedBox(width: 8),
        // Açıklama
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
              children: [
                TextSpan(text: '$text '),
                TextSpan(
                  text: highlight,
                  style: const TextStyle(
                    color: Color(0xFFFF6D00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' $trailingText'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Alt ok (üçgen) çizici
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
