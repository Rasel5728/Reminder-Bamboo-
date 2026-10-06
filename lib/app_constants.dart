import 'package:flutter/material.dart';

class AppCategories {
  static const List<String> all = [
    'Study',
    'Work',
    'Personal',
    'Health',
    'Finance',
    'Other',
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case 'Study':
        return Icons.school_rounded;
      case 'Work':
        return Icons.work_rounded;
      case 'Personal':
        return Icons.person_rounded;
      case 'Health':
        return Icons.favorite_rounded;
      case 'Finance':
        return Icons.account_balance_wallet_rounded;
      case 'Other':
      default:
        return Icons.bookmark_rounded;
    }
  }

  static Color getColor(String category) {
    switch (category) {
      case 'Study':
        return const Color(0xFF6366F1); // Indigo
      case 'Work':
        return const Color(0xFF0EA5E9); // Sky
      case 'Personal':
        return const Color(0xFF10B981); // Emerald
      case 'Health':
        return const Color(0xFFF43F5E); // Rose
      case 'Finance':
        return const Color(0xFFF59E0B); // Amber
      case 'Other':
      default:
        return const Color(0xFF8B5CF6); // Violet
    }
  }
}

class AppPriorities {
  static const List<String> all = ['Low', 'Medium', 'High'];

  static Color getColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFEF4444); // Red
      case 'Medium':
        return const Color(0xFFF59E0B); // Amber
      case 'Low':
      default:
        return const Color(0xFF10B981); // Green
    }
  }

  static IconData getIcon(String priority) {
    switch (priority) {
      case 'High':
        return Icons.priority_high_rounded;
      case 'Medium':
        return Icons.remove_rounded;
      case 'Low':
      default:
        return Icons.arrow_downward_rounded;
    }
  }
}

class AppNotificationMethods {
  static const String notification = 'Notification';
  static const String alarm = 'Alarm';
  static const String both = 'Both';
  static const String noAlert = 'No alert';

  static const List<String> all = [notification, alarm, both, noAlert];

  static IconData getIcon(String method) {
    switch (method) {
      case alarm:
        return Icons.alarm_rounded;
      case both:
        return Icons.notifications_active_rounded;
      case noAlert:
        return Icons.notifications_off_rounded;
      case notification:
      default:
        return Icons.notifications_rounded;
    }
  }

  static String getSubtitle(String method) {
    switch (method) {
      case alarm:
        return 'Loud and noticeable alarm alert';
      case both:
        return 'Standard notification plus alarm sound';
      case noAlert:
        return 'Silent, in-app reminder only';
      case notification:
      default:
        return 'Standard heads-up notification';
    }
  }
}

class AppRepeatTypes {
  static const String once = 'Once';
  static const String daily = 'Daily';
  static const String weekly = 'Weekly';
  static const String monthly = 'Monthly';
  static const String customDays = 'CustomDays';

  static const List<String> all = [once, daily, weekly, monthly, customDays];

  static String getLabel(String repeatType) {
    switch (repeatType) {
      case daily:
        return 'Every day';
      case weekly:
        return 'Every week';
      case monthly:
        return 'Every month';
      case customDays:
        return 'Custom days';
      case once:
      default:
        return 'Once';
    }
  }

  static const Map<int, String> weekdayNames = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };
}
