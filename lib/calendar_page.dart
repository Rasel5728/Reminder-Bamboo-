import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';
import 'widgets/reminder_card.dart';
import 'add_edit_reminder_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _taskMatchesDate(Task task, DateTime date) {
    // If one-time
    if (task.repeatType == 'Once') {
      return _isSameDay(task.dateTime, date);
    }
    // If Daily
    if (task.repeatType == 'Daily') {
      final taskStartDay = DateTime(task.dateTime.year, task.dateTime.month, task.dateTime.day);
      return !date.isBefore(taskStartDay);
    }
    // If Weekly
    if (task.repeatType == 'Weekly') {
      final taskStartDay = DateTime(task.dateTime.year, task.dateTime.month, task.dateTime.day);
      return !date.isBefore(taskStartDay) && task.dateTime.weekday == date.weekday;
    }
    // If Monthly
    if (task.repeatType == 'Monthly') {
      final taskStartDay = DateTime(task.dateTime.year, task.dateTime.month, task.dateTime.day);
      return !date.isBefore(taskStartDay) && task.dateTime.day == date.day;
    }
    // If CustomDays
    if (task.repeatType == 'CustomDays') {
      final taskStartDay = DateTime(task.dateTime.year, task.dateTime.month, task.dateTime.day);
      return !date.isBefore(taskStartDay) && task.repeatDays.contains(date.weekday);
    }
    return false;
  }

  List<Task> _getTasksForDate(List<Task> allTasks, DateTime date) {
    final list = allTasks.where((task) => _taskMatchesDate(task, date)).toList();
    list.sort((a, b) {
      final aTime = TimeOfDay.fromDateTime(a.dateTime);
      final bTime = TimeOfDay.fromDateTime(b.dateTime);
      return (aTime.hour * 60 + aTime.minute).compareTo(bTime.hour * 60 + bTime.minute);
    });
    return list;
  }

  bool _dateHasTasks(List<Task> allTasks, DateTime date) {
    return allTasks.any((task) => _taskMatchesDate(task, date));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskBox = Hive.box<Task>('tasksBox');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar View"),
        actions: [
          IconButton(
            tooltip: "Jump to Today",
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _focusedMonth = DateTime(now.year, now.month, 1);
                _selectedDate = DateTime(now.year, now.month, now.day);
              });
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<Task> box, _) {
          final allTasks = box.values.toList();
          final selectedTasks = _getTasksForDate(allTasks, _selectedDate);

          return Column(
            children: [
              // Calendar Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    // Month Navigation Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () {
                            setState(() {
                              _focusedMonth = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month - 1,
                                1,
                              );
                            });
                          },
                        ),
                        Text(
                          DateFormat('MMMM y').format(_focusedMonth),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () {
                            setState(() {
                              _focusedMonth = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month + 1,
                                1,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Weekday Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                          .map(
                            (day) => SizedBox(
                              width: 36,
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),

                    // Calendar Grid
                    _buildMonthGrid(allTasks),
                  ],
                ),
              ),

              // Selected Date Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSameDay(_selectedDate, DateTime.now())
                          ? "Today (${DateFormat('d MMM').format(_selectedDate)})"
                          : DateFormat('EEEE, d MMMM').format(_selectedDate),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${selectedTasks.length} ${selectedTasks.length == 1 ? 'task' : 'tasks'}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Reminders for selected date
              Expanded(
                child: selectedTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available_rounded, size: 48, color: Colors.grey[600]),
                            const SizedBox(height: 12),
                            Text(
                              "No reminders for this day",
                              style: TextStyle(fontSize: 15, color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddEditReminderPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text("Create Reminder"),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        itemCount: selectedTasks.length,
                        itemBuilder: (context, index) {
                          return ReminderCard(task: selectedTasks[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthGrid(List<Task> allTasks) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday; // 1 = Mon

    final List<Widget> dayWidgets = [];

    // Leading empty days
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 36, height: 36));
    }

    final today = DateTime.now();

    for (int day = 1; day <= daysInMonth; day++) {
      final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected = _isSameDay(cellDate, _selectedDate);
      final isCurrentDay = _isSameDay(cellDate, today);
      final hasTasks = _dateHasTasks(allTasks, cellDate);

      dayWidgets.add(
        InkWell(
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isCurrentDay ? theme.colorScheme.primary.withValues(alpha: 0.2) : null),
              borderRadius: BorderRadius.circular(10),
              border: isCurrentDay && !isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 1.2)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  "$day",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected || isCurrentDay ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : null,
                  ),
                ),
                if (hasTasks)
                  Positioned(
                    bottom: 3,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: (MediaQuery.of(context).size.width - 28 - 28 - (36 * 7)) / 6 > 0
          ? (MediaQuery.of(context).size.width - 28 - 28 - (36 * 7)) / 6
          : 6,
      runSpacing: 6,
      children: dayWidgets,
    );
  }
}
