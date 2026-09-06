import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../progress/services/progress_service.dart';
import '../../question_activity/data/question_activity_context_factory.dart';
import '../../question_activity/data/models/question_activity_models.dart';
import '../../question_activity/services/question_activity_reporter.dart';
import '../../question_bank/data/models/question_models.dart';
import '../../question_bank/data/services/question_service.dart';
import '../../revision/services/revision_service.dart';
import '../data/mappers/question_bank_mapper.dart';
import '../data/models/test_engine_models.dart';
import '../data/repositories/test_repository.dart';
import '../data/test_attempt_api.dart';
import '../data/test_engine_defaults.dart';
import '../repository/test_attempt_cloud_repository.dart';

/// Core Test Attempt Engine service.
///
/// One engine for practice, topic/section/paper tests, mocks, and PYPs.
/// Question content is always requested from the Question Bank.
///
/// Catalog tests use server-authoritative start/submit callables.
/// Local practice sessions may still score on-device for UX, but must not
/// write authoritative `test_attempts` score documents from the client.
class TestService {
  TestService({
    TestRepository? repository,
    QuestionService? questionService,
    TestAttemptCloudRepository? attemptCloudRepository,
    TestAttemptApi? attemptApi,
    QuestionActivityReporter? questionActivityReporter,
  }) : _repository = repository ?? TestRepository.instance,
       _questionService = questionService ?? QuestionService.instance,
       _attemptCloud = attemptCloudRepository ?? TestAttemptCloudRepository(),
       _attemptApiOverride = attemptApi,
       _questionActivity =
           questionActivityReporter ?? QuestionActivityReporter.instance;

  final TestRepository _repository;
  final QuestionService _questionService;
  final TestAttemptCloudRepository _attemptCloud;
  final QuestionActivityReporter _questionActivity;
  TestAttemptApi? _attemptApiOverride;

  TestAttemptApi get _attemptApi => _attemptApiOverride ??= TestAttemptApi();

  /// Optional hook after submit (e.g. progress credit). Cleared after run.
  void Function(TestResult result)? onCompleted;

  /// Server attempt id from [startServerAttempt]. Required for catalog submit.
  String? serverAttemptId;

  /// Dedupes cloud saves if [submitTest] is invoked more than once on this
  /// instance (controller already guards UI double-submit).
  String? _cloudSavedAttemptKey;

  /// Stable per TestService instance — reused across submit retries.
  String? _questionActivitySessionId;

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
    String? partId,
    String? lessonId,
    String? majorStudyAreaId,
    String? contentTopicId,
    String? syllabusUnitId,
    List<String>? instructions,
    bool shuffleOptions = false,
  }) async {
    final bankQuestions = await _questionService.getQuestionsForTest(
      count: totalQuestions,
      courseId: courseId,
      paperId: paperId,
      sectionId: sectionId,
      topicId: topicId,
      partId: partId,
      lessonId: lessonId,
      majorStudyAreaId: majorStudyAreaId,
      contentTopicId: contentTopicId,
      syllabusUnitId: syllabusUnitId,
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
      partId: partId,
      lessonId: lessonId,
      majorStudyAreaId: majorStudyAreaId,
      contentTopicId: contentTopicId,
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
    final resolvedDuration =
        duration ?? Duration(seconds: seconds.clamp(60, 45 * 60));
    String? shared(Iterable<String?> values) {
      final list = values.toList(growable: false);
      if (list.isEmpty) return null;
      final first = list.first?.trim();
      if (first == null || first.isEmpty) return null;
      for (final value in list.skip(1)) {
        if ((value ?? '').trim() != first) return null;
      }
      return first;
    }

    final sharedSyllabus = (
      partId: shared(questions.map((q) => q.partId)),
      lessonId: shared(questions.map((q) => q.lessonId)),
      majorStudyAreaId: shared(questions.map((q) => q.majorStudyAreaId)),
      contentTopicId: shared(questions.map((q) => q.contentTopicId)),
    );

    final test = Test(
      id: id,
      title: title,
      courseId: courseId,
      paperId: shared(questions.map((q) => q.paperId)),
      sectionId: shared(questions.map((q) => q.sectionId)),
      topicId: shared(questions.map((q) => q.topicId)),
      partId: sharedSyllabus.partId,
      lessonId: sharedSyllabus.lessonId,
      majorStudyAreaId: sharedSyllabus.majorStudyAreaId,
      contentTopicId: sharedSyllabus.contentTopicId,
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

  Future<Test> createTestFromStudentSafeQuestions({
    required String id,
    required String title,
    required String courseId,
    required List<Map<String, dynamic>> studentQuestions,
    TestMode mode = TestMode.practice,
    Duration? duration,
    int? totalMarks,
    double negativeMarks = 0.25,
    List<String>? instructions,
  }) async {
    if (studentQuestions.isEmpty) {
      throw StateError(
        'Test configuration is invalid: studentQuestions must not be empty.',
      );
    }

    final mapped = <TestQuestion>[
      for (final raw in studentQuestions)
        _testQuestionFromStudentSafe(raw, courseId),
    ];

    String? shared(Iterable<String?> values) {
      final list = values.toList(growable: false);
      if (list.isEmpty) return null;
      final first = list.first?.trim();
      if (first == null || first.isEmpty) return null;
      for (final value in list.skip(1)) {
        if ((value ?? '').trim() != first) return null;
      }
      return first;
    }

    final test = Test(
      id: id,
      title: title,
      courseId: courseId,
      paperId: shared(mapped.map((q) => q.paperId)),
      partId: shared(mapped.map((q) => q.partId)),
      duration: duration ?? Duration(minutes: mapped.length.clamp(1, 180)),
      totalQuestions: mapped.length,
      totalMarks: totalMarks ?? mapped.length,
      negativeMarks: negativeMarks,
      instructions: instructions ?? TestEngineDefaults.instructions,
      mode: mode,
      questions: mapped,
    );
    await _repository.loadOrCache(test);
    return test;
  }

  TestQuestion _testQuestionFromStudentSafe(
    Map<String, dynamic> raw,
    String courseId,
  ) {
    final questionId = (raw['questionId'] as String?)?.trim() ?? '';
    if (questionId.isEmpty) {
      throw StateError('Student-safe question missing questionId.');
    }
    final text = (raw['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      throw StateError('Student-safe question missing text.');
    }
    final optionsRaw = raw['options'];
    if (optionsRaw is! List || optionsRaw.isEmpty) {
      throw StateError('Student-safe question missing options.');
    }

    // Same bilingual convention as QuestionBankMapper: content.te + option.teluguText.
    final content = _contentFromStudentSafe(raw['content']);
    final teluguOptions = content?.te?.options;

    final options = <TestOption>[];
    for (var i = 0; i < optionsRaw.length; i++) {
      final option = optionsRaw[i];
      if (option is! Map) continue;
      final label = (option['label']?.toString() ?? '').trim().toUpperCase();
      final optionText = (option['text']?.toString() ?? '').trim();
      if (label.isEmpty || optionText.isEmpty) continue;

      String? teluguText = (option['teluguText']?.toString() ?? '').trim();
      if (teluguText.isEmpty) {
        teluguText = null;
      }
      if (teluguText == null &&
          teluguOptions != null &&
          i < teluguOptions.length) {
        final fromContent = teluguOptions[i].text.trim();
        teluguText = fromContent.isEmpty ? null : fromContent;
      }

      options.add(
        TestOption(label: label, text: optionText, teluguText: teluguText),
      );
    }
    if (options.length < 2) {
      throw StateError('Student-safe question has invalid options.');
    }

    final paperId = (raw['paperId'] as String?)?.trim();
    final partId = (raw['partId'] as String?)?.trim();
    final syllabusUnitId = (raw['syllabusUnitId'] as String?)?.trim();
    final majorStudyAreaId = (raw['majorStudyAreaId'] as String?)?.trim();
    final contentTopicId = (raw['contentTopicId'] as String?)?.trim();
    final resolvedCourseId =
        (raw['courseId'] as String?)?.trim().isNotEmpty == true
        ? (raw['courseId'] as String).trim()
        : courseId;

    return TestQuestion(
      id: questionId,
      text: text,
      options: options,
      // Answer key is server-only until submit; placeholder is unused for scoring.
      correctOption: '',
      explanation: '',
      paperId: paperId,
      content: content,
      syllabus: QuestionSyllabusAttribution(
        courseId: resolvedCourseId,
        paperId: paperId ?? '',
        partId: partId,
        syllabusUnitId: syllabusUnitId,
        majorStudyAreaId: majorStudyAreaId,
        contentTopicId: contentTopicId,
      ),
    );
  }

  /// Parses snapshot `content` using the same shape as Question Bank documents.
  QuestionContent? _contentFromStudentSafe(dynamic raw) {
    if (raw is! Map) return null;
    final en = _localizedFromStudentSafe(raw['en']);
    if (en == null) return null;
    return QuestionContent(en: en, te: _localizedFromStudentSafe(raw['te']));
  }

  QuestionLocalizedContent? _localizedFromStudentSafe(dynamic raw) {
    if (raw is! Map) return null;
    final question = (raw['question'] as String?)?.trim() ?? '';
    if (question.isEmpty) return null;
    final optionsRaw = raw['options'];
    final options = <QuestionOption>[];
    if (optionsRaw is List) {
      for (final option in optionsRaw) {
        if (option is String) {
          final text = option.trim();
          if (text.isNotEmpty) options.add(QuestionOption(text: text));
        } else if (option is Map) {
          final text = (option['text']?.toString() ?? '').trim();
          if (text.isNotEmpty) options.add(QuestionOption(text: text));
        }
      }
    }
    final statements = <String>[];
    final statementsRaw = raw['statements'];
    if (statementsRaw is List) {
      for (final item in statementsRaw) {
        final text = item?.toString().trim() ?? '';
        if (text.isNotEmpty) statements.add(text);
      }
    }
    return QuestionLocalizedContent(
      question: question,
      options: options,
      // Attempt snapshots intentionally omit explanations until reveal.
      explanation: (raw['explanation'] as String?)?.trim() ?? '',
      statements: statements,
    );
  }

  /// Applies post-submit revealed snapshots so in-session analysis uses frozen keys.
  void applyRevealedQuestionSnapshots(
    Test test,
    List<Map<String, dynamic>> snapshots,
  ) {
    if (snapshots.isEmpty) return;
    final byId = {
      for (final raw in snapshots)
        if ((raw['questionId'] as String?)?.trim().isNotEmpty == true)
          (raw['questionId'] as String).trim(): raw,
    };
    for (var i = 0; i < test.questions.length; i++) {
      final current = test.questions[i];
      final raw = byId[current.id];
      if (raw == null) continue;
      final correct = (raw['correctOption'] as String?)?.trim().toUpperCase();
      final explanation = (raw['explanation'] as String?)?.trim() ?? '';
      if (correct == null || correct.isEmpty) continue;
      final optionsRaw = raw['options'];
      var options = current.options;
      if (optionsRaw is List && optionsRaw.isNotEmpty) {
        final teluguFromContent = current.content?.te?.options;
        final parsed = <TestOption>[];
        for (var oi = 0; oi < optionsRaw.length; oi++) {
          final option = optionsRaw[oi];
          if (option is! Map) continue;
          final label =
              (option['label']?.toString() ?? '').trim().toUpperCase();
          final optionText = (option['text']?.toString() ?? '').trim();
          if (label.isEmpty || optionText.isEmpty) continue;

          // Preserve Telugu across reveal: raw → prior option → content.te.
          String? teluguText;
          final fromRaw = (option['teluguText']?.toString() ?? '').trim();
          if (fromRaw.isNotEmpty) {
            teluguText = fromRaw;
          } else if (oi < current.options.length) {
            final fromCurrent = current.options[oi].teluguText?.trim();
            if (fromCurrent != null && fromCurrent.isNotEmpty) {
              teluguText = fromCurrent;
            }
          }
          if (teluguText == null &&
              teluguFromContent != null &&
              oi < teluguFromContent.length) {
            final fromContent = teluguFromContent[oi].text.trim();
            if (fromContent.isNotEmpty) teluguText = fromContent;
          }

          parsed.add(
            TestOption(
              label: label,
              text: optionText,
              teluguText: teluguText,
            ),
          );
        }
        if (parsed.length >= 2) options = parsed;
      }
      test.questions[i] = TestQuestion(
        id: current.id,
        text: (raw['text'] as String?)?.trim().isNotEmpty == true
            ? (raw['text'] as String).trim()
            : current.text,
        options: options,
        correctOption: correct,
        explanation: explanation,
        paperId: current.paperId,
        sectionId: current.sectionId,
        topicId: current.topicId,
        content: current.content,
        syllabus: current.syllabus,
      );
    }
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
    // Test-level hierarchy is shared-only; mixed tests keep nulls.
    if (totalMarks != null && duration != null) {
      final mapped = QuestionBankMapper.toTestQuestions(questions);
      String? shared(Iterable<String?> values) {
        final list = values.toList(growable: false);
        if (list.isEmpty) return null;
        final first = list.first?.trim();
        if (first == null || first.isEmpty) return null;
        for (final value in list.skip(1)) {
          if ((value ?? '').trim() != first) return null;
        }
        return first;
      }

      final test = Test(
        id: id,
        title: title,
        courseId: courseId,
        paperId: shared(questions.map((q) => q.paperId)),
        sectionId: shared(questions.map((q) => q.sectionId)),
        topicId: shared(questions.map((q) => q.topicId)),
        partId: shared(questions.map((q) => q.partId)),
        lessonId: shared(questions.map((q) => q.lessonId)),
        majorStudyAreaId: shared(questions.map((q) => q.majorStudyAreaId)),
        contentTopicId: shared(questions.map((q) => q.contentTopicId)),
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
    final byId = {for (final question in test.questions) question.id: question};

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
    final marksPerQuestion = test.totalQuestions == 0
        ? 0.0
        : test.totalMarks / test.totalQuestions;
    final score = (correct * marksPerQuestion) - (wrong * test.negativeMarks);
    final clampedScore = score < 0 ? 0.0 : score;
    final accuracy = attempted == 0 ? 0.0 : (correct / attempted) * 100;
    final percentage = test.totalMarks == 0
        ? 0.0
        : (clampedScore / test.totalMarks) * 100;
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
          attempt:
              attemptByQ[question.id] ??
              QuestionAttempt(questionId: question.id),
          isCorrect:
              attemptByQ[question.id]?.answered == true &&
              attemptByQ[question.id]?.selectedOption == question.correctOption,
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

      final items =
          totals.entries
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
    final strongAreas = ranked.reversed
        .take(3)
        .where((a) => a.total > 0)
        .toList();

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
    final TestResult result;
    final attemptId = serverAttemptId?.trim();

    if (attemptId != null && attemptId.isNotEmpty) {
      result = await _submitServerAttempt(
        attemptId: attemptId,
        attempts: attempts,
        timeTaken: timeTaken,
      );
      final revealed = _pendingRevealedSnapshots;
      if (revealed != null && revealed.isNotEmpty) {
        applyRevealedQuestionSnapshots(test, revealed);
        _pendingRevealedSnapshots = null;
      }
    } else {
      // Local practice / non-catalog path: score on device for UX only.
      // Do NOT write authoritative test_attempts from the client.
      result = calculateScore(
        test: test,
        attempts: attempts,
        timeTaken: timeTaken,
      );
    }

    await _repository.submitAttempt(
      testId: test.id,
      attempts: attempts,
      result: result,
    );

    final isServerCatalog = attemptId != null && attemptId.isNotEmpty;
    if (isServerCatalog) {
      // Phase 5.21: authoritative progress/revision applied by backend from
      // the verified attempt. Do not mirror forgeable analytics from the client.
    } else {
      // Practice / non-catalog: local session UX only. Cloud writes are denied
      // by rules; sync failures are swallowed by ProgressService/RevisionService.
      await ProgressService.instance.recordTestAttempt(
        test: test,
        result: result,
        attempts: attempts,
      );
      RevisionService.instance.scheduleCloudSync(courseId: test.courseId);
    }

    // Shared activity boundary: encounter context under global question IDs.
    // Catalog revision is already applied by submitTestAttempt.
    // Practice / revision practice also dispatch verified reportQuestionActivity.
    await _reportWrongActivity(
      test: test,
      attempts: attempts,
      isServerCatalog: isServerCatalog,
    );

    onCompleted?.call(result);
    onCompleted = null;
    return result;
  }

  String _ensureQuestionActivitySessionId() {
    return _questionActivitySessionId ??=
        's${DateTime.now().microsecondsSinceEpoch}_${Object().hashCode.abs()}';
  }

  Future<void> _reportWrongActivity({
    required Test test,
    required List<QuestionAttempt> attempts,
    required bool isServerCatalog,
  }) async {
    final byId = {
      for (final question in test.questions) question.id: question,
    };
    final wrongAttempts = <QuestionAttempt>[];
    for (final attempt in attempts) {
      final question = byId[attempt.questionId];
      if (question == null) continue;
      if (!attempt.answered || attempt.selectedOption == null) continue;
      if (attempt.selectedOption == question.correctOption) continue;
      wrongAttempts.add(attempt);
    }
    if (wrongAttempts.isEmpty) return;

    if (isServerCatalog) {
      final contexts = [
        for (final attempt in wrongAttempts)
          QuestionActivityContextFactory.fromTest(
            test,
            questionId: attempt.questionId,
            encounterId: serverAttemptId,
          ),
      ];
      _questionActivity.reportWrongAnswers(
        contexts: contexts,
        authority: QuestionActivityAuthority.serverVerified,
      );
      return;
    }

    final sessionId = _ensureQuestionActivitySessionId();
    final submissions = <QuestionActivityWrongSubmission>[
      for (final attempt in wrongAttempts)
        QuestionActivityWrongSubmission(
          activityEventId: QuestionActivityReporter.activityEventIdFor(
            activitySessionId: sessionId,
            questionId: attempt.questionId,
          ),
          selectedOption: attempt.selectedOption!.trim(),
          context: QuestionActivityContextFactory.fromTest(
            test,
            questionId: attempt.questionId,
            encounterId: sessionId,
          ),
        ),
    ];

    // LOCAL ACTIVITY RECORDED + optional SERVER AUTHORITATIVE PERSISTED.
    // Failures are returned in results; submit UX still completes.
    final results = await _questionActivity.reportAndPersistWrongAnswers(
      submissions: submissions,
    );
    final failed = results
        .where((r) => r.state == QuestionActivityPersistState.serverFailed)
        .length;
    if (failed > 0) {
      debugPrint(
        'TestService: $failed practice wrong(s) failed verified activity persist',
      );
    }
  }

  /// Stable unique key for one Start Test action (retries reuse the same key).
  static String newStartRequestId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final entropy = Object().hashCode.abs();
    return 'start_${now}_$entropy';
  }

  /// Starts a server-authored attempt for a published catalog test.
  Future<Map<String, dynamic>> startServerAttempt({
    required String testId,
    required String startRequestId,
  }) {
    return _attemptApi.startTestAttempt(
      testId: testId,
      startRequestId: startRequestId,
    );
  }

  Future<TestResult> _submitServerAttempt({
    required String attemptId,
    required List<QuestionAttempt> attempts,
    required Duration timeTaken,
  }) async {
    final selectedAnswers = <Map<String, String>>[
      for (final attempt in attempts)
        if (attempt.answered &&
            attempt.selectedOption != null &&
            attempt.selectedOption!.trim().isNotEmpty)
          {
            'questionId': attempt.questionId,
            'selectedOption': attempt.selectedOption!.trim(),
          },
    ];

    final dedupeKey = '$attemptId:${selectedAnswers.length}';
    if (_cloudSavedAttemptKey == dedupeKey && _lastServerResult != null) {
      return _lastServerResult!;
    }

    final data = await _attemptApi.submitTestAttempt(
      attemptId: attemptId,
      selectedAnswers: selectedAnswers,
    );

    final snapshotsRaw = data['questionSnapshots'];
    if (snapshotsRaw is List) {
      _pendingRevealedSnapshots = [
        for (final item in snapshotsRaw)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    }

    final result = TestResult(
      totalQuestions:
          (data['totalQuestions'] as num?)?.toInt() ?? attempts.length,
      attempted: (data['attempted'] as num?)?.toInt() ?? 0,
      correct: (data['correct'] as num?)?.toInt() ?? 0,
      wrong: (data['wrong'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as num?)?.toInt() ?? 0,
      score: (data['score'] as num?)?.toDouble() ?? 0,
      accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0,
      percentage: (data['percentage'] as num?)?.toDouble() ?? 0,
      timeTaken: timeTaken,
      passed: data['passed'] == true,
      authority: (data['authority'] as String?) ?? 'server_verified',
      attemptId: attemptId,
    );

    _cloudSavedAttemptKey = dedupeKey;
    _lastServerResult = result;
    return result;
  }

  TestResult? _lastServerResult;
  List<Map<String, dynamic>>? _pendingRevealedSnapshots;

  /// Legacy helper retained for unit tests of mapper payloads only.
  /// Production catalog submits must not call this for authoritative scores.
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
    // Intentionally retained for legacy unit tests. Do not use for new
    // authoritative catalog submissions — Firestore rules deny client writes.
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
