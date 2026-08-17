import 'package:flutter/material.dart';

import '../../test_engine/data/models/test_engine_models.dart';
import '../../test_engine/presentation/test_engine_navigation.dart';
import '../../test_engine/services/test_service.dart' as engine;
import '../data/models/test_models.dart';
import '../data/tests_dummy_data.dart';

typedef StartCatalogAttempt =
    Future<Map<String, dynamic>> Function({
      required String testId,
      required String startRequestId,
    });

/// Starts a server-backed catalog attempt for a published Firestore test.
///
/// Dummy/synthetic catalog models never reach [startAttempt].
/// Returns true when the question engine was opened.
Future<bool> openTestPracticeSession(
  BuildContext context,
  TestModel test, {
  StartCatalogAttempt? startAttempt,
  engine.TestService? engineService,
  String? startRequestId,
}) async {
  if (!test.isAvailableForNewAttempts ||
      TestsDummyData.isSyntheticCatalogTest(test)) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This test is not available for new attempts.'),
      ),
    );
    return false;
  }

  final negativeMarks = _parseNegative(test.negativeMarking);
  final mode = _modeFor(test.category);
  final requestId = (startRequestId != null && startRequestId.trim().isNotEmpty)
      ? startRequestId.trim()
      : engine.TestService.newStartRequestId();

  try {
    // Server-authoritative attempt creation — question set/config from backend.
    final start =
        startAttempt ??
        (engineService ?? engine.TestService()).startServerAttempt;
    final started = await start(testId: test.id, startRequestId: requestId);
    final attemptId = started['attemptId'] as String?;
    if (attemptId == null || attemptId.isEmpty) {
      throw StateError('Server did not return an attempt id.');
    }

    final questionIds = (started['questionIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((id) => id.isNotEmpty)
        .toList();
    final studentQuestions =
        (started['studentQuestions'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    final totalMarks = (started['totalMarks'] as num?)?.toInt() ?? test.marks;
    final durationSeconds =
        (started['durationSeconds'] as num?)?.toInt() ??
        test.durationMinutes * 60;
    final serverNegative =
        (started['negativeMarks'] as num?)?.toDouble() ?? negativeMarks;
    final courseId = (started['courseId'] as String?)?.trim().isNotEmpty == true
        ? started['courseId'] as String
        : test.examId;
    final testSnapshot = started['testSnapshot'] is Map
        ? Map<String, dynamic>.from(started['testSnapshot'] as Map)
        : null;
    final instructions =
        (testSnapshot?['instructions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        TestsDummyData.instructions;

    if (questionIds.isEmpty && studentQuestions.isEmpty) {
      throw StateError('Server returned an empty question set.');
    }

    if (!context.mounted) return false;
    await TestEngineNavigation.openFixedConfigured(
      context: context,
      id: test.id,
      title: (testSnapshot?['title'] as String?)?.trim().isNotEmpty == true
          ? (testSnapshot!['title'] as String).trim()
          : test.title,
      courseId: courseId,
      mode: mode,
      questionIds: questionIds.isNotEmpty
          ? questionIds
          : [
              for (final q in studentQuestions)
                (q['questionId'] as String? ?? ''),
            ].where((id) => id.isNotEmpty).toList(),
      expectedQuestionCount: studentQuestions.isNotEmpty
          ? studentQuestions.length
          : questionIds.length,
      totalMarks: totalMarks,
      durationMinutes: (durationSeconds / 60).ceil().clamp(1, 24 * 60),
      negativeMarks: serverNegative,
      instructions: instructions,
      serverAttemptId: attemptId,
      skipInstructions: true,
      engineService: engineService,
      studentQuestions: studentQuestions.isNotEmpty ? studentQuestions : null,
    );
    return true;
  } catch (_) {
    return false;
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
