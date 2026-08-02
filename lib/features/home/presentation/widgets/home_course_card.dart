import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../course_dashboard/models/course_model.dart';

class HomeCourseCard extends StatelessWidget {
  const HomeCourseCard({
    super.key,
    required this.course,
    this.onTap,
  });

  final CourseModel course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final actionLabel = course.isEnrolled ? 'Continue →' : 'Enroll →';
    final actionColor =
        course.isEnrolled ? AppColors.primary : AppColors.secondary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(_iconFor(course.icon), color: actionColor, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            course.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${course.totalMarks} Marks · ${course.totalPapers} Papers',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            actionLabel,
            style: AppTextStyles.label(context).copyWith(color: actionColor),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String key) {
    return switch (key) {
      'school' => Icons.school_rounded,
      'menu_book' => Icons.menu_book_rounded,
      'badge' => Icons.badge_rounded,
      'local_police' => Icons.local_police_rounded,
      _ => Icons.auto_stories_rounded,
    };
  }
}
