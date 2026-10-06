import 'package:flutter/material.dart';

class DashboardSummary extends StatelessWidget {
  final int totalCount;
  final int completedCount;
  final int pendingCount;
  final int highPriorityCount;

  const DashboardSummary({
    super.key,
    required this.totalCount,
    required this.completedCount,
    required this.pendingCount,
    required this.highPriorityCount,
  });

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "$count",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSummaryCard(
              context,
              title: "Today",
              count: totalCount,
              icon: Icons.calendar_today_rounded,
              color: const Color(0xFF60A5FA),
            ),
            const SizedBox(width: 8),
            _buildSummaryCard(
              context,
              title: "Completed",
              count: completedCount,
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(width: 8),
            _buildSummaryCard(
              context,
              title: "Pending",
              count: pendingCount,
              icon: Icons.schedule_rounded,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 8),
            _buildSummaryCard(
              context,
              title: "High Pri",
              count: highPriorityCount,
              icon: Icons.priority_high_rounded,
              color: const Color(0xFFEF4444),
            ),
          ],
        ),
      ],
    );
  }
}
