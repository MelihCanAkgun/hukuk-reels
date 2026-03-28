import 'package:hive/hive.dart';

part 'question.g.dart';

@HiveType(typeId: 1)
class Question extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String noteId;

  @HiveField(2)
  int type = 0; // 0: cloze, 1: multipleChoice

  @HiveField(3)
  late String questionText;

  @HiveField(4)
  late String correctAnswer;

  @HiveField(5)
  List<String> options = [];

  // Spaced Repetition
  @HiveField(6)
  int repetitionLevel = 0;

  @HiveField(7)
  DateTime? nextReviewDate;

  @HiveField(8)
  int correctCount = 0;

  @HiveField(9)
  int wrongCount = 0;

  @HiveField(10)
  DateTime createdAt = DateTime.now();

  @HiveField(11)
  String sourceSnippet = '';

  bool get isCloze => type == 0;
  bool get isMultipleChoice => type == 1;
}
