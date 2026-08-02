import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../services/syllabus_service.dart';
import '../widgets/syllabus_list_tile_card.dart';
import 'syllabus_papers_screen.dart';

/// Chapters tab root — select a course (syllabus).
class SyllabusHomeScreen extends StatelessWidget {
  const SyllabusHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = SyllabusService.instance.getAllCourses();

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
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Select Course',
                style: AppTextStyles.titleLarge(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final course in courses) ...[
                SyllabusListTileCard(
                  title: course.name,
                  subtitle:
                      '${course.totalMarks} Marks · ${course.totalPapers} Papers',
                  enabled: course.papers.isNotEmpty,
                  onTap: course.papers.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SyllabusPapersScreen(
                                courseId: course.id,
                              ),
                            ),
                          );
                        },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
