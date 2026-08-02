import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../test_engine/presentation/test_engine_navigation.dart';
import '../../services/syllabus_service.dart';
import '../widgets/syllabus_list_tile_card.dart';
import '../widgets/syllabus_scroll_body.dart';

class SyllabusTopicDetailScreen extends StatelessWidget {
  const SyllabusTopicDetailScreen({
    super.key,
    required this.courseId,
    required this.paperId,
    required this.sectionId,
    required this.topicId,
  });

  final String courseId;
  final String paperId;
  final String sectionId;
  final String topicId;

  @override
  Widget build(BuildContext context) {
    final course = SyllabusService.instance.getCourseById(courseId);
    final paper = SyllabusService.instance.getPaper(
      courseId: courseId,
      paperId: paperId,
    );
    final topic = SyllabusService.instance.getTopic(
      courseId: courseId,
      paperId: paperId,
      sectionId: sectionId,
      topicId: topicId,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(topic?.title ?? 'Topic')),
      body: SyllabusScrollBody(
        bottomInset: false,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  topic?.title ?? 'Topic',
                  style: AppTextStyles.headline(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${course?.name ?? ''} · ${paper?.title ?? ''}',
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SyllabusListTileCard(
                  title: 'Practice Questions',
                  subtitle: 'Start a practice session',
                  onTap: () {
                    TestEngineNavigation.openPractice(
                      context: context,
                      courseId: courseId,
                      title: topic?.title ?? 'Practice Questions',
                      paperId: paperId,
                      sectionId: sectionId,
                      topicId: topicId,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                SyllabusListTileCard(
                  title: 'Previous Year Questions',
                  subtitle: 'Coming soon',
                  enabled: false,
                ),
                const SizedBox(height: AppSpacing.md),
                SyllabusListTileCard(
                  title: 'Study Notes',
                  subtitle: 'Coming soon',
                  enabled: false,
                ),
                const SizedBox(height: AppSpacing.md),
                SyllabusListTileCard(
                  title: 'Bookmark',
                  subtitle: 'Coming soon',
                  enabled: false,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
