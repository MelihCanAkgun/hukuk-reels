/// Spaced Repetition kuyruğu için yardımcı model
class ReviewItem {
  final int questionId;
  final DateTime scheduledDate;
  final int level;

  const ReviewItem({
    required this.questionId,
    required this.scheduledDate,
    required this.level,
  });

  /// Seviyeye göre sonraki tekrar günü
  static Duration intervalForLevel(int level) {
    switch (level) {
      case 0: return const Duration(hours: 4);   // Aynı gün
      case 1: return const Duration(days: 1);
      case 2: return const Duration(days: 3);
      case 3: return const Duration(days: 7);
      case 4: return const Duration(days: 21);
      default: return const Duration(days: 30);
    }
  }
}
