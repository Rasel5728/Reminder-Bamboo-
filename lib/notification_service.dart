import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ================= INITIALIZE =================
  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  // ================= PERMISSION =================
  Future<void> requestPermission() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
    await Permission.systemAlertWindow.request();
  }

  // ================= SCHEDULE NOTIFICATION =================
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_reminder_channel',
          'Task Reminders',
          channelDescription: 'Task এর সময় হলে reminder দেখানোর জন্য',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // exact alarm permission na thakle alarmClock mode exception dey,
    // tokhon inexact mode e fallback kori jate schedule fail na hoy.
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
    );
  }

  // ================= CANCEL NOTIFICATION =================
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
