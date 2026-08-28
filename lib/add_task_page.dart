import 'package:flutter/material.dart';
import 'task_model.dart';
import 'notification_service.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isHighPriority = false;

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> saveTask() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Set Title")));
      return;
    }

    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Set Date and Time")));
      return;
    }

    final DateTime finalDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    final Task newTask = Task(
      title: titleController.text,
      description: descriptionController.text,
      dateTime: finalDateTime,
      isHighPriority: isHighPriority,
      notificationId: notificationId,
    );

    if (finalDateTime.isAfter(DateTime.now())) {
      try {
        await NotificationService().scheduleNotification(
          id: notificationId,
          title: "Task Reminder",
          body: newTask.title,
          scheduledDateTime: finalDateTime,
        );
      } catch (e) {
        // Notification schedule fail korle o task save hobe, just reminder set hobe na.
        debugPrint("Notification schedule failed: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Task saved, but reminder could not be scheduled. Check exact alarm permission in Settings.",
              ),
            ),
          );
        }
      }
    }

    if (!mounted) return;

    Navigator.pop(context, newTask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Task")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                selectedDate == null
                    ? "Set Date"
                    : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
              ),
              onTap: pickDate,
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(
                selectedTime == null
                    ? "Set Time"
                    : selectedTime!.format(context),
              ),
              onTap: pickTime,
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("High Priority"),
              value: isHighPriority,
              onChanged: (value) {
                setState(() {
                  isHighPriority = value;
                });
              },
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveTask,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text("Save Task"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
