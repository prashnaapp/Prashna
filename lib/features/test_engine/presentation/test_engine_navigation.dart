import 'package:flutter/material.dart';

import '../../question_activity/data/models/question_activity_models.dart';
import '../data/models/test_engine_models.dart';
import '../services/test_service.dart';
import 'screens/test_attempt_flow_screen.dart';

/// Entry points for launching the shared Test Attempt Engine.
abstract final class TestEngineNavigation {
  /// [Navigator] name for [TestAttemptRoute].
  static const String attemptRouteName = '/test-attempt';

  /// [Navigator] name for catalog [TestInstructionsScreen] (not the in-flow one).
  static const String catalogInstructionsRouteName = '/test-instructions';

  static Route<T> catalogInstructionsRoute<T extends Object?>(
    WidgetBuilder builder,
  ) {
    return MaterialPageRoute<T>(
      settings: const RouteSettings(name: catalogInstructionsRouteName),
      builder: builder,
    );
  }

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
        settings: const RouteSettings(name: attemptRouteName),
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
    return openTest(
      context,
      test: test.copyWith(
        activitySourceModule: QuestionActivitySourceModule.practice,
        activitySourceType: QuestionActivitySourceType.topicPractice,
      ),
      onCompleted: onCompleted,
    );
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
    QuestionActivitySourceModule? activitySourceModule,
    QuestionActivitySourceType? activitySourceType,
    String? currentAffairsSetId,
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
      test: test.copyWith(
        activitySourceModule: activitySourceModule,
        activitySourceType: activitySourceType,
        currentAffairsSetId: currentAffairsSetId,
      ),
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
    QuestionActivitySourceModule? activitySourceModule,
    QuestionActivitySourceType? activitySourceType,
    String? syllabusUnitId,
    String? seriesId,
    int? year,
    String? paperId,
    String? partId,
    void Function(TestResult result)? onCompleted,
  }) async {
    final service = engineService ?? TestService();
    final Test built;
    if (studentQuestions != null && studentQuestions.isNotEmpty) {
      built = await service.createTestFromStudentSafeQuestions(
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
      built = await service.createTestFromQuestionIds(
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
    final test = built.copyWith(
      activitySourceModule: activitySourceModule,
      activitySourceType: activitySourceType,
      syllabusUnitId: syllabusUnitId,
      seriesId: seriesId,
      year: year,
      paperId: paperId ?? built.paperId,
      partId: partId ?? built.partId,
    );
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
