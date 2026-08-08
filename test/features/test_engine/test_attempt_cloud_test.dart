import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/test_attempt_cloud_mapper.dart';
import 'package:telangana_prep/features/test_engine/repository/test_attempt_cloud_repository.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

void main() {
  Test buildTest() {
    return Test(
      id: 'test-group-ii-001',
      title: 'Group-II Practice Test 1',
      courseId: 'group-ii',
      duration: const Duration(minutes: 1),
      totalQuestions: 1,
      totalMarks: 1,
      negativeMarks: 0,
      instructions: const ['Read carefully'],
      mode: TestMode.topic,
      questions: const [
        TestQuestion(
          id: 'q-test-group-ii-001',
          text: 'What is the capital of Telangana?',
          options: [
            TestOption(label: 'A', text: 'Hyderabad'),
            TestOption(label: 'B', text: 'Warangal'),
            TestOption(label: 'C', text: 'Nizamabad'),
            TestOption(label: 'D', text: 'Karimnagar'),
          ],
          correctOption: 'A',
          explanation: 'Hyderabad is the capital.',
        ),
      ],
    );
  }

  List<QuestionAttempt> buildAttempts() {
    return [
      QuestionAttempt(questionId: 'q-test-group-ii-001')
        ..selectedOption = 'A'
        ..answered = true
        ..visited = true
        ..markedForReview = false
        ..timeSpent = 12,
    ];
  }

  TestResult buildResult() {
    return const TestResult(
      totalQuestions: 1,
      attempted: 1,
      correct: 1,
      wrong: 0,
      skipped: 0,
      score: 1,
      accuracy: 100,
      percentage: 100,
      timeTaken: Duration(seconds: 12),
      passed: true,
    );
  }

  group('TestAttemptCloudMapper', () {
    test('1: completed attempt maps correctly to Firestore data', () {
      final data = TestAttemptCloudMapper.toCreateMap(
        attemptId: 'attempt-1',
        uid: 'user-1',
        test: buildTest(),
        result: buildResult(),
        attempts: buildAttempts(),
        startedAt: DateTime(2026, 8, 8, 10, 0),
        courseTitle: 'Group-II',
      );

      expect(data['id'], 'attempt-1');
      expect(data['uid'], 'user-1');
      expect(data['testId'], 'test-group-ii-001');
      expect(data['testTitle'], 'Group-II Practice Test 1');
      expect(data['courseId'], 'group-ii');
      expect(data['courseTitle'], 'Group-II');
      expect(data['status'], 'submitted');
      expect(data['score'], 1);
      expect(data['correct'], 1);
      expect(data['wrong'], 0);
      expect(data['skipped'], 0);
      expect(data['totalQuestions'], 1);
      expect(data['accuracy'], 100);
      expect(data['timeSpentSeconds'], 12);
      expect(data['submittedAt'], isA<FieldValue>());
      expect(data['startedAt'], isA<Timestamp>());

      final answers = data['answers'] as List<dynamic>;
      expect(answers, hasLength(1));
      final answer = answers.single as Map<String, dynamic>;
      expect(answer['questionId'], 'q-test-group-ii-001');
      expect(answer['selectedOption'], 'A');
      expect(answer['visited'], isTrue);
      expect(answer['markedForReview'], isFalse);
      expect(answer['timeSpentSeconds'], 12);
    });

    test('includes testTitle from Test.title and courseTitle argument', () {
      final data = TestAttemptCloudMapper.toCreateMap(
        attemptId: 'a1',
        uid: 'u1',
        test: buildTest(),
        result: buildResult(),
        attempts: buildAttempts(),
        startedAt: DateTime(2026, 8, 8),
        courseTitle: 'Group-II',
      );

      expect(data['testTitle'], 'Group-II Practice Test 1');
      expect(data['courseTitle'], 'Group-II');
      expect(data['testId'], 'test-group-ii-001');
      expect(data['courseId'], 'group-ii');
    });

    test('falls back to ids when titles are blank', () {
      final data = TestAttemptCloudMapper.toCreateMap(
        attemptId: 'a1',
        uid: 'u1',
        test: Test(
          id: 'practice-indian-economy-topic',
          title: '   ',
          courseId: 'group-ii',
          duration: const Duration(minutes: 1),
          totalQuestions: 1,
          totalMarks: 1,
          negativeMarks: 0,
          instructions: const [],
          mode: TestMode.topic,
          questions: buildTest().questions,
        ),
        result: buildResult(),
        attempts: buildAttempts(),
        startedAt: DateTime(2026, 8, 8),
        courseTitle: '',
      );

      expect(data['testTitle'], 'practice-indian-economy-topic');
      expect(data['courseTitle'], 'group-ii');
    });
  });

  group('TestAttemptCloudRepository', () {
    test('2/3/4/5/6: uid/testId/courseId/score/answers from auth + result',
        () async {
      Map<String, dynamic>? saved;
      String? savedId;

      final repo = TestAttemptCloudRepository.withSaver(
        currentUid: () => 'auth-user-42',
        saver: ({required attemptId, required data}) async {
          savedId = attemptId;
          saved = data;
        },
      );

      final result = await repo.saveCompletedAttempt(
        test: buildTest(),
        result: buildResult(),
        attempts: buildAttempts(),
        timeTaken: const Duration(seconds: 12),
        attemptId: 'forced-attempt-id',
      );

      expect(result.success, isTrue);
      expect(result.attemptId, 'forced-attempt-id');
      expect(savedId, 'forced-attempt-id');
      expect(saved!['uid'], 'auth-user-42');
      expect(saved!['testId'], 'test-group-ii-001');
      expect(saved!['testTitle'], 'Group-II Practice Test 1');
      expect(saved!['courseId'], 'group-ii');
      expect(saved!['courseTitle'], isNot(isEmpty));
      expect(saved!['score'], 1);
      expect(saved!['correct'], 1);
      expect(saved!['wrong'], 0);
      expect(saved!['skipped'], 0);
      expect((saved!['answers'] as List), hasLength(1));
    });

    test('UID comes from authenticated user, not arguments', () async {
      Map<String, dynamic>? saved;
      final repo = TestAttemptCloudRepository.withSaver(
        currentUid: () => 'only-auth-uid',
        saver: ({required attemptId, required data}) async {
          saved = data;
        },
      );

      await repo.saveCompletedAttempt(
        test: buildTest(),
        result: buildResult(),
        attempts: buildAttempts(),
        timeTaken: const Duration(seconds: 5),
      );

      expect(saved!['uid'], 'only-auth-uid');
    });

    test('7: save failure returns failed result without throwing', () async {
      final repo = TestAttemptCloudRepository.withSaver(
        currentUid: () => 'user-1',
        saver: ({required attemptId, required data}) async {
          throw StateError('network down');
        },
      );

      final result = await repo.saveCompletedAttempt(
        test: buildTest(),
        result: buildResult(),
        attempts: buildAttempts(),
        timeTaken: const Duration(seconds: 5),
      );

      expect(result.success, isFalse);
      expect(result.error, isA<StateError>());
    });

    test('fails clearly when there is no authenticated user', () async {
      final repo = TestAttemptCloudRepository.withSaver(
        currentUid: () => null,
        saver: ({required attemptId, required data}) async {
          fail('should not write without uid');
        },
      );

      final result = await repo.saveCompletedAttempt(
        test: buildTest(),
        result: buildResult(),
        attempts: buildAttempts(),
        timeTaken: const Duration(seconds: 5),
      );

      expect(result.success, isFalse);
      expect(result.error, isA<StateError>());
    });
  });

  group('TestService cloud persistence (without ProgressService)', () {
    test('7: cloud save failure does not destroy the scored result', () async {
      final service = TestService(
        attemptCloudRepository: TestAttemptCloudRepository.withSaver(
          currentUid: () => 'user-1',
          saver: ({required attemptId, required data}) async {
            throw StateError('firestore unavailable');
          },
        ),
      );

      final test = buildTest();
      final attempts = buildAttempts();
      final result = service.calculateScore(
        test: test,
        attempts: attempts,
        timeTaken: const Duration(seconds: 12),
      );

      await service.persistCompletedAttemptToCloud(
        test: test,
        result: result,
        attempts: attempts,
        timeTaken: const Duration(seconds: 12),
      );

      // Score object is unchanged after a failed cloud write.
      expect(result.score, 1);
      expect(result.correct, 1);
      expect(result.wrong, 0);
      expect(result.passed, isTrue);
    });

    test('8: duplicate persist on same service skips second cloud write',
        () async {
      var writes = 0;
      final service = TestService(
        attemptCloudRepository: TestAttemptCloudRepository.withSaver(
          currentUid: () => 'user-1',
          saver: ({required attemptId, required data}) async {
            writes++;
          },
        ),
      );

      final test = buildTest();
      final attempts = buildAttempts();
      const timeTaken = Duration(seconds: 12);
      final result = service.calculateScore(
        test: test,
        attempts: attempts,
        timeTaken: timeTaken,
      );

      await service.persistCompletedAttemptToCloud(
        test: test,
        result: result,
        attempts: attempts,
        timeTaken: timeTaken,
      );
      await service.persistCompletedAttemptToCloud(
        test: test,
        result: result,
        attempts: attempts,
        timeTaken: timeTaken,
      );

      expect(writes, 1);
    });
  });
}
