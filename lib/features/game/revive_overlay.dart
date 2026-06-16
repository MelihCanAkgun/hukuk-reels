import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/data/questions_data.dart';
import '../../core/models/quiz_question.dart';

/// Oyun bitince "bir soru karşılığı devam et" akışı (oyun başına 1 kez).
/// Block Blast, Flappy ve Subway Silly'nin ortak kullandığı katman.
///
/// Doğru cevap → [onRevive] (oyun kaldığı yerden devam), Hayır/yanlış →
/// [onGiveUp] (oyun gerçekten biter). Arka plan dokunuşlarını yutar; bu yüzden
/// ekranı saran onTap/onPan dinleyicili oyunlarda da güvenle çalışır.
class ReviveOverlay extends StatefulWidget {
  final VoidCallback onRevive;
  final VoidCallback onGiveUp;
  const ReviveOverlay({
    super.key,
    required this.onRevive,
    required this.onGiveUp,
  });

  @override
  State<ReviveOverlay> createState() => _ReviveOverlayState();
}

class _ReviveOverlayState extends State<ReviveOverlay> {
  static final _rng = Random();
  bool _quiz = false;
  QuizQuestion? _q;
  int? _selected;

  void _accept() {
    setState(() {
      _quiz = true;
      _selected = null;
      _q = kQuestions[_rng.nextInt(kQuestions.length)].withShuffledOptions(_rng);
    });
  }

  void _answer(int i) {
    if (_selected != null) return;
    setState(() => _selected = i);
    final correct = i == _q!.correctIndex;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (correct) {
        widget.onRevive();
      } else {
        widget.onGiveUp();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // arka plan dokunuşlarını yut (alttaki oyunu tetikleme)
      child: Container(
        color: Colors.black.withValues(alpha: _quiz ? 0.72 : 0.6),
        alignment: Alignment.center,
        child: _quiz ? _quizCard() : _askCard(),
      ),
    );
  }

  Widget _askCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 36),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💖', style: TextStyle(fontSize: 46)),
          const SizedBox(height: 8),
          const Text(
            'Bir şansın daha!',
            style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bir soruyu doğru bilirsen oyuna kaldığın yerden devam edersin.\n(Oyun başına yalnızca 1 hak)',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5, height: 1.35, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          _bigBtn('Evet, soruyu göster 🧠', primary: true, onTap: _accept),
          const SizedBox(height: 10),
          _bigBtn('Hayır, bitir', primary: false, onTap: widget.onGiveUp),
        ],
      ),
    );
  }

  Widget _quizCard() {
    final q = _q!;
    final answered = _selected != null;
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: q.category.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(30),
                border:
                    Border.all(color: q.category.color.withValues(alpha: 0.5)),
              ),
              child: Text(
                'DEVAM SORUSU · ${q.category.label.toUpperCase()}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: q.category.color,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              q.question,
              style: const TextStyle(
                fontSize: 17,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < q.options.length; i++) _option(i, q),
            const SizedBox(height: 4),
            Text(
              answered
                  ? (_selected == q.correctIndex
                      ? 'Doğru! Devam ediyorsun… 🎉'
                      : 'Yanlış… oyun bitiyor.')
                  : 'Doğru bilirsen oyun devam eder.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: answered
                    ? (_selected == q.correctIndex
                        ? AppTheme.success
                        : AppTheme.danger)
                    : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(int i, QuizQuestion q) {
    final sel = _selected;
    Color bg = AppTheme.surface;
    Color border = AppTheme.border;
    Color fg = AppTheme.textPrimary;
    if (sel != null) {
      final isCorrect = i == q.correctIndex;
      final isChosen = i == sel;
      if (isCorrect) {
        bg = AppTheme.success.withValues(alpha: 0.18);
        border = AppTheme.success;
      } else if (isChosen) {
        bg = AppTheme.danger.withValues(alpha: 0.18);
        border = AppTheme.danger;
      } else {
        fg = AppTheme.textMuted;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: sel == null ? () => _answer(i) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  String.fromCharCode(65 + i),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  q.options[i],
                  style: TextStyle(
                      fontSize: 14.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: fg),
                ),
              ),
            ],
          ),
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
        child: Text(
          label,
          style: TextStyle(
            color: primary ? Colors.white : AppTheme.textSecondary,
            fontSize: primary ? 16 : 15,
            fontWeight: primary ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
