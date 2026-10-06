import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';

class SettingsService {
  static const String boxName = 'settingsBox';

  // Keys
  static const String snoozMinutesKey = 'snoozMinutes';
  static const String notificationsEnabledKey = 'notificationsEnabled';
  static const String defaultNotificationMethodKey = 'defaultNotificationMethod';
  static const String soundEnabledKey = 'soundEnabled';
  static const String vibrationEnabledKey = 'vibrationEnabled';
  static const String themeModeKey = 'themeMode';
  static const String defaultPriorityKey = 'defaultPriority';
  static const String defaultCategoryKey = 'defaultCategory';

  static Box get _box => Hive.box(boxName);

  // ValueNotifier for real-time ThemeMode reactivity
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  static Future<void> init() async {
    await Hive.openBox(boxName);
    themeModeNotifier.value = currentThemeMode;
  }

  // --- Snooze Duration ---
  static int get snoozeMinutes =>
      _box.get(snoozMinutesKey, defaultValue: 10) as int;

  static Future<void> setSnoozeMinutes(int minutes) async {
    await _box.put(snoozMinutesKey, minutes);
  }

  // --- Notifications Master Switch ---
  static bool get notificationsEnabled =>
      _box.get(notificationsEnabledKey, defaultValue: true) as bool;

  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _box.put(notificationsEnabledKey, enabled);
  }

  // --- Default Notification Method ---
  // Options: 'Notification', 'Alarm', 'Both', 'No alert'
  static String get defaultNotificationMethod =>
      _box.get(defaultNotificationMethodKey, defaultValue: 'Notification')
          as String;

  static Future<void> setDefaultNotificationMethod(String method) async {
    await _box.put(defaultNotificationMethodKey, method);
  }

  // --- Sound & Vibration ---
  static bool get soundEnabled =>
      _box.get(soundEnabledKey, defaultValue: true) as bool;

  static Future<void> setSoundEnabled(bool enabled) async {
    await _box.put(soundEnabledKey, enabled);
  }

  static bool get vibrationEnabled =>
      _box.get(vibrationEnabledKey, defaultValue: true) as bool;

  static Future<void> setVibrationEnabled(bool enabled) async {
    await _box.put(vibrationEnabledKey, enabled);
  }

  // --- Theme Mode ---
  // Options: 'dark', 'light', 'system'
  static String get themeModeString =>
      _box.get(themeModeKey, defaultValue: 'dark') as String;

  static ThemeMode get currentThemeMode {
    final mode = themeModeString;
    if (mode == 'light') return ThemeMode.light;
    if (mode == 'system') return ThemeMode.system;
    return ThemeMode.dark;
  }

  static Future<void> setThemeMode(String mode) async {
    await _box.put(themeModeKey, mode);
    themeModeNotifier.value = currentThemeMode;
  }

  // --- Default Priority & Category ---
  static String get defaultPriority =>
      _box.get(defaultPriorityKey, defaultValue: 'Medium') as String;

  static Future<void> setDefaultPriority(String priority) async {
    await _box.put(defaultPriorityKey, priority);
  }

  static String get defaultCategory =>
      _box.get(defaultCategoryKey, defaultValue: 'Study') as String;

  static Future<void> setDefaultCategory(String category) async {
    await _box.put(defaultCategoryKey, category);
  }

  // --- Data Backup & Restore (JSON) ---
  static String exportBackupJson(Box<Task> taskBox) {
    final List<Map<String, dynamic>> taskList = [];
    for (int i = 0; i < taskBox.length; i++) {
      final task = taskBox.getAt(i);
      if (task != null) {
        taskList.add(task.toJson());
      }
    }
    return jsonEncode({
      'app': 'TaskBell',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': taskList,
    });
  }

  static int importBackupJson(Box<Task> taskBox, String jsonString) {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic> || !decoded.containsKey('tasks')) {
        return 0;
      }
      final List tasksList = decoded['tasks'] as List;
      int imported = 0;
      for (final item in tasksList) {
        if (item is Map<String, dynamic>) {
          final task = Task.fromJson(item);
          taskBox.put(task.notificationId, task);
          imported++;
        }
      }
      return imported;
    } catch (e) {
      debugPrint("Import error: $e");
      return 0;
    }
  }

  static Future<void> clearAllData(Box<Task> taskBox) async {
    await taskBox.clear();
  }
}
