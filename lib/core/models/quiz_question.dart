import 'dart:math';
import 'package:flutter/material.dart';

/// Medeni Usul Hukuku konu başlıkları.
/// Her kategorinin kendi rengi ve kısa etiketi vardır.
enum QuizCategory {
  ispatDeliller(
    'İspat ve Deliller',
    Color(0xFFFF8FB6), // pembe
  ),
  geciciKoruma(
    'Geçici Hukuki Korumalar',
    Color(0xFFFFB07A), // şeftali
  ),
  kanunYollari(
    'Kanun Yolları',
    Color(0xFFBFA0F5), // lavanta
  ),
  tarafIslemleri(
    'Davaya Son Veren Taraf İşlemleri',
    Color(0xFFFF9AD5), // magenta-pembe
  ),
  arabuluculuk(
    'Alternatif Uyuşmazlık Çözümleri',
    Color(0xFFFF7388), // gül
  ),
  hukumKesinHuku(
    'Hüküm ve Kesin Hüküm',
    Color(0xFFE49AD2), // orkide
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

  /// Şıkları verilen sırayla dizilmiş bir kopya döndürür; doğru cevabın
  /// yeni konumu otomatik hesaplanır. Kalıcı oturum geri yüklenirken
  /// kaydedilmiş sıra buradan uygulanır.
  QuizQuestion withOptionOrder(List<int> order) {
    assert(order.length == options.length);
    return QuizQuestion(
      id: id,
      category: category,
      question: question,
      options: [for (final i in order) options[i]],
      correctIndex: order.indexOf(correctIndex),
      explanation: explanation,
    );
  }

  /// Şıkları rastgele karıştırılmış bir kopya döndürür. Böylece doğru
  /// cevap her oturumda farklı şıkka denk gelir (A/B/C/D eşit dağılır).
  QuizQuestion withShuffledOptions(Random rng) {
    final order = List<int>.generate(options.length, (i) => i)..shuffle(rng);
    return withOptionOrder(order);
  }
}
