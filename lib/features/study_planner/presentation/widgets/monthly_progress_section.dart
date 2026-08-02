import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/study_planner_models.dart';

class MonthlyProgressSection extends StatelessWidget {
  const MonthlyProgressSection({super.key, required this.progress});

  final MonthlyProgressPlan progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'Monthly Progress'),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Row(
            children: [
              _ProgressRing(percent: progress.percent),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Study Days',
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${progress.studyDays}',
                      style: AppTextStyles.titleMedium(context),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Remaining Chapters',
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${progress.remainingChapters}',
                      style: AppTextStyles.titleMedium(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.section,
      height: AppSpacing.section,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AppCircularProgress(
            value: (percent / 100).clamp(0.0, 1.0),
            size: AppSpacing.section,
            strokeWidth: AppSpacing.sm,
          ),
          Text('$percent%', style: AppTextStyles.titleMedium(context)),
        ],
      ),
    );
  }
}
