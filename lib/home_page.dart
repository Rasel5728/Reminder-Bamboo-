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

  //UI design
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TASKS")),
      body: tasks.isEmpty
          ? const Center(
              child: Text(
                "No Task Add,Click \n+ Button To Add New Task",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    //checkbox
                    leading: Checkbox(
                      value: task.isDone,
                     onChanged: (value)=>toggleDone(index),
                     ),

                     //Title
                     title: Text(
                      task.title,
                      style: TextStyle(
                        //strikethough
                        decoration: task.isDone?TextDecoration.lineThrough:TextDecoration.none,
                        fontWeight: FontWeight.bold,
                      ),
                     ),

                     //SubTitle
                     subtitle: Text(
                      "${task.description}\n"
                      "${task.dateTime.day}/${task.dateTime.month}/${task.dateTime.year} "
                      "${TimeOfDay.fromDateTime(task.dateTime).format(context)}",
                     ),
                     isThreeLine: true,

                     //Priority Idicator and Delete Button

                     trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        //High Priority indicate red dot
                        if(task.isHighPriority)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.priority_high,color: Colors.red,),
                        ),
                        IconButton(
                          onPressed: ()=> deleteTask(index), 
                          icon: Icon(Icons.delete_outline),
                          ),
                      ],
                     ),


                  ),
                );
              },
            ),

            //Add Button
            floatingActionButton: FloatingActionButton(onPressed: goToAddTaskPage,
            child: const Icon(Icons.add),
            
            ),
    );
  }
}
