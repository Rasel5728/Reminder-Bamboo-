import 'package:flutter/material.dart';
import 'add_edit_reminder_page.dart';

// Backwards-compatible wrapper
class AddTaskPage extends StatelessWidget {
  const AddTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AddEditReminderPage();
  }
}
