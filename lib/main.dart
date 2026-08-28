import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';
import 'home_page.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------- Hive Setup ----------
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasksBox');

  // ---------- Notification Setup ----------
  await NotificationService().init();
  await NotificationService().requestPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
