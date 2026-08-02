import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/course_dashboard_models.dart';

class CourseHeaderSection extends StatelessWidget {
  const CourseHeaderSection({
    super.key,
    required this.data,
  });

  final CourseDashboardData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(data.title, style: AppTextStyles.headline(context)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  data.marksLabel,
                  style: AppTextStyles.bodyMedium(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          _ProgressRing(percent: data.overallProgressPercent),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: AppSpacing.section,
      height: AppSpacing.section,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AppCircularProgress(
            value: value,
            size: AppSpacing.section,
            strokeWidth: AppSpacing.sm,
          ),
          Text(
            '$percent%',
            style: AppTextStyles.titleMedium(context),
          ),
        ],
      ),
    );
  }
}
