import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../course_dashboard/models/course_model.dart';
import '../../../course_dashboard/presentation/screens/course_dashboard_screen.dart';
import '../../../course_dashboard/services/course_service.dart';
import '../../../profile/presentation/profile_navigation.dart';
import '../../../subscription/service/course_open_guard.dart';

class HomeCoursesSection extends StatelessWidget {
  const HomeCoursesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = CourseService.instance.getAllCourses();
    if (courses.isEmpty) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'My Courses'),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < courses.length; i += crossAxisCount) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _CourseRow(
            courses: courses.sublist(
              i,
              i + crossAxisCount > courses.length
                  ? courses.length
                  : i + crossAxisCount,
            ),
            crossAxisCount: crossAxisCount,
            onCourseTap: (course) => _onCourseTap(context, course),
          ),
        ],
      ],
    );
  }

  Future<void> _onCourseTap(BuildContext context, CourseModel course) async {
    if (!course.isAvailable) {
      openSubscription(context);
      return;
    }

    await CourseOpenGuard.attemptOpen(
      context: context,
      courseId: course.id,
      onAllowed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDashboardScreen(courseId: course.id),
          ),
        );
      },
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({
    required this.courses,
    required this.crossAxisCount,
    required this.onCourseTap,
  });

  final List<CourseModel> courses;
  final int crossAxisCount;
  final ValueChanged<CourseModel> onCourseTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < crossAxisCount; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: i < courses.length
                ? CourseGridCard(
                    title: courses[i].name,
                    marksValue: '${courses[i].totalMarks}',
                    papersValue: '${courses[i].totalPapers}',
                    accentColor: _accentFor(courses[i]),
                    icon: _iconFor(courses[i].icon),
                    locked: !courses[i].isAvailable,
                    onTap: courses[i].isAvailable
                        ? () => onCourseTap(courses[i])
                        : null,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  Color _accentFor(CourseModel course) {
    return switch (course.id) {
      'group-iii' => AppColors.success,
      'group-ii' => AppColors.primary,
      _ => course.isEnrolled ? AppColors.primary : AppColors.secondary,
    };
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
