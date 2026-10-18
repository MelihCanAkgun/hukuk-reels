import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/data/questions_data.dart';
import '../../core/models/quiz_question.dart';
import '../../core/services/progress_service.dart';
import '../../core/widgets/pixel_logo.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/readable_width.dart';
import '../beat/beat_mode_screen.dart';
import '../reels/screens/reels_screen.dart';
import '../summaries/summaries_screen.dart';

/// "Çalış" sekmesi: özetler (kalemle not) ve soru pratiği bir arada.
class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  /// Yanlış yapılmış sorular, en çok yanlıştan başlayarak.
  List<QuizQuestion> get _wrong {
    final stats = ProgressService.instance.stats;
    final wrong = [
      for (final q in kQuestions)
        if ((stats[q.id]?.wrong ?? 0) > 0) q
    ]..sort((a, b) => stats[b.id]!.wrong.compareTo(stats[a.id]!.wrong));
    return wrong;
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {}); // yanlış sayısı değişmiş olabilir
  }

  @override
  Widget build(BuildContext context) {
    final gutter = readableGutter(context);
    final wrong = _wrong;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 12, 10),
                child: Row(
                  children: [
                    PixelLogo(kLogoLawBook, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Çalış',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  primary: true,
                  padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 24),
                  children: [
                    _title('ÖZETLER'),
                    const SummaryTiles(),
                    const SizedBox(height: 10),
                    const SummaryHint(),
                    _title('SORU PRATİĞİ'),
                    _card(
                      key: const ValueKey('study-beat'),
                      logo: const PixelBatIcon(size: 30),
                      title: 'Yanlış Soruları Döv',
                      subtitle: wrong.isEmpty
                          ? 'Yanlışın yok 🎉 Soru çözdükçe burada birikir.'
                          : '${wrong.length} yanlış soru · sopayla dağıt',
                      onTap: wrong.isEmpty
                          ? null
                          : () => _push(BeatModeScreen(questions: wrong)),
                    ),
                    if (wrong.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _card(
                        key: const ValueKey('study-retry'),
                        logo: const Icon(Icons.replay_rounded,
                            color: AppTheme.accent, size: 28),
                        title: 'Yanlışlarımı çöz',
                        subtitle: 'Aynı soruları yeniden dene',
                        onTap: () => _push(ReelsScreen(retryQuestions: wrong)),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _card(
                      key: const ValueKey('study-bank'),
                      logo: const PixelLogo(kLogoQuestionBank, size: 30),
                      title: 'Soru bankası',
                      subtitle: ReelsScreen.maintenance
                          ? 'Bakımda · çok yakında 🛠️'
                          : 'Hukuk testlerine devam et',
                      onTap: () => _push(const ReelsScreen()),
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

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppTheme.textSecondary,
          ),
        ),
      );

  Widget _card({
    required Key key,
    required Widget logo,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          SizedBox(width: 34, child: Center(child: logo)),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ],
      ),
    );
    if (onTap == null) {
      return Opacity(key: key, opacity: .6, child: card);
    }
    return Pressable(key: key, semanticLabel: title, onTap: onTap, child: card);
  }
}
