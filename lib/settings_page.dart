import 'package:flutter/material.dart';
import 'settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int snoozeMinutes;

  @override
  void initState() {
    super.initState();
    snoozeMinutes = SettingsService.snoozeMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text("Remind Me Later"),
            subtitle: Text("After $snoozeMinutes Minutes"),
            trailing: DropdownButton<int>(
              value: snoozeMinutes,
              items: const [5, 10, 15, 30, 60]
                  .map((m) => DropdownMenuItem(value: m, child: Text("$m min")))
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;
                await SettingsService.setSnoozeMinutes(value);
                setState(() {
                  snoozeMinutes = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}