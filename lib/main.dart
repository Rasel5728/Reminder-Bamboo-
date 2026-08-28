import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';
import 'home_page.dart';
import 'notification_service.dart';

void main() async {
  //Hive Setup
  WidgetsFlutterBinding.ensureInitialized(); 
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter()); 
  await Hive.openBox<Task>('tasksBox');

  //notification setup
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