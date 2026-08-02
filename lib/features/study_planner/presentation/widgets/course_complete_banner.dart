import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// Shown when every chapter in the course is complete.
class CourseCompleteBanner extends StatelessWidget {
  const CourseCompleteBanner({super.key, required this.courseTitle});

  final String courseTitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Congratulations!',
            style: AppTextStyles.titleLarge(context),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You have completed the $courseTitle syllabus.',
            style: AppTextStyles.bodyMedium(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Continue with Mock Tests and Previous Papers.',
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }
}
