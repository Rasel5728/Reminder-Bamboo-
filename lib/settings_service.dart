import 'package:hive_flutter/adapters.dart';

class SettingsService  {
  static const String boxName = 'settingsBox';
  static const String alarmEnableKey = 'alarmEnabled';
  static const String snoozMinutesKey = 'snoozMinutes';

  static Box get _box => Hive.box(boxName);

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static bool get isAlarmEnabled =>
      _box.get(alarmEnableKey, defaultValue: false);

  static Future<void> setAlarmEnabled(bool value) async {
    await _box.put(alarmEnableKey, value);
  }

  static int get snoozeMinutes => _box.get(snoozMinutesKey, defaultValue: 10);

  static Future<void> setSnoozeMinutes(int minutes) async {
    await _box.put(snoozMinutesKey, minutes);
  }
}
