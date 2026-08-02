import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../../tests/presentation/widgets/test_category_card.dart';
import '../../data/services/current_affairs_service.dart';
import '../current_affairs_navigation.dart';

class WeeklyMcqListScreen extends StatelessWidget {
  const WeeklyMcqListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sets = CurrentAffairsService.instance.getWeeklySets();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Weekly MCQs')),
      body: SafeArea(
        bottom: false,
        child: AppResponsivePadding(
          child: TabScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            children: [
              for (var i = 0; i < sets.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                TestCategoryCard(
                  title: sets[i].title,
                  subtitle: 'Current affairs MCQ set',
                  onTap: () => openCurrentAffairsSet(context, sets[i]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
