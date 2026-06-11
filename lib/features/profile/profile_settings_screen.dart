import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/data/questions_data.dart';
import '../../core/models/quiz_question.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/progress_service.dart';
import '../intro/confidence_gate_screen.dart';

/// Profil (doğru/yanlış istatistikleri) + Ayarlar (sıfırlama) ekranı.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _progress = ProgressService.instance;

  @override
  Widget build(BuildContext context) {
    final stats = _progress.stats;
    final byId = {for (final q in kQuestions) q.id: q};

    final answered = <(QuizQuestion, QuestionStat)>[
      for (final e in stats.entries)
        if (byId.containsKey(e.key)) (byId[e.key]!, e.value),
    ];
    final wrongOnes = answered.where((t) => t.$2.wrong > 0).toList()
      ..sort((a, b) => b.$2.wrong.compareTo(a.$2.wrong));
    final rightOnes = answered
        .where((t) => t.$2.wrong == 0 && t.$2.correct > 0)
        .toList()
      ..sort((a, b) => b.$2.correct.compareTo(a.$2.correct));

    final totC = answered.fold(0, (s, t) => s + t.$2.correct);
    final totW = answered.fold(0, (s, t) => s + t.$2.wrong);
    final totA = totC + totW;
    final pct = totA == 0 ? 0 : (totC / totA * 100).round();

    final solved = _progress.solvedIds;
    final solvedInPool =
        kQuestions.where((q) => solved.contains(q.id)).length;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Üst bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                    ),
                    const Text('👤', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    const Text(
                      'Profil & Ayarlar',
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  children: [
                    _successCard(pct, totC, totW, totA),
                    const SizedBox(height: 12),
                    _poolCard(solvedInPool),
                    const SizedBox(height: 22),
                    _sectionHeader('❌  Yanlış Yaptıkların', wrongOnes.length,
                        AppTheme.danger),
                    const SizedBox(height: 10),
                    if (wrongOnes.isEmpty)
                      _emptyNote('Henüz yanlışın yok. Devam! 🎉')
                    else
                      ...wrongOnes.map((t) => _questionTile(t.$1, t.$2)),
                    const SizedBox(height: 22),
                    _sectionHeader('✅  Doğru Yaptıkların', rightOnes.length,
                        AppTheme.success),
                    const SizedBox(height: 10),
                    if (rightOnes.isEmpty)
                      _emptyNote('Henüz hatasız çözülmüş soru yok.')
                    else
                      ...rightOnes.map((t) => _questionTile(t.$1, t.$2)),
                    const SizedBox(height: 26),
                    _sectionHeader('⚙️  Ayarlar', null, AppTheme.accent),
                    const SizedBox(height: 10),
                    _settingTile(
                      icon: Icons.restart_alt_rounded,
                      color: AppTheme.accent,
                      title: 'Soru havuzunu sıfırla',
                      subtitle:
                          'Çözülmüşlük işaretleri temizlenir, istatistikler '
                          'kalır. Mevcut test kapanır ve yeni test başlar.',
                      onTap: _onResetPool,
                    ),
                    const SizedBox(height: 10),
                    _settingTile(
                      icon: Icons.delete_forever_rounded,
                      color: AppTheme.danger,
                      title: 'Her şeyi sıfırla',
                      subtitle:
                          'Tüm ilerleme, istatistik ve test silinir; '
                          'uygulama en başa döner.',
                      onTap: _onResetAll,
                    ),
                    const SizedBox(height: 26),
                    const Center(
                      child: Text(
                        'Sendeyiz Arifecim 🫂',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
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

  // ───────────────────────── Aksiyonlar ─────────────────────────

  Future<void> _onResetPool() async {
    final ok = await _confirm(
      icon: Icons.restart_alt_rounded,
      color: AppTheme.accent,
      title: 'Soru havuzu sıfırlansın mı?',
      message:
          'Tüm sorular yeniden "çözülmemiş" sayılır ve yeni bir test başlar. '
          'İstatistiklerin (doğru/yanlış geçmişin) silinmez.',
      confirmLabel: 'Sıfırla',
    );
    if (!ok || !mounted) return;
    await _progress.resetPool();
    await _progress.clearSession();
    if (!mounted) return;
    Navigator.of(context).pop('poolReset');
  }

  Future<void> _onResetAll() async {
    final ok = await _confirm(
      icon: Icons.delete_forever_rounded,
      color: AppTheme.danger,
      title: 'Her şey sıfırlansın mı?',
      message:
          'Tüm ilerleme, istatistikler ve mevcut test kalıcı olarak silinir. '
          'Bu işlem geri alınamaz.',
      confirmLabel: 'Evet, sıfırla',
    );
    if (!ok || !mounted) return;
    await _progress.resetAll();
    await AudioService.instance.pauseForLifecycle();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ConfidenceGateScreen()),
      (route) => false,
    );
  }

  Future<bool> _confirm({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.bgElevated,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 42),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Text(
                          'Vazgeç',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return res ?? false;
  }

  // ───────────────────────── Parçalar ─────────────────────────

  Widget _successCard(int pct, int totC, int totW, int totA) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface, AppTheme.bgElevated],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Yüzde halkası
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: totA == 0 ? 0 : pct / 100,
                  strokeWidth: 7,
                  backgroundColor: AppTheme.border.withValues(alpha: 0.5),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                ),
                Center(
                  child: Text(
                    '%$pct',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Başarı Oranın',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _statRow(Icons.check_circle_rounded, AppTheme.success,
                    '$totC doğru cevap'),
                const SizedBox(height: 6),
                _statRow(Icons.cancel_rounded, AppTheme.danger,
                    '$totW yanlış cevap'),
                const SizedBox(height: 6),
                _statRow(Icons.functions_rounded, AppTheme.textMuted,
                    'toplam $totA cevap'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, Color color, String text) => Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  Widget _poolCard(int solvedInPool) {
    final pool = _progress.poolSize;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded,
                  color: AppTheme.accent, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Soru Havuzu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$solvedInPool / $pool çözüldü',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pool == 0 ? 0 : solvedInPool / pool,
              minHeight: 6,
              backgroundColor: AppTheme.border.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Çözdüğün sorular sonraki testlerde tekrar karşına çıkmaz.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int? count, Color color) => Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      );

  Widget _emptyNote(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppTheme.textSecondary,
          ),
        ),
      );

  Widget _questionTile(QuizQuestion q, QuestionStat st) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: q.category.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              q.question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (st.wrong > 0) _countChip('✗${st.wrong}', AppTheme.danger),
          if (st.wrong > 0 && st.correct > 0) const SizedBox(width: 5),
          if (st.correct > 0) _countChip('✓${st.correct}', AppTheme.success),
        ],
      ),
    );
  }

  Widget _countChip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      );

  Widget _settingTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
