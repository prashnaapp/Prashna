import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/study_planner_models.dart';

class WeeklyPlanSection extends StatelessWidget {
  const WeeklyPlanSection({super.key, required this.days});

  final List<WeeklyPlanDay> days;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'Weekly Plan'),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    days[i].dayLabel,
                    style: AppTextStyles.titleMedium(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _chipColor(days[i].status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    days[i].statusLabel,
                    style: AppTextStyles.label(context).copyWith(
                      color: _chipColor(days[i].status),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _chipColor(WeeklyPlanStatus status) {
    return switch (status) {
      WeeklyPlanStatus.completed => AppColors.success,
      WeeklyPlanStatus.current => AppColors.primary,
      WeeklyPlanStatus.upcoming => AppColors.textSecondary,
      WeeklyPlanStatus.revision => AppColors.accentWarm,
      WeeklyPlanStatus.mockTest => AppColors.secondary,
    };
  }
}
