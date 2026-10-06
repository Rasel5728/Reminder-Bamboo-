import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';
import 'settings_service.dart';

const String completeActionId = 'complete_action';
const String snoozeActionId = 'snooze_action';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Hive.isBoxOpen('tasksBox')) {
    await Hive.initFlutter();
  }
  await handleNotificationAction(response);
}

Future<void> handleNotificationAction(NotificationResponse response) async {
  debugPrint("Notification action tapped: ${response.actionId}");

  if (response.actionId != completeActionId &&
      response.actionId != snoozeActionId) {
    return;
  }

  final String? payload = response.payload;
  if (payload == null) {
    debugPrint("Payload null, returning");
    return;
  }

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TaskAdapter());
  }

  final Box<Task> taskBox = Hive.isBoxOpen('tasksBox')
      ? Hive.box<Task>('tasksBox')
      : await Hive.openBox<Task>('tasksBox');

  final int notifId = int.tryParse(payload) ?? -1;
  if (notifId == -1) return;

  final Task? task = taskBox.get(notifId);
  if (task == null) {
    debugPrint("Task not found for id: $notifId");
    return;
  }

  if (response.actionId == completeActionId) {
    task.isDone = true;
    task.updatedAt = DateTime.now();
    await task.save();
    await NotificationService().cancelNotification(task.notificationId);

    // Confirmation - Task Completed
    await NotificationService().showConfirmation("Task Completed: ${task.title}");
    debugPrint("Task marked completed: ${task.title}");
  } else if (response.actionId == snoozeActionId) {
    if (!Hive.isBoxOpen(SettingsService.boxName)) {
      await Hive.openBox(SettingsService.boxName);
    }
    final int minutes = task.snoozeMinutes > 0
        ? task.snoozeMinutes
        : SettingsService.snoozeMinutes;
    final DateTime newTime = DateTime.now().add(Duration(minutes: minutes));

    // Cancel current alert sound
    await NotificationService().cancelNotification(task.notificationId);

    // Reschedule alarm for snooze duration
    await NotificationService().scheduleTaskNotification(
      task,
      overrideDateTime: newTime,
    );

    // Confirmation - Reminder Snoozed
    await NotificationService().showConfirmation(
      "Reminder snoozed for $minutes minutes...",
    );
    debugPrint("Snoozed task ${task.title} for $minutes minutes (until $newTime)");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
      final String currentTimeZone = tzInfo.identifier;
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      debugPrint("Initialized local timezone to $currentTimeZone");
    } catch (e) {
      debugPrint("Could not set local timezone automatically: $e");
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        await handleNotificationAction(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create Notification Channels explicitly for Android
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Clean up previous channel if it had no sound configured
      try {
        await androidImplementation.deleteNotificationChannel('task_alarm_channel_v1');
      } catch (_) {}

      // 1. Standard Reminder Channel (Notification Mode)
      const AndroidNotificationChannel reminderChannel =
          AndroidNotificationChannel(
        'task_reminder_channel_v3',
        'Task Reminders',
        description: 'Standard notifications for task reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // 2. Dedicated Alarm Channel (Alarm Mode & Both Mode)
      // Uses raw resource alarm_sound.wav and AudioAttributesUsage.alarm stream
      final AndroidNotificationChannel alarmChannel =
          AndroidNotificationChannel(
        'task_alarm_channel_v2',
        'Task Alarms',
        description: 'Loud, repeating alarm-style alerts for reminders',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      // 3. Confirmation Channel
      const AndroidNotificationChannel confirmationChannel =
          AndroidNotificationChannel(
        'confirmation_channel',
        'Confirmations',
        description: 'Brief confirmations for completed and snoozed tasks',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );

      await androidImplementation.createNotificationChannel(reminderChannel);
      await androidImplementation.createNotificationChannel(alarmChannel);
      await androidImplementation.createNotificationChannel(confirmationChannel);
    }

    _initialized = true;
  }

  // --- Independent Permission Checks & Requests ---

  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  Future<bool> isExactAlarmPermissionGranted() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? canScheduleExact =
          await androidImplementation?.canScheduleExactNotifications();
      if (canScheduleExact != null) return canScheduleExact;
    } catch (_) {}
    return await Permission.scheduleExactAlarm.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }

  Future<bool> requestPermission() async {
    final notifGranted = await requestNotificationPermission();
    final alarmGranted = await requestExactAlarmPermission();
    return notifGranted && alarmGranted;
  }

  /// High-level method to schedule a reminder Task according to its settings.
  Future<void> scheduleTaskNotification(
    Task task, {
    DateTime? overrideDateTime,
  }) async {
    // 1. Check master switch
    if (!SettingsService.notificationsEnabled) {
      debugPrint("Notifications globally disabled in settings.");
      return;
    }

    // 2. Check task enabled & notification method
    if (!task.isEnabled || task.isDone) {
      debugPrint("Task disabled or completed, skipping schedule.");
      return;
    }

    final method = task.notificationMethod;
    if (method == 'No alert') {
      debugPrint("Task set to 'No alert' / Silent, skipping notification.");
      return;
    }

    final targetDateTime = overrideDateTime ?? task.dateTime;
    final isAlarm = method == 'Alarm' || method == 'Both';

    // 3. Configure Android notification details
    final sound = SettingsService.soundEnabled;
    final vibration = SettingsService.vibrationEnabled;

    final AndroidNotificationDetails androidDetails;
    if (isAlarm) {
      // Real Alarm configuration:
      // Uses task_alarm_channel_v2 with bundled alarm_sound.wav
      // audioAttributesUsage: AudioAttributesUsage.alarm (plays on Android alarm volume stream)
      // additionalFlags: [4] (Notification.FLAG_INSISTENT: loops alarm until completed/snoozed/dismissed)
      // fullScreenIntent: true (wakes screen / heads-up notification)
      androidDetails = AndroidNotificationDetails(
        'task_alarm_channel_v2',
        'Task Alarms',
        channelDescription: 'Loud, repeating alarm-style alerts for reminders',
        importance: Importance.max,
        priority: Priority.max,
        playSound: sound,
        sound: sound ? const RawResourceAndroidNotificationSound('alarm_sound') : null,
        enableVibration: vibration,
        vibrationPattern: vibration
            ? Int64List.fromList([0, 1000, 500, 1000, 500, 1000])
            : null,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT: continuous repeating alarm sound
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            completeActionId,
            'Complete',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            snoozeActionId,
            'Snooze',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      );
    } else {
      // Standard Notification mode
      androidDetails = AndroidNotificationDetails(
        'task_reminder_channel_v3',
        'Task Reminders',
        channelDescription: 'Standard task notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: sound,
        enableVibration: vibration,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            completeActionId,
            'Complete',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            snoozeActionId,
            'Snooze',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      );
    }

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    final bool canScheduleExact = await isExactAlarmPermissionGranted();
    final scheduleMode = canScheduleExact
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final String title = isAlarm ? "⏰ [Alarm] ${task.title}" : task.title;
    final String body = task.description.isNotEmpty
        ? task.description
        : "Reminder for ${task.title}";

    final scheduledTimeFormatted =
        DateFormat('yyyy-MM-dd HH:mm').format(targetDateTime);
    final currentTimeFormatted =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final String localTzName = tz.local.name;

    // Handle repeat patterns
    if (task.repeatType == 'CustomDays' && task.repeatDays.isNotEmpty) {
      if (isAlarm) {
        debugPrint("==================================================");
        debugPrint("Alarm scheduling started (CustomDays)");
        debugPrint("Reminder ID: ${task.id ?? task.notificationId}");
        debugPrint("Alarm time: $scheduledTimeFormatted");
        debugPrint("Alarm ID: ${task.notificationId}");
        debugPrint("Current device time: $currentTimeFormatted");
        debugPrint("Selected reminder time: $scheduledTimeFormatted");
        debugPrint("Timezone: $localTzName");
        debugPrint("Repeat Days: ${task.repeatDays}");
        debugPrint("Schedule mode: $scheduleMode");
        debugPrint("==================================================");
      }

      try {
        for (final int weekday in task.repeatDays) {
          final subId = task.notificationId + (weekday * 100000);
          final tz.TZDateTime scheduledDate = _nextInstanceOfWeekday(
            weekday,
            targetDateTime.hour,
            targetDateTime.minute,
          );

          await _notificationsPlugin.zonedSchedule(
            subId,
            title,
            body,
            scheduledDate,
            details,
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: task.notificationId.toString(),
          );
        }
        if (isAlarm) {
          debugPrint("Alarm successfully scheduled (ID: ${task.notificationId})");
        } else {
          debugPrint("Notification successfully scheduled (ID: ${task.notificationId})");
        }
      } catch (e) {
        debugPrint("Scheduling FAILED with error: $e");
        rethrow;
      }
    } else {
      tz.TZDateTime scheduledDate =
          tz.TZDateTime.from(targetDateTime, tz.local);

      DateTimeComponents? matchComponents;
      if (task.repeatType == 'Daily') {
        matchComponents = DateTimeComponents.time;
        if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
      } else if (task.repeatType == 'Weekly') {
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
          scheduledDate = scheduledDate.add(const Duration(days: 7));
        }
      } else if (task.repeatType == 'Monthly') {
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
      } else {
        // Once - only schedule if in future
        if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
          debugPrint("Scheduled date is in the past for one-time task. Skipping.");
          return;
        }
      }

      final finalTimestampFormatted = scheduledDate.toIso8601String();

      if (isAlarm) {
        debugPrint("==================================================");
        debugPrint("Alarm scheduling started");
        debugPrint("Reminder ID: ${task.id ?? task.notificationId}");
        debugPrint("Alarm time: $scheduledTimeFormatted");
        debugPrint("Alarm ID: ${task.notificationId}");
        debugPrint("Current device time: $currentTimeFormatted");
        debugPrint("Selected reminder time: $scheduledTimeFormatted");
        debugPrint("Timezone: $localTzName");
        debugPrint("Final scheduled timestamp: $finalTimestampFormatted");
        debugPrint("Exact alarm mode: ${canScheduleExact ? 'alarmClock (exact)' : 'inexact'}");
        debugPrint("==================================================");
      } else {
        debugPrint("==================================================");
        debugPrint("Notification scheduling started");
        debugPrint("Reminder ID: ${task.id ?? task.notificationId}");
        debugPrint("Notification time: $scheduledTimeFormatted");
        debugPrint("Notification ID: ${task.notificationId}");
        debugPrint("Current device time: $currentTimeFormatted");
        debugPrint("Selected reminder time: $scheduledTimeFormatted");
        debugPrint("Timezone: $localTzName");
        debugPrint("Final scheduled timestamp: $finalTimestampFormatted");
        debugPrint("==================================================");
      }

      try {
        await _notificationsPlugin.zonedSchedule(
          task.notificationId,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchComponents,
          payload: task.notificationId.toString(),
        );

        if (isAlarm) {
          debugPrint("Alarm successfully scheduled");
        } else {
          debugPrint("Notification successfully scheduled");
        }
      } catch (e) {
        debugPrint("Alarm scheduling FAILED with error: $e");
        rethrow;
      }
    }
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    return scheduledDate;
  }

  /// Triggers a test alarm after [seconds] to immediately verify alarm audio & vibration
  Future<void> triggerTestAlarm({int seconds = 5}) async {
    final testTime = DateTime.now().add(Duration(seconds: seconds));
    final testTask = Task(
      title: "Test Alarm",
      description: "Alarm audio, vibration, and notification test.",
      dateTime: testTime,
      notificationId: 88888,
      notificationMethod: 'Alarm',
      priority: 'High',
    );
    await scheduleTaskNotification(testTask);
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    for (int day = 1; day <= 7; day++) {
      await _notificationsPlugin.cancel(id + (day * 100000));
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> rescheduleAllActiveReminders(Box<Task> taskBox) async {
    debugPrint("Rescheduling all active reminders...");
    for (int i = 0; i < taskBox.length; i++) {
      final task = taskBox.getAt(i);
      if (task != null && task.isEnabled && !task.isDone) {
        try {
          await scheduleTaskNotification(task);
        } catch (e) {
          debugPrint("Failed to reschedule task ${task.title}: $e");
        }
      }
    }
  }

  /// Confirmation Notification with 3 second auto-cancel
  Future<void> showConfirmation(String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'confirmation_channel',
      'Confirmations',
      channelDescription: 'Brief confirmation messages',
      importance: Importance.low,
      priority: Priority.low,
      autoCancel: true,
      timeoutAfter: 3000,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(999999, "TaskBell", message, details);
  }
}
