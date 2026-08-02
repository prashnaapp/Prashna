import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/course_dashboard_models.dart';

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({
    super.key,
    required this.activity,
  });

  final RecentActivityItem? activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'Recent Activity'),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: activity == null
              ? Text(
                  'No tests completed yet.',
                  style: AppTextStyles.bodyMedium(context),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activity!.title,
                      style: AppTextStyles.titleMedium(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      activity!.scoreLabel,
                      style: AppTextStyles.titleLarge(context).copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      activity!.metaLabel,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
