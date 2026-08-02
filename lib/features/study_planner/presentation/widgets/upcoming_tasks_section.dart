import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/study_planner_models.dart';

class UpcomingTasksSection extends StatelessWidget {
  const UpcomingTasksSection({super.key, required this.tasks});

  final List<UpcomingTaskPlan> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'Upcoming Tasks'),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < tasks.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tasks[i].paperLabel,
                  style: AppTextStyles.titleMedium(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  tasks[i].chapterLabel,
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Estimated  ${tasks[i].estimatedMinutes} Minutes',
                  style: AppTextStyles.label(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
