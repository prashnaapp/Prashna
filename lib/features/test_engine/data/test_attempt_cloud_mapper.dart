import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/test_attempt_history.dart';
import 'models/test_attempt_history_detail.dart';
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
    final resolvedTestTitle = test.title.trim().isNotEmpty
        ? test.title.trim()
        : test.id;
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
      'answers': answersFromAttempts(attempts, questions: test.questions),
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
    List<QuestionAttempt> attempts, {
    List<TestQuestion> questions = const [],
  }) {
    final byId = {for (final question in questions) question.id: question};
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
          if (_canonicalAttribution(byId[attempt.questionId]) != null)
            'canonicalAttribution': _canonicalAttribution(
              byId[attempt.questionId],
            ),
        },
    ];
  }

  static Map<String, String?>? _canonicalAttribution(TestQuestion? question) {
    final syllabus = question?.syllabus;
    if (syllabus == null) return null;
    final values = <String, String?>{
      'majorStudyAreaId': syllabus.majorStudyAreaId,
      'contentTopicId': syllabus.contentTopicId,
      'partId': syllabus.partId,
      'topicId': syllabus.topicId,
      'lessonId': syllabus.lessonId,
    };
    if (values.values.every((value) => value == null)) return null;
    return values;
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
      authority: _optionalTrimmed(data['authority'] as String?),
      snapshotSchemaVersion: asInt(data['snapshotSchemaVersion']),
    );
  }

  /// Full detail including immutable [questionSnapshots] when present.
  static TestAttemptHistoryDetail? detailFromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    final summary = historyFromFirestore(docId, data);
    if (summary == null) return null;

    final snapshots = <HistoricalQuestionSnapshot>[];
    final rawSnapshots = data['questionSnapshots'];
    if (rawSnapshots is List) {
      for (final item in rawSnapshots) {
        if (item is! Map) continue;
        final mapped = _snapshotFromMap(Map<String, dynamic>.from(item));
        if (mapped != null) snapshots.add(mapped);
      }
    }

    final answers = <HistoricalAnswerRecord>[];
    final rawAnswers = data['answers'];
    if (rawAnswers is List) {
      for (final item in rawAnswers) {
        if (item is! Map) continue;
        final mapped = _answerFromMap(Map<String, dynamic>.from(item));
        if (mapped != null) answers.add(mapped);
      }
    }

    return TestAttemptHistoryDetail(
      summary: summary,
      questionSnapshots: snapshots,
      answers: answers,
    );
  }

  static HistoricalQuestionSnapshot? _snapshotFromMap(
    Map<String, dynamic> data,
  ) {
    final questionId = (data['questionId'] as String?)?.trim() ?? '';
    final text = (data['text'] as String?)?.trim() ?? '';
    final correctOption = (data['correctOption'] as String?)?.trim() ?? '';
    if (questionId.isEmpty || text.isEmpty || correctOption.isEmpty) {
      return null;
    }

    final options = <HistoricalQuestionOption>[];
    final rawOptions = data['options'];
    if (rawOptions is List) {
      for (final option in rawOptions) {
        if (option is Map) {
          final label = (option['label'] as String?)?.trim() ?? '';
          final optionText = (option['text'] as String?)?.trim() ?? '';
          if (label.isEmpty || optionText.isEmpty) continue;
          options.add(HistoricalQuestionOption(label: label, text: optionText));
        } else if (option is String && option.trim().isNotEmpty) {
          options.add(
            HistoricalQuestionOption(
              label: String.fromCharCode(65 + options.length),
              text: option.trim(),
            ),
          );
        }
      }
    }

    return HistoricalQuestionSnapshot(
      questionId: questionId,
      text: text,
      options: options,
      correctOption: correctOption.toUpperCase(),
      explanation: _optionalTrimmed(data['explanation'] as String?),
      position: asInt(data['position']),
    );
  }

  static HistoricalAnswerRecord? _answerFromMap(Map<String, dynamic> data) {
    final questionId = (data['questionId'] as String?)?.trim() ?? '';
    if (questionId.isEmpty) return null;
    final selected = _optionalTrimmed(data['selectedOption'] as String?);
    final answered = data['answered'] == true ||
        (selected != null && selected.isNotEmpty);
    return HistoricalAnswerRecord(
      questionId: questionId,
      selectedOption: selected,
      answered: answered,
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
