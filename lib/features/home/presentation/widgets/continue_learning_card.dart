import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/home_models.dart';

class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final ContinueLearningModel data;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    if (!data.hasHistory) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Start Learning', style: AppTextStyles.titleLarge(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pick a course and begin your first session.',
              style: AppTextStyles.bodyMedium(context),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppPrimaryButton(
              label: 'Start Learning',
              onPressed: onContinue,
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Continue Learning', style: AppTextStyles.titleMedium(context)),
          const SizedBox(height: AppSpacing.lg),
          Text(data.courseName, style: AppTextStyles.titleLarge(context)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${data.paperLabel} · ${data.partLabel}',
            style: AppTextStyles.bodyMedium(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(data.chapterLabel, style: AppTextStyles.label(context)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppLinearProgress(
                  value: data.progressPercent / 100,
                  height: AppSpacing.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${data.progressPercent.round()}%',
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppPrimaryButton(
            label: 'Continue →',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
