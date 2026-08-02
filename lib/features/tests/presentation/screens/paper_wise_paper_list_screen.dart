import 'package:flutter/material.dart';

import '../../services/test_service.dart';
import '../paper_wise_navigation.dart';
import 'test_series_paper_list_screen.dart';

/// Paper-wise Tests → paper list for a group exam.
class PaperWisePaperListScreen extends StatelessWidget {
  const PaperWisePaperListScreen({
    super.key,
    required this.examId,
    required this.title,
  });

  final String examId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final papers = TestService.instance.getPaperWisePapers(examId);

    return TestSeriesPaperListScreen(
      title: title,
      papers: papers,
      onPaperTap: (paper) => openPaperWiseParts(
        context: context,
        examId: examId,
        paper: paper,
      ),
    );
  }
}
