import 'package:flutter/material.dart';

import '../data/models/current_affairs_models.dart';
import 'screens/current_affairs_home_screen.dart';
import 'screens/current_affairs_test_detail_screen.dart';
import 'screens/monthly_mcq_list_screen.dart';
import 'screens/weekly_mcq_list_screen.dart';

void openCurrentAffairs(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CurrentAffairsHomeScreen()),
  );
}

void openWeeklyMcqs(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WeeklyMcqListScreen()),
  );
}

void openMonthlyMcqs(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MonthlyMcqListScreen()),
  );
}

void openCurrentAffairsSet(
  BuildContext context,
  CurrentAffairsSet set,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CurrentAffairsTestDetailScreen(set: set),
    ),
  );
}
