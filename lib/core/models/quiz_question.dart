import 'package:flutter/material.dart';

/// Medeni Usul Hukuku konu başlıkları.
/// Her kategorinin kendi rengi ve kısa etiketi vardır.
enum QuizCategory {
  ispatDeliller(
    'İspat ve Deliller',
    Color(0xFF5B8DEF), // mavi
  ),
  geciciKoruma(
    'Geçici Hukuki Korumalar',
    Color(0xFFF2A33C), // amber
  ),
  kanunYollari(
    'Kanun Yolları',
    Color(0xFF9B7BEA), // mor
  ),
  tarafIslemleri(
    'Davaya Son Veren Taraf İşlemleri',
    Color(0xFF35C2A6), // teal
  ),
  arabuluculuk(
    'Alternatif Uyuşmazlık Çözümleri',
    Color(0xFFE86A92), // gül
  );

  const QuizCategory(this.label, this.color);
  final String label;
  final Color color;
}

/// Tek bir çoktan seçmeli soru.
@immutable
class QuizQuestion {
  final String id;
  final QuizCategory category;
  final String question;
  final List<String> options;
  final int correctIndex;

  /// Cevaplandıktan sonra gösterilen açıklama / gerekçe (madde atfı dahil).
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  }) : assert(correctIndex >= 0);

  String get correctAnswer => options[correctIndex];
}
