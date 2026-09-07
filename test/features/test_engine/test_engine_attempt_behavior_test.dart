import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_activity/data/models/question_activity_models.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/repositories/test_repository.dart';
import 'package:telangana_prep/features/test_engine/presentation/controllers/test_engine_controller.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

/// Offline QuestionService stub — avoids live bank / bookmark side effects.
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
  required String courseId,
  required TestMode mode,
  required List<TestQuestion> questions,
  QuestionActivitySourceModule? module,
  String? currentAffairsSetId,
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
    currentAffairsSetId: currentAffairsSetId,
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

void main() {
  group('TE-01 answer retention across navigation', () {
    test('select on Q1 survives Next then Previous', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'retain',
          courseId: 'group-ii',
          mode: TestMode.topic,
          module: QuestionActivitySourceModule.chapters,
          questions: [
            _tq('q1', 'First'),
            _tq('q2', 'Second'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.currentIndex, 0);
      controller.selectOption('B');
      expect(controller.currentAttempt.selectedOption, 'B');
      expect(controller.currentAttempt.answered, isTrue);

      controller.goNext();
      expect(controller.currentIndex, 1);
      expect(controller.currentQuestion.id, 'q2');
      expect(controller.currentAttempt.selectedOption, isNull);

      controller.goPrevious();
      expect(controller.currentIndex, 0);
      expect(controller.currentQuestion.id, 'q1');
      expect(controller.attempts[0].selectedOption, 'B');
      expect(controller.attempts[0].answered, isTrue);
      expect(controller.currentAttempt.selectedOption, 'B');
      expect(controller.currentAttempt.answered, isTrue);
    });
  });

  group('TE-02 navigation boundaries', () {
    test('goPrevious on first and goNext on last do not leave valid range', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'bounds',
          courseId: 'group-ii',
          mode: TestMode.topic,
          module: QuestionActivitySourceModule.chapters,
          questions: [
            _tq('q1', 'First'),
            _tq('q2', 'Second'),
            _tq('q3', 'Third'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.isFirst, isTrue);
      controller.goPrevious();
      expect(controller.currentIndex, 0);
      expect(controller.attempts, hasLength(3));

      controller.goTo(2);
      expect(controller.isLast, isTrue);
      controller.goNext();
      expect(controller.currentIndex, 2);
      expect(controller.attempts.map((a) => a.questionId).toList(), [
        'q1',
        'q2',
        'q3',
      ]);
    });
  });

  group('TE-03 goTo navigation', () {
    test('goTo moves to index, visits destination, preserves prior answers', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'goto',
          courseId: 'group-iii',
          mode: TestMode.section,
          module: QuestionActivitySourceModule.testSeries,
          questions: [
            _tq('q1', 'First'),
            _tq('q2', 'Second'),
            _tq('q3', 'Third'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      controller.selectOption('C');
      controller.goTo(2);
      expect(controller.currentIndex, 2);
      expect(controller.currentQuestion.id, 'q3');
      expect(controller.currentAttempt.visited, isTrue);
      expect(controller.attempts[0].selectedOption, 'C');
      expect(controller.attempts[0].answered, isTrue);
    });

    test('goTo clamps out-of-range indexes to valid bounds', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'goto-clamp',
          courseId: 'group-ii',
          mode: TestMode.topic,
          module: QuestionActivitySourceModule.chapters,
          questions: [
            _tq('q1', 'First'),
            _tq('q2', 'Second'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      // Real contract: TestService.navigateTo uses index.clamp(0, total - 1).
      controller.goTo(99);
      expect(controller.currentIndex, 1);
      expect(controller.currentQuestion.id, 'q2');

      controller.goTo(-5);
      expect(controller.currentIndex, 0);
      expect(controller.currentQuestion.id, 'q1');
    });
  });

  group('TE-04 mark for review', () {
    test('toggle ON then OFF restores answered status priority', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'review',
          courseId: 'group-ii',
          mode: TestMode.practice,
          module: QuestionActivitySourceModule.practice,
          questions: [
            _tq('q1', 'Only'),
            _tq('q2', 'Two'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.currentAttempt.markedForReview, isFalse);
      expect(controller.currentAttempt.status, QuestionStatus.notVisited);

      controller.selectOption('A');
      expect(controller.currentAttempt.answered, isTrue);
      expect(controller.currentAttempt.status, QuestionStatus.answered);
      expect(controller.statusCounts[QuestionStatus.answered], 1);

      controller.toggleMarkForReview();
      expect(controller.currentAttempt.markedForReview, isTrue);
      // markedForReview takes priority over answered in QuestionAttempt.status.
      expect(
        controller.currentAttempt.status,
        QuestionStatus.markedForReview,
      );
      expect(controller.statusCounts[QuestionStatus.markedForReview], 1);
      expect(controller.statusCounts[QuestionStatus.answered], 0);
      expect(controller.currentAttempt.selectedOption, 'A');
      expect(controller.currentAttempt.answered, isTrue);

      controller.toggleMarkForReview();
      expect(controller.currentAttempt.markedForReview, isFalse);
      expect(controller.currentAttempt.status, QuestionStatus.answered);
      expect(controller.statusCounts[QuestionStatus.answered], 1);
      expect(controller.statusCounts[QuestionStatus.markedForReview], 0);
    });
  });

  group('TE-06 / TE-07 bookmark toggle in TestEngineController', () {
    test('eligible test toggles local attempt.bookmarked ON then OFF', () async {
      final controller = _controllerFor(
        _buildTest(
          id: 'bm-on',
          courseId: 'group-ii',
          mode: TestMode.topic,
          module: QuestionActivitySourceModule.chapters,
          questions: [_tq('q1', 'Bookable')],
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.bookmarksEnabled, isTrue);
      expect(controller.currentAttempt.bookmarked, isFalse);

      // toggleBookmark updates attempt.bookmarked synchronously, then fire-and-
      // forgets BookmarkService.instance (hard singleton → real QuestionService).
      // Without Firebase, that side-effect Future throws; swallow it so this
      // suite asserts controller local state only (cloud path covered elsewhere).
      Object? unexpected;
      await runZonedGuarded(() async {
        controller.toggleBookmark();
        expect(controller.currentAttempt.bookmarked, isTrue);

        controller.toggleBookmark();
        expect(controller.currentAttempt.bookmarked, isFalse);

        // Flush unawaited BookmarkService futures before leaving the zone.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
      }, (error, _) {
        final text = error.toString();
        final expectedNoApp =
            text.contains('no-app') || text.contains('Firebase App');
        if (!expectedNoApp) unexpected = error;
      });
      expect(unexpected, isNull);
    });

    test('Current Affairs stamps: bookmarksEnabled false and toggle is no-op', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'ca-week-1',
          courseId: 'current-affairs',
          mode: TestMode.practice,
          module: QuestionActivitySourceModule.currentAffairs,
          currentAffairsSetId: 'ca-week-1',
          questions: [_tq('ca-q1', 'CA question')],
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.bookmarksEnabled, isFalse);
      expect(controller.currentAttempt.bookmarked, isFalse);

      controller.toggleBookmark();
      expect(controller.currentAttempt.bookmarked, isFalse);
    });

    test('unsafe course without CA module still disables bookmark toggle', () {
      final controller = _controllerFor(
        _buildTest(
          id: 'unsafe',
          courseId: 'unknown-course',
          mode: TestMode.topic,
          module: QuestionActivitySourceModule.chapters,
          questions: [_tq('q1', 'Unsafe')],
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.bookmarksEnabled, isFalse);
      controller.toggleBookmark();
      expect(controller.currentAttempt.bookmarked, isFalse);
    });
  });
}
