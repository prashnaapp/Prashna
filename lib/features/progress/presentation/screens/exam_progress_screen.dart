import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../services/progress_service.dart';
import '../widgets/overall_progress_card.dart';
import '../widgets/paper_progress_card.dart';
import '../widgets/tracker_scroll_body.dart';
import 'paper_progress_screen.dart';

class ExamProgressScreen extends StatelessWidget {
  const ExamProgressScreen({
    super.key,
    required this.examId,
  });

  final String examId;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance.getOverallProgress(examId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${progress.examTitle} Progress')),
      body: TrackerScrollBody(
        bottomInset: false,
        children: [
          OverallProgressCard(
            title: 'Overall Progress',
            coveredMarks: progress.coveredMarks,
            maxMarks: progress.maxMarks,
            progressPercent: progress.progressPercent,
          ),
          const SizedBox(height: AppSpacing.xxl),
          for (var i = 0; i < progress.papers.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            PaperProgressCard(
              title: progress.papers[i].label,
              coveredMarks: progress.papers[i].coveredMarks,
              maxMarks: progress.papers[i].maxMarks,
              progressPercent: progress.papers[i].progressPercent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaperProgressScreen(
                      examId: examId,
                      paperId: progress.papers[i].id,
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
