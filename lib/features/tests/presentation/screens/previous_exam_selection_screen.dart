import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../services/test_service.dart';
import '../previous_papers_navigation.dart';
import '../widgets/test_category_card.dart';
import '../widgets/tests_scroll_body.dart';

/// Previous Papers → choose exam (Group-II / Group-III).
class PreviousExamSelectionScreen extends StatelessWidget {
  const PreviousExamSelectionScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final exams = TestService.instance.getPreviousPaperExams();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: TestsScrollBody(
        bottomInset: false,
        children: [
          for (var i = 0; i < exams.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            TestCategoryCard(
              title: exams[i].title,
              subtitle: 'Previous year papers',
              onTap: () => openPreviousYears(context: context, exam: exams[i]),
            ),
          ],
        ],
      ),
    );
  }
}
