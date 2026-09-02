import 'package:hive_flutter/adapters.dart';

class SettingsService {
  static const String boxName = 'settingsBox';
  static const String snoozMinutesKey = 'snoozMinutes';

  static Box get _box => Hive.box(boxName);

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static int get snoozeMinutes => _box.get(snoozMinutesKey, defaultValue: 10);

  static Future<void> setSnoozeMinutes(int minutes) async {
    await _box.put(snoozMinutesKey, minutes);
  }
}
