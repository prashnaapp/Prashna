import 'package:flutter/material.dart';

import '../../test_engine/data/models/test_engine_models.dart';
import '../../test_engine/presentation/test_engine_navigation.dart';
import '../data/models/test_models.dart';
import '../services/test_service.dart';

Future<void> openTestPracticeSession(
  BuildContext context,
  TestModel test,
) async {
  final instructions = TestService.instance.getInstructions(test);
  final negativeMarks = _parseNegative(test.negativeMarking);
  final mode = _modeFor(test.category);

  try {
    if (test.questionIds.isNotEmpty) {
      await TestEngineNavigation.openFixedConfigured(
        context: context,
        id: test.id,
        title: test.title,
        courseId: test.examId,
        mode: mode,
        questionIds: test.questionIds,
        expectedQuestionCount: test.questionCount,
        totalMarks: test.marks,
        durationMinutes: test.durationMinutes,
        negativeMarks: negativeMarks,
        instructions: instructions.instructions,
      );
      return;
    }

    // Progress is recorded automatically by Test Engine → ProgressService.
    await TestEngineNavigation.openConfigured(
      context: context,
      id: test.id,
      title: test.title,
      courseId: test.examId,
      mode: mode,
      questionCount: test.questionCount,
      totalMarks: test.marks,
      durationMinutes: test.durationMinutes,
      negativeMarks: negativeMarks,
      instructions: instructions.instructions,
    );
  } catch (error) {
    if (!context.mounted) return;
    final message = error is StateError
        ? error.message
        : 'Unable to start test. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

TestMode _modeFor(TestCategoryType category) {
  switch (category) {
    case TestCategoryType.chapterTests:
      return TestMode.topic;
    case TestCategoryType.partTests:
      return TestMode.section;
    case TestCategoryType.paperTests:
      return TestMode.paper;
    case TestCategoryType.mockTests:
      return TestMode.mock;
    case TestCategoryType.previousYear:
      return TestMode.previousYear;
  }
}

double _parseNegative(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return 0;
  return double.tryParse(cleaned) ?? 0.25;
}
