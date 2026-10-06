import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../task_model.dart';
import '../app_constants.dart';
import '../notification_service.dart';
import '../add_edit_reminder_page.dart';

class ReminderCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onDeleted;
  final VoidCallback? onStatusChanged;

  const ReminderCard({
    super.key,
    required this.task,
    this.onDeleted,
    this.onStatusChanged,
  });

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDate = DateTime(dt.year, dt.month, dt.day);

    final timeStr = DateFormat('h:mm a').format(dt);

    if (reminderDate == today) {
      return "Today, $timeStr";
    } else if (reminderDate == today.add(const Duration(days: 1))) {
      return "Tomorrow, $timeStr";
    } else if (reminderDate == today.subtract(const Duration(days: 1))) {
      return "Yesterday, $timeStr";
    } else {
      return "${DateFormat('d MMM').format(dt)}, $timeStr";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryColor = AppCategories.getColor(task.category);
    final priorityColor = AppPriorities.getColor(task.priority);

    final isOverdue = task.isOverdue;

    return Dismissible(
      key: ValueKey("task_${task.notificationId}_${task.key}"),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 26),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Reminder?"),
            content: Text("Do you want to delete \"${task.title}\"?"),
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
      },
      onDismissed: (direction) async {
        await NotificationService().cancelNotification(task.notificationId);
        await task.delete();
        onDeleted?.call();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: task.isDone
                ? Colors.transparent
                : (isOverdue
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : (task.priority == 'High'
                        ? priorityColor.withValues(alpha: 0.4)
                        : Colors.transparent)),
            width: 1.2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditReminderPage(taskToEdit: task),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Checkbox, Title, Category Badge, Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Checkbox
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: task.isDone,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        activeColor: theme.colorScheme.primary,
                        onChanged: (val) async {
                          task.isDone = val ?? false;
                          task.updatedAt = DateTime.now();
                          await task.save();
                          if (task.isDone) {
                            await NotificationService().cancelNotification(task.notificationId);
                          } else if (task.isEnabled) {
                            await NotificationService().scheduleTaskNotification(task);
                          }
                          onStatusChanged?.call();
                        },
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: task.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: task.isDone
                                  ? Colors.grey
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              task.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: task.isDone
                                    ? Colors.grey.withValues(alpha: 0.6)
                                    : (isDark ? Colors.white60 : Colors.black54),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Quick Active/Inactive Toggle
                    IconButton(
                      tooltip: task.isEnabled ? "Reminder Active" : "Reminder Paused",
                      icon: Icon(
                        task.isEnabled ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
                        color: task.isEnabled ? theme.colorScheme.primary : Colors.grey,
                        size: 22,
                      ),
                      onPressed: () async {
                        task.isEnabled = !task.isEnabled;
                        task.updatedAt = DateTime.now();
                        await task.save();
                        if (task.isEnabled && !task.isDone) {
                          await NotificationService().scheduleTaskNotification(task);
                        } else {
                          await NotificationService().cancelNotification(task.notificationId);
                        }
                        onStatusChanged?.call();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bottom Row: Date/Time, Badges (Priority, Method, Category, Repeat)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Time chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? Colors.redAccent.withValues(alpha: 0.15)
                            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOverdue ? Icons.error_outline_rounded : Icons.access_time_rounded,
                            size: 13,
                            color: isOverdue ? Colors.redAccent : Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(task.dateTime),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOverdue ? Colors.redAccent : null,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppCategories.getIcon(task.category), size: 12, color: categoryColor),
                          const SizedBox(width: 4),
                          Text(
                            task.category,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: categoryColor),
                          ),
                        ],
                      ),
                    ),

                    // Priority Badge (Text + Icon for accessibility)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppPriorities.getIcon(task.priority), size: 12, color: priorityColor),
                          const SizedBox(width: 4),
                          Text(
                            task.priority,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: priorityColor),
                          ),
                        ],
                      ),
                    ),

                    // Notification Method Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppNotificationMethods.getIcon(task.notificationMethod),
                            size: 12,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.notificationMethod,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    // Repeat Badge if repeating
                    if (task.repeatType != AppRepeatTypes.once)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.repeat_rounded, size: 12, color: theme.colorScheme.secondary),
                            const SizedBox(width: 4),
                            Text(
                              AppRepeatTypes.getLabel(task.repeatType),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
