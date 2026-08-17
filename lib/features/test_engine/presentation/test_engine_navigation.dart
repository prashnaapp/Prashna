import 'package:flutter/material.dart';

import '../data/models/test_engine_models.dart';
import '../services/test_service.dart';
import 'screens/test_attempt_flow_screen.dart';

/// Entry points for launching the shared Test Attempt Engine.
abstract final class TestEngineNavigation {
  static Future<void> openTest(
    BuildContext context, {
    required Test test,
    String? serverAttemptId,
    bool skipInstructions = false,
    TestService? engineService,
    void Function(TestResult result)? onCompleted,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TestAttemptRoute(
          test: test,
          serverAttemptId: serverAttemptId,
          skipInstructions: skipInstructions,
          engineService: engineService,
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
    // Practice is local UX only — no authoritative cloud attempt.
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
    String? serverAttemptId,
    bool skipInstructions = false,
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
    return openTest(
      context,
      test: test,
      serverAttemptId: serverAttemptId,
      skipInstructions: skipInstructions,
      onCompleted: onCompleted,
    );
  }

  /// Fixed question assignment — uses [createTestFromQuestionIds] with strict
  /// validation (all IDs present, same course, count matches).
  ///
  /// When [studentQuestions] is provided (server snapshot), the live question
  /// bank is not consulted for attempt content.
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
    String? serverAttemptId,
    bool skipInstructions = false,
    TestService? engineService,
    List<Map<String, dynamic>>? studentQuestions,
    void Function(TestResult result)? onCompleted,
  }) async {
    final service = engineService ?? TestService();
    final Test test;
    if (studentQuestions != null && studentQuestions.isNotEmpty) {
      test = await service.createTestFromStudentSafeQuestions(
        id: id,
        title: title,
        courseId: courseId,
        studentQuestions: studentQuestions,
        mode: mode,
        duration: Duration(minutes: durationMinutes),
        totalMarks: totalMarks,
        negativeMarks: negativeMarks,
        instructions: instructions,
      );
    } else {
      test = await service.createTestFromQuestionIds(
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
    }
    if (!context.mounted) return;
    return openTest(
      context,
      test: test,
      serverAttemptId: serverAttemptId,
      skipInstructions: skipInstructions,
      engineService: engineService,
      onCompleted: onCompleted,
    );
  }
}
