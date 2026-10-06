import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';
import 'app_constants.dart';
import 'widgets/reminder_card.dart';
import 'widgets/dashboard_summary.dart';
import 'add_edit_reminder_page.dart';
import 'calendar_page.dart';
import 'statistics_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTabIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Today', 'Upcoming', 'Pending', 'Completed', 'Overdue', 'High Priority', or Category name

  final Box<Task> _taskBox = Hive.box<Task>('tasksBox');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Task> _filterTasks(List<Task> allTasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Task> filtered = allTasks;

    // 1. Search Query Filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q);
      }).toList();
    }

    // 2. Tab Filter
    switch (_selectedFilter) {
      case 'Today':
        filtered = filtered.where((t) {
          final tDate = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
          return _isSameDay(tDate, today) ||
              (t.repeatType == 'Daily') ||
              (t.repeatType == 'Weekly' && t.dateTime.weekday == today.weekday) ||
              (t.repeatType == 'CustomDays' && t.repeatDays.contains(today.weekday));
        }).toList();
        break;
      case 'Upcoming':
        filtered = filtered.where((t) {
          return !t.isDone && t.dateTime.isAfter(now);
        }).toList();
        break;
      case 'Pending':
        filtered = filtered.where((t) => !t.isDone).toList();
        break;
      case 'Completed':
        filtered = filtered.where((t) => t.isDone).toList();
        break;
      case 'Overdue':
        filtered = filtered.where((t) => t.isOverdue).toList();
        break;
      case 'High Priority':
        filtered = filtered.where((t) => t.priority == 'High').toList();
        break;
      case 'All':
        break;
      default:
        // Must be a Category filter
        if (AppCategories.all.contains(_selectedFilter)) {
          filtered = filtered.where((t) => t.category == _selectedFilter).toList();
        }
        break;
    }

    // Sort chronologically (pending first, then by date/time)
    filtered.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      return a.dateTime.compareTo(b.dateTime);
    });

    return filtered;
  }

  void _goToAddReminder({Task? taskToEdit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditReminderPage(taskToEdit: taskToEdit),
      ),
    );
  }

  Widget _buildFilterChip(String label, {IconData? icon, Color? color}) {
    final theme = Theme.of(context);
    final isSelected = _selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        avatar: icon != null
            ? Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (color ?? theme.colorScheme.primary),
              )
            : null,
        label: Text(label),
        selected: isSelected,
        selectedColor: color ?? theme.colorScheme.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : null,
        ),
        backgroundColor: theme.cardColor,
        onSelected: (val) {
          setState(() {
            _selectedFilter = label;
          });
        },
      ),
    );
  }

  Widget _buildRemindersDashboard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: _taskBox.listenable(),
      builder: (context, Box<Task> box, _) {
        final allTasks = box.values.toList();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Calculate Today metrics
        final todayTasks = allTasks.where((t) {
          final tDate = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
          return _isSameDay(tDate, today) ||
              (t.repeatType == 'Daily') ||
              (t.repeatType == 'Weekly' && t.dateTime.weekday == today.weekday) ||
              (t.repeatType == 'CustomDays' && t.repeatDays.contains(today.weekday));
        }).toList();

        final todayTotal = todayTasks.length;
        final todayCompleted = todayTasks.where((t) => t.isDone).length;
        final todayPending = todayTasks.where((t) => !t.isDone).length;
        final todayHighPri = todayTasks.where((t) => t.priority == 'High').length;

        final displayTasks = _filterTasks(allTasks);

        return CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              pinned: false,
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_active_rounded, size: 22, color: Color(0xFF60A5FA)),
                  SizedBox(width: 8),
                  Text("TaskBell", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              centerTitle: true,
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  // Today Summary Dashboard
                  DashboardSummary(
                    totalCount: todayTotal,
                    completedCount: todayCompleted,
                    pendingCount: todayPending,
                    highPriorityCount: todayHighPri,
                  ),
                  const SizedBox(height: 14),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: "Search reminders, notes, or categories...",
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips Scrollable Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', icon: Icons.all_inbox_rounded),
                        _buildFilterChip('Today', icon: Icons.today_rounded),
                        _buildFilterChip('Upcoming', icon: Icons.upcoming_rounded),
                        _buildFilterChip('Pending', icon: Icons.schedule_rounded),
                        _buildFilterChip('Completed', icon: Icons.check_circle_rounded),
                        _buildFilterChip('Overdue', icon: Icons.error_outline_rounded, color: Colors.redAccent),
                        _buildFilterChip('High Priority', icon: Icons.priority_high_rounded, color: Colors.redAccent),
                        ...AppCategories.all.map(
                          (cat) => _buildFilterChip(
                            cat,
                            icon: AppCategories.getIcon(cat),
                            color: AppCategories.getColor(cat),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header of list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedFilter == 'All'
                            ? "All Reminders"
                            : "$_selectedFilter Reminders",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${displayTasks.length} ${displayTasks.length == 1 ? 'item' : 'items'}",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ]),
              ),
            ),

            // Reminders List or Empty State
            if (displayTasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.task_alt_rounded,
                          size: 56,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? "No reminders match \"$_searchQuery\""
                              : (_selectedFilter != 'All'
                                  ? "No $_selectedFilter reminders found"
                                  : "No reminders yet!\nTap the + button below to create one."),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[400],
                            height: 1.4,
                          ),
                        ),
                        if (_selectedFilter == 'All' && _searchQuery.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _goToAddReminder(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text("Create First Reminder"),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = displayTasks[index];
                      return ReminderCard(
                        task: task,
                        onDeleted: () => setState(() {}),
                        onStatusChanged: () => setState(() {}),
                      );
                    },
                    childCount: displayTasks.length,
                  ),
                ),
              ),

            // Bottom space for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildRemindersDashboard(),
      const CalendarPage(),
      const StatisticsPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            selectedIcon: Icon(Icons.checklist_rounded, color: Color(0xFF60A5FA)),
            label: "Reminders",
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF60A5FA)),
            label: "Calendar",
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: Color(0xFF60A5FA)),
            label: "Insights",
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF60A5FA)),
            label: "Settings",
          ),
        ],
      ),
      floatingActionButton: (_currentTabIndex == 0 || _currentTabIndex == 1)
          ? FloatingActionButton(
              onPressed: () => _goToAddReminder(),
              tooltip: "Add Reminder",
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }
}