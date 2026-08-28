import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
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

  @HiveField(5)
  int notificationId;

  Task({
    required this.title,
    required this.description,
    required this.dateTime,
    required this.isHighPriority,
    this.isDone = false,
    required this.notificationId,
  });
}