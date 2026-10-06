import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';
import 'home_page.dart';
import 'notification_service.dart';
import 'settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TaskAdapter());
  }

  final Box<Task> tasksBox = await Hive.openBox<Task>('tasksBox');
  await SettingsService.init();

  final notifService = NotificationService();
  await notifService.init();
  await notifService.requestPermission();

  // Restore/reschedule active reminders after reboot/startup
  await notifService.rescheduleAllActiveReminders(tasksBox);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService.themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'TaskBell',
          debugShowCheckedModeBanner: false,

          // --- DARK THEME (Original refined) ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF0B1220),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF60A5FA),
              secondary: Color(0xFF38BDF8),
              surface: Color(0xFF162033),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0B1220),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF162033),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF60A5FA),
              foregroundColor: Color(0xFF0B1220),
            ),
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
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60A5FA),
                foregroundColor: const Color(0xFF0B1220),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: Color(0xFF162033),
              contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              elevation: 6,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF0B1220),
              indicatorColor: const Color(0xFF60A5FA).withValues(alpha: 0.2),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF60A5FA));
                }
                return const TextStyle(fontSize: 12, color: Colors.grey);
              }),
            ),
          ),

          // --- LIGHT THEME ---
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              secondary: Color(0xFF0284C7),
              surface: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF8FAFC),
              foregroundColor: Color(0xFF0F172A),
              elevation: 0,
              centerTitle: true,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: Color(0xFF1E293B),
              contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              elevation: 6,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB));
                }
                return const TextStyle(fontSize: 12, color: Colors.grey);
              }),
            ),
          ),

          themeMode: currentThemeMode,
          home: const HomePage(),
        );
      },
    );
  }
}
