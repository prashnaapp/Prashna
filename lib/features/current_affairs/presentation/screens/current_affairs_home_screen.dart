import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../current_affairs_navigation.dart';
import '../widgets/current_affairs_mode_card.dart';

class CurrentAffairsHomeScreen extends StatelessWidget {
  const CurrentAffairsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Current Affairs')),
      body: SafeArea(
        bottom: false,
        child: AppResponsivePadding(
          child: TabScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            children: [
              Text(
                'Practice weekly and monthly current affairs.',
                style: AppTextStyles.bodyMedium(context),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              CurrentAffairsModeCard(
                title: 'Weekly MCQs',
                subtitle: 'Practice the latest weekly current affairs.',
                icon: Icons.calendar_today_rounded,
                onTap: () => openWeeklyMcqs(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              CurrentAffairsModeCard(
                title: 'Monthly MCQs',
                subtitle: 'Revise complete monthly current affairs.',
                icon: Icons.menu_book_rounded,
                onTap: () => openMonthlyMcqs(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
