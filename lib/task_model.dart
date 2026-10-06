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

  @HiveField(6)
  String priority; // 'Low', 'Medium', 'High'

  @HiveField(7)
  String category; // 'Study', 'Work', 'Personal', 'Health', 'Finance', 'Other'

  @HiveField(8)
  String notificationMethod; // 'Notification', 'Alarm', 'Both', 'No alert'

  @HiveField(9)
  String repeatType; // 'Once', 'Daily', 'Weekly', 'Monthly', 'CustomDays'

  @HiveField(10)
  List<int> repeatDays; // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun

  @HiveField(11)
  int snoozeMinutes; // 5, 10, 15, 30, 60

  @HiveField(12)
  bool isEnabled;

  @HiveField(13)
  DateTime? createdAt;

  @HiveField(14)
  DateTime? updatedAt;

  @HiveField(15)
  String? id;

  Task({
    required this.title,
    this.description = '',
    required this.dateTime,
    this.isHighPriority = false,
    this.isDone = false,
    required this.notificationId,
    String? priority,
    this.category = 'Other',
    this.notificationMethod = 'Notification',
    this.repeatType = 'Once',
    List<int>? repeatDays,
    this.snoozeMinutes = 10,
    this.isEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.id,
  })  : priority = priority ?? (isHighPriority ? 'High' : 'Medium'),
        repeatDays = repeatDays ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isCompleted => isDone;
  set isCompleted(bool value) {
    isDone = value;
  }

  bool get isOverdue => !isDone && dateTime.isBefore(DateTime.now());

  Task copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isHighPriority,
    bool? isDone,
    int? notificationId,
    String? priority,
    String? category,
    String? notificationMethod,
    String? repeatType,
    List<int>? repeatDays,
    int? snoozeMinutes,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? id,
  }) {
    final effectivePriority = priority ?? this.priority;
    return Task(
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isHighPriority: isHighPriority ?? (effectivePriority == 'High'),
      isDone: isDone ?? this.isDone,
      notificationId: notificationId ?? this.notificationId,
      priority: effectivePriority,
      category: category ?? this.category,
      notificationMethod: notificationMethod ?? this.notificationMethod,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? List<int>.from(this.repeatDays),
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? notificationId.toString(),
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'isHighPriority': isHighPriority,
      'isDone': isDone,
      'notificationId': notificationId,
      'priority': priority,
      'category': category,
      'notificationMethod': notificationMethod,
      'repeatType': repeatType,
      'repeatDays': repeatDays,
      'snoozeMinutes': snoozeMinutes,
      'isEnabled': isEnabled,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final bool highPri = json['isHighPriority'] as bool? ??
        (json['priority'] == 'High');
    return Task(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'] as String)
          : DateTime.now(),
      isHighPriority: highPri,
      isDone: json['isDone'] as bool? ?? (json['isCompleted'] as bool? ?? false),
      notificationId: json['notificationId'] as int? ??
          (DateTime.now().millisecondsSinceEpoch % 100000),
      priority: json['priority'] as String? ?? (highPri ? 'High' : 'Medium'),
      category: json['category'] as String? ?? 'Other',
      notificationMethod: json['notificationMethod'] as String? ?? 'Notification',
      repeatType: json['repeatType'] as String? ?? 'Once',
      repeatDays: json['repeatDays'] != null
          ? List<int>.from(json['repeatDays'] as List)
          : <int>[],
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 10,
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}