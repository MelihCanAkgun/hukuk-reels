import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────
/// Android Chrome "Uygulamayı Yükle" Banner'ı
///
/// Kullanıcıya adım adım görsel talimat:
/// 1. Sağ üst köşedeki üç nokta menüsüne bas
/// 2. "Uygulamayı yükle" veya "Ana ekrana ekle" seç
/// 3. "Yükle" butonuna bas
/// ──────────────────────────────────────────────────
class AndroidInstallBanner extends StatefulWidget {
  final VoidCallback onDismiss;

  const AndroidInstallBanner({super.key, required this.onDismiss});

  @override
  State<AndroidInstallBanner> createState() => _AndroidInstallBannerState();
}

class _AndroidInstallBannerState extends State<AndroidInstallBanner>
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
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

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
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            top: topPadding + 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF2979FF).withValues(alpha: 0.3),
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
              // Başlık
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.install_mobile,
                        color: Color(0xFF2979FF),
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

              // Adımlar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    _StepRow(
                      stepNumber: 1,
                      icon: Icons.more_vert,
                      text: 'Sağ üstteki',
                      highlight: 'üç nokta menüsüne',
                      trailingText: 'dokunun',
                    ),
                    const SizedBox(height: 14),
                    _StepRow(
                      stepNumber: 2,
                      icon: Icons.add_to_home_screen,
                      text: 'Listeden',
                      highlight: '"Uygulamayı yükle"',
                      trailingText: "seçin",
                    ),
                    const SizedBox(height: 14),
                    _StepRow(
                      stepNumber: 3,
                      icon: Icons.check_circle_outline,
                      text: 'Açılan pencerede',
                      highlight: '"Yükle"',
                      trailingText: 'butonuna basın',
                    ),
                  ],
                ),
              ),

              // Alt bilgi
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
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF2979FF).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                color: Color(0xFF2979FF),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: Colors.white60, size: 20),
        const SizedBox(width: 8),
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
                    color: Color(0xFF2979FF),
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
