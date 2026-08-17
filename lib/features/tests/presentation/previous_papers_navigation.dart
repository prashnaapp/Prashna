import 'package:flutter/material.dart';

import '../data/models/test_models.dart';
import '../services/test_service.dart';
import 'screens/previous_year_list_screen.dart';
import 'screens/test_list_screen.dart';
import 'screens/test_series_paper_list_screen.dart';

/// Previous Papers navigation — scoped to a single [examId] / course.
///
/// Does not show a cross-course exam picker.
void openPreviousPapers({
  required BuildContext context,
  required String examId,
  required String title,
}) {
  final exam = _examFor(examId, fallbackTitle: title);
  openPreviousYears(context: context, exam: exam);
}

void openPreviousYears({
  required BuildContext context,
  required PreviousPaperExam exam,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PreviousYearListScreen(exam: exam)),
  );
}

void openPreviousYearPapers({
  required BuildContext context,
  required PreviousPaperExam exam,
  required PreviousPaperYear year,
}) {
  final papers = TestService.instance.getPreviousPapers(exam.examId);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TestSeriesPaperListScreen(
        title: year.title,
        papers: papers,
        onPaperTap: (paper) => openPreviousPaperTest(
          context: context,
          examId: exam.examId,
          year: year,
          paper: paper,
        ),
      ),
    ),
  );
}

void openPreviousPaperTest({
  required BuildContext context,
  required String examId,
  required PreviousPaperYear year,
  required PaperWisePaper paper,
  TestService? testService,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TestListScreen(
        examId: examId,
        category: TestCategoryType.previousYear,
        title: '${year.title} · ${paper.title}',
        testService: testService,
      ),
    ),
  );
}

PreviousPaperExam _examFor(String examId, {required String fallbackTitle}) {
  for (final exam in TestService.instance.getPreviousPaperExams()) {
    if (exam.examId == examId) return exam;
  }
  return PreviousPaperExam(examId: examId, title: fallbackTitle);
}
