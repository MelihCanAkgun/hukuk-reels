import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../core/models/quiz_question.dart';

/// Tek bir soruyu gösteren kart: çoktan seçmeli şıklar + cevap sonrası
/// açıklama. Kart KAYDIRILMAZ; böylece yukarı kaydırınca PageView bir
/// sonraki soruya geçer. Uzun açıklamalar alt panelden (tam metin) okunur.
class QuestionCard extends StatefulWidget {
  final QuizQuestion question;
  final void Function(bool correct) onAnswered;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  int? _selected;

  bool get _answered => _selected != null;
  bool get _isCorrect => _selected == widget.question.correctIndex;
  Color get _accent => widget.question.category.color;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  void _select(int index) {
    if (_answered) return;
    setState(() => _selected = index);
    HapticFeedback.lightImpact();
    widget.onAnswered(index == widget.question.correctIndex);
  }

  void _openFullExplanation() {
    final q = widget.question;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgElevated,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final color = _isCorrect ? AppTheme.success : AppTheme.danger;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _badge(q.category),
                const SizedBox(height: 16),
                Text(
                  q.question,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Doğru cevap: ${_letters[q.correctIndex]}) ${q.correctAnswer}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Açıklama',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  q.explanation,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface, AppTheme.bgElevated],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.16),
            blurRadius: 32,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _badge(q.category),
            const SizedBox(height: 14),
            Text(
              q.question,
              style: const TextStyle(
                fontSize: 17.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(q.options.length, (i) => _option(i)),
            if (_answered) ...[
              const SizedBox(height: 6),
              Flexible(child: _resultPanel()),
            ] else
              const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _badge(QuizCategory cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cat.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cat.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              cat.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cat.color,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(int index) {
    final q = widget.question;
    final isCorrect = index == q.correctIndex;
    final isSelected = index == _selected;

    Color bg = AppTheme.surfaceHigh;
    Color borderColor = AppTheme.border;
    Color fg = AppTheme.textPrimary;
    Color badgeBg = AppTheme.bg;
    Color badgeFg = AppTheme.textSecondary;
    IconData? trailing;
    Color? trailingColor;

    if (_answered) {
      if (isCorrect) {
        bg = AppTheme.success.withValues(alpha: 0.14);
        borderColor = AppTheme.success;
        badgeBg = AppTheme.success;
        badgeFg = Colors.white;
        trailing = Icons.check_circle_rounded;
        trailingColor = AppTheme.success;
      } else if (isSelected) {
        bg = AppTheme.danger.withValues(alpha: 0.12);
        borderColor = AppTheme.danger;
        badgeBg = AppTheme.danger;
        badgeFg = Colors.white;
        fg = AppTheme.textSecondary;
        trailing = Icons.cancel_rounded;
        trailingColor = AppTheme.danger;
      } else {
        fg = AppTheme.textMuted;
        borderColor = AppTheme.border.withValues(alpha: 0.5);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GestureDetector(
        onTap: () => _select(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _letters[index],
                  style: TextStyle(
                    color: badgeFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q.options[index],
                  style: TextStyle(
                    color: fg,
                    fontSize: 14.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, color: trailingColor, size: 19),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultPanel() {
    final color = _isCorrect ? AppTheme.success : AppTheme.danger;

    return GestureDetector(
      onTap: _openFullExplanation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isCorrect
                      ? Icons.verified_rounded
                      : Icons.cancel_rounded,
                  color: color,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Text(
                  _isCorrect ? 'Doğru!' : 'Yanlış',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tümünü oku',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color, size: 17),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                widget.question.explanation,
                overflow: TextOverflow.fade,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.keyboard_double_arrow_up_rounded,
                    color: AppTheme.textMuted, size: 15),
                const SizedBox(width: 5),
                Text(
                  'Sonraki soru için yukarı kaydır',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
