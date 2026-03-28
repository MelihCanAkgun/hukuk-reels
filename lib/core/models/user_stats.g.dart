// GENERATED — Hive TypeAdapter for UserStats

part of 'user_stats.dart';

class UserStatsAdapter extends TypeAdapter<UserStats> {
  @override
  final int typeId = 2;

  @override
  UserStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserStats()
      ..totalAnswered = fields[0] as int
      ..totalCorrect = fields[1] as int
      ..totalWrong = fields[2] as int
      ..currentStreak = fields[3] as int
      ..longestStreak = fields[4] as int
      ..lastStudyDate = fields[5] as DateTime?
      ..dailyHistory = (fields[6] as Map).cast<String, int>();
  }

  @override
  void write(BinaryWriter writer, UserStats obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.totalAnswered)
      ..writeByte(1)..write(obj.totalCorrect)
      ..writeByte(2)..write(obj.totalWrong)
      ..writeByte(3)..write(obj.currentStreak)
      ..writeByte(4)..write(obj.longestStreak)
      ..writeByte(5)..write(obj.lastStudyDate)
      ..writeByte(6)..write(obj.dailyHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatsAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
