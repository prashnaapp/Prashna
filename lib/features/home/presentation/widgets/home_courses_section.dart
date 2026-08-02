import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../course_dashboard/models/course_model.dart';
import '../../../course_dashboard/presentation/screens/course_dashboard_screen.dart';
import '../../../course_dashboard/services/course_service.dart';
import '../../../profile/presentation/profile_navigation.dart';
import 'home_course_card.dart';

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
        // Content-height rows (no fixed aspect-ratio cells that reserve empty space).
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

  void _onCourseTap(BuildContext context, CourseModel course) {
    if (course.isEnrolled) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseDashboardScreen(courseId: course.id),
        ),
      );
      return;
    }
    openSubscription(context);
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
                ? HomeCourseCard(
                    course: courses[i],
                    onTap: () => onCourseTap(courses[i]),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}
