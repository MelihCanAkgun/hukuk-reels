import 'package:flutter/material.dart';
import '../../../core/services/database_service.dart';

/// ──────────────────────────────────
/// İstatistik Ekranı
///
/// Doğru/yanlış oranları, seri (streak),
/// ve günlük çalışma geçmişini gösterir.
/// ──────────────────────────────────
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _db = DatabaseService.instance;

  @override
  Widget build(BuildContext context) {
    final stats = _db.getStats();
    final dueCount = _db.getDueQuestions().length;
    final totalQuestions = _db.getAllQuestions().length;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('İstatistikler'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Özet Kartları ──
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Toplam Cevap',
                    value: '${stats.totalAnswered}',
                    icon: Icons.quiz_outlined,
                    color: const Color(0xFF2979FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Doğruluk',
                    value: '${stats.accuracy.toStringAsFixed(1)}%',
                    icon: Icons.check_circle_outline,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Mevcut Seri',
                    value: '${stats.currentStreak}',
                    icon: Icons.local_fire_department,
                    color: const Color(0xFFFF6D00),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'En Uzun Seri',
                    value: '${stats.longestStreak}',
                    icon: Icons.emoji_events_outlined,
                    color: Colors.amberAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Tekrar Kuyruğu ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Color(0xFFFF6D00), size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Spaced Repetition',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Toplam Soru', value: '$totalQuestions'),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Bugün Tekrar Edilecek',
                    value: '$dueCount',
                    highlight: dueCount > 0,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Doğru',
                    value: '${stats.totalCorrect}',
                    valueColor: Colors.greenAccent,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Yanlış',
                    value: '${stats.totalWrong}',
                    valueColor: Colors.redAccent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Doğru/Yanlış Çubuk ──
            if (stats.totalAnswered > 0) ...[
              const Text(
                'Doğru / Yanlış Oranı',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      Expanded(
                        flex: stats.totalCorrect.clamp(1, 999999),
                        child: Container(
                          color: Colors.greenAccent.withValues(alpha: 0.7),
                          alignment: Alignment.center,
                          child: Text(
                            '${stats.totalCorrect}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      if (stats.totalWrong > 0)
                        Expanded(
                          flex: stats.totalWrong,
                          child: Container(
                            color: Colors.redAccent.withValues(alpha: 0.7),
                            alignment: Alignment.center,
                            child: Text(
                              '${stats.totalWrong}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Son 7 Gün ──
            if (stats.dailyHistory.isNotEmpty) ...[
              const Text(
                'Son 7 Günlük Aktivite',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: _WeeklyChart(dailyHistory: stats.dailyHistory),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
        ),
        Container(
          padding: highlight
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 2)
              : EdgeInsets.zero,
          decoration: highlight
              ? BoxDecoration(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                )
              : null,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? (highlight ? const Color(0xFFFF6D00) : Colors.white),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Son 7 günün bar chart'ı (fl_chart yerine özel widget)
class _WeeklyChart extends StatelessWidget {
  final Map<String, int> dailyHistory;

  const _WeeklyChart({required this.dailyHistory});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });

    final values = days.map((d) => dailyHistory[d] ?? 0).toList();
    final maxVal = values.fold(0, (a, b) => a > b ? a : b).clamp(1, 999999);

    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      const turkishDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return turkishDays[d.weekday - 1];
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final ratio = values[i] / maxVal;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (values[i] > 0)
                  Text(
                    '${values[i]}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  height: (ratio * 70).clamp(4, 70),
                  decoration: BoxDecoration(
                    color: values[i] > 0
                        ? const Color(0xFFFF6D00).withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dayLabels[i],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
