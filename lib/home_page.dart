import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';
import 'add_task_page.dart';
import 'notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Box<Task> taskBox = Hive.box<Task>('tasksBox');

  Future<void> goToAddTaskPage() async {
    final Task? newTask = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskPage()),
    );

    if (newTask != null) {
      setState(() {
        taskBox.add(newTask);
      });
    }
  }

  void deleteTask(int index) {
    final task = taskBox.getAt(index);
    if (task != null) {
      NotificationService().cancelNotification(task.notificationId);
    }
    setState(() {
      taskBox.deleteAt(index);
    });
  }

  void toggleDone(Task task) {
    setState(() {
      task.isDone = !task.isDone;
      task.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tasks")),

      body: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<Task> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                "Click\n+ Button To Add New Task",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final task = box.getAt(index)!;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Checkbox(
                    value: task.isDone,
                    onChanged: (value) => toggleDone(task),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "${task.description}\n"
                    "${task.dateTime.day}/${task.dateTime.month}/${task.dateTime.year} "
                    "${TimeOfDay.fromDateTime(task.dateTime).format(context)}",
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (task.isHighPriority)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.priority_high, color: Colors.red),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => deleteTask(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: goToAddTaskPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}
