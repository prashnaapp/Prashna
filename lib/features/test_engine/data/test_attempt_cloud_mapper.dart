import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/test_attempt_history.dart';
import 'models/test_engine_models.dart';

/// Maps engine models ↔ Firestore `test_attempts/{attemptId}` documents.
///
/// Pure functions — no Firebase I/O (unit-testable).
abstract final class TestAttemptCloudMapper {
  /// Firestore create payload. [submittedAt] uses server timestamp.
  ///
  /// [courseTitle] should be the human course name from existing syllabus/course
  /// data (not hardcoded). Falls back to [Test.courseId] when blank.
  static Map<String, dynamic> toCreateMap({
    required String attemptId,
    required String uid,
    required Test test,
    required TestResult result,
    required List<QuestionAttempt> attempts,
    required DateTime startedAt,
    String? courseTitle,
  }) {
    final resolvedTestTitle =
        test.title.trim().isNotEmpty ? test.title.trim() : test.id;
    final resolvedCourseTitle = () {
      final trimmed = courseTitle?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
      return test.courseId;
    }();

    return {
      'id': attemptId,
      'uid': uid,
      'testId': test.id,
      'testTitle': resolvedTestTitle,
      'courseId': test.courseId,
      'courseTitle': resolvedCourseTitle,
      'mode': test.mode.name,
      'status': 'submitted',
      'startedAt': Timestamp.fromDate(startedAt),
      'submittedAt': FieldValue.serverTimestamp(),
      'answers': answersFromAttempts(attempts),
      'score': result.score,
      'correct': result.correct,
      'wrong': result.wrong,
      'skipped': result.skipped,
      'attempted': result.attempted,
      'totalQuestions': result.totalQuestions,
      'accuracy': result.accuracy,
      'percentage': result.percentage,
      'passed': result.passed,
      'timeSpentSeconds': result.timeTaken.inSeconds,
    };
  }

  static List<Map<String, dynamic>> answersFromAttempts(
    List<QuestionAttempt> attempts,
  ) {
    return [
      for (final attempt in attempts)
        {
          'questionId': attempt.questionId,
          'selectedOption': attempt.selectedOption,
          'visited': attempt.visited,
          'markedForReview': attempt.markedForReview,
          'timeSpentSeconds': attempt.timeSpent,
          'answered': attempt.answered,
          'bookmarked': attempt.bookmarked,
        },
    ];
  }

  /// Firestore document → [TestAttemptHistoryItem].
  ///
  /// Returns null when required identity fields (`testId` / `courseId`) are missing.
  static TestAttemptHistoryItem? historyFromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    final rawId = data['id'] as String?;
    final attemptId = (rawId != null && rawId.isNotEmpty) ? rawId : docId;
    if (attemptId.isEmpty) return null;

    final testId = data['testId'] as String?;
    final courseId = data['courseId'] as String?;
    if (testId == null ||
        testId.isEmpty ||
        courseId == null ||
        courseId.isEmpty) {
      return null;
    }

    final rawTestTitle = data['testTitle'] as String?;
    final rawCourseTitle = data['courseTitle'] as String?;

    return TestAttemptHistoryItem(
      attemptId: attemptId,
      testId: testId,
      courseId: courseId,
      testTitle: _optionalTrimmed(rawTestTitle),
      courseTitle: _optionalTrimmed(rawCourseTitle),
      mode: (data['mode'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'submitted',
      score: asDouble(data['score']) ?? 0,
      percentage: asDouble(data['percentage']) ?? 0,
      accuracy: asDouble(data['accuracy']) ?? 0,
      correct: asInt(data['correct']) ?? 0,
      wrong: asInt(data['wrong']) ?? 0,
      skipped: asInt(data['skipped']) ?? 0,
      totalQuestions: asInt(data['totalQuestions']) ?? 0,
      timeSpentSeconds: asInt(data['timeSpentSeconds']) ?? 0,
      startedAt: readTimestamp(data['startedAt']),
      submittedAt: readTimestamp(data['submittedAt']),
      passed: data['passed'] == true,
      uid: data['uid'] as String?,
    );
  }

  static String? _optionalTrimmed(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static int? asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// Outcome of a best-effort cloud attempt save.
class TestAttemptSaveResult {
  const TestAttemptSaveResult._({
    required this.success,
    this.attemptId,
    this.error,
  });

  factory TestAttemptSaveResult.ok(String attemptId) {
    return TestAttemptSaveResult._(success: true, attemptId: attemptId);
  }

  factory TestAttemptSaveResult.failed(Object error, {String? attemptId}) {
    return TestAttemptSaveResult._(
      success: false,
      attemptId: attemptId,
      error: error,
    );
  }

  final bool success;
  final String? attemptId;
  final Object? error;
}
