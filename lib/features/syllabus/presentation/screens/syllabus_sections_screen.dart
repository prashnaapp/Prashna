import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../services/syllabus_service.dart';
import '../widgets/syllabus_list_tile_card.dart';
import '../widgets/syllabus_scroll_body.dart';
import 'syllabus_topics_screen.dart';

class SyllabusSectionsScreen extends StatelessWidget {
  const SyllabusSectionsScreen({
    super.key,
    required this.courseId,
    required this.paperId,
  });

  final String courseId;
  final String paperId;

  @override
  Widget build(BuildContext context) {
    final paper = SyllabusService.instance.getPaper(
      courseId: courseId,
      paperId: paperId,
    );
    final sections = paper?.sections ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(paper?.title ?? 'Sections')),
      body: SyllabusScrollBody(
        bottomInset: false,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Select Section',
                  style: AppTextStyles.titleLarge(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final section in sections) ...[
                  SyllabusListTileCard(
                    title: section.title,
                    subtitle: '${section.topics.length} Chapters',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SyllabusTopicsScreen(
                            courseId: courseId,
                            paperId: paperId,
                            sectionId: section.id,
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
