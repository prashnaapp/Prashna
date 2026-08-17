import 'package:flutter/material.dart';

import '../../../course_dashboard/presentation/screens/course_dashboard_screen.dart';
import '../../../course_enrollment/model/course.dart';
import '../../../course_enrollment/service/course_loader_service.dart';
import '../../../subscription/service/course_open_guard.dart';
import '../home_visual.dart';
import 'home_decorations.dart';

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
          HomeSectionTitle('My Courses'),
          SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: HomeVisual.ctaEnd,
              ),
            ),
          ),
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
        const HomeSectionTitle('My Courses'),
        const SizedBox(height: 14),
        for (var i = 0; i < courses.length; i += crossAxisCount) ...[
          if (i > 0) const SizedBox(height: 12),
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
          MaterialPageRoute<void>(
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
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: i < courses.length
                ? _HomeCourseCard(
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

class _HomeCourseCard extends StatelessWidget {
  const _HomeCourseCard({required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(course);

    return Material(
      color: HomeVisual.surface,
      borderRadius: BorderRadius.circular(HomeVisual.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeVisual.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: HomeVisual.surface,
            borderRadius: BorderRadius.circular(HomeVisual.cardRadius),
            boxShadow: HomeVisual.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconFor(course.icon), color: accent, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  course.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: HomeVisual.ink,
                  ),
                ),
                if (course.shortTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    course.shortTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HomeVisual.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _accentFor(Course course) {
    final parsed = _parseColor(course.color);
    if (parsed != null) return parsed;

    return switch (course.courseId) {
      'group-iii' => const Color(0xFF2BB8A8),
      'group-ii' => HomeVisual.ctaEnd,
      _ => HomeVisual.accentBlue,
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
