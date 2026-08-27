import 'package:flutter/material.dart';
import 'task_model.dart';
import 'add_task_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //State
  //Hive add next time
  final List<Task> tasks = [];

  //Navigation
  Future<void> goToAddTaskPage() async {
    final Task? newTask = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskPage()),
    );

    //Click Back buttom,result: newtask null
    if (newTask != null) {
      setState(() {
        tasks.add(newTask);
      });
    }
  }

  //Delete Task
  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
  }

  //Toggle Done
  void toggleDone(int index) {
    setState(() {
      tasks[index].isDone = !tasks[index].isDone;
    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
