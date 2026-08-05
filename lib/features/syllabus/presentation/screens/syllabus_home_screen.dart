import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../../subscription/service/course_open_guard.dart';
import '../../data/models/syllabus_models.dart';
import '../../services/syllabus_service.dart';
import 'syllabus_papers_screen.dart';

/// Chapters tab root — select a course (syllabus).
class SyllabusHomeScreen extends StatelessWidget {
  const SyllabusHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = SyllabusService.instance.getAllCourses();
    final available = courses.where((c) => c.isAvailable).toList();
    final launchingSoon = courses.where((c) => !c.isAvailable).toList();

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 3 : 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: AppResponsivePadding(
          child: TabScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Chapters', style: AppTextStyles.headline(context)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Select a course to browse the syllabus.',
                style: AppTextStyles.bodyMedium(context),
              ),
              if (available.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: 'Available'),
                const SizedBox(height: AppSpacing.lg),
                _CourseGrid(
                  crossAxisCount: crossAxisCount,
                  children: [
                    for (final course in available)
                      CourseGridCard(
                        title: course.name,
                        marksValue: '${course.totalMarks}',
                        papersValue: '${course.totalPapers}',
                        accentColor: _accentFor(course.id),
                        icon: _iconFor(course.icon),
                        onTap: () => _openCourse(context, course),
                      ),
                  ],
                ),
              ],
              if (launchingSoon.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxxl),
                const SectionHeader(title: 'Launching Soon'),
                const SizedBox(height: AppSpacing.lg),
                _CourseGrid(
                  crossAxisCount: crossAxisCount,
                  children: [
                    for (final course in launchingSoon)
                      CourseGridCard(
                        title: course.name,
                        locked: true,
                        icon: _iconFor(course.icon),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCourse(BuildContext context, SyllabusCourse course) async {
    await CourseOpenGuard.attemptOpen(
      context: context,
      courseId: course.id,
      onAllowed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SyllabusPapersScreen(courseId: course.id),
          ),
        );
      },
    );
  }

  Color _accentFor(String courseId) {
    return switch (courseId) {
      'group-iii' => AppColors.success,
      _ => AppColors.primary,
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

class _CourseGrid extends StatelessWidget {
  const _CourseGrid({
    required this.crossAxisCount,
    required this.children,
  });

  final int crossAxisCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i += crossAxisCount) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < crossAxisCount; c++) ...[
                if (c > 0) const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: i + c < children.length
                      ? children[i + c]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
