import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  //  INITIALIZE

  Future<void> init() async {
    tz_data.initializeTimeZones(); // timezone

    // time zone Asia or Dhaka

    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // use app icon

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  //  PERMISSION

  Future<void> requestPermission() async {
    await Permission.notification.request();

    // Exact time  alarm schedule  permission (Android 12+)
    await Permission.scheduleExactAlarm.request();
  }

  // SCHEDULE NOTIFICATION
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

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(
        scheduledDateTime,
        tz.local,
      ), // make DateTime to timezone-aware
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // CANCEL NOTIFICATION

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // ডিবাগ - Pending Notification চেক করা
  Future<void> printPendingNotifications() async {
    final List<PendingNotificationRequest> pending = await _notificationsPlugin
        .pendingNotificationRequests();
    print("========== Pending Notifications: ${pending.length} ==========");
    for (var n in pending) {
      print("ID: ${n.id}, Title: ${n.title}, Body: ${n.body}");
    }
    print("================================================");
  }
}
