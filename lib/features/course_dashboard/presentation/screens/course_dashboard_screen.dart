import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/app_nav_item.dart';
import '../../../../navigation/main_navigation_screen.dart';
import '../../../syllabus/presentation/screens/syllabus_papers_screen.dart';
import '../../services/course_service.dart';

class CourseDashboardScreen extends StatelessWidget {
  const CourseDashboardScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final course = CourseService.instance.getCourseById(courseId);
    final name = course?.name ?? 'Course';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(name)),
      body: AppResponsivePadding(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(name, style: AppTextStyles.headline(context)),
            if (course != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(course.subtitle, style: AppTextStyles.bodyMedium(context)),
            ],
            const SizedBox(height: AppSpacing.xxl),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Continue Learning',
                    style: AppTextStyles.titleMedium(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Browse the $name syllabus and start practicing.',
                    style: AppTextStyles.bodyMedium(context),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppPrimaryButton(
                    label: 'Continue →',
                    onPressed: () => _openSyllabus(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: AppSpacing.lg),
            ..._actions(context),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(title: 'Course Information'),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Text(
                course == null
                    ? 'Course details unavailable.'
                    : '${course.totalMarks} Marks · ${course.totalPapers} Papers',
                style: AppTextStyles.bodyLarge(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    final tiles = [
      ('Study', Icons.menu_book_rounded, null),
      ('Practice', Icons.fitness_center_rounded, null),
      ('Test Series', Icons.quiz_rounded, AppTab.testSeries),
      ('Progress', Icons.insights_rounded, AppTab.progress),
    ];
    return [
      for (var i = 0; i < tiles.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.md),
        AppCard(
          onTap: () {
            final tab = tiles[i].$3;
            if (tab == null) {
              _openSyllabus(context);
            } else {
              _openTab(context, tab);
            }
          },
          child: Row(
            children: [
              Icon(tiles[i].$2, color: AppColors.primary),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  tiles[i].$1,
                  style: AppTextStyles.titleMedium(context),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ],
    ];
  }

  void _openSyllabus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SyllabusPapersScreen(courseId: courseId),
      ),
    );
  }

  void _openTab(BuildContext context, AppTab tab) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainNavigationScreen(initialTab: tab)),
      (route) => false,
    );
  }
}
