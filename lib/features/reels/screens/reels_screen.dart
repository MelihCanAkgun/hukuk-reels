import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../core/data/questions_data.dart';
import '../../../core/models/quiz_question.dart';
import '../../../core/services/audio_service.dart';
import '../widgets/music_control_panel.dart';
import '../widgets/question_card.dart';

/// Dikey kaydırmalı soru çözme ekranı (reels formatı).
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen>
    with WidgetsBindingObserver {
  final _pageController = PageController();
  final _audio = AudioService.instance;
  final _rng = Random();

  late List<QuizQuestion> _questions;
  final Set<int> _answered = {};
  final List<QuizQuestion> _wrongQuestions = [];
  int _correct = 0;
  int _page = 0;
  int _deckId = 0;
  bool _audioStarted = false;
  bool _showMusicPanel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _questions = _buildDeck();
  }

  List<QuizQuestion> _buildDeck() =>
      kQuestions.map((q) => q.withShuffledOptions(_rng)).toList()
        ..shuffle(_rng);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _audio.pauseForLifecycle();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _audio.pauseForLifecycle();
    } else if (state == AppLifecycleState.resumed) {
      _audio.resumeForLifecycle();
    }
  }

  void _startAudioOnce() {
    if (_audioStarted) return;
    _audioStarted = true;
    _audio.start();
  }

  void _onAnswered(int index, bool correct) {
    if (_answered.contains(index)) return;
    setState(() {
      _answered.add(index);
      if (correct) {
        _correct++;
      } else {
        _wrongQuestions.add(_questions[index]);
      }
    });
  }

  void _restart() {
    setState(() {
      _deckId++;
      _questions = _buildDeck();
      _wrongQuestions.clear();
      _answered.clear();
      _correct = 0;
      _page = 0;
    });
    _pageController.jumpToPage(0);
  }

  /// Sadece yanlış çözülen soruları, cevapları kapalı (yeniden çözülebilir)
  /// şekilde tekrar dizer.
  void _retryWrong() {
    if (_wrongQuestions.isEmpty) return;
    final retry = _wrongQuestions
        .map((q) => q.withShuffledOptions(_rng))
        .toList()
      ..shuffle(_rng);
    setState(() {
      _deckId++;
      _questions = retry;
      _wrongQuestions.clear();
      _answered.clear();
      _correct = 0;
      _page = 0;
    });
    _pageController.jumpToPage(0);
  }

  Color get _currentAccent => _page < _questions.length
      ? _questions[_page].category.color
      : AppTheme.accent;

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;
    final onSummary = _page >= total;
    final progress = total == 0 ? 0.0 : (_page.clamp(0, total)) / total;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _startAudioOnce(),
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: Stack(
            children: [
              // ── Soru sayfaları (köşe görselleri kartın içinde) ──
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                itemCount: total + 1, // son sayfa: özet
                onPageChanged: (i) {
                  setState(() => _page = i);
                  HapticFeedback.selectionClick();
                },
                itemBuilder: (context, index) {
                  if (index >= total) {
                    return _SummaryCard(
                      correct: _correct,
                      total: total,
                      wrongCount: _wrongQuestions.length,
                      onRestart: _restart,
                      onRetryWrong: _retryWrong,
                    );
                  }
                  final topInset = MediaQuery.of(context).padding.top + 58;
                  // Geniş ekranlarda kartı ortala ve max 480px tut; mobilde
                  // tam genişlik. SizedBox tight boyut verir (yükseklik bozulmaz,
                  // dar ekranda taşma olmaz).
                  return Padding(
                    padding: EdgeInsets.only(top: topInset),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth < 480 ? c.maxWidth : 480.0;
                        return Center(
                          child: SizedBox(
                            width: w,
                            height: c.maxHeight,
                            child: QuestionCard(
                              key: ValueKey('${_deckId}_${_questions[index].id}'),
                              question: _questions[index],
                              onAnswered: (c) => _onAnswered(index, c),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // ── Üst bar: ilerleme + skor + müzik ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopBar(
                  progress: progress,
                  accent: _currentAccent,
                  label: onSummary ? 'Bitti 🎉' : '${_page + 1} / $total',
                  correct: _correct,
                  answered: _answered.length,
                  showMusic: _audio.hasTracks,
                  musicOpen: _showMusicPanel,
                  onMusicTap: () =>
                      setState(() => _showMusicPanel = !_showMusicPanel),
                ),
              ),

              // ── Müzik denetim masası ──
              if (_showMusicPanel) ...[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _showMusicPanel = false),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 54,
                  right: 12,
                  child: MusicControlPanel(
                    onClose: () => setState(() => _showMusicPanel = false),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Üst bilgi çubuğu: ince ilerleme çizgisi, soru sayacı, skor ve müzik.
class _TopBar extends StatelessWidget {
  final double progress;
  final Color accent;
  final String label;
  final int correct;
  final int answered;
  final bool showMusic;
  final bool musicOpen;
  final VoidCallback onMusicTap;

  const _TopBar({
    required this.progress,
    required this.accent,
    required this.label,
    required this.correct,
    required this.answered,
    required this.showMusic,
    required this.musicOpen,
    required this.onMusicTap,
  });

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return Container(
      padding: EdgeInsets.fromLTRB(16, pad.top + 8, 16, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.bg.withValues(alpha: 0.95),
            AppTheme.bg.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Skor
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.success, size: 15),
                    const SizedBox(width: 5),
                    Text(
                      '$correct/$answered',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (showMusic) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onMusicTap,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: musicOpen
                          ? accent.withValues(alpha: 0.2)
                          : AppTheme.surfaceHigh,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: musicOpen ? accent : AppTheme.border,
                      ),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: accent,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // İlerleme çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: progress),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: AppTheme.border.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Test bitince gösterilen özet kartı.
class _SummaryCard extends StatelessWidget {
  final int correct;
  final int total;
  final int wrongCount;
  final VoidCallback onRestart;
  final VoidCallback onRetryWrong;

  const _SummaryCard({
    required this.correct,
    required this.total,
    required this.wrongCount,
    required this.onRestart,
    required this.onRetryWrong,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (correct / total * 100).round();
    final (emoji, msg) = switch (pct) {
      >= 85 => ('🏆', 'Finali geçtin gitti!'),
      >= 60 => ('💪', 'İyi gidiyorsun, biraz daha tekrar.'),
      >= 40 => ('📚', 'Eksikler var, açıklamaları çalış.'),
      _ => ('🔁', 'Baştan tur atmakta fayda var.'),
    };

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 86),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 20),
                const Text(
                  'Test Tamamlandı',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _stat('$correct', 'Doğru', AppTheme.success),
                      _divider(),
                      _stat('$wrongCount', 'Yanlış', AppTheme.danger),
                      _divider(),
                      _stat('%$pct', 'Başarı', AppTheme.accent),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _button(
                  label: 'Yeniden Karıştır',
                  icon: Icons.refresh_rounded,
                  onTap: onRestart,
                  primary: true,
                ),
                if (wrongCount > 0) ...[
                  const SizedBox(height: 12),
                  _button(
                    label: 'Sadece Yanlışları Çöz ($wrongCount)',
                    icon: Icons.error_outline_rounded,
                    onTap: onRetryWrong,
                    primary: false,
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 22,
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              'Sendeyiz Arifecim 🫂',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _button({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(
                  colors: [Color(0xFF6C8CFF), Color(0xFF8A6CFF)])
              : null,
          color: primary ? null : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(15),
          border: primary
              ? null
              : Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primary ? Colors.white : AppTheme.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.white : AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 22),
        color: AppTheme.border,
      );
}
