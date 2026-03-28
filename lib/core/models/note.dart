import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  DateTime createdAt = DateTime.now();

  @HiveField(4)
  DateTime updatedAt = DateTime.now();

  @HiveField(5)
  bool isFromOcr = false;

  @HiveField(6)
  List<String> tags = [];
}
