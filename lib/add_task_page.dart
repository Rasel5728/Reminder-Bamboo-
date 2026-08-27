import 'package:flutter/material.dart';
import 'task_model.dart';

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
  

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
