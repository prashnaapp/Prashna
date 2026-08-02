import 'package:flutter/material.dart';

import '../data/models/test_models.dart';
import '../services/test_service.dart';
import 'screens/previous_exam_selection_screen.dart';
import 'screens/previous_year_list_screen.dart';
import 'screens/test_series_paper_list_screen.dart';
import 'test_quiz_navigation.dart';

/// Phase 4 navigation helpers for Previous Papers.
void openPreviousPapers({
  required BuildContext context,
  required String title,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PreviousExamSelectionScreen(title: title),
    ),
  );
}

void openPreviousYears({
  required BuildContext context,
  required PreviousPaperExam exam,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PreviousYearListScreen(exam: exam),
    ),
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
}) {
  final test = TestService.instance.getPreviousPaperTest(
    examId: examId,
    year: year,
    paper: paper,
  );
  openTestPracticeSession(context, test);
}
