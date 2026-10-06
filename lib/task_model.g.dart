// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final bool isHigh = fields[3] as bool? ?? false;
    return Task(
      title: fields[0] as String? ?? '',
      description: fields[1] as String? ?? '',
      dateTime: fields[2] as DateTime? ?? DateTime.now(),
      isHighPriority: isHigh,
      isDone: fields[4] as bool? ?? false,
      notificationId: fields[5] as int? ?? 0,
      priority: fields[6] as String? ?? (isHigh ? 'High' : 'Medium'),
      category: fields[7] as String? ?? 'Other',
      notificationMethod: fields[8] as String? ?? 'Notification',
      repeatType: fields[9] as String? ?? 'Once',
      repeatDays: (fields[10] as List?)?.cast<int>() ?? <int>[],
      snoozeMinutes: fields[11] as int? ?? 10,
      isEnabled: fields[12] as bool? ?? true,
      createdAt: fields[13] as DateTime?,
      updatedAt: fields[14] as DateTime?,
      id: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.dateTime)
      ..writeByte(3)
      ..write(obj.isHighPriority)
      ..writeByte(4)
      ..write(obj.isDone)
      ..writeByte(5)
      ..write(obj.notificationId)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.notificationMethod)
      ..writeByte(9)
      ..write(obj.repeatType)
      ..writeByte(10)
      ..write(obj.repeatDays)
      ..writeByte(11)
      ..write(obj.snoozeMinutes)
      ..writeByte(12)
      ..write(obj.isEnabled)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
