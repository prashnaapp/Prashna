import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_activity/data/models/question_activity_models.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/repositories/test_repository.dart';
import 'package:telangana_prep/features/test_engine/presentation/controllers/test_engine_controller.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

/// Offline QuestionService stub — avoids live bank / Firebase.
class _NoopQuestionService extends QuestionService {
  @override
  Future<Question?> getById(String id) async => null;

  @override
  Future<void> setBookmarked(String questionId, {required bool value}) async {}
}

TestQuestion _tq(String id, String text) {
  return TestQuestion(
    id: id,
    text: text,
    options: const [
      TestOption(label: 'A', text: 'Option A'),
      TestOption(label: 'B', text: 'Option B'),
      TestOption(label: 'C', text: 'Option C'),
      TestOption(label: 'D', text: 'Option D'),
    ],
    correctOption: 'A',
    explanation: 'e',
  );
}

Test _buildTest({
  required String id,
  required List<TestQuestion> questions,
  String courseId = 'group-ii',
  TestMode mode = TestMode.topic,
  QuestionActivitySourceModule? module =
      QuestionActivitySourceModule.chapters,
  Duration duration = const Duration(minutes: 30),
}) {
  return Test(
    id: id,
    title: id,
    courseId: courseId,
    duration: duration,
    totalQuestions: questions.length,
    totalMarks: questions.length,
    negativeMarks: 0,
    instructions: const [],
    mode: mode,
    questions: questions,
    activitySourceModule: module,
  );
}

TestEngineController _controllerFor(Test test) {
  return TestEngineController(
    test: test,
    service: TestService(
      repository: TestRepository(),
      questionService: _NoopQuestionService(),
    ),
  );
}

Map<QuestionStatus, int> _counts(TestEngineController c) => c.statusCounts;

int _visitedCount(TestEngineController c) =>
    c.attempts.where((a) => a.visited).length;

void main() {
  group('TE-20 session initialization integrity', () {
    test('creates one attempt per question at index 0 without pre-visiting', () {
      final questions = [_tq('q1', 'One'), _tq('q2', 'Two'), _tq('q3', 'Three')];
      final controller = _controllerFor(
        _buildTest(id: 'init', questions: questions),
      );
      addTearDown(controller.dispose);

      expect(controller.attempts, hasLength(3));
      expect(controller.attempts.map((a) => a.questionId).toList(), [
        'q1',
        'q2',
        'q3',
      ]);
      expect(
        controller.attempts.map((a) => a.questionId).toSet(),
        hasLength(3),
      );
      expect(controller.currentIndex, 0);
      expect(controller.currentQuestion.id, 'q1');
      expect(controller.questionNumber, 1);
      expect(controller.started, isFalse);

      // Real contract: constructor does not call _enterCurrentQuestion / start().
      expect(controller.attempts.every((a) => !a.visited), isTrue);
      expect(
        _counts(controller)[QuestionStatus.notVisited],
        3,
      );
    });

    test('start() marks only the initial question visited', () async {
      final controller = _controllerFor(
        _buildTest(
          id: 'init-start',
          questions: [_tq('q1', 'One'), _tq('q2', 'Two'), _tq('q3', 'Three')],
        ),
      );
      addTearDown(controller.dispose);

      await controller.start();
      expect(controller.started, isTrue);
      expect(controller.attempts[0].visited, isTrue);
      expect(controller.attempts[1].visited, isFalse);
      expect(controller.attempts[2].visited, isFalse);
      expect(_visitedCount(controller), 1);
      expect(_counts(controller)[QuestionStatus.notVisited], 2);
      expect(_counts(controller)[QuestionStatus.notAnswered], 1);
    });

    test('empty questions: zero attempts; current accessors throw', () {
      final controller = _controllerFor(
        _buildTest(id: 'empty', questions: const []),
      );
      addTearDown(controller.dispose);

      expect(controller.attempts, isEmpty);
      expect(controller.currentIndex, 0);
      expect(controller.isFirst, isTrue);
      // length - 1 == -1 → isLast is true for empty collections.
      expect(controller.isLast, isTrue);
      expect(
        () => controller.currentQuestion,
        throwsA(isA<RangeError>()),
      );
      expect(
        () => controller.currentAttempt,
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('TE-21 question attempt initial state', () {
    test('fresh attempts have clean unset fields and notVisited status', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'initial-state',
          questions: [_tq('q1', 'One'), _tq('q2', 'Two')],
        ),
      );
      addTearDown(controller.dispose);

      for (final attempt in controller.attempts) {
        expect(attempt.selectedOption, isNull);
        expect(attempt.visited, isFalse);
        expect(attempt.answered, isFalse);
        expect(attempt.markedForReview, isFalse);
        expect(attempt.bookmarked, isFalse);
        expect(attempt.timeSpent, 0);
        expect(attempt.status, QuestionStatus.notVisited);
        // Must not report answered without a selection.
        expect(attempt.answered && attempt.selectedOption == null, isFalse);
      }
    });
  });

  group('TE-22 answer change integrity', () {
    test('changing option replaces prior answer and survives navigation', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'answer-change',
          questions: [_tq('q1', 'One'), _tq('q2', 'Two')],
        ),
      );
      addTearDown(controller.dispose);

      controller.selectOption('A');
      expect(controller.currentAttempt.selectedOption, 'A');
      expect(controller.currentAttempt.answered, isTrue);
      expect(_counts(controller)[QuestionStatus.answered], 1);

      controller.toggleMarkForReview();
      expect(controller.currentAttempt.markedForReview, isTrue);
      expect(
        controller.currentAttempt.status,
        QuestionStatus.markedForReview,
      );

      controller.selectOption('B');
      expect(controller.currentAttempt.selectedOption, 'B');
      expect(controller.currentAttempt.answered, isTrue);
      expect(controller.currentAttempt.markedForReview, isTrue);
      expect(
        controller.currentAttempt.status,
        QuestionStatus.markedForReview,
      );
      // Still one attempt row — no duplicate attempt objects.
      expect(controller.attempts, hasLength(2));
      expect(
        controller.attempts.where((a) => a.questionId == 'q1'),
        hasLength(1),
      );

      controller.goNext();
      controller.goPrevious();
      expect(controller.currentIndex, 0);
      expect(controller.currentAttempt.selectedOption, 'B');
      expect(controller.currentAttempt.answered, isTrue);
      expect(controller.currentAttempt.markedForReview, isTrue);
    });
  });

  group('TE-23 visited state integrity', () {
    test('navigation visits destination only; prior stays visited', () async {
      final controller = _controllerFor(
        _buildTest(
          id: 'visited',
          questions: [
            _tq('q1', 'One'),
            _tq('q2', 'Two'),
            _tq('q3', 'Three'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.attempts.every((a) => !a.visited), isTrue);

      await controller.start();
      expect(controller.attempts.map((a) => a.visited).toList(), [
        true,
        false,
        false,
      ]);

      controller.goNext();
      expect(controller.attempts.map((a) => a.visited).toList(), [
        true,
        true,
        false,
      ]);

      controller.goTo(2);
      expect(controller.currentIndex, 2);
      expect(controller.attempts.map((a) => a.visited).toList(), [
        true,
        true,
        true,
      ]);

      // Returning does not clear visited; unrelated already covered.
      controller.goTo(0);
      expect(controller.attempts.every((a) => a.visited), isTrue);
      expect(_visitedCount(controller), 3);
      expect(_counts(controller)[QuestionStatus.notVisited], 0);
    });
  });

  group('TE-24 question status matrix', () {
    test('status tracks visited/answer/review priority combinations', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'status-matrix',
          questions: [_tq('q1', 'One'), _tq('q2', 'Two')],
        ),
      );
      addTearDown(controller.dispose);

      // A. Not visited
      expect(controller.attempts[0].status, QuestionStatus.notVisited);

      // B. Visited but unanswered (clearResponse also marks visited)
      controller.goTo(0);
      expect(controller.currentAttempt.visited, isTrue);
      expect(controller.currentAttempt.answered, isFalse);
      expect(controller.currentAttempt.status, QuestionStatus.notAnswered);

      // C. Answered
      controller.selectOption('A');
      expect(controller.currentAttempt.status, QuestionStatus.answered);

      // D. Marked for review without answer
      controller.goTo(1);
      controller.toggleMarkForReview();
      expect(controller.currentAttempt.selectedOption, isNull);
      expect(controller.currentAttempt.answered, isFalse);
      expect(controller.currentAttempt.markedForReview, isTrue);
      expect(
        controller.currentAttempt.status,
        QuestionStatus.markedForReview,
      );

      // E. Marked for review with answer
      controller.selectOption('C');
      expect(controller.currentAttempt.answered, isTrue);
      expect(
        controller.currentAttempt.status,
        QuestionStatus.markedForReview,
      );

      // G. Answer changed while review active
      controller.selectOption('D');
      expect(controller.currentAttempt.selectedOption, 'D');
      expect(
        controller.currentAttempt.status,
        QuestionStatus.markedForReview,
      );

      // F. Review removed after answer → answered
      controller.toggleMarkForReview();
      expect(controller.currentAttempt.markedForReview, isFalse);
      expect(controller.currentAttempt.status, QuestionStatus.answered);
    });
  });

  group('TE-25 progress / count consistency', () {
    test('statusCounts follow QuestionAttempt.status semantics across transitions',
        () {
      final controller = _controllerFor(
        _buildTest(
          id: 'counts',
          questions: [
            _tq('q1', 'One'),
            _tq('q2', 'Two'),
            _tq('q3', 'Three'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.test.totalQuestions, 3);
      expect(controller.attempts, hasLength(3));
      expect(_counts(controller), {
        QuestionStatus.answered: 0,
        QuestionStatus.notAnswered: 0,
        QuestionStatus.markedForReview: 0,
        QuestionStatus.notVisited: 3,
      });

      // Answer Q1
      controller.selectOption('A');
      expect(_counts(controller)[QuestionStatus.answered], 1);
      expect(_counts(controller)[QuestionStatus.notVisited], 2);

      // Mark Q1 review — answered bucket loses it (status priority).
      controller.toggleMarkForReview();
      expect(_counts(controller)[QuestionStatus.markedForReview], 1);
      expect(_counts(controller)[QuestionStatus.answered], 0);
      expect(controller.attempts[0].answered, isTrue);

      // Navigate Q2 + answer
      controller.goNext();
      controller.selectOption('B');
      expect(_counts(controller)[QuestionStatus.answered], 1);
      expect(_counts(controller)[QuestionStatus.markedForReview], 1);
      expect(_counts(controller)[QuestionStatus.notVisited], 1);
      // Q2 entered via goNext → visited; if somehow unanswered would be notAnswered.
      expect(_visitedCount(controller), 2);

      // Remove review Q1
      controller.goPrevious();
      controller.toggleMarkForReview();
      expect(controller.attempts[0].markedForReview, isFalse);
      expect(_counts(controller)[QuestionStatus.answered], 2);
      expect(_counts(controller)[QuestionStatus.markedForReview], 0);

      // Change answer Q2
      controller.goNext();
      controller.selectOption('C');
      expect(controller.attempts[1].selectedOption, 'C');
      expect(_counts(controller)[QuestionStatus.answered], 2);
      expect(_counts(controller)[QuestionStatus.notVisited], 1);
      expect(
        _counts(controller).values.fold<int>(0, (a, b) => a + b),
        3,
      );
    });
  });

  group('TE-26 session isolation', () {
    test('new controller does not inherit prior session attempt fields', () {
      final questions = [_tq('shared-q1', 'Shared'), _tq('q2', 'Two')];
      final sessionA = _controllerFor(
        _buildTest(id: 'session-a', questions: questions),
      );
      addTearDown(sessionA.dispose);

      sessionA.selectOption('B');
      sessionA.toggleMarkForReview();
      sessionA.goNext();
      expect(sessionA.attempts[0].selectedOption, 'B');
      expect(sessionA.attempts[0].markedForReview, isTrue);
      expect(sessionA.attempts[0].visited, isTrue);
      expect(sessionA.attempts[1].visited, isTrue);

      final sessionB = _controllerFor(
        _buildTest(id: 'session-b', questions: questions),
      );
      addTearDown(sessionB.dispose);

      // Attempt/session state is per controller (startTest creates fresh rows).
      expect(sessionB.attempts[0].selectedOption, isNull);
      expect(sessionB.attempts[0].answered, isFalse);
      expect(sessionB.attempts[0].markedForReview, isFalse);
      expect(sessionB.attempts[0].visited, isFalse);
      expect(sessionB.attempts[1].visited, isFalse);
      expect(sessionB.currentIndex, 0);
      expect(identical(sessionA.attempts, sessionB.attempts), isFalse);

      // Global BookmarkService hydrate is intentional and separate from attempt
      // answer state — this suite does not toggle bookmarks, so bookmarked stays
      // false unless an external singleton already held the id.
      expect(sessionB.attempts[0].bookmarked, isFalse);
    });
  });

  group('TE-27 controller / service state consistency', () {
    test('index, question, and attempt stay synchronized under navigation', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'sync',
          questions: [
            _tq('q1', 'One'),
            _tq('q2', 'Two'),
            _tq('q3', 'Three'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      void expectSynced(int index) {
        expect(controller.currentIndex, index);
        expect(controller.currentQuestion.id, 'q${index + 1}');
        expect(controller.currentAttempt.questionId, 'q${index + 1}');
        expect(controller.questionNumber, index + 1);
        expect(controller.currentIndex, inInclusiveRange(0, 2));
      }

      expectSynced(0);
      controller.goNext();
      expectSynced(1);
      controller.goNext();
      expectSynced(2);
      controller.goNext(); // no-op at last
      expectSynced(2);
      controller.goTo(0);
      expectSynced(0);
      controller.goPrevious(); // no-op at first
      expectSynced(0);
      controller.goTo(99); // clamp
      expectSynced(2);
      controller.goTo(-3); // clamp
      expectSynced(0);

      // Repeated valid ops do not corrupt attempt list identity/length.
      final firstIds = controller.attempts.map((a) => a.questionId).toList();
      for (var i = 0; i < 5; i++) {
        controller.goTo(i % 3);
        controller.selectOption(['A', 'B', 'C'][i % 3]);
      }
      expect(controller.attempts.map((a) => a.questionId).toList(), firstIds);
      expect(controller.attempts, hasLength(3));
    });
  });

  group('TE-28 edge sequence integrity', () {
    test('sequence A: answer/review/nav/change ends consistent', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'seq-a',
          questions: [_tq('q1', 'One'), _tq('q2', 'Two')],
        ),
      );
      addTearDown(controller.dispose);

      controller.selectOption('A');
      controller.toggleMarkForReview();
      controller.goNext();
      controller.selectOption('B');
      controller.goTo(0);
      controller.selectOption('C');
      controller.toggleMarkForReview();
      controller.goTo(1);

      expect(controller.currentIndex, 1);
      expect(controller.attempts[0].selectedOption, 'C');
      expect(controller.attempts[0].answered, isTrue);
      expect(controller.attempts[0].markedForReview, isFalse);
      expect(controller.attempts[0].status, QuestionStatus.answered);
      expect(controller.attempts[1].selectedOption, 'B');
      expect(controller.attempts[1].status, QuestionStatus.answered);
      expect(_counts(controller)[QuestionStatus.answered], 2);
      expect(_counts(controller)[QuestionStatus.markedForReview], 0);
      expect(controller.attempts.every((a) => a.visited), isTrue);
    });

    test('sequence B: navigate/clamp/review/answer without corruption', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'seq-b',
          questions: [
            _tq('q1', 'One'),
            _tq('q2', 'Two'),
            _tq('q3', 'Three'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      controller.goNext();
      controller.goPrevious();
      controller.goTo(100);
      expect(controller.currentIndex, 2);
      controller.toggleMarkForReview();
      controller.selectOption('D');
      controller.toggleMarkForReview();

      expect(controller.attempts[2].selectedOption, 'D');
      expect(controller.attempts[2].markedForReview, isFalse);
      expect(controller.attempts[2].status, QuestionStatus.answered);
      expect(controller.attempts[0].visited, isTrue);
      expect(controller.attempts[1].visited, isTrue);
      expect(controller.attempts[2].visited, isTrue);
      // Q0/Q1 never answered in this sequence.
      expect(controller.attempts[0].answered, isFalse);
      expect(controller.attempts[1].answered, isFalse);
      expect(_counts(controller)[QuestionStatus.answered], 1);
      expect(_counts(controller)[QuestionStatus.notAnswered], 2);
      expect(controller.attempts, hasLength(3));
    });
  });
}
