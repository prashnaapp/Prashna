import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_models.dart';
import '../../services/test_service.dart';
import '../paper_wise_navigation.dart';
import '../widgets/test_category_card.dart';
import '../widgets/tests_scroll_body.dart';

/// Paper-wise Tests → parts for a selected paper.
class PaperWisePartListScreen extends StatelessWidget {
  const PaperWisePartListScreen({
    super.key,
    required this.examId,
    required this.paper,
  });

  final String examId;
  final PaperWisePaper paper;

  @override
  Widget build(BuildContext context) {
    final parts = TestService.instance.getPaperWiseParts(
      examId: examId,
      paperId: paper.id,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(paper.title)),
      body: TestsScrollBody(
        bottomInset: false,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            TestCategoryCard(
              title: parts[i].title,
              subtitle:
                  '${parts[i].questionCount} Questions\n'
                  '${parts[i].marks} Marks\n'
                  '${parts[i].durationMinutes} Minutes',
              onTap: () => openPaperWisePartTest(
                context: context,
                part: parts[i],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
