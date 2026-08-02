import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../services/progress_service.dart';
import '../widgets/overall_progress_card.dart';
import '../widgets/part_progress_card.dart';
import '../widgets/tracker_scroll_body.dart';
import 'part_progress_screen.dart';

class PaperProgressScreen extends StatelessWidget {
  const PaperProgressScreen({
    super.key,
    required this.examId,
    required this.paperId,
  });

  final String examId;
  final String paperId;

  @override
  Widget build(BuildContext context) {
    final paper = ProgressService.instance.getPaperProgress(
      examId: examId,
      paperId: paperId,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(paper.label)),
      body: TrackerScrollBody(
        bottomInset: false,
        children: [
          OverallProgressCard(
            title: paper.label,
            coveredMarks: paper.coveredMarks,
            maxMarks: paper.maxMarks,
            progressPercent: paper.progressPercent,
          ),
          const SizedBox(height: AppSpacing.xxl),
          for (var i = 0; i < paper.parts.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            PartProgressCard(
              title: paper.parts[i].label,
              coveredMarks: paper.parts[i].coveredMarks,
              maxMarks: paper.parts[i].maxMarks,
              progressPercent: paper.parts[i].progressPercent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PartProgressScreen(
                      examId: examId,
                      paperId: paperId,
                      partId: paper.parts[i].id,
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
