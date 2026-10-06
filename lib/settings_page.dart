import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'task_model.dart';
import 'settings_service.dart';
import 'notification_service.dart';
import 'app_constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int snoozeMinutes;
  late bool notificationsEnabled;
  late String defaultNotificationMethod;
  late bool soundEnabled;
  late bool vibrationEnabled;
  late String themeModeString;
  late String defaultPriority;
  late String defaultCategory;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    snoozeMinutes = SettingsService.snoozeMinutes;
    notificationsEnabled = SettingsService.notificationsEnabled;
    defaultNotificationMethod = SettingsService.defaultNotificationMethod;
    soundEnabled = SettingsService.soundEnabled;
    vibrationEnabled = SettingsService.vibrationEnabled;
    themeModeString = SettingsService.themeModeString;
    defaultPriority = SettingsService.defaultPriority;
    defaultCategory = SettingsService.defaultCategory;
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    final taskBox = Hive.box<Task>('tasksBox');
    final jsonStr = SettingsService.exportBackupJson(taskBox);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Export Backup (JSON)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Here is your reminders data backup. You can copy it to your clipboard to save or transfer:",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonStr,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text("Copy JSON"),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Backup copied to clipboard!"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Restore Backup (JSON)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Paste the exported JSON text below to restore your reminders:",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '{"app":"TaskBell", ...}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file_rounded, size: 16),
            label: const Text("Restore"),
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isEmpty) return;

              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final taskBox = Hive.box<Task>('tasksBox');
              final count = SettingsService.importBackupJson(taskBox, text);
              if (count > 0) {
                await NotificationService().rescheduleAllActiveReminders(taskBox);
              }
              nav.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    count > 0
                        ? "Successfully restored $count reminders!"
                        : "Invalid backup JSON.",
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All Reminders?"),
        content: const Text(
          "This will permanently delete all stored reminders and cancel any scheduled notifications. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final taskBox = Hive.box<Task>('tasksBox');
              await NotificationService().cancelAllNotifications();
              await SettingsService.clearAllData(taskBox);
              nav.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text("All reminders cleared."),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // --- NOTIFICATIONS SECTION ---
          _buildSectionHeader("Notifications & Alerts", Icons.notifications_active_rounded),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_rounded),
                  title: const Text("Enable Notifications"),
                  subtitle: const Text("Allow TaskBell to alert you for reminders"),
                  value: notificationsEnabled,
                  onChanged: (val) async {
                    await SettingsService.setNotificationsEnabled(val);
                    final taskBox = Hive.box<Task>('tasksBox');
                    if (val) {
                      await NotificationService().rescheduleAllActiveReminders(taskBox);
                    } else {
                      await NotificationService().cancelAllNotifications();
                    }
                    setState(() => notificationsEnabled = val);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text("Default Reminder Method"),
                  subtitle: Text(defaultNotificationMethod),
                  trailing: DropdownButton<String>(
                    value: defaultNotificationMethod,
                    underline: const SizedBox(),
                    items: AppNotificationMethods.all
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) async {
                      if (val == null) return;
                      await SettingsService.setDefaultNotificationMethod(val);
                      setState(() => defaultNotificationMethod = val);
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_rounded),
                  title: const Text("Sound"),
                  subtitle: const Text("Play alert sound for reminders"),
                  value: soundEnabled,
                  onChanged: (val) async {
                    await SettingsService.setSoundEnabled(val);
                    setState(() => soundEnabled = val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration_rounded),
                  title: const Text("Vibration"),
                  subtitle: const Text("Vibrate device on alert"),
                  value: vibrationEnabled,
                  onChanged: (val) async {
                    await SettingsService.setVibrationEnabled(val);
                    setState(() => vibrationEnabled = val);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.snooze_rounded),
                  title: const Text("Default Snooze Duration"),
                  subtitle: Text("Remind me again after $snoozeMinutes minutes"),
                  trailing: DropdownButton<int>(
                    value: snoozeMinutes,
                    underline: const SizedBox(),
                    items: const [5, 10, 15, 30, 60]
                        .map((m) => DropdownMenuItem(value: m, child: Text("$m min")))
                        .toList(),
                    onChanged: (val) async {
                      if (val == null) return;
                      await SettingsService.setSnoozeMinutes(val);
                      setState(() => snoozeMinutes = val);
                    },
                  ),
                ),
              ],
            ),
          ),

          // --- APPEARANCE SECTION ---
          _buildSectionHeader("Appearance & Theme", Icons.palette_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded),
                  title: const Text("Theme Mode"),
                  subtitle: Text(
                    themeModeString == 'dark'
                        ? "Dark Mode"
                        : (themeModeString == 'light' ? "Light Mode" : "System Default"),
                  ),
                  trailing: DropdownButton<String>(
                    value: themeModeString,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'dark', child: Text("Dark")),
                      DropdownMenuItem(value: 'light', child: Text("Light")),
                      DropdownMenuItem(value: 'system', child: Text("System")),
                    ],
                    onChanged: (val) async {
                      if (val == null) return;
                      await SettingsService.setThemeMode(val);
                      setState(() => themeModeString = val);
                    },
                  ),
                ),
              ],
            ),
          ),

          // --- REMINDER DEFAULTS ---
          _buildSectionHeader("Reminder Defaults", Icons.bookmark_added_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_rounded),
                  title: const Text("Default Priority"),
                  subtitle: Text(defaultPriority),
                  trailing: DropdownButton<String>(
                    value: defaultPriority,
                    underline: const SizedBox(),
                    items: AppPriorities.all
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) async {
                      if (val == null) return;
                      await SettingsService.setDefaultPriority(val);
                      setState(() => defaultPriority = val);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_rounded),
                  title: const Text("Default Category"),
                  subtitle: Text(defaultCategory),
                  trailing: DropdownButton<String>(
                    value: defaultCategory,
                    underline: const SizedBox(),
                    items: AppCategories.all
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) async {
                      if (val == null) return;
                      await SettingsService.setDefaultCategory(val);
                      setState(() => defaultCategory = val);
                    },
                  ),
                ),
              ],
            ),
          ),

          // --- DATA MANAGEMENT ---
          _buildSectionHeader("Data Management (Offline)", Icons.storage_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_rounded, color: Color(0xFF60A5FA)),
                  title: const Text("Backup Reminders"),
                  subtitle: const Text("Export your reminders as JSON"),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: _showBackupDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_page_rounded, color: Color(0xFF10B981)),
                  title: const Text("Restore Reminders"),
                  subtitle: const Text("Import reminders from JSON backup"),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: _showRestoreDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                  title: const Text("Clear All Data", style: TextStyle(color: Colors.redAccent)),
                  subtitle: const Text("Delete all reminders and cancel alerts"),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: _showClearConfirmDialog,
                ),
              ],
            ),
          ),

          // --- ABOUT / PERMISSIONS ---
          _buildSectionHeader("Permissions & Alarm Diagnostics", Icons.info_outline_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded, color: Color(0xFF60A5FA)),
                  title: const Text("Notification Permission"),
                  subtitle: const Text("Required for notification banners and alerts"),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final granted = await NotificationService().requestNotificationPermission();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          granted
                              ? "Notification permission is granted!"
                              : "Notification permission denied. Please allow it in settings.",
                        ),
                        action: !granted
                            ? SnackBarAction(
                                label: "Settings",
                                onPressed: () => openAppSettings(),
                              )
                            : null,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alarm_rounded, color: Color(0xFFF59E0B)),
                  title: const Text("Exact Alarm Permission"),
                  subtitle: const Text("Required for exact-minute alarm delivery"),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final granted = await NotificationService().requestExactAlarmPermission();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          granted
                              ? "Exact Alarm permission is granted!"
                              : "Alarm permission is disabled. Please allow alarms in Android Settings.",
                        ),
                        action: !granted
                            ? SnackBarAction(
                                label: "Settings",
                                onPressed: () => openAppSettings(),
                              )
                            : null,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notification_add_rounded, color: Color(0xFF38BDF8)),
                  title: const Text("Send Test Notification"),
                  subtitle: const Text("Shows an immediate reminder notification"),
                  trailing: const Icon(Icons.send_rounded, size: 16),
                  onTap: () async {
                    await NotificationService().showConfirmation("TaskBell: Notifications are working!");
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alarm_on_rounded, color: Color(0xFFEF4444)),
                  title: const Text("Test Alarm (Rings in 5 seconds)"),
                  subtitle: const Text("Schedules an alarm to ring with sound & vibration in 5s"),
                  trailing: const Icon(Icons.play_arrow_rounded, size: 20),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await NotificationService().triggerTestAlarm(seconds: 5);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("Test Alarm scheduled! It will ring in 5 seconds..."),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}