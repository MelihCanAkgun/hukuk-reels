import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/notes_bridge.dart';
import '../../core/widgets/pixel_logo.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/readable_width.dart';
import '../../core/services/activity_area.dart';

/// Bir ders özeti. İçerik `web/notes/summaries/<id>.js` dosyasındadır;
/// not modu (web/notes/notes.js) onu Flutter'ın üstünde açar.
class SummaryInfo {
  const SummaryInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.topics,
  });

  final String id;
  final String title;
  final String subtitle;
  final int topics;
}

const List<String> _kMonths = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık'
];

/// Son düzenleme etiketi: "bugün", "dün", "3 gün önce", "12 Ekim",
/// başka yıldaysa "12 Ekim 2025". Günler takvime göre sayılır.
String editedLabel(DateTime t, DateTime now) {
  final days = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(t.year, t.month, t.day))
      .inDays;
  if (days <= 0) return 'bugün';
  if (days == 1) return 'dün';
  if (days < 7) return '$days gün önce';
  final d = '${t.day} ${_kMonths[t.month - 1]}';
  return t.year == now.year ? d : '$d ${t.year}';
}

const List<SummaryInfo> kSummaries = [
  SummaryInfo(
    id: 'icra',
    title: 'İcra Hukuku',
    subtitle: 'Genel haciz yolundan icra suçlarına şema özet',
    topics: 19,
  ),
];

/// Özetler listesi. Notlar cihazda (IndexedDB) saklanır; hesaba bağlı değildir.
class SummariesScreen extends StatefulWidget {
  const SummariesScreen({super.key, this.summaries = kSummaries});

  final List<SummaryInfo> summaries;

  @override
  State<SummariesScreen> createState() => _SummariesScreenState();
}

class _SummariesScreenState extends State<SummariesScreen> {
  final Map<String, SummaryNotes> _notes = {};
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _refreshCounts();
  }

  Future<void> _refreshCounts() async {
    for (final s in widget.summaries) {
      final info = await summaryNotes(s.id);
      if (!mounted) return;
      setState(() => _notes[s.id] = info);
    }
  }

  Future<void> _open(SummaryInfo s) async {
    if (_opening) return;
    _opening = true;
    final result = await openSummary(s.id);
    _opening = false;
    if (!mounted) return;
    if (result.startsWith('error:')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.substring(6))));
      return;
    }
    await _refreshCounts();
  }

  @override
  Widget build(BuildContext context) =>
      ActivityAreaScope(area: 'summaries', child: _areaBody(context));

  Widget _areaBody(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Geri',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                    ),
                    const PixelLogo(kLogoLawBook, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Özetler',
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
                  padding: EdgeInsets.fromLTRB(
                      readableGutter(context), 8, readableGutter(context), 28),
                  children: [
                    _hint(),
                    const SizedBox(height: 16),
                    for (final s in widget.summaries) ...[
                      _tile(s),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Yeni dersler ve kategoriler yakında eklenecek.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
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

  Widget _hint() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.edit_note_rounded, color: AppTheme.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notesSupported
                  ? 'iPad\'de Apple Pencil ile özetin üstüne ve kenarlarına '
                      'not alabilirsin. Parmakla kaydır, iki parmakla '
                      'yakınlaştır. Notlar bu cihazda saklanır; menüden '
                      'yedekleyebilirsin.'
                  : 'Özetler ve not alma web uygulamasında çalışır.',
              style: const TextStyle(
                  fontSize: 13, height: 1.4, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(SummaryInfo s) {
    final info = _notes[s.id] ?? const SummaryNotes();
    final n = info.count;
    final edited = info.edited;
    final notes = n == 0
        ? 'henüz not yok'
        : edited == null
            ? '$n not'
            : '$n not · son düzenleme ${editedLabel(edited, DateTime.now())}';
    return Pressable(
      semanticLabel: '${s.title} özetini aç',
      onTap: () => _open(s),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const PixelLogo(kLogoLawBook, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 3),
                  Text(s.subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text(
                    '${s.topics} konu · $notes',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
