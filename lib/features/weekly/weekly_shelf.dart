import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/pressable.dart';
import 'weekly_screen.dart';
import 'weekly_store.dart';
import 'weekly_trophies.dart';

/// Profildeki kupa rafı: haftalık meydan okumada kazanılan kupalar rozet
/// olarak. Bağlı değilken (ya da veri henüz gelmediyse) yer kaplamaz.
/// Dokununca meydan okuma ekranı açılır.
class WeeklyTrophyShelf extends StatefulWidget {
  const WeeklyTrophyShelf({super.key});

  @override
  State<WeeklyTrophyShelf> createState() => _WeeklyTrophyShelfState();
}

class _WeeklyTrophyShelfState extends State<WeeklyTrophyShelf> {
  final _store = WeeklyStore.instance;

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _store.changes.addListener(_changed);
    _store.refresh();
  }

  @override
  void dispose() {
    _store.changes.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = _store.data;
    if (d == null) return const SizedBox.shrink();
    final won = d.trophiesOf(d.me);
    final total = d.totals[d.me] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Pressable(
        key: const ValueKey('profile-trophies'),
        semanticLabel: 'Kupalarım',
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const WeeklyScreen())),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Kupalarım',
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                  ),
                  Text(total == 0 ? 'Henüz kupa yok' : '$total tur kazandın',
                      key: const ValueKey('profile-trophy-count'),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted)),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppTheme.textMuted),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, box) {
                const gap = 8.0;
                final n = kWeeklyTrophies.length;
                final size = math.min(56.0, (box.maxWidth - gap * (n - 1)) / n);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < n; i++)
                      TrophyBadge(
                        trophy: kWeeklyTrophies[i],
                        size: size,
                        won: (won[i] ?? 0) > 0,
                        count: won[i] ?? 0,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
