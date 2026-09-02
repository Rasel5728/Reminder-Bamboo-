import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';
import 'settings_service.dart';

const String completeActionId = 'complete_action';
const String snoozeActionId = 'snooze_action';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  await handleNotificationAction(response);
}

Future<void> handleNotificationAction(NotificationResponse response) async {
  if (response.actionId != completeActionId &&
      response.actionId != snoozeActionId) {
    return;
  }

  final String? payload = response.payload;
  if (payload == null) return;

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TaskAdapter());
  }

  final Box<Task> taskBox = Hive.isBoxOpen('taskBox')
      ? Hive.box<Task>('taskBox')
      : await Hive.openBox<Task>('taskBox');

  final int notifId = int.parse(payload);
  final Task? task = taskBox.get(notifId);
  if (task == null) return;

  if (response.actionId == completeActionId) {
    task.isDone = true;
    await task.save();
    await NotificationService().cancelNotification(task.notificationId);
  } else if (response.actionId == snoozeActionId) {
    if (!Hive.isBoxOpen(SettingsService.boxName)) {
      await Hive.openBox(SettingsService.boxName);
    }
    final int minutes = SettingsService.snoozeMinutes;
    final DateTime newTime = DateTime.now().add(Duration(minutes: minutes));
    await NotificationService().scheduleNotification(
      id: task.notificationId,
      title: "Task Remider",
      body: task.title,
      scheduledDateTime: newTime,
      payload: notifId.toString(),
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
  }

  Future<void> requestPermission() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_reminder_channel',
          'Task Reminder',
          channelDescription: 'Task er smy hole remider',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,

          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              completeActionId,
              'complete',
              showsUserInterface: false,
              cancelNotification: true,
            ),

            AndroidNotificationAction(
              snoozeActionId,
              'Remind Later',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    final bool canScheduleExact = await Permission.scheduleExactAlarm.isGranted;
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      details,
      androidScheduleMode: canScheduleExact
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexactAllowWhileIdle,

      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
