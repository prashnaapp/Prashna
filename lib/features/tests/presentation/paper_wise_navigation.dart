import 'package:flutter/material.dart';

import '../data/models/test_models.dart';
import '../data/test_series_browser_groups.dart';
import '../services/test_service.dart';
import 'screens/grand_tests_screen.dart';
import 'screens/paper_wise_part_list_screen.dart';
import 'screens/test_list_screen.dart';
import 'screens/test_series_browser_screen.dart';

/// Category entry routing for Test Series group dashboards.
///
/// Paper-wise, Grand Tests, and Previous Papers use the Chapters-style
/// tab + card browser. Other categories keep the published [TestListScreen].
void openTestCategory({
  required BuildContext context,
  required String examId,
  required TestCategoryModel category,
  TestService? testService,
}) {
  final mode = switch (category.type) {
    TestCategoryType.partTests => TestSeriesBrowserMode.paperWise,
    TestCategoryType.mockTests => TestSeriesBrowserMode.grandTests,
    TestCategoryType.previousYear => TestSeriesBrowserMode.previousPapers,
    _ => null,
  };

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) {
        if (category.type == TestCategoryType.mockTests) {
          return GrandTestsScreen(examId: examId, testService: testService);
        }
        return mode == null
            ? TestListScreen(
                examId: examId,
                category: category.type,
                title: category.title,
                testService: testService,
              )
            : TestSeriesBrowserScreen(
                examId: examId,
                mode: mode,
                testService: testService,
              );
      },
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
      builder: (_) => PaperWisePartListScreen(examId: examId, paper: paper),
    ),
  );
}

void openPaperWisePartTest({
  required BuildContext context,
  required TestModel part,
  TestService? testService,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TestListScreen(
        examId: part.examId,
        category: TestCategoryType.partTests,
        title: part.title,
        testService: testService,
      ),
    ),
  );
}
