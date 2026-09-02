import 'package:bamboo/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';
import 'home_page.dart';
import 'notification_service.dart';
import 'settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasksBox');
  await SettingsService.init(); // notun line

  await NotificationService().init();
  await NotificationService().requestPermission();

  runApp(const MyApp());
}

// baki code same thakbe

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,

        // Background
        scaffoldBackgroundColor: const Color(0xFF0B1220),

        // Colors
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF60A5FA),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF162033),
        ),

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1220),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),

        // Card
        cardTheme: CardThemeData(
          color: const Color(0xFF162033),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Floating Action Button
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF60A5FA),
          foregroundColor: Color(0xFF0B1220),
        ),

        // Input Field
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF162033),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
          ),
        ),

        // Elevated Button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF60A5FA),
            foregroundColor: const Color(0xFF0B1220),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        // SnackBar
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF162033),
          contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          
        ),
      ),

      themeMode: ThemeMode.dark,
      // darkTheme: ThemeData(
      //   brightness: .dark,
      //   useMaterial3: true,
      //   colorSchemeSeed: Colors.green,
      // ),
      //themeMode: ThemeMode.dark,

      // //theme: ThemeData.light(),
      // darkTheme: ThemeData.dark(),
      // themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}
