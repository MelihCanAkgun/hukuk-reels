import '../models/review_item.dart';

/// ─────────────────────────────────────────────────────
/// Aralıklı Tekrar (Spaced Repetition) Servisi
///
/// Basitleştirilmiş Leitner sistemi:
///   Doğru → seviye +1 (daha uzun aralık)
///   Yanlış → seviye 0'a dön (aynı gün tekrar)
/// ─────────────────────────────────────────────────────
class SpacedRepetitionService {
  /// Doğru cevapta sonraki tekrar zamanını hesaplar
  static DateTime onCorrect(int currentLevel) {
    final nextLevel = (currentLevel + 1).clamp(0, 5);
    final interval = ReviewItem.intervalForLevel(nextLevel);
    return DateTime.now().add(interval);
  }

  /// Yanlış cevapta tekrar sıfırlanır
  static DateTime onWrong() {
    return DateTime.now().add(ReviewItem.intervalForLevel(0));
  }

  /// Bugün tekrar edilmesi gereken soruları filtreler
  static List<int> getDueQuestionIds(List<ReviewItem> allItems) {
    final now = DateTime.now();
    return allItems
        .where((item) => item.scheduledDate.isBefore(now))
        .map((item) => item.questionId)
        .toList();
  }
}
