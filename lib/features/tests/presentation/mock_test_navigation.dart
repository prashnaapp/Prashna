import 'package:flutter/material.dart';

import '../data/models/test_models.dart';
import '../services/test_service.dart';
import 'screens/mock_test_list_screen.dart';
import 'screens/mock_test_paper_list_screen.dart';
import 'screens/test_list_screen.dart';

/// Phase 3 navigation helpers for Mock Tests.
void openMockTests({
  required BuildContext context,
  required String examId,
  required String title,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MockTestListScreen(examId: examId, title: title),
    ),
  );
}

void openMockPapers({
  required BuildContext context,
  required String examId,
  required MockTestEntry mock,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MockTestPaperListScreen(examId: examId, mock: mock),
    ),
  );
}

void openMockPaperTest({
  required BuildContext context,
  required String examId,
  required MockTestEntry mock,
  required PaperWisePaper paper,
  TestService? testService,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TestListScreen(
        examId: examId,
        category: TestCategoryType.mockTests,
        title: '${mock.title} · ${paper.title}',
        testService: testService,
      ),
    ),
  );
}
