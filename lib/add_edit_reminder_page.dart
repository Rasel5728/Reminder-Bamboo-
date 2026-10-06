import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'task_model.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'app_constants.dart';

class AddEditReminderPage extends StatefulWidget {
  final Task? taskToEdit;

  const AddEditReminderPage({super.key, this.taskToEdit});

  @override
  State<AddEditReminderPage> createState() => _AddEditReminderPageState();
}

class _AddEditReminderPageState extends State<AddEditReminderPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  late String selectedPriority;
  late String selectedCategory;
  late String selectedNotificationMethod;
  late String selectedRepeatType;
  late List<int> selectedRepeatDays;
  late int selectedSnoozeMinutes;
  bool isEnabled = true;

  bool get isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    if (task != null) {
      titleController.text = task.title;
      descriptionController.text = task.description;
      selectedDate = DateTime(task.dateTime.year, task.dateTime.month, task.dateTime.day);
      selectedTime = TimeOfDay(hour: task.dateTime.hour, minute: task.dateTime.minute);
      selectedPriority = task.priority;
      selectedCategory = task.category;
      selectedNotificationMethod = task.notificationMethod;
      selectedRepeatType = task.repeatType;
      selectedRepeatDays = List<int>.from(task.repeatDays);
      selectedSnoozeMinutes = task.snoozeMinutes;
      isEnabled = task.isEnabled;
    } else {
      selectedDate = DateTime.now();
      // Default to 1 hour from now
      final now = DateTime.now().add(const Duration(hours: 1));
      selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      selectedPriority = SettingsService.defaultPriority;
      selectedCategory = SettingsService.defaultCategory;
      selectedNotificationMethod = SettingsService.defaultNotificationMethod;
      selectedRepeatType = AppRepeatTypes.once;
      selectedRepeatDays = [];
      selectedSnoozeMinutes = SettingsService.snoozeMinutes;
      isEnabled = true;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
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
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "Passed";
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;

    final List<String> parts = [];
    if (days > 0) parts.add("$days days");
    if (hours > 0) parts.add("$hours hours");
    if (minutes > 0) parts.add("$minutes minutes");

    if (parts.isEmpty) return "less than a minute";
    return parts.join(" ");
  }

  Future<void> saveReminder() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a reminder title", textAlign: TextAlign.center),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please set both date and time", textAlign: TextAlign.center),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final DateTime finalDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (selectedRepeatType == AppRepeatTypes.customDays && selectedRepeatDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one day for custom repeat",
              textAlign: TextAlign.center),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Verify Alarm Permission if Alarm or Both is selected
    final isAlarmSelected = selectedNotificationMethod == AppNotificationMethods.alarm ||
        selectedNotificationMethod == AppNotificationMethods.both;

    if (isAlarmSelected) {
      final hasAlarmPerm = await NotificationService().isExactAlarmPermissionGranted();
      if (!hasAlarmPerm) {
        final requested = await NotificationService().requestExactAlarmPermission();
        if (!requested && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Alarm permission is disabled. Please allow alarms in Android Settings.",
              ),
              action: SnackBarAction(
                label: "Settings",
                onPressed: () => openAppSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }

    // Verify Notification Permission if Notification or Both is selected
    final isNotifSelected = selectedNotificationMethod == AppNotificationMethods.notification ||
        selectedNotificationMethod == AppNotificationMethods.both;

    if (isNotifSelected) {
      final hasNotifPerm = await NotificationService().isNotificationPermissionGranted();
      if (!hasNotifPerm) {
        await NotificationService().requestNotificationPermission();
      }
    }

    final int notifId = isEditing
        ? widget.taskToEdit!.notificationId
        : (DateTime.now().millisecondsSinceEpoch % 100000);

    final Task task = isEditing
        ? widget.taskToEdit!.copyWith(
            title: title,
            description: descriptionController.text.trim(),
            dateTime: finalDateTime,
            priority: selectedPriority,
            category: selectedCategory,
            notificationMethod: selectedNotificationMethod,
            repeatType: selectedRepeatType,
            repeatDays: selectedRepeatDays,
            snoozeMinutes: selectedSnoozeMinutes,
            isEnabled: isEnabled,
            updatedAt: DateTime.now(),
          )
        : Task(
            title: title,
            description: descriptionController.text.trim(),
            dateTime: finalDateTime,
            priority: selectedPriority,
            category: selectedCategory,
            notificationMethod: selectedNotificationMethod,
            repeatType: selectedRepeatType,
            repeatDays: selectedRepeatDays,
            snoozeMinutes: selectedSnoozeMinutes,
            isEnabled: isEnabled,
            notificationId: notifId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

    final taskBox = Hive.box<Task>('tasksBox');

    // If editing, cancel previous scheduled notification first
    if (isEditing) {
      await NotificationService().cancelNotification(task.notificationId);
    }

    // Save in Hive
    await taskBox.put(task.notificationId, task);

    // Schedule notification/alarm if enabled and not silent
    if (task.isEnabled && !task.isDone && task.notificationMethod != AppNotificationMethods.noAlert) {
      final willRemind = task.repeatType != AppRepeatTypes.once ||
          finalDateTime.isAfter(DateTime.now());

      if (willRemind) {
        try {
          await NotificationService().scheduleTaskNotification(task);
        } catch (e) {
          debugPrint("Failed to schedule notification: $e");
        }
      }
    } else {
      await NotificationService().cancelNotification(task.notificationId);
    }

    if (!mounted) return;

    final String message;
    if (task.notificationMethod == AppNotificationMethods.noAlert) {
      message = "Reminder saved (Silent / No Alert)";
    } else if (task.repeatType != AppRepeatTypes.once) {
      message = "Repeating reminder scheduled (${AppRepeatTypes.getLabel(task.repeatType)})";
    } else if (finalDateTime.isAfter(DateTime.now())) {
      final diff = finalDateTime.difference(DateTime.now());
      message = "Reminder set for ${_formatDuration(diff)} from now";
    } else {
      message = "Reminder saved";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Reminder" : "New Reminder"),
        actions: [
          if (isEditing)
            IconButton(
              tooltip: "Delete Reminder",
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () async {
                final nav = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Delete Reminder?"),
                    content: Text("Are you sure you want to delete \"${widget.taskToEdit!.title}\"?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await NotificationService().cancelNotification(widget.taskToEdit!.notificationId);
                  await widget.taskToEdit!.delete();
                  nav.pop();
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Input
            TextField(
              controller: titleController,
              autofocus: !isEditing,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: "Title *",
                hintText: "e.g. Study DSA, Team Meeting",
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 14),

            // Description Input
            TextField(
              controller: descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Description",
                hintText: "Add notes, checklist, or details...",
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 20),

            // Date & Time Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Date", style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                const SizedBox(height: 2),
                                Text(
                                  selectedDate == null
                                      ? "Set Date"
                                      : DateFormat('d MMM y').format(selectedDate!),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: pickTime,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Time", style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                const SizedBox(height: 2),
                                Text(
                                  selectedTime == null
                                      ? "Set Time"
                                      : selectedTime!.format(context),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Priority Section
            const Text(
              "Priority",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.3),
            ),
            const SizedBox(height: 10),
            Row(
              children: AppPriorities.all.map((priority) {
                final isSelected = selectedPriority == priority;
                final color = AppPriorities.getColor(priority);
                final icon = AppPriorities.getIcon(priority);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => selectedPriority = priority),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.2)
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: isSelected ? color : Colors.grey, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              priority,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? color : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // Category Section
            const Text(
              "Category",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.3),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppCategories.all.map((category) {
                final isSelected = selectedCategory == category;
                final catColor = AppCategories.getColor(category);
                final catIcon = AppCategories.getIcon(category);

                return ChoiceChip(
                  avatar: Icon(
                    catIcon,
                    size: 16,
                    color: isSelected ? Colors.white : catColor,
                  ),
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: catColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: theme.cardColor,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => selectedCategory = category);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // How should we remind you? (Notification Method Freedom)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "How should we remind you?",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...AppNotificationMethods.all.map((method) {
                    final isSelected = selectedNotificationMethod == method;
                    final icon = AppNotificationMethods.getIcon(method);
                    final subtitle = AppNotificationMethods.getSubtitle(method);

                    return InkWell(
                      onTap: () => setState(() => selectedNotificationMethod = method),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(left: 6, right: 10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? theme.colorScheme.primary : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            Icon(icon, size: 20, color: isSelected ? theme.colorScheme.primary : Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    method,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? theme.colorScheme.primary : null,
                                    ),
                                  ),
                                  Text(
                                    subtitle,
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Repeat Options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.repeat_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Repeat",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      DropdownButton<String>(
                        value: selectedRepeatType,
                        underline: const SizedBox(),
                        items: AppRepeatTypes.all.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(AppRepeatTypes.getLabel(type)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedRepeatType = val);
                          }
                        },
                      ),
                    ],
                  ),
                  if (selectedRepeatType == AppRepeatTypes.customDays) ...[
                    const Divider(height: 20),
                    const Text(
                      "Select days of the week:",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: AppRepeatTypes.weekdayNames.entries.map((entry) {
                        final dayNum = entry.key;
                        final dayName = entry.value;
                        final isChosen = selectedRepeatDays.contains(dayNum);

                        return ChoiceChip(
                          label: Text(dayName),
                          selected: isChosen,
                          onSelected: (chosen) {
                            setState(() {
                              if (chosen) {
                                selectedRepeatDays.add(dayNum);
                                selectedRepeatDays.sort();
                              } else {
                                selectedRepeatDays.remove(dayNum);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Snooze Duration
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.snooze_rounded, size: 20),
                      SizedBox(width: 8),
                      Text("Snooze Duration", style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  DropdownButton<int>(
                    value: selectedSnoozeMinutes,
                    underline: const SizedBox(),
                    items: const [5, 10, 15, 30, 60].map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text("$m min"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedSnoozeMinutes = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Enabled Switch (if editing)
            if (isEditing)
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: const Text("Reminder Enabled", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(isEnabled ? "Active" : "Paused / Inactive"),
                  value: isEnabled,
                  onChanged: (val) => setState(() => isEnabled = val),
                ),
              ),
            const SizedBox(height: 28),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: saveReminder,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(
                  isEditing ? "Update Reminder" : "Save Reminder",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
