import 'package:hive/hive.dart';

part 'user_stats.g.dart';

@HiveType(typeId: 2)
class UserStats extends HiveObject {
  @HiveField(0)
  int totalAnswered = 0;

  @HiveField(1)
  int totalCorrect = 0;

  @HiveField(2)
  int totalWrong = 0;

  @HiveField(3)
  int currentStreak = 0;

  @HiveField(4)
  int longestStreak = 0;

  @HiveField(5)
  DateTime? lastStudyDate;

  /// Günlük çalışma geçmişi: {"2026-03-28": 15, ...} (gün başına cevap)
  @HiveField(6)
  Map<String, int> dailyHistory = {};

  double get accuracy =>
      totalAnswered > 0 ? (totalCorrect / totalAnswered) * 100 : 0;
}
