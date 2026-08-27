import 'package:flutter/material.dart';
import 'add_task_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),       //Light mode
      darkTheme: ThemeData.dark(),    // Dark mode
      themeMode: ThemeMode.system,    //System mode check dark or light
      home: const AddTaskPage(),
    );
  }
}