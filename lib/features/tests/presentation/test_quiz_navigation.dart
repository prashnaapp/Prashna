import 'package:flutter/material.dart';

import '../../test_engine/data/models/test_engine_models.dart';
import '../../test_engine/presentation/test_engine_navigation.dart';
import '../data/models/test_models.dart';
import '../services/test_service.dart';

void openTestPracticeSession(BuildContext context, TestModel test) {
  final instructions = TestService.instance.getInstructions(test);

  // Progress is recorded automatically by Test Engine → ProgressService.
  TestEngineNavigation.openConfigured(
    context: context,
    id: test.id,
    title: test.title,
    courseId: test.examId,
    mode: _modeFor(test.category),
    questionCount: test.questionCount,
    totalMarks: test.marks,
    durationMinutes: test.durationMinutes,
    negativeMarks: _parseNegative(test.negativeMarking),
    instructions: instructions.instructions,
  );
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
