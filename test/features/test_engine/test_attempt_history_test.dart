import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_attempt_history.dart';
import 'package:telangana_prep/features/test_engine/data/test_attempt_cloud_mapper.dart';
import 'package:telangana_prep/features/test_engine/repository/test_attempt_cloud_repository.dart';

void main() {
  TestAttemptHistoryItem item({
    required String attemptId,
    required String testId,
    required String courseId,
    required DateTime startedAt,
    String uid = 'user-1',
    double score = 1,
  }) {
    return TestAttemptHistoryItem(
      attemptId: attemptId,
      testId: testId,
      courseId: courseId,
      mode: 'topic',
      status: 'submitted',
      score: score,
      percentage: 100,
      accuracy: 100,
      correct: 1,
      wrong: 0,
      skipped: 0,
      totalQuestions: 1,
      timeSpentSeconds: 12,
      startedAt: startedAt,
      submittedAt: startedAt.add(const Duration(seconds: 12)),
      passed: true,
      uid: uid,
    );
  }

  group('TestAttemptCloudMapper.historyFromFirestore', () {
    test('maps a Firestore attempt document with titles', () {
      final mapped = TestAttemptCloudMapper.historyFromFirestore('attempt-1', {
        'id': 'attempt-1',
        'uid': 'user-1',
        'testId': 'test-group-ii-001',
        'testTitle': 'Group-II Practice Test 1',
        'courseId': 'group-ii',
        'courseTitle': 'Group-II',
        'mode': 'topic',
        'status': 'submitted',
        'score': 1,
        'percentage': 100,
        'accuracy': 100,
        'correct': 1,
        'wrong': 0,
        'skipped': 0,
        'totalQuestions': 1,
        'timeSpentSeconds': 12,
        'startedAt': Timestamp.fromDate(DateTime(2026, 8, 8, 10)),
        'submittedAt': Timestamp.fromDate(DateTime(2026, 8, 8, 10, 0, 12)),
        'passed': true,
      });

      expect(mapped, isNotNull);
      expect(mapped!.attemptId, 'attempt-1');
      expect(mapped.testId, 'test-group-ii-001');
      expect(mapped.testTitle, 'Group-II Practice Test 1');
      expect(mapped.courseId, 'group-ii');
      expect(mapped.courseTitle, 'Group-II');
      expect(mapped.displayTestTitle, 'Group-II Practice Test 1');
      expect(mapped.displayCourseTitle, 'Group-II');
      expect(mapped.mode, 'topic');
      expect(mapped.status, 'submitted');
      expect(mapped.score, 1);
      expect(mapped.percentage, 100);
      expect(mapped.accuracy, 100);
      expect(mapped.correct, 1);
      expect(mapped.wrong, 0);
      expect(mapped.skipped, 0);
      expect(mapped.totalQuestions, 1);
      expect(mapped.timeSpentSeconds, 12);
      expect(mapped.passed, isTrue);
      expect(mapped.uid, 'user-1');
      expect(mapped.startedAt, DateTime(2026, 8, 8, 10));
    });

    test('old attempt without titles does not crash and falls back to ids', () {
      final mapped = TestAttemptCloudMapper.historyFromFirestore('old-1', {
        'testId': 'practice-indian-economy-topic',
        'courseId': 'group-ii',
        'score': 8,
        'percentage': 80,
        'accuracy': 80,
        'correct': 8,
        'wrong': 2,
        'skipped': 0,
        'totalQuestions': 10,
      });

      expect(mapped, isNotNull);
      expect(mapped!.testTitle, isNull);
      expect(mapped.courseTitle, isNull);
      expect(mapped.testId, 'practice-indian-economy-topic');
      expect(mapped.courseId, 'group-ii');
      expect(mapped.displayTestTitle, 'practice-indian-economy-topic');
      expect(mapped.displayCourseTitle, 'group-ii');
      expect(mapped.score, 8);
      expect(mapped.percentage, 80);
      expect(mapped.accuracy, 80);
    });

    test('empty string titles fall back to ids', () {
      final mapped = TestAttemptCloudMapper.historyFromFirestore('a2', {
        'testId': 't-id',
        'courseId': 'c-id',
        'testTitle': '   ',
        'courseTitle': '',
        'score': 1,
        'percentage': 100,
        'accuracy': 100,
      });

      expect(mapped, isNotNull);
      expect(mapped!.testTitle, isNull);
      expect(mapped.courseTitle, isNull);
      expect(mapped.displayTestTitle, 't-id');
      expect(mapped.displayCourseTitle, 'c-id');
      expect(mapped.score, 1);
      expect(mapped.percentage, 100);
      expect(mapped.accuracy, 100);
    });

    test('handles missing optional fields safely', () {
      final mapped = TestAttemptCloudMapper.historyFromFirestore('attempt-2', {
        'testId': 'test-group-ii-001',
        'courseId': 'group-ii',
      });

      expect(mapped, isNotNull);
      expect(mapped!.attemptId, 'attempt-2');
      expect(mapped.mode, '');
      expect(mapped.status, 'submitted');
      expect(mapped.score, 0);
      expect(mapped.percentage, 0);
      expect(mapped.accuracy, 0);
      expect(mapped.correct, 0);
      expect(mapped.wrong, 0);
      expect(mapped.skipped, 0);
      expect(mapped.totalQuestions, 0);
      expect(mapped.timeSpentSeconds, 0);
      expect(mapped.startedAt, isNull);
      expect(mapped.submittedAt, isNull);
      expect(mapped.passed, isFalse);
      expect(mapped.displayTestTitle, 'test-group-ii-001');
      expect(mapped.displayCourseTitle, 'group-ii');
    });

    test('maps numeric fields that arrive as double', () {
      final mapped = TestAttemptCloudMapper.historyFromFirestore('a3', {
        'testId': 't1',
        'courseId': 'group-ii',
        'score': 1.0,
        'percentage': 100.0,
        'correct': 1.0,
        'timeSpentSeconds': 12.0,
      });

      expect(mapped, isNotNull);
      expect(mapped!.score, 1.0);
      expect(mapped.correct, 1);
      expect(mapped.timeSpentSeconds, 12);
    });

    test('returns null when required identity fields are missing', () {
      expect(
        TestAttemptCloudMapper.historyFromFirestore('x', {'courseId': 'group-ii'}),
        isNull,
      );
      expect(
        TestAttemptCloudMapper.historyFromFirestore('x', {'testId': 't1'}),
        isNull,
      );
    });

    test('preserves ids even when titles are present', () {
      final mapped = TestAttemptCloudMapper.historyFromFirestore('a4', {
        'testId': 'test-group-ii-001',
        'testTitle': 'Group-II Practice Test 1',
        'courseId': 'group-ii',
        'courseTitle': 'Group-II',
      });

      expect(mapped!.testId, 'test-group-ii-001');
      expect(mapped.courseId, 'group-ii');
      expect(mapped.testTitle, 'Group-II Practice Test 1');
      expect(mapped.courseTitle, 'Group-II');
    });
  });

  group('TestAttemptCloudRepository.getMyCompletedAttempts', () {
    test('empty history returns empty list', () async {
      final repo = TestAttemptCloudRepository.withHandlers(
        currentUid: () => 'user-1',
        loader: ({courseId}) async => const [],
      );

      final items = await repo.getMyCompletedAttempts();
      expect(items, isEmpty);
    });

    test('multiple attempts sorted by startedAt DESC', () async {
      final older = item(
        attemptId: 'a-old',
        testId: 't1',
        courseId: 'group-ii',
        startedAt: DateTime(2026, 8, 1),
      );
      final newer = item(
        attemptId: 'a-new',
        testId: 't1',
        courseId: 'group-ii',
        startedAt: DateTime(2026, 8, 8),
      );

      final repo = TestAttemptCloudRepository.withHandlers(
        currentUid: () => 'user-1',
        loader: ({courseId}) async {
          // Simulate Firestore orderBy startedAt DESC.
          final all = [newer, older];
          return all;
        },
      );

      final items = await repo.getMyCompletedAttempts();
      expect(items.map((e) => e.attemptId), ['a-new', 'a-old']);
      expect(
        items.first.startedAt!.isAfter(items.last.startedAt!),
        isTrue,
      );
    });

    test('current-user filtering: loader is uid-scoped', () async {
      final repo = TestAttemptCloudRepository.withHandlers(
        currentUid: () => 'user-1',
        loader: ({courseId}) async {
          // Only the signed-in user's attempts are returned by the query.
          return [
            item(
              attemptId: 'mine',
              testId: 't1',
              courseId: 'group-ii',
              startedAt: DateTime(2026, 8, 8),
              uid: 'user-1',
            ),
          ];
        },
      );

      final items = await repo.getMyCompletedAttempts();
      expect(items, hasLength(1));
      expect(items.single.uid, 'user-1');
      expect(items.any((e) => e.uid == 'user-2'), isFalse);
    });

    test('courseId isolation filters within the user-scoped set', () async {
      final repo = TestAttemptCloudRepository.withHandlers(
        currentUid: () => 'user-1',
        loader: ({courseId}) async {
          final all = [
            item(
              attemptId: 'ii',
              testId: 't-ii',
              courseId: 'group-ii',
              startedAt: DateTime(2026, 8, 8),
            ),
            item(
              attemptId: 'iii',
              testId: 't-iii',
              courseId: 'group-iii',
              startedAt: DateTime(2026, 8, 7),
            ),
          ];
          if (courseId == null) return all;
          return [
            for (final entry in all)
              if (entry.courseId == courseId) entry,
          ];
        },
      );

      final groupIi = await repo.getMyCompletedAttempts(courseId: 'group-ii');
      expect(groupIi.every((e) => e.courseId == 'group-ii'), isTrue);
      expect(groupIi.map((e) => e.attemptId), isNot(contains('iii')));

      final groupIii = await repo.getMyCompletedAttempts(courseId: 'group-iii');
      expect(groupIii.every((e) => e.courseId == 'group-iii'), isTrue);
      expect(groupIii.map((e) => e.attemptId), isNot(contains('ii')));
    });

    test('returns empty when there is no authenticated user', () async {
      final repo = TestAttemptCloudRepository(currentUid: () => null);
      final items = await repo.getMyCompletedAttempts();
      expect(items, isEmpty);
    });
  });
}
