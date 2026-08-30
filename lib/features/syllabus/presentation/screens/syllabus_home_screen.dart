import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/app_nav_metrics.dart';
import '../../../subscription/service/course_open_guard.dart';
import '../../data/models/syllabus_models.dart';
import '../../services/syllabus_service.dart';
import '../syllabus_visual.dart';
import '../widgets/chapters_course_card.dart';
import '../widgets/chapters_hero.dart';
import 'syllabus_browser_screen.dart';

/// Chapters tab root — compact header plus Available course cards.
///
/// Only the currently-available courses (Group-II / Group-III) are shown.
/// There is no "Launching Soon" section or "Coming Soon" banner.
class SyllabusHomeScreen extends StatelessWidget {
  const SyllabusHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final available = SyllabusService.instance
        .getAllCourses()
        .where((c) => c.isAvailable)
        .toList();
    final bottomInset =
        AppNavMetrics.bottomNavigationHeight(context) + AppSpacing.lg;

    return Scaffold(
      backgroundColor: SyllabusVisual.page,
      body: ColoredBox(
        color: SyllabusVisual.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ChaptersHero(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  SyllabusVisual.pagePadding,
                  AppSpacing.sm,
                  SyllabusVisual.pagePadding,
                  bottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (available.isNotEmpty) ...[
                      Text(
                        'Available',
                        style: AppTextStyles.titleMedium(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: SyllabusVisual.ink,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < available.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: ChaptersCourseCard(
                                title: available[i].name,
                                marks: available[i].totalMarks,
                                papers: available[i].totalPapers,
                                icon: _iconFor(available[i].icon),
                                accent: _accentFor(available[i].id),
                                onTap: () => _openCourse(context, available[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
          MaterialPageRoute<void>(
            builder: (_) => SyllabusBrowserScreen(courseId: course.id),
          ),
        );
      },
    );
  }

  Color _accentFor(String courseId) {
    return switch (courseId) {
      'group-iii' => AppColors.accentTeal,
      'group-ii' => AppColors.primaryStrong,
      _ => AppColors.accent,
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
