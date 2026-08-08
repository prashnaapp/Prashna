import 'package:flutter/material.dart';

import '../data/models/test_engine_models.dart';
import '../services/test_service.dart';
import 'screens/test_attempt_flow_screen.dart';

/// Entry points for launching the shared Test Attempt Engine.
abstract final class TestEngineNavigation {
  static Future<void> openTest(
    BuildContext context, {
    required Test test,
    void Function(TestResult result)? onCompleted,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TestAttemptRoute(
          test: test,
          onCompleted: onCompleted,
        ),
      ),
    );
  }

  static Future<void> openPractice({
    required BuildContext context,
    required String courseId,
    required String title,
    String? paperId,
    String? sectionId,
    String? topicId,
    int questionCount = 10,
    int durationMinutes = 15,
    void Function(TestResult result)? onCompleted,
  }) async {
    final test = await TestService().createConfiguredTest(
      id: 'practice-${topicId ?? sectionId ?? paperId ?? courseId}',
      title: title,
      courseId: courseId,
      mode: TestMode.practice,
      duration: Duration(minutes: durationMinutes),
      totalQuestions: questionCount,
      totalMarks: questionCount,
      paperId: paperId,
      sectionId: sectionId,
      topicId: topicId,
    );
    if (!context.mounted) return;
    return openTest(context, test: test, onCompleted: onCompleted);
  }

  static Future<void> openConfigured({
    required BuildContext context,
    required String id,
    required String title,
    required String courseId,
    required TestMode mode,
    required int questionCount,
    required int totalMarks,
    required int durationMinutes,
    double negativeMarks = 0.25,
    String? paperId,
    String? sectionId,
    String? topicId,
    List<String>? instructions,
    void Function(TestResult result)? onCompleted,
  }) async {
    final test = await TestService().createConfiguredTest(
      id: id,
      title: title,
      courseId: courseId,
      mode: mode,
      duration: Duration(minutes: durationMinutes),
      totalQuestions: questionCount,
      totalMarks: totalMarks,
      negativeMarks: negativeMarks,
      paperId: paperId,
      sectionId: sectionId,
      topicId: topicId,
      instructions: instructions,
    );
    if (!context.mounted) return;
    return openTest(context, test: test, onCompleted: onCompleted);
  }

  /// Fixed question assignment — uses [createTestFromQuestionIds] with strict
  /// validation (all IDs present, same course, count matches).
  static Future<void> openFixedConfigured({
    required BuildContext context,
    required String id,
    required String title,
    required String courseId,
    required TestMode mode,
    required List<String> questionIds,
    required int expectedQuestionCount,
    required int totalMarks,
    required int durationMinutes,
    double negativeMarks = 0.25,
    List<String>? instructions,
    void Function(TestResult result)? onCompleted,
  }) async {
    final test = await TestService().createTestFromQuestionIds(
      id: id,
      title: title,
      courseId: courseId,
      questionIds: questionIds,
      mode: mode,
      duration: Duration(minutes: durationMinutes),
      totalMarks: totalMarks,
      negativeMarks: negativeMarks,
      instructions: instructions,
      requireCompleteSet: true,
      requireCourseMatch: true,
      expectedCount: expectedQuestionCount,
    );
    if (!context.mounted) return;
    return openTest(context, test: test, onCompleted: onCompleted);
  }
}
