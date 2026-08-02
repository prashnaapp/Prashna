import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/study_planner_models.dart';

class StudyProgressSection extends StatelessWidget {
  const StudyProgressSection({super.key, required this.progress});

  final StudyProgressPlan progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'Study Progress'),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Today's Progress",
                      style: AppTextStyles.titleMedium(context),
                    ),
                  ),
                  Text(
                    '${progress.percent}%',
                    style: AppTextStyles.label(context).copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppLinearProgress(
                value: progress.percent / 100,
                height: AppSpacing.sm,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Questions Solved',
                style: AppTextStyles.bodyMedium(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${progress.solved} / ${progress.total}',
                style: AppTextStyles.titleMedium(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
