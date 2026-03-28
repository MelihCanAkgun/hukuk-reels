// GENERATED — Hive TypeAdapter for Question

part of 'question.dart';

class QuestionAdapter extends TypeAdapter<Question> {
  @override
  final int typeId = 1;

  @override
  Question read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Question()
      ..id = fields[0] as String
      ..noteId = fields[1] as String
      ..type = fields[2] as int
      ..questionText = fields[3] as String
      ..correctAnswer = fields[4] as String
      ..options = (fields[5] as List).cast<String>()
      ..repetitionLevel = fields[6] as int
      ..nextReviewDate = fields[7] as DateTime?
      ..correctCount = fields[8] as int
      ..wrongCount = fields[9] as int
      ..createdAt = fields[10] as DateTime
      ..sourceSnippet = fields[11] as String;
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.noteId)
      ..writeByte(2)..write(obj.type)
      ..writeByte(3)..write(obj.questionText)
      ..writeByte(4)..write(obj.correctAnswer)
      ..writeByte(5)..write(obj.options)
      ..writeByte(6)..write(obj.repetitionLevel)
      ..writeByte(7)..write(obj.nextReviewDate)
      ..writeByte(8)..write(obj.correctCount)
      ..writeByte(9)..write(obj.wrongCount)
      ..writeByte(10)..write(obj.createdAt)
      ..writeByte(11)..write(obj.sourceSnippet);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
