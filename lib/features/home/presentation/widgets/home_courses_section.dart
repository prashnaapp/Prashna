import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../course_dashboard/presentation/screens/course_dashboard_screen.dart';
import '../../../course_enrollment/model/course.dart';
import '../../../course_enrollment/service/course_loader_service.dart';
import '../../../subscription/service/course_open_guard.dart';

class HomeCoursesSection extends StatelessWidget {
  const HomeCoursesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final courseContext = CourseLoaderService.instance.current;
    if (courseContext == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(title: 'My Courses'),
          SizedBox(height: AppSpacing.lg),
          Center(child: AppCircularProgress()),
        ],
      );
    }

    final courses = courseContext.publishedCourses;
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

  Future<void> _onCourseTap(BuildContext context, Course course) async {
    await CourseOpenGuard.attemptOpen(
      context: context,
      courseId: course.courseId,
      onAllowed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDashboardScreen(courseId: course.courseId),
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

  final List<Course> courses;
  final int crossAxisCount;
  final ValueChanged<Course> onCourseTap;

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
                    title: courses[i].title,
                    subtitle: courses[i].shortTitle,
                    accentColor: _accentFor(courses[i]),
                    icon: _iconFor(courses[i].icon),
                    locked: false,
                    onTap: () => onCourseTap(courses[i]),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  Color _accentFor(Course course) {
    final parsed = _parseColor(course.color);
    if (parsed != null) return parsed;

    return switch (course.courseId) {
      'group-iii' => AppColors.success,
      'group-ii' => AppColors.primary,
      _ => AppColors.secondary,
    };
  }

  Color? _parseColor(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var hex = raw.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return Color(value);
  }

  IconData _iconFor(String? key) {
    return switch (key) {
      'school' => Icons.school_rounded,
      'menu_book' => Icons.menu_book_rounded,
      'badge' => Icons.badge_rounded,
      'local_police' => Icons.local_police_rounded,
      _ => Icons.auto_stories_rounded,
    };
  }
}
