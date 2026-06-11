import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../core/models/quiz_question.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/progress_service.dart';
import '../../beat/beat_mode_screen.dart';
import '../../profile/profile_settings_screen.dart';
import '../widgets/music_control_panel.dart';
import '../widgets/question_card.dart';

/// Dikey kaydırmalı soru çözme ekranı (reels formatı).
///
/// İki mod:
///  • Ana mod: havuzdan rastgele [ProgressService.testSize] soruluk test.
///    İlerleme cihaza kaydedilir — uygulamadan çıkıp girince kaldığın
///    yerden devam edersin. Çözülen sorular sonraki testlerde gelmez.
///  • Tekrar modu ([retryQuestions] verilirse): yanlışları yeniden çözmek
///    için geçici tur; hiçbir şey kaydedilmez, üst barda geri oku olur.
class ReelsScreen extends StatefulWidget {
  final List<QuizQuestion>? retryQuestions;
  const ReelsScreen({super.key, this.retryQuestions});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen>
    with WidgetsBindingObserver {
  final _audio = AudioService.instance;
  final _progress = ProgressService.instance;
  final _rng = Random();

  PageController? _pageController;
  List<QuizQuestion> _questions = [];
  final Map<int, int> _answers = {}; // soru index -> seçilen şık index
  int _page = 0;
  int _deckId = 0;
  bool _loading = true;
  bool _audioStarted = false;
  bool _showMusicPanel = false;

  bool get _isRetry => widget.retryQuestions != null;

  int get _correct {
    var c = 0;
    _answers.forEach((i, sel) {
      if (sel == _questions[i].correctIndex) c++;
    });
    return c;
  }

  List<QuizQuestion> get _wrongQuestions => [
        for (final e in _answers.entries)
          if (e.value != _questions[e.key].correctIndex) _questions[e.key],
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    if (_isRetry) {
      _questions = widget.retryQuestions!
          .map((q) => q.withShuffledOptions(_rng))
          .toList()
        ..shuffle(_rng);
      _pageController = PageController();
      setState(() => _loading = false);
      return;
    }
    await _progress.init();
    // Kayıtlı oturum varsa kaldığı yerden; yoksa yeni test.
    var session = _progress.loadSession();
    session ??= await _progress.startNewTest(_rng);
    if (!mounted) return;
    if (session == null) {
      // Havuzdaki her şey çözülmüş ve aktif oturum yok.
      _questions = [];
      _pageController = PageController();
      setState(() => _loading = false);
      return;
    }
    _questions = session.questions;
    _answers
      ..clear()
      ..addAll(session.answers);
    _page = session.page.clamp(0, _questions.length);
    _pageController = PageController(initialPage: _page);
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController?.dispose();
    // Tekrar modundan çıkarken müzik kesilmesin (ana ekran devam ediyor).
    if (!_isRetry) _audio.pauseForLifecycle();
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

  void _onAnswered(int index, int selected, bool correct) {
    if (_answers.containsKey(index)) return;
    setState(() => _answers[index] = selected);
    if (!_isRetry) {
      final q = _questions[index];
      _progress.recordAnswer(q.id, correct);
      _progress.saveAnswer(q.id, selected);
    }
  }

  /// Havuzdan (çözülmemişler) yeni bir test başlatır.
  Future<void> _startNextTest() async {
    final session = await _progress.startNewTest(_rng);
    if (!mounted) return;
    setState(() {
      _deckId++;
      _questions = session?.questions ?? [];
      _answers.clear();
      _page = 0;
    });
    if (_questions.isNotEmpty) _pageController?.jumpToPage(0);
  }

  Future<void> _resetPoolAndStart() async {
    await _progress.resetPool();
    await _startNextTest();
  }

  /// Tekrar modunda desteyi yeniden karıştırır.
  void _reshuffleRetry() {
    setState(() {
      _deckId++;
      _questions = widget.retryQuestions!
          .map((q) => q.withShuffledOptions(_rng))
          .toList()
        ..shuffle(_rng);
      _answers.clear();
      _page = 0;
    });
    _pageController?.jumpToPage(0);
  }

  void _retryWrong() {
    final wrong = List.of(_wrongQuestions);
    if (wrong.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReelsScreen(retryQuestions: wrong),
    ));
  }

  void _beatWrong() {
    if (_wrongQuestions.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BeatModeScreen(questions: List.of(_wrongQuestions)),
    ));
  }

  Future<void> _openProfile() async {
    final res = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
    );
    if (!mounted) return;
    if (res == 'poolReset') {
      await _startNextTest();
    } else {
      setState(() {}); // sayaçlar tazelensin
    }
  }

  Color get _currentAccent => _page < _questions.length
      ? _questions[_page].category.color
      : AppTheme.accent;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: Container(
          decoration:
              const BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          ),
        ),
      );
    }

    if (_questions.isEmpty && !_isRetry) return _poolDoneScaffold();

    final total = _questions.length;
    final onSummary = _page >= total;
    final progress = total == 0 ? 0.0 : (_page.clamp(0, total)) / total;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _startAudioOnce(),
        child: Container(
          decoration:
              const BoxDecoration(gradient: AppTheme.backgroundGradient),
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
                  if (!_isRetry) _progress.savePage(i);
                },
                itemBuilder: (context, index) {
                  if (index >= total) {
                    return _SummaryCard(
                      correct: _correct,
                      answered: _answers.length,
                      wrongCount: _wrongQuestions.length,
                      isRetry: _isRetry,
                      remaining: _isRetry ? 0 : _progress.unsolvedCount,
                      onNextTest: _startNextTest,
                      onResetPool: _resetPoolAndStart,
                      onReshuffleRetry: _reshuffleRetry,
                      onRetryWrong: _retryWrong,
                      onBeatWrong: _beatWrong,
                    );
                  }
                  final topInset = MediaQuery.of(context).padding.top + 58;
                  // Geniş ekranlarda kartı ortala ve max 480px tut; mobilde
                  // tam genişlik (tight SizedBox: taşma/yükseklik sorunu yok).
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
                              key: ValueKey(
                                  '${_deckId}_${_questions[index].id}'),
                              question: _questions[index],
                              initialSelected: _answers[index],
                              onAnswered: (sel, ok) =>
                                  _onAnswered(index, sel, ok),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // ── Üst bar: ilerleme + skor + profil + müzik ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopBar(
                  progress: progress,
                  accent: _currentAccent,
                  label: onSummary
                      ? 'Bitti 🎉'
                      : '${_page + 1} / $total${_isRetry ? '  ·  Tekrar' : ''}',
                  correct: _correct,
                  answered: _answers.length,
                  showBack: _isRetry,
                  onBack: () => Navigator.of(context).maybePop(),
                  onProfile: _openProfile,
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

  /// Havuz tamamen bitmiş ve aktif oturum yokken gösterilen ekran.
  Widget _poolDoneScaffold() {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 6,
                right: 12,
                child: _CircleIconButton(
                  icon: Icons.person_rounded,
                  color: AppTheme.accent,
                  onTap: _openProfile,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 18),
                      const Text(
                        'Havuzdaki tüm soruları çözdün!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Yeni sorular eklenene kadar havuzu sıfırlayıp '
                        'baştan çözebilirsin. İstatistiklerin korunur.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 26),
                      GestureDetector(
                        onTap: _resetPoolAndStart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 26, vertical: 15),
                          decoration: BoxDecoration(
                            gradient: AppTheme.pinkGradient,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppTheme.accent.withValues(alpha: 0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.restart_alt_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Havuzu Sıfırla & Yeni Test',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Üst bardaki küçük yuvarlak ikon butonu.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

/// Üst bilgi çubuğu: ince ilerleme çizgisi, soru sayacı, skor, profil, müzik.
class _TopBar extends StatelessWidget {
  final double progress;
  final Color accent;
  final String label;
  final int correct;
  final int answered;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onProfile;
  final bool showMusic;
  final bool musicOpen;
  final VoidCallback onMusicTap;

  const _TopBar({
    required this.progress,
    required this.accent,
    required this.label,
    required this.correct,
    required this.answered,
    required this.showBack,
    required this.onBack,
    required this.onProfile,
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
              if (showBack) ...[
                _CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary,
                  onTap: onBack,
                ),
                const SizedBox(width: 10),
              ],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.person_rounded,
                color: AppTheme.accent,
                onTap: onProfile,
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
  final int answered;
  final int wrongCount;
  final bool isRetry;
  final int remaining; // havuzda kalan çözülmemiş soru sayısı
  final VoidCallback onNextTest;
  final VoidCallback onResetPool;
  final VoidCallback onReshuffleRetry;
  final VoidCallback onRetryWrong;
  final VoidCallback onBeatWrong;

  const _SummaryCard({
    required this.correct,
    required this.answered,
    required this.wrongCount,
    required this.isRetry,
    required this.remaining,
    required this.onNextTest,
    required this.onResetPool,
    required this.onReshuffleRetry,
    required this.onRetryWrong,
    required this.onBeatWrong,
  });

  @override
  Widget build(BuildContext context) {
    final pct = answered == 0 ? 0 : (correct / answered * 100).round();
    final (emoji, msg) = answered == 0
        ? ('🤔', 'Hiç soru çözmeden sona geldin!')
        : switch (pct) {
            >= 85 => ('🏆', 'Finali geçtin gitti!'),
            >= 60 => ('💪', 'İyi gidiyorsun, biraz daha tekrar.'),
            >= 40 => ('📚', 'Eksikler var, açıklamaları çalış.'),
            _ => ('🔁', 'Baştan tur atmakta fayda var.'),
          };
    final nextSize =
        remaining < ProgressService.testSize ? remaining : ProgressService.testSize;

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
                Text(
                  isRetry ? 'Tekrar Turu Bitti' : 'Test Tamamlandı',
                  style: const TextStyle(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 20),
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
                if (isRetry)
                  _button(
                    label: 'Tekrar Karıştır',
                    icon: Icons.refresh_rounded,
                    onTap: onReshuffleRetry,
                    primary: true,
                  )
                else if (remaining > 0)
                  _button(
                    label: 'Sıradaki Test ($nextSize soru)',
                    icon: Icons.arrow_forward_rounded,
                    onTap: onNextTest,
                    primary: true,
                  )
                else ...[
                  const Text(
                    '🎉 Havuzdaki tüm soruları çözdün!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _button(
                    label: 'Havuzu Sıfırla & Yeni Test',
                    icon: Icons.restart_alt_rounded,
                    onTap: onResetPool,
                    primary: true,
                  ),
                ],
                if (wrongCount > 0) ...[
                  const SizedBox(height: 12),
                  _button(
                    label: 'Sadece Yanlışları Çöz ($wrongCount)',
                    icon: Icons.error_outline_rounded,
                    onTap: onRetryWrong,
                    primary: false,
                  ),
                  const SizedBox(height: 12),
                  _button(
                    label: 'Yanlış Soruları Döv 🏏 ($wrongCount)',
                    icon: Icons.sports_cricket_rounded,
                    onTap: onBeatWrong,
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
          gradient: primary ? AppTheme.pinkGradient : null,
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
            Icon(icon,
                color: primary ? Colors.white : AppTheme.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.white : AppTheme.textPrimary,
                fontSize: 15.5,
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
