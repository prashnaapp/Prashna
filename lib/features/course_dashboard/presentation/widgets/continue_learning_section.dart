import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/course_dashboard_models.dart';

class ContinueLearningSection extends StatelessWidget {
  const ContinueLearningSection({
    super.key,
    required this.data,
  });

  final ContinueLearningDummy data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'Continue Learning'),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          onTap: () {},
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data.paperLabel, style: AppTextStyles.titleLarge(context)),
              const SizedBox(height: AppSpacing.sm),
              Text(data.partLabel, style: AppTextStyles.bodyMedium(context)),
              const SizedBox(height: AppSpacing.xs),
              Text(data.chapterLabel, style: AppTextStyles.label(context)),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Continue →',
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
