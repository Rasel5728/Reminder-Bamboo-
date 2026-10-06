import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';
import 'app_constants.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final taskBox = Hive.box<Task>('tasksBox');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics & Insights"),
      ),
      body: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<Task> box, _) {
          final tasks = box.values.toList();
          final int total = tasks.length;
          final int completed = tasks.where((t) => t.isDone).length;
          final int pending = tasks.where((t) => !t.isDone && !t.isOverdue).length;
          final int overdue = tasks.where((t) => t.isOverdue).length;

          final double completionRate = total > 0 ? (completed / total) : 0.0;
          final int completionPercent = (completionRate * 100).round();

          // Calculate category distribution
          final Map<String, int> categoryCounts = {};
          for (final cat in AppCategories.all) {
            categoryCounts[cat] = 0;
          }
          for (final t in tasks) {
            categoryCounts[t.category] = (categoryCounts[t.category] ?? 0) + 1;
          }

          // Calculate priority distribution
          final int highCount = tasks.where((t) => t.priority == 'High').length;
          final int medCount = tasks.where((t) => t.priority == 'Medium').length;
          final int lowCount = tasks.where((t) => t.priority == 'Low').length;

          // Weekly Summary (scheduled within 7 days from today)
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final in7Days = today.add(const Duration(days: 7));
          final int thisWeekCount = tasks.where((t) {
            final tDate = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
            return !tDate.isBefore(today) && !tDate.isAfter(in7Days);
          }).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Progress Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Circular indicator
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 76,
                            height: 76,
                            child: CircularProgressIndicator(
                              value: completionRate,
                              strokeWidth: 8,
                              backgroundColor: isDark ? Colors.white12 : Colors.black12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            "$completionPercent%",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Completion Rate",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$completed of $total tasks completed",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "$thisWeekCount due this week",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Status Overview Cards (2x2 Grid)
                Row(
                  children: [
                    _buildStatCard(
                      context,
                      title: "Total Reminders",
                      count: total,
                      icon: Icons.list_alt_rounded,
                      color: const Color(0xFF60A5FA),
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      context,
                      title: "Completed",
                      count: completed,
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      context,
                      title: "Pending",
                      count: pending,
                      icon: Icons.schedule_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      context,
                      title: "Overdue",
                      count: overdue,
                      icon: Icons.warning_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Priority Breakdown
                const Text(
                  "Priority Breakdown",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPriorityItem("High", highCount, AppPriorities.getColor('High')),
                      _buildPriorityItem("Medium", medCount, AppPriorities.getColor('Medium')),
                      _buildPriorityItem("Low", lowCount, AppPriorities.getColor('Low')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Categories Breakdown
                const Text(
                  "Categories Distribution",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: AppCategories.all.map((category) {
                      final count = categoryCounts[category] ?? 0;
                      final ratio = total > 0 ? (count / total) : 0.0;
                      final color = AppCategories.getColor(category);
                      final icon = AppCategories.getIcon(category);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, size: 16, color: color),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 70,
                              child: Text(
                                category,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 8,
                                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "$count",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$count",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          "$count",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppPriorities.getIcon(label), size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
