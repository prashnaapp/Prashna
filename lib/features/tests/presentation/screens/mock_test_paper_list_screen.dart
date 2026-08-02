import 'package:flutter/material.dart';

import '../../data/models/test_models.dart';
import '../../services/test_service.dart';
import '../mock_test_navigation.dart';
import 'test_series_paper_list_screen.dart';

/// Mock Tests → papers for a selected mock set.
class MockTestPaperListScreen extends StatelessWidget {
  const MockTestPaperListScreen({
    super.key,
    required this.examId,
    required this.mock,
  });

  final String examId;
  final MockTestEntry mock;

  @override
  Widget build(BuildContext context) {
    final papers = TestService.instance.getMockPapers(examId);

    return TestSeriesPaperListScreen(
      title: mock.title,
      papers: papers,
      onPaperTap: (paper) => openMockPaperTest(
        context: context,
        examId: examId,
        mock: mock,
        paper: paper,
      ),
    );
  }
}
