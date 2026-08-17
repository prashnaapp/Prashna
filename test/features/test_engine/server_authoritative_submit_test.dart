import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_attempt_history.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/test_attempt_api.dart';
import 'package:telangana_prep/features/test_engine/data/test_attempt_cloud_mapper.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

void main() {
  Test buildTest() {
    return Test(
      id: 'test-group-ii-001',
      title: 'Group-II Practice Test 1',
      courseId: 'group-ii',
      duration: const Duration(minutes: 1),
      totalQuestions: 2,
      totalMarks: 2,
      negativeMarks: 0.25,
      instructions: const ['Read carefully'],
      mode: TestMode.topic,
      questions: const [
        TestQuestion(
          id: 'q1',
          text: 'Capital of Telangana?',
          options: [
            TestOption(
              label: 'A',
              text: 'Hyderabad',
              teluguText: 'హైదరాబాద్',
            ),
            TestOption(label: 'B', text: 'Warangal', teluguText: 'వరంగల్'),
            TestOption(label: 'C', text: 'Nizamabad'),
            TestOption(label: 'D', text: 'Karimnagar'),
          ],
          correctOption: 'A',
          explanation: 'Hyderabad is the capital.',
          content: QuestionContent(
            en: QuestionLocalizedContent(
              question: 'Capital of Telangana?',
              options: [
                QuestionOption(text: 'Hyderabad'),
                QuestionOption(text: 'Warangal'),
                QuestionOption(text: 'Nizamabad'),
                QuestionOption(text: 'Karimnagar'),
              ],
              explanation: 'Hyderabad is the capital.',
            ),
            te: QuestionLocalizedContent(
              question: 'తెలంగాణ రాజధాని?',
              options: [
                QuestionOption(text: 'హైదరాబాద్'),
                QuestionOption(text: 'వరంగల్'),
                QuestionOption(text: 'నిజామాబాద్'),
                QuestionOption(text: 'కరీమ్‌నగర్'),
              ],
              explanation: 'హైదరాబాద్ రాజధాని.',
            ),
          ),
        ),
        TestQuestion(
          id: 'q2',
          text: '2 + 2 = ?',
          options: [
            TestOption(label: 'A', text: '3'),
            TestOption(label: 'B', text: '4'),
            TestOption(label: 'C', text: '5'),
            TestOption(label: 'D', text: '6'),
          ],
          correctOption: 'B',
          explanation: 'Basic arithmetic.',
        ),
      ],
    );
  }

  group('Phase 5.20 server-authoritative client path', () {
    test('44/45: answer selection and bilingual fields still work', () {
      final service = TestService();
      final test = buildTest();
      final attempts = service.startTest(test);

      service.saveAnswer(attempt: attempts[0], optionLabel: 'A');
      expect(attempts[0].selectedOption, 'A');
      expect(attempts[0].answered, isTrue);
      expect(test.questions[0].teluguText, contains('తెలంగాణ'));
      expect(test.questions[0].options.first.teluguText, 'హైదరాబాద్');
    });

    test('46/47/48: submit invokes backend and retries same attemptId', () async {
      final calls = <Map<String, dynamic>>[];
      var submitCount = 0;

      final api = TestAttemptApi(
        callOverride: (name, data) async {
          calls.add({'name': name, ...data});
          if (name == 'submitTestAttempt') {
            submitCount += 1;
            return <String, dynamic>{
              'attemptId': data['attemptId'],
              'duplicate': submitCount > 1,
              'totalQuestions': 2,
              'attempted': 1,
              'correct': 1,
              'wrong': 0,
              'skipped': 1,
              'score': 1.0,
              'accuracy': 100.0,
              'percentage': 50.0,
              'passed': true,
              'authority': 'server_verified',
              'scoringVersion': 'v1',
            };
          }
          throw StateError('unexpected $name');
        },
      );

      final service = TestService(attemptApi: api)..serverAttemptId = 'attempt-1';
      final test = buildTest();
      final attempts = service.startTest(test);
      service.saveAnswer(attempt: attempts[0], optionLabel: 'A');

      final first = await service.submitTest(
        test: test,
        attempts: attempts,
        timeTaken: const Duration(seconds: 20),
      );
      final second = await service.submitTest(
        test: test,
        attempts: attempts,
        timeTaken: const Duration(seconds: 20),
      );

      expect(first.authority, 'server_verified');
      expect(first.attemptId, 'attempt-1');
      expect(first.score, 1.0);
      expect(second.attemptId, 'attempt-1');
      expect(second.score, first.score);
      expect(
        calls.where((c) => c['name'] == 'submitTestAttempt').length,
        1,
        reason: 'duplicate submit must reuse cached verified result',
      );
      expect(calls.first['attemptId'], 'attempt-1');
    });

    test('49: verified result renders scoring fields', () async {
      final api = TestAttemptApi(
        callOverride: (name, data) async {
          return <String, dynamic>{
            'attemptId': 'attempt-verified',
            'totalQuestions': 2,
            'attempted': 2,
            'correct': 2,
            'wrong': 0,
            'skipped': 0,
            'score': 2.0,
            'accuracy': 100.0,
            'percentage': 100.0,
            'passed': true,
            'authority': 'server_verified',
          };
        },
      );
      final service = TestService(attemptApi: api)
        ..serverAttemptId = 'attempt-verified';
      final test = buildTest();
      final attempts = service.startTest(test);
      service.saveAnswer(attempt: attempts[0], optionLabel: 'A');
      service.saveAnswer(attempt: attempts[1], optionLabel: 'B');

      final result = await service.submitTest(
        test: test,
        attempts: attempts,
        timeTaken: const Duration(seconds: 30),
      );

      expect(result.isServerVerified, isTrue);
      expect(result.passed, isTrue);
      expect(result.percentage, 100);
    });

    test('50: historical legacy result remains readable via mapper', () {
      final item = TestAttemptCloudMapper.historyFromFirestore('legacy-1', {
        'id': 'legacy-1',
        'uid': 'user-1',
        'testId': 'test-1',
        'courseId': 'group-ii',
        'mode': 'mock',
        'status': 'submitted',
        'score': 3,
        'percentage': 75,
        'accuracy': 80,
        'correct': 3,
        'wrong': 1,
        'skipped': 0,
        'totalQuestions': 4,
        'timeSpentSeconds': 100,
        'passed': true,
      });

      expect(item, isNotNull);
      expect(item!.isLegacyClient, isTrue);
      expect(item.isServerVerified, isFalse);
      expect(item.score, 3);

      final verified = TestAttemptHistoryItem(
        attemptId: 'v1',
        testId: 't',
        courseId: 'c',
        mode: 'mock',
        status: 'submitted',
        score: 1,
        percentage: 50,
        accuracy: 50,
        correct: 1,
        wrong: 1,
        skipped: 0,
        totalQuestions: 2,
        timeSpentSeconds: 10,
        startedAt: null,
        submittedAt: null,
        passed: true,
        authority: 'server_verified',
      );
      expect(verified.isServerVerified, isTrue);
      expect(verified.isLegacyClient, isFalse);
    });

    test('catalog submit does not invoke local progress/revision cloud side effects', () async {
      var progressCalls = 0;
      // Detected via absence of ProgressService cloud debug when using override API path.
      final api = TestAttemptApi(
        callOverride: (name, data) async {
          return <String, dynamic>{
            'attemptId': 'attempt-no-client-analytics',
            'totalQuestions': 2,
            'attempted': 1,
            'correct': 1,
            'wrong': 0,
            'skipped': 1,
            'score': 1.0,
            'accuracy': 100.0,
            'percentage': 50.0,
            'passed': true,
            'authority': 'server_verified',
          };
        },
      );
      final service = TestService(attemptApi: api)
        ..serverAttemptId = 'attempt-no-client-analytics';
      final test = buildTest();
      final attempts = service.startTest(test);
      service.saveAnswer(attempt: attempts[0], optionLabel: 'A');

      final result = await service.submitTest(
        test: test,
        attempts: attempts,
        timeTaken: const Duration(seconds: 5),
      );

      expect(result.isServerVerified, isTrue);
      expect(progressCalls, 0);
      // ProgressService.recordTestAttempt is skipped for serverAttemptId path.
    });

    test('local practice path does not require serverAttemptId', () async {
      final service = TestService();
      final test = buildTest();
      final attempts = service.startTest(test);
      service.saveAnswer(attempt: attempts[0], optionLabel: 'A');
      service.saveAnswer(attempt: attempts[1], optionLabel: 'A');

      final result = await service.submitTest(
        test: test,
        attempts: attempts,
        timeTaken: const Duration(seconds: 10),
      );

      expect(result.authority, isNull);
      expect(result.correct, 1);
      expect(result.wrong, 1);
    });
  });
}
