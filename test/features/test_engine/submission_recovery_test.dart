import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/test_attempt_api.dart';
import 'package:telangana_prep/features/test_engine/presentation/controllers/test_engine_controller.dart';
import 'package:telangana_prep/features/test_engine/presentation/screens/test_attempt_flow_screen.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

void main() {
  Test buildTest({Duration duration = const Duration(minutes: 30)}) {
    return Test(
      id: 'test-group-ii-001',
      title: 'Group-II Practice Test 1',
      courseId: 'group-ii',
      duration: duration,
      totalQuestions: 1,
      totalMarks: 1,
      negativeMarks: 0,
      instructions: const ['Read carefully'],
      mode: TestMode.topic,
      questions: const [
        TestQuestion(
          id: 'q1',
          text: 'Capital of Telangana?',
          options: [
            TestOption(label: 'A', text: 'Hyderabad'),
            TestOption(label: 'B', text: 'Warangal'),
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
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> successPayload(String attemptId) {
    return <String, dynamic>{
      'attemptId': attemptId,
      'duplicate': false,
      'totalQuestions': 1,
      'attempted': 1,
      'correct': 1,
      'wrong': 0,
      'skipped': 0,
      'score': 1.0,
      'accuracy': 100.0,
      'percentage': 100.0,
      'passed': true,
      'authority': 'server_verified',
      'scoringVersion': 'v1',
    };
  }

  test('I: concurrent submit uses one in-flight request', () async {
    var calls = 0;
    final gate = Completer<void>();
    final api = TestAttemptApi(
      callOverride: (name, data) async {
        expect(name, 'submitTestAttempt');
        calls += 1;
        await gate.future;
        return successPayload(data['attemptId'] as String);
      },
    );
    final service = TestService(attemptApi: api);
    final controller = TestEngineController(
      test: buildTest(),
      service: service,
      serverAttemptId: 'attempt-keep',
    );
    final first = controller.submit();
    final second = controller.submit();
    gate.complete();
    final results = await Future.wait([first, second]);
    expect(calls, 1);
    expect(results[0]?.attemptId, 'attempt-keep');
    expect(results[1]?.attemptId, 'attempt-keep');
    expect(controller.submissionPhase, TestSubmissionPhase.submitted);
    controller.dispose();
  });

  testWidgets(
    'G/H: submission failure shows recovery UI and retries the same attempt',
    (tester) async {
      final attemptIds = <String>[];
      var fail = true;
      final api = TestAttemptApi(
        callOverride: (name, data) async {
          expect(name, 'submitTestAttempt');
          attemptIds.add(data['attemptId'] as String);
          if (fail) {
            throw StateError('network failed');
          }
          return successPayload(data['attemptId'] as String);
        },
      );
      final service = TestService(attemptApi: api);

      await tester.pumpWidget(
        MaterialApp(
          home: TestAttemptFlowScreen(
            test: buildTest(),
            serverAttemptId: 'attempt-keep',
            engineService: service,
          ),
        ),
      );

      await tester.tap(find.text('Start Test'));
      await tester.pumpAndSettle();

      final submit = find.byKey(const ValueKey('submit-attempt'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('submission-error')), findsOneWidget);
      expect(find.byKey(const ValueKey('retry-submission')), findsOneWidget);
      expect(
        find.text(
          'Unable to submit your test. Your answers are saved. Please try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Result'), findsNothing);
      expect(find.text('Capital of Telangana?'), findsOneWidget);
      expect(attemptIds, ['attempt-keep']);

      fail = false;
      await tester.tap(find.byKey(const ValueKey('retry-submission')));
      await tester.pumpAndSettle();

      expect(find.text('Result'), findsOneWidget);
      expect(attemptIds, ['attempt-keep', 'attempt-keep']);
    },
  );

  testWidgets('I: multiple submit taps cannot start overlapping submissions', (
    tester,
  ) async {
    var calls = 0;
    final gate = Completer<void>();
    final api = TestAttemptApi(
      callOverride: (name, data) async {
        calls += 1;
        await gate.future;
        return successPayload(data['attemptId'] as String);
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TestAttemptFlowScreen(
          test: buildTest(),
          serverAttemptId: 'attempt-keep',
          engineService: TestService(attemptApi: api),
        ),
      ),
    );

    await tester.tap(find.text('Start Test'));
    await tester.pumpAndSettle();

    final submit = find.byKey(const ValueKey('submit-attempt'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-submit')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('submitting-indicator')), findsOneWidget);
    await tester.tap(submit, warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Result'), findsOneWidget);
    expect(calls, 1);
  });

  Future<void> pumpToQuestions(
    WidgetTester tester, {
    required Widget app,
  }) async {
    await tester.pumpWidget(app);
    await tester.tap(find.text('Start Test'));
    await tester.pumpAndSettle();
    expect(find.text('Capital of Telangana?'), findsOneWidget);
  }

  Future<void> elapseTimeout(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets('A: timeout submission shows Result', (tester) async {
    var calls = 0;
    final api = TestAttemptApi(
      callOverride: (name, data) async {
        expect(name, 'submitTestAttempt');
        calls += 1;
        return successPayload(data['attemptId'] as String);
      },
    );

    await pumpToQuestions(
      tester,
      app: MaterialApp(
        home: TestAttemptFlowScreen(
          test: buildTest(duration: const Duration(seconds: 1)),
          serverAttemptId: 'attempt-keep',
          engineService: TestService(attemptApi: api),
        ),
      ),
    );

    await elapseTimeout(tester);

    expect(find.text('Result'), findsOneWidget);
    expect(find.text('TEST COMPLETED!'), findsOneWidget);
    expect(find.text('Capital of Telangana?'), findsNothing);
    expect(calls, 1);
  });

  testWidgets('B: timeout while Review shows Result', (tester) async {
    var calls = 0;
    final api = TestAttemptApi(
      callOverride: (name, data) async {
        expect(name, 'submitTestAttempt');
        calls += 1;
        return successPayload(data['attemptId'] as String);
      },
    );

    await pumpToQuestions(
      tester,
      app: MaterialApp(
        home: TestAttemptFlowScreen(
          test: buildTest(duration: const Duration(seconds: 1)),
          serverAttemptId: 'attempt-keep',
          engineService: TestService(attemptApi: api),
        ),
      ),
    );

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Attempt Summary'), findsOneWidget);

    await elapseTimeout(tester);

    expect(find.text('Result'), findsOneWidget);
    expect(find.text('Attempt Summary'), findsNothing);
    expect(calls, 1);
  });

  testWidgets('C: timeout submission failure stays on question screen', (
    tester,
  ) async {
    var calls = 0;
    final api = TestAttemptApi(
      callOverride: (name, data) async {
        expect(name, 'submitTestAttempt');
        calls += 1;
        throw StateError('network failed');
      },
    );

    await pumpToQuestions(
      tester,
      app: MaterialApp(
        home: TestAttemptFlowScreen(
          test: buildTest(duration: const Duration(seconds: 1)),
          serverAttemptId: 'attempt-keep',
          engineService: TestService(attemptApi: api),
        ),
      ),
    );

    await elapseTimeout(tester);

    expect(find.text('Result'), findsNothing);
    expect(find.text('Capital of Telangana?'), findsOneWidget);
    expect(find.byKey(const ValueKey('submission-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('retry-submission')), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('D: Retry Submission after timeout failure shows Result', (
    tester,
  ) async {
    var fail = true;
    var calls = 0;
    final api = TestAttemptApi(
      callOverride: (name, data) async {
        expect(name, 'submitTestAttempt');
        calls += 1;
        if (fail) throw StateError('network failed');
        return successPayload(data['attemptId'] as String);
      },
    );

    await pumpToQuestions(
      tester,
      app: MaterialApp(
        home: TestAttemptFlowScreen(
          test: buildTest(duration: const Duration(seconds: 1)),
          serverAttemptId: 'attempt-keep',
          engineService: TestService(attemptApi: api),
        ),
      ),
    );

    await elapseTimeout(tester);
    expect(find.byKey(const ValueKey('retry-submission')), findsOneWidget);

    fail = false;
    await tester.tap(find.byKey(const ValueKey('retry-submission')));
    await tester.pumpAndSettle();

    expect(find.text('Result'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('E: manual Submit still shows Result', (tester) async {
    var calls = 0;
    final api = TestAttemptApi(
      callOverride: (name, data) async {
        expect(name, 'submitTestAttempt');
        calls += 1;
        return successPayload(data['attemptId'] as String);
      },
    );

    await pumpToQuestions(
      tester,
      app: MaterialApp(
        home: TestAttemptFlowScreen(
          test: buildTest(),
          serverAttemptId: 'attempt-keep',
          engineService: TestService(attemptApi: api),
        ),
      ),
    );

    final submit = find.byKey(const ValueKey('submit-attempt'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Result'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('F: timeout + manual Submit race uses one submitTestAttempt', (
    tester,
  ) async {
    var calls = 0;
    final gate = Completer<void>();
    final api = TestAttemptApi(
      callOverride: (name, data) async {
        expect(name, 'submitTestAttempt');
        calls += 1;
        await gate.future;
        return successPayload(data['attemptId'] as String);
      },
    );

    await pumpToQuestions(
      tester,
      app: MaterialApp(
        home: TestAttemptFlowScreen(
          test: buildTest(duration: const Duration(seconds: 1)),
          serverAttemptId: 'attempt-keep',
          engineService: TestService(attemptApi: api),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byKey(const ValueKey('submitting-indicator')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('submit-attempt')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(calls, 1);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Result'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('G: timeout Result Analysis back Retry rebinds controller', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var calls = 0;
    final api = TestAttemptApi(
      callOverride: (name, data) async {
        expect(name, 'submitTestAttempt');
        calls += 1;
        return successPayload(data['attemptId'] as String);
      },
    );

    await pumpToQuestions(
      tester,
      app: MaterialApp(
        home: TestAttemptFlowScreen(
          test: buildTest(duration: const Duration(seconds: 1)),
          serverAttemptId: 'attempt-keep',
          engineService: TestService(attemptApi: api),
          startAttempt: ({required testId, required startRequestId}) async => {
            'attemptId': 'attempt-retry',
            'studentQuestions': const <Map<String, dynamic>>[],
          },
        ),
      ),
    );

    await elapseTimeout(tester);
    expect(find.text('Result'), findsOneWidget);
    expect(calls, 1);

    await tester.tap(find.text('Review Answers'));
    await tester.pumpAndSettle();
    expect(find.text('Detailed Analysis'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Result'), findsOneWidget);
    expect(find.text('Retry Test'), findsNothing);
    expect(find.text('Review Answers'), findsOneWidget);
    expect(find.text('Back to Unit'), findsOneWidget);

    final flowState = tester.state<TestAttemptFlowScreenState>(
      find.byType(TestAttemptFlowScreen),
    );
    await flowState.retryAttempt();
    await tester.pumpAndSettle();
    expect(find.text('Start Test'), findsOneWidget);
    expect(find.text('Instructions'), findsOneWidget);

    await tester.tap(find.text('Start Test'));
    await tester.pumpAndSettle();
    expect(find.text('Capital of Telangana?'), findsOneWidget);
    expect(find.text('Result'), findsNothing);
  });
}
