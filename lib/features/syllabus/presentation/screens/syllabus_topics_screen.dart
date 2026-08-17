import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../services/syllabus_service.dart';
import '../widgets/syllabus_list_tile_card.dart';
import '../widgets/syllabus_scroll_body.dart';
import 'syllabus_topic_detail_screen.dart';

class SyllabusTopicsScreen extends StatelessWidget {
  const SyllabusTopicsScreen({
    super.key,
    required this.courseId,
    required this.paperId,
    required this.sectionId,
  });

  final String courseId;
  final String paperId;
  final String sectionId;

  @override
  Widget build(BuildContext context) {
    final section = SyllabusService.instance.getSection(
      courseId: courseId,
      paperId: paperId,
      sectionId: sectionId,
    );
    final topics = section?.topics ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(section?.title ?? 'Chapters')),
      body: SyllabusScrollBody(
        bottomInset: false,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('Select Topic', style: AppTextStyles.titleLarge(context)),
                const SizedBox(height: AppSpacing.lg),
                for (final topic in topics) ...[
                  SyllabusListTileCard(
                    title: topic.title,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SyllabusTopicDetailScreen(
                            courseId: courseId,
                            paperId: paperId,
                            sectionId: sectionId,
                            topicId: topic.id,
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
