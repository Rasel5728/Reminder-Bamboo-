import 'package:hive/hive.dart';

part 'task_model.g.dart'; // build_runner autoGenarate

@HiveType(typeId: 0) // typeID
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String description;

  @HiveField(2)
  DateTime dateTime;

  @HiveField(3)
  bool isHighPriority;

  @HiveField(4)
  bool isDone;

  Task({
    required this.title,
    required this.description,
    required this.dateTime,
    required this.isHighPriority,
    this.isDone = false,
  });
}