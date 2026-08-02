import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../services/progress_service.dart';
import '../widgets/progress_info_card.dart';
import '../widgets/tracker_scroll_body.dart';

class ChapterProgressDetailScreen extends StatelessWidget {
  const ChapterProgressDetailScreen({
    super.key,
    required this.examId,
    required this.paperId,
    required this.partId,
    required this.chapterId,
  });

  final String examId;
  final String paperId;
  final String partId;
  final String chapterId;

  @override
  Widget build(BuildContext context) {
    final chapter = ProgressService.instance.getChapterProgress(
      examId: examId,
      paperId: paperId,
      partId: partId,
      chapterId: chapterId,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(chapter.label)),
      body: TrackerScrollBody(
        bottomInset: false,
        children: [
          Text(
            chapter.label,
            style: AppTextStyles.headline(context),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ProgressInfoCard(
            label: 'Weightage',
            value: _marks(chapter.maxMarks),
          ),
          const SizedBox(height: AppSpacing.md),
          ProgressInfoCard(
            label: 'Marks Covered',
            value: _marks(chapter.coveredMarks),
          ),
          const SizedBox(height: AppSpacing.md),
          ProgressInfoCard(
            label: 'Progress',
            value: '${chapter.progressPercent.round()}%',
          ),
          const SizedBox(height: AppSpacing.md),
          ProgressInfoCard(
            label: 'Remaining',
            value: _marks(chapter.remainingMarks),
          ),
          const SizedBox(height: AppSpacing.md),
          ProgressInfoCard(
            label: 'Status',
            value: chapter.status,
          ),
        ],
      ),
    );
  }

  String _marks(double value) {
    final formatted =
        value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$formatted Marks';
  }
}
