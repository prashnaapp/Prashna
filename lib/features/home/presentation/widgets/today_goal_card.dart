import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/home_models.dart';

class TodayGoalCard extends StatelessWidget {
  const TodayGoalCard({
    super.key,
    required this.goal,
  });

  final TodayGoalModel goal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Today's Goal", style: AppTextStyles.titleMedium(context)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Questions Completed Today',
                  style: AppTextStyles.bodyMedium(context),
                ),
              ),
              Text(
                '${goal.completedQuestions} / ${goal.targetQuestions}',
                style: AppTextStyles.titleMedium(context).copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppLinearProgress(value: goal.progress, height: AppSpacing.md),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${goal.progressPercent}%',
            style: AppTextStyles.caption(context),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            goal.motivationText,
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }
}
