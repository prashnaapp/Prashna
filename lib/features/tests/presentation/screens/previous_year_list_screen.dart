import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_models.dart';
import '../../services/test_service.dart';
import '../previous_papers_navigation.dart';
import '../widgets/test_category_card.dart';
import '../widgets/tests_scroll_body.dart';

/// Previous Papers → year list for a selected exam.
class PreviousYearListScreen extends StatelessWidget {
  const PreviousYearListScreen({
    super.key,
    required this.exam,
  });

  final PreviousPaperExam exam;

  @override
  Widget build(BuildContext context) {
    final years = TestService.instance.getPreviousPaperYears(exam.examId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(exam.title)),
      body: TestsScrollBody(
        bottomInset: false,
        children: [
          for (var i = 0; i < years.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            TestCategoryCard(
              title: years[i].title,
              subtitle: 'Select a paper to begin',
              onTap: () => openPreviousYearPapers(
                context: context,
                exam: exam,
                year: years[i],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
