import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../services/syllabus_service.dart';
import '../widgets/syllabus_list_tile_card.dart';
import '../widgets/syllabus_scroll_body.dart';
import 'syllabus_sections_screen.dart';

class SyllabusPapersScreen extends StatelessWidget {
  const SyllabusPapersScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final course = SyllabusService.instance.getCourseById(courseId);
    final papers = course?.papers ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(course?.name ?? 'Papers')),
      body: SyllabusScrollBody(
        bottomInset: false,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('Select Paper', style: AppTextStyles.titleLarge(context)),
                const SizedBox(height: AppSpacing.lg),
                for (final paper in papers) ...[
                  SyllabusListTileCard(
                    title: paper.title,
                    subtitle: '${paper.sections.length} Sections',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SyllabusSectionsScreen(
                            courseId: courseId,
                            paperId: paper.id,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
