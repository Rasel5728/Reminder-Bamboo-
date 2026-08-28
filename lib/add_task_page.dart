import 'package:flutter/material.dart';
import 'task_model.dart';
import 'notification_service.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  // TextDield controller
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  //State Variavles
  DateTime? selectedDate;
  TimeOfDay? SelectedTime;
  bool isHighPriority = false;

  //Date picker
  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    //null check
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  //Time Picker
  Future<void> pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    //null check
    if (picked != null) {
      setState(() {
        SelectedTime = picked;
      });
    }
  }

  //Save Task

  void saveTask() async {
    //check fill TextField
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Set Titile")));
      return;
    }

    if (selectedDate == null || SelectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Set Date and Time")));
      return;
    }

    //togather date and time
    final DateTime finalDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      SelectedTime!.hour,
      SelectedTime!.minute,
    );

    //notificationId
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    //New Task Object
    final Task newTask = Task(
      title: titleController.text,
      description: descriptionController.text,
      dateTime: finalDateTime,
      isHighPriority: isHighPriority,
      notificationId: notificationId,
    );

    //notifiaction Schedule
    if (finalDateTime.isAfter(DateTime.now())) {
      await NotificationService().scheduleNotification(
        id: notificationId,
        title: "Task Reminder",
        body: newTask.title,
        scheduledDateTime: finalDateTime,
      );
      await NotificationService().printPendingNotifications();
    }

    if (!mounted) return;

    //Hive code part
    Navigator.pop(context, newTask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Task")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Title Field
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            //Description Field
            TextField(
              controller: descriptionController,
              maxLines: 3, //Maximum 3 line write
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            //Date Picker Button
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

            //Time picker Button
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(
                SelectedTime == null
                    ? "Set Time"
                    : SelectedTime!.format(context),
              ),
              onTap: pickTime,
            ),

            const SizedBox(height: 16),

            //Priority Toggle
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
