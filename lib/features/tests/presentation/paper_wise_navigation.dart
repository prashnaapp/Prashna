import 'package:flutter/material.dart';

import '../data/models/test_models.dart';
import '../services/test_service.dart';
import 'screens/paper_wise_part_list_screen.dart';
import 'screens/test_list_screen.dart';

/// Category entry routing for Test Series group dashboards.
///
/// Every executable list is Firestore-backed [TestListScreen]. Dummy
/// paper/mock/previous helpers must not start server attempts.
void openTestCategory({
  required BuildContext context,
  required String examId,
  required TestCategoryModel category,
  TestService? testService,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TestListScreen(
        examId: examId,
        category: category.type,
        title: category.title,
        testService: testService,
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
