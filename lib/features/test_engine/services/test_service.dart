import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../progress/services/progress_service.dart';
import '../../question_bank/data/models/question_models.dart';
import '../../question_bank/data/services/question_service.dart';
import '../../revision/services/revision_service.dart';
import '../data/mappers/question_bank_mapper.dart';
import '../data/models/test_engine_models.dart';
import '../data/repositories/test_repository.dart';
import '../data/test_engine_defaults.dart';
import '../repository/test_attempt_cloud_repository.dart';

/// Core Test Attempt Engine service.
///
/// One engine for practice, topic/section/paper tests, mocks, and PYPs.
/// Question content is always requested from the Question Bank.
class TestService {
  TestService({
    TestRepository? repository,
    QuestionService? questionService,
    TestAttemptCloudRepository? attemptCloudRepository,
  }) : _repository = repository ?? TestRepository.instance,
       _questionService = questionService ?? QuestionService.instance,
       _attemptCloud =
           attemptCloudRepository ?? TestAttemptCloudRepository();

  final TestRepository _repository;
  final QuestionService _questionService;
  final TestAttemptCloudRepository _attemptCloud;

  /// Optional hook after submit (e.g. progress credit). Cleared after run.
  void Function(TestResult result)? onCompleted;

  /// Dedupes cloud saves if [submitTest] is invoked more than once on this
  /// instance (controller already guards UI double-submit).
  String? _cloudSavedAttemptKey;

  Future<Test> loadTest(String testId) => _repository.loadTest(testId);

  Future<Test> prepareTest(Test test) => _repository.loadOrCache(test);

  /// Builds a configured test by requesting questions from the Question Bank.
  Future<Test> createConfiguredTest({
    required String id,
    required String title,
    required String courseId,
    required TestMode mode,
    required Duration duration,
    required int totalQuestions,
    required int totalMarks,
    double negativeMarks = 0.25,
    String? paperId,
    String? sectionId,
    String? topicId,
    List<String>? instructions,
    bool shuffleOptions = false,
  }) async {
    final bankQuestions = await _questionService.getQuestionsForTest(
      count: totalQuestions,
      courseId: courseId,
      paperId: paperId,
      sectionId: sectionId,
      topicId: topicId,
      questionType: QuestionBankMapper.questionTypeForMode(mode),
      shuffleOptionOrder: shuffleOptions,
    );

    final questions = QuestionBankMapper.toTestQuestions(bankQuestions);

    final test = Test(
      id: id,
      title: title,
      courseId: courseId,
      paperId: paperId,
      sectionId: sectionId,
      topicId: topicId,
      duration: duration,
      totalQuestions: questions.length,
      totalMarks: totalMarks,
      negativeMarks: negativeMarks,
      instructions: instructions ?? TestEngineDefaults.instructions,
      mode: mode,
      questions: questions,
    );

    await _repository.loadOrCache(test);
    return test;
  }

  /// Builds a test from explicit Question Bank questions (e.g. Revision).
  Future<Test> createTestFromQuestions({
    required String id,
    required String title,
    required String courseId,
    required List<Question> questions,
    TestMode mode = TestMode.practice,
    Duration? duration,
    double negativeMarks = 0.25,
    List<String>? instructions,
  }) async {
    final mapped = QuestionBankMapper.toTestQuestions(questions);

    // Use bank marks when present.
    var totalMarks = 0.0;
    for (final question in questions) {
      totalMarks += question.marks;
    }
    if (totalMarks <= 0) totalMarks = mapped.length.toDouble();

    final seconds = questions.fold<int>(
      0,
      (sum, q) => sum + q.estimatedTime.inSeconds,
    );
    final resolvedDuration = duration ??
        Duration(seconds: seconds.clamp(60, 45 * 60));

    final test = Test(
      id: id,
      title: title,
      courseId: courseId,
      paperId: questions.isEmpty ? null : questions.first.paperId,
      sectionId: questions.isEmpty ? null : questions.first.sectionId,
      topicId: questions.isEmpty ? null : questions.first.topicId,
      duration: resolvedDuration,
      totalQuestions: mapped.length,
      totalMarks: totalMarks.round(),
      negativeMarks: negativeMarks,
      instructions: instructions ?? TestEngineDefaults.instructions,
      mode: mode,
      questions: mapped,
    );

    await _repository.loadOrCache(test);
    return test;
  }

  Future<Test> createTestFromQuestionIds({
    required String id,
    required String title,
    required String courseId,
    required List<String> questionIds,
    TestMode mode = TestMode.practice,
    Duration? duration,
    int? totalMarks,
    double negativeMarks = 0.25,
    List<String>? instructions,
    bool requireCompleteSet = false,
    bool requireCourseMatch = false,
    int? expectedCount,
  }) async {
    if (requireCompleteSet && questionIds.isEmpty) {
      throw StateError(
        'Test configuration is invalid: questionIds must not be empty.',
      );
    }

    if (expectedCount != null && questionIds.length != expectedCount) {
      throw StateError(
        'Test configuration is invalid: questionIds length '
        '(${questionIds.length}) does not match questionCount ($expectedCount).',
      );
    }

    final questions = await _questionService.getByIds(questionIds);

    if (requireCompleteSet) {
      if (questions.length != questionIds.length) {
        throw StateError(
          'Test configuration is invalid: one or more assigned questions '
          'are missing.',
        );
      }
      for (var i = 0; i < questionIds.length; i++) {
        if (questions[i].id != questionIds[i]) {
          throw StateError(
            'Test configuration is invalid: one or more assigned questions '
            'are missing.',
          );
        }
      }
    }

    if (requireCourseMatch) {
      for (final question in questions) {
        if (question.courseId != courseId) {
          throw StateError(
            'Test configuration is invalid: assigned questions must belong '
            'to the same course as the test.',
          );
        }
      }
    }

    // Catalog fixed path: honor configured totalMarks / duration.
    if (totalMarks != null && duration != null) {
      final mapped = QuestionBankMapper.toTestQuestions(questions);
      final test = Test(
        id: id,
        title: title,
        courseId: courseId,
        paperId: questions.isEmpty ? null : questions.first.paperId,
        sectionId: questions.isEmpty ? null : questions.first.sectionId,
        topicId: questions.isEmpty ? null : questions.first.topicId,
        duration: duration,
        totalQuestions: mapped.length,
        totalMarks: totalMarks,
        negativeMarks: negativeMarks,
        instructions: instructions ?? TestEngineDefaults.instructions,
        mode: mode,
        questions: mapped,
      );
      await _repository.loadOrCache(test);
      return test;
    }

    return createTestFromQuestions(
      id: id,
      title: title,
      courseId: courseId,
      questions: questions,
      mode: mode,
      duration: duration,
      negativeMarks: negativeMarks,
      instructions: instructions,
    );
  }

  List<QuestionAttempt> startTest(Test test) {
    return [
      for (final question in test.questions)
        QuestionAttempt(questionId: question.id),
    ];
  }

  void saveAnswer({
    required QuestionAttempt attempt,
    required String? optionLabel,
  }) {
    attempt.selectedOption = optionLabel;
    attempt.answered = optionLabel != null;
    attempt.visited = true;
  }

  void clearResponse(QuestionAttempt attempt) {
    attempt.selectedOption = null;
    attempt.answered = false;
    attempt.visited = true;
  }

  void bookmarkQuestion(QuestionAttempt attempt, {bool? value}) {
    attempt.bookmarked = value ?? !attempt.bookmarked;
    attempt.visited = true;
    unawaited(
      _questionService.setBookmarked(
        attempt.questionId,
        value: attempt.bookmarked,
      ),
    );
  }

  void markReview(QuestionAttempt attempt, {bool? value}) {
    attempt.markedForReview = value ?? !attempt.markedForReview;
    attempt.visited = true;
  }

  void markVisited(QuestionAttempt attempt) {
    attempt.visited = true;
  }

  void addTimeSpent(QuestionAttempt attempt, int seconds) {
    if (seconds <= 0) return;
    attempt.timeSpent += seconds;
  }

  int navigateNext(int currentIndex, int total) {
    if (currentIndex >= total - 1) return currentIndex;
    return currentIndex + 1;
  }

  int navigatePrevious(int currentIndex) {
    if (currentIndex <= 0) return 0;
    return currentIndex - 1;
  }

  int navigateTo(int index, int total) {
    if (total <= 0) return 0;
    return index.clamp(0, total - 1);
  }

  TestResult calculateScore({
    required Test test,
    required List<QuestionAttempt> attempts,
    required Duration timeTaken,
  }) {
    final byId = {
      for (final question in test.questions) question.id: question,
    };

    var correct = 0;
    var wrong = 0;
    var attempted = 0;

    for (final attempt in attempts) {
      final question = byId[attempt.questionId];
      if (question == null) continue;
      if (!attempt.answered || attempt.selectedOption == null) continue;

      attempted++;
      if (attempt.selectedOption == question.correctOption) {
        correct++;
      } else {
        wrong++;
      }
    }

    final skipped = test.totalQuestions - attempted;
    final marksPerQuestion =
        test.totalQuestions == 0 ? 0.0 : test.totalMarks / test.totalQuestions;
    final score = (correct * marksPerQuestion) - (wrong * test.negativeMarks);
    final clampedScore = score < 0 ? 0.0 : score;
    final accuracy = attempted == 0 ? 0.0 : (correct / attempted) * 100;
    final percentage =
        test.totalMarks == 0 ? 0.0 : (clampedScore / test.totalMarks) * 100;
    final passed = percentage >= 40;

    return TestResult(
      totalQuestions: test.totalQuestions,
      attempted: attempted,
      correct: correct,
      wrong: wrong,
      skipped: skipped,
      score: double.parse(clampedScore.toStringAsFixed(2)),
      accuracy: double.parse(accuracy.toStringAsFixed(1)),
      percentage: double.parse(percentage.toStringAsFixed(1)),
      timeTaken: timeTaken,
      passed: passed,
    );
  }

  TestAnalysis generateAnalysis({
    required Test test,
    required List<QuestionAttempt> attempts,
  }) {
    final attemptByQ = {
      for (final attempt in attempts) attempt.questionId: attempt,
    };

    final reviews = <QuestionReviewItem>[
      for (final question in test.questions)
        QuestionReviewItem(
          question: question,
          attempt: attemptByQ[question.id] ??
              QuestionAttempt(questionId: question.id),
          isCorrect: attemptByQ[question.id]?.answered == true &&
              attemptByQ[question.id]?.selectedOption ==
                  question.correctOption,
        ),
    ];

    List<AreaPerformance> groupBy(
      String? Function(TestQuestion q) keyOf,
      String Function(String id) labelOf,
    ) {
      final totals = <String, int>{};
      final corrects = <String, int>{};

      for (final question in test.questions) {
        final key = keyOf(question);
        if (key == null || key.isEmpty) continue;
        totals[key] = (totals[key] ?? 0) + 1;
        final attempt = attemptByQ[question.id];
        if (attempt != null &&
            attempt.answered &&
            attempt.selectedOption == question.correctOption) {
          corrects[key] = (corrects[key] ?? 0) + 1;
        }
      }

      final items = totals.entries
          .map(
            (e) => AreaPerformance(
              id: e.key,
              label: labelOf(e.key),
              correct: corrects[e.key] ?? 0,
              total: e.value,
            ),
          )
          .toList()
        ..sort((a, b) => a.label.compareTo(b.label));
      return items;
    }

    final byPaper = groupBy(
      (q) => q.paperId,
      (id) => 'Paper ${id.replaceAll('paper-', '')}',
    );
    final bySection = groupBy(
      (q) => q.sectionId,
      (id) => 'Section ${id.replaceAll('section-', '')}',
    );
    final byTopic = groupBy(
      (q) => q.topicId,
      (id) => 'Topic ${id.replaceAll('topic-', '')}',
    );

    final ranked = [...byTopic]
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    final weakAreas = ranked.take(3).where((a) => a.total > 0).toList();
    final strongAreas =
        ranked.reversed.take(3).where((a) => a.total > 0).toList();

    return TestAnalysis(
      byPaper: byPaper,
      bySection: bySection,
      byTopic: byTopic,
      weakAreas: weakAreas,
      strongAreas: strongAreas,
      reviews: reviews,
    );
  }

  Future<TestResult> submitTest({
    required Test test,
    required List<QuestionAttempt> attempts,
    required Duration timeTaken,
  }) async {
    final result = calculateScore(
      test: test,
      attempts: attempts,
      timeTaken: timeTaken,
    );
    await _repository.submitAttempt(
      testId: test.id,
      attempts: attempts,
      result: result,
    );
    await ProgressService.instance.recordTestAttempt(
      test: test,
      result: result,
      attempts: attempts,
    );
    // Mirror revision lists (wrong / weak / frequent) without blocking submit.
    RevisionService.instance.scheduleCloudSync(courseId: test.courseId);

    // Best-effort Firestore persistence — never blocks or alters the result.
    await _persistAttemptToCloud(
      test: test,
      result: result,
      attempts: attempts,
      timeTaken: timeTaken,
    );

    onCompleted?.call(result);
    onCompleted = null;
    return result;
  }

  /// Best-effort cloud persist used by [submitTest]. Exposed for unit tests.
  @visibleForTesting
  Future<void> persistCompletedAttemptToCloud({
    required Test test,
    required TestResult result,
    required List<QuestionAttempt> attempts,
    required Duration timeTaken,
  }) {
    return _persistAttemptToCloud(
      test: test,
      result: result,
      attempts: attempts,
      timeTaken: timeTaken,
    );
  }

  Future<void> _persistAttemptToCloud({
    required Test test,
    required TestResult result,
    required List<QuestionAttempt> attempts,
    required Duration timeTaken,
  }) async {
    final dedupeKey = '${test.id}:${result.score}:${timeTaken.inSeconds}';
    if (_cloudSavedAttemptKey == dedupeKey) {
      debugPrint(
        'TestService: skipping duplicate cloud attempt save for $dedupeKey',
      );
      return;
    }

    final saveResult = await _attemptCloud.saveCompletedAttempt(
      test: test,
      result: result,
      attempts: attempts,
      timeTaken: timeTaken,
    );

    if (saveResult.success) {
      _cloudSavedAttemptKey = dedupeKey;
      debugPrint(
        'TestService: saved test attempt ${saveResult.attemptId} to Firestore',
      );
      return;
    }

    debugPrint(
      'TestService: Firestore attempt save failed '
      '(result screen unchanged): ${saveResult.error}',
    );
  }

  Future<void> saveProgress({
    required String testId,
    required List<QuestionAttempt> attempts,
  }) {
    return _repository.saveAttempt(testId: testId, attempts: attempts);
  }

  Map<QuestionStatus, int> statusCounts(List<QuestionAttempt> attempts) {
    var answered = 0;
    var notAnswered = 0;
    var marked = 0;
    var notVisited = 0;

    for (final attempt in attempts) {
      switch (attempt.status) {
        case QuestionStatus.answered:
          answered++;
          break;
        case QuestionStatus.notAnswered:
          notAnswered++;
          break;
        case QuestionStatus.markedForReview:
          marked++;
          break;
        case QuestionStatus.notVisited:
          notVisited++;
          break;
      }
    }

    return {
      QuestionStatus.answered: answered,
      QuestionStatus.notAnswered: notAnswered,
      QuestionStatus.markedForReview: marked,
      QuestionStatus.notVisited: notVisited,
    };
  }
}
