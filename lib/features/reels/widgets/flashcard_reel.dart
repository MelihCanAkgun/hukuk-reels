import 'dart:math';
import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────
/// 3D Flip Animasyonlu Flashcard Widget
///
/// Ön yüz: Soru metni
/// Arka yüz: Doğru cevap + kaynak snippet
/// Tıklayınca Y ekseni etrafında 3D flip yapar
/// ──────────────────────────────────────────────
class FlashcardReel extends StatefulWidget {
  final String frontText;
  final String backText;
  final String? sourceSnippet;
  final List<String> options;
  final VoidCallback? onCorrect;
  final VoidCallback? onWrong;
  final Color accentColor;

  const FlashcardReel({
    super.key,
    required this.frontText,
    required this.backText,
    this.sourceSnippet,
    this.options = const [],
    this.onCorrect,
    this.onWrong,
    this.accentColor = const Color(0xFFFF6D00),
  });

  @override
  State<FlashcardReel> createState() => _FlashcardReelState();
}

class _FlashcardReelState extends State<FlashcardReel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  bool _showFront = true;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _showFront = !_showFront);
  }

  void _selectOption(String option) {
    setState(() => _selectedOption = option);
    final isCorrect = option.toLowerCase().trim() ==
        widget.backText.toLowerCase().trim();
    if (isCorrect) {
      widget.onCorrect?.call();
    } else {
      widget.onWrong?.call();
    }
    // Kısa gecikme sonrası kartı çevir
    Future.delayed(const Duration(milliseconds: 600), _toggleCard);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * pi;
        final isFrontVisible = angle < pi / 2;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspektif
            ..rotateY(angle),
          child: isFrontVisible
              ? _buildFront(context)
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _buildBack(context),
                ),
        );
      },
    );
  }

  Widget _buildFront(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E2E),
            const Color(0xFF2D2D44),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Üst etiket
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.options.isNotEmpty ? 'SORU' : 'FLASHCARD',
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Soru metni
            Expanded(
              child: Center(
                child: Text(
                  widget.frontText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Seçenekler veya "Cevabı gör" butonu
            if (widget.options.isNotEmpty)
              ..._buildOptions()
            else ...[
              const SizedBox(height: 16),
              _buildRevealButton(),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptions() {
    return widget.options.map((option) {
      final isSelected = _selectedOption == option;
      final isCorrect = option.toLowerCase().trim() ==
          widget.backText.toLowerCase().trim();
      final showResult = _selectedOption != null;

      Color bgColor = Colors.white.withValues(alpha: 0.08);
      Color borderColor = Colors.white24;

      if (showResult && isSelected) {
        bgColor = isCorrect
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.red.withValues(alpha: 0.2);
        borderColor = isCorrect ? Colors.green : Colors.red;
      } else if (showResult && isCorrect) {
        bgColor = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green.withValues(alpha: 0.5);
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: _selectedOption == null ? () => _selectOption(option) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildRevealButton() {
    return GestureDetector(
      onTap: _toggleCard,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        decoration: BoxDecoration(
          color: widget.accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: widget.accentColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, color: widget.accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Cevabı Gör',
              style: TextStyle(
                color: widget.accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.accentColor.withValues(alpha: 0.15),
              const Color(0xFF1E1E2E),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'CEVAP',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Icon(Icons.check_circle_outline,
                  color: Colors.greenAccent, size: 48),
              const SizedBox(height: 20),
              Text(
                widget.backText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              if (widget.sourceSnippet != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.sourceSnippet!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                'Geri dönmek için dokun',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
