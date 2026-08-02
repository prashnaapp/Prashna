import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../services/progress_service.dart';
import '../widgets/chapter_progress_card.dart';
import '../widgets/overall_progress_card.dart';
import '../widgets/tracker_scroll_body.dart';
import 'chapter_progress_detail_screen.dart';

class PartProgressScreen extends StatelessWidget {
  const PartProgressScreen({
    super.key,
    required this.examId,
    required this.paperId,
    required this.partId,
  });

  final String examId;
  final String paperId;
  final String partId;

  @override
  Widget build(BuildContext context) {
    final paper = ProgressService.instance.getPaperProgress(
      examId: examId,
      paperId: paperId,
    );
    final part = ProgressService.instance.getPartProgress(
      examId: examId,
      paperId: paperId,
      partId: partId,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${paper.label} · ${part.label}')),
      body: TrackerScrollBody(
        bottomInset: false,
        children: [
          OverallProgressCard(
            title: part.label,
            coveredMarks: part.coveredMarks,
            maxMarks: part.maxMarks,
            progressPercent: part.progressPercent,
          ),
          const SizedBox(height: AppSpacing.xxl),
          for (var i = 0; i < part.chapters.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            ChapterProgressCard(
              title: part.chapters[i].label,
              coveredMarks: part.chapters[i].coveredMarks,
              maxMarks: part.chapters[i].maxMarks,
              progressPercent: part.chapters[i].progressPercent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChapterProgressDetailScreen(
                      examId: examId,
                      paperId: paperId,
                      partId: partId,
                      chapterId: part.chapters[i].id,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
