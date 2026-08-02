import 'package:flutter/material.dart';

import '../data/models/test_models.dart';
import 'mock_test_navigation.dart';
import 'previous_papers_navigation.dart';
import 'screens/paper_wise_paper_list_screen.dart';
import 'screens/paper_wise_part_list_screen.dart';
import 'screens/test_list_screen.dart';
import 'test_quiz_navigation.dart';

/// Category entry routing for Test Series group dashboards.
void openTestCategory({
  required BuildContext context,
  required String examId,
  required TestCategoryModel category,
}) {
  if (category.type == TestCategoryType.partTests) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaperWisePaperListScreen(
          examId: examId,
          title: category.title,
        ),
      ),
    );
    return;
  }

  if (category.type == TestCategoryType.mockTests) {
    openMockTests(
      context: context,
      examId: examId,
      title: category.title,
    );
    return;
  }

  if (category.type == TestCategoryType.previousYear) {
    openPreviousPapers(
      context: context,
      title: category.title,
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TestListScreen(
        examId: examId,
        category: category.type,
        title: category.title,
      ),
    ),
  );
}

void openPaperWiseParts({
  required BuildContext context,
  required String examId,
  required PaperWisePaper paper,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PaperWisePartListScreen(
        examId: examId,
        paper: paper,
      ),
    ),
  );
}

void openPaperWisePartTest({
  required BuildContext context,
  required TestModel part,
}) {
  // Existing Test Engine entry (includes engine instructions step).
  openTestPracticeSession(context, part);
}
