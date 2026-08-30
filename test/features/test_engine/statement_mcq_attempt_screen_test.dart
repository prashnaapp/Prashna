import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/core/design_system/design_system.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/repositories/test_repository.dart';
import 'package:telangana_prep/features/test_engine/data/test_attempt_api.dart';
import 'package:telangana_prep/features/test_engine/presentation/controllers/test_engine_controller.dart';
import 'package:telangana_prep/features/test_engine/presentation/screens/test_attempt_flow_screen.dart';
import 'package:telangana_prep/features/test_engine/presentation/screens/test_question_screen.dart';
import 'package:telangana_prep/features/test_engine/presentation/widgets/attempt_option_tile.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

void main() {
  const englishQuestion =
      'Which of the following statements regarding Article 371-D of the '
      'Indian Constitution is/are correct?';
  const teluguQuestion =
      'భారత రాజ్యాంగంలోని అధికరణ 371-D కి సంబంధించి క్రింది వ్యాఖ్యలలో '
      'ఏది/వి సరైనది/వి?';

  Map<String, dynamic> statementStudentQuestion({
    required int statementCount,
    String questionId = 'stmt-q',
    bool includeSpuriousTeluguOptions = false,
  }) {
    final english = [
      for (var i = 0; i < statementCount; i++) 'English statement ${i + 1}.',
    ];
    final telugu = [
      for (var i = 0; i < statementCount; i++) 'Telugu statement ${i + 1}.',
    ];
    return <String, dynamic>{
      'questionId': questionId,
      'position': 0,
      'text': englishQuestion,
      'itemFormat': 'statement_mcq',
      'options': [
        <String, dynamic>{
          'label': 'A',
          'text': '1 and 3 only',
          if (includeSpuriousTeluguOptions) 'teluguText': '1 మరియు 3 మాత్రమే',
        },
        <String, dynamic>{
          'label': 'B',
          'text': '2 and 3 only',
          if (includeSpuriousTeluguOptions) 'teluguText': '2 మరియు 3 మాత్రమే',
        },
        <String, dynamic>{
          'label': 'C',
          'text': '1 and 2 only',
          if (includeSpuriousTeluguOptions) 'teluguText': '1 మరియు 2 మాత్రమే',
        },
        <String, dynamic>{
          'label': 'D',
          'text': '1, 2 and 3',
          if (includeSpuriousTeluguOptions) 'teluguText': '1, 2 మరియు 3',
        },
      ],
      'content': <String, dynamic>{
        'en': <String, dynamic>{
          'question': englishQuestion,
          'statements': english,
          'options': [
            <String, dynamic>{'text': '1 and 3 only'},
            <String, dynamic>{'text': '2 and 3 only'},
            <String, dynamic>{'text': '1 and 2 only'},
            <String, dynamic>{'text': '1, 2 and 3'},
          ],
        },
        'te': <String, dynamic>{
          'question': teluguQuestion,
          'statements': telugu,
        },
      },
      'courseId': 'group-ii',
      'paperId': 'group-ii-paper-i',
      'majorStudyAreaId': 'group-ii-paper-i-area-01',
      'contentTopicId': 'group-ii-paper-i-area-01-topic-01',
    };
  }

  Map<String, dynamic> standardStudentQuestion() {
    return <String, dynamic>{
      'questionId': 'std-q',
      'position': 0,
      'text': 'Which city is the capital of Telangana?',
      'options': [
        <String, dynamic>{
          'label': 'A',
          'text': 'Warangal',
          'teluguText': 'వరంగల్',
        },
        <String, dynamic>{
          'label': 'B',
          'text': 'Hyderabad',
          'teluguText': 'హైదరాబాద్',
        },
        <String, dynamic>{
          'label': 'C',
          'text': 'Nizamabad',
          'teluguText': 'నిజామాబాద్',
        },
        <String, dynamic>{
          'label': 'D',
          'text': 'Karimnagar',
          'teluguText': 'కరీంనగర్',
        },
      ],
      'content': <String, dynamic>{
        'en': <String, dynamic>{
          'question': 'Which city is the capital of Telangana?',
          'options': [
            <String, dynamic>{'text': 'Warangal'},
            <String, dynamic>{'text': 'Hyderabad'},
            <String, dynamic>{'text': 'Nizamabad'},
            <String, dynamic>{'text': 'Karimnagar'},
          ],
        },
        'te': <String, dynamic>{
          'question': 'తెలంగాణ రాజధాని నగరం ఏది?',
          'options': [
            <String, dynamic>{'text': 'వరంగల్'},
            <String, dynamic>{'text': 'హైదరాబాద్'},
            <String, dynamic>{'text': 'నిజామాబాద్'},
            <String, dynamic>{'text': 'కరీంనగర్'},
          ],
        },
      },
      'courseId': 'group-ii',
      'paperId': 'group-ii-paper-i',
    };
  }

  Future<Test> mapQuestions(
    TestService service,
    List<Map<String, dynamic>> studentQuestions,
  ) {
    return service.createTestFromStudentSafeQuestions(
      id: 'stmt-attempt',
      title: 'Home',
      courseId: 'group-ii',
      studentQuestions: studentQuestions,
      duration: const Duration(minutes: 10),
      totalMarks: 1,
      negativeMarks: 0,
    );
  }

  Future<TestEngineController> pumpAttempt(
    WidgetTester tester,
    Test test, {
    TestService? service,
    VoidCallback? onOpenReview,
    Future<void> Function()? onSubmit,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TestEngineController(
      test: test,
      service: service ?? TestService(repository: TestRepository()),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: TestQuestionScreen(
          controller: controller,
          onOpenReview: onOpenReview ?? () {},
          onSubmit: onSubmit ?? () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets(
    'A: Standard MCQ has no statement section and bilingual options',
    (tester) async {
      final service = TestService(repository: TestRepository());
      final test = await mapQuestions(service, [standardStudentQuestion()]);
      await pumpAttempt(tester, test, service: service);

      expect(find.byKey(const ValueKey('statement-section')), findsNothing);
      expect(find.text('Statements'), findsNothing);
      expect(
        find.text('Which city is the capital of Telangana?'),
        findsOneWidget,
      );
      expect(find.text('తెలంగాణ రాజధాని నగరం ఏది?'), findsOneWidget);

      final optionA = tester.widget<AttemptOptionTile>(
        find.byKey(const ValueKey('attempt-option-A')),
      );
      expect(optionA.optionText, 'Warangal\nవరంగల్');
      final optionB = tester.widget<AttemptOptionTile>(
        find.byKey(const ValueKey('attempt-option-B')),
      );
      expect(optionB.optionText, 'Hyderabad\nహైదరాబాద్');
    },
  );

  for (final count in [1, 2, 3, 4, 5, 6]) {
    testWidgets('B/C: Statement MCQ renders $count bilingual statement(s)', (
      tester,
    ) async {
      final service = TestService(repository: TestRepository());
      final test = await mapQuestions(service, [
        statementStudentQuestion(statementCount: count),
      ]);
      expect(test.questions.single.hasNumberedStatements, isTrue);
      expect(test.questions.single.englishStatements, hasLength(count));

      await pumpAttempt(tester, test, service: service);

      expect(find.text(englishQuestion), findsOneWidget);
      expect(find.text(teluguQuestion), findsOneWidget);
      expect(find.byKey(const ValueKey('statement-section')), findsOneWidget);

      for (var i = 1; i <= count; i++) {
        expect(find.byKey(ValueKey('statement-en-$i')), findsOneWidget);
        expect(find.byKey(ValueKey('statement-te-$i')), findsOneWidget);
        expect(find.text('English statement $i.'), findsOneWidget);
        expect(find.text('Telugu statement $i.'), findsOneWidget);
      }
      expect(find.byKey(ValueKey('statement-en-${count + 1}')), findsNothing);

      for (final letter in ['A', 'B', 'C', 'D']) {
        final tile = tester.widget<AttemptOptionTile>(
          find.byKey(ValueKey('attempt-option-$letter')),
        );
        expect(tile.optionText.contains('\n'), isFalse);
      }
      expect(find.text('1 and 3 only'), findsOneWidget);
      expect(find.text('2 and 3 only'), findsOneWidget);
      expect(find.text('1 and 2 only'), findsOneWidget);
      expect(find.text('1, 2 and 3'), findsOneWidget);
    });
  }

  testWidgets(
    'D: Statement MCQ does not show Telugu under A-D even if teluguText is present',
    (tester) async {
      final service = TestService(repository: TestRepository());
      final test = await mapQuestions(service, [
        statementStudentQuestion(
          statementCount: 3,
          includeSpuriousTeluguOptions: true,
        ),
      ]);
      await pumpAttempt(tester, test, service: service);

      final optionA = tester.widget<AttemptOptionTile>(
        find.byKey(const ValueKey('attempt-option-A')),
      );
      expect(optionA.optionText, '1 and 3 only');
      expect(find.text('1 మరియు 3 మాత్రమే'), findsNothing);
    },
  );

  testWidgets('E: selecting A-D still records exactly one option', (
    tester,
  ) async {
    final service = TestService(repository: TestRepository());
    final test = await mapQuestions(service, [
      statementStudentQuestion(statementCount: 2),
    ]);
    final controller = await pumpAttempt(tester, test, service: service);

    await tester.tap(find.byKey(const ValueKey('attempt-option-C')));
    await tester.pump();

    expect(controller.currentAttempt.selectedOption, 'C');
    expect(controller.currentAttempt.answered, isTrue);

    await tester.tap(find.byKey(const ValueKey('attempt-option-A')));
    await tester.pump();
    expect(controller.currentAttempt.selectedOption, 'A');
  });

  test('F: submit payload remains questionId + selectedOption only', () async {
    Map<String, dynamic>? submitted;
    final api = TestAttemptApi(
      callOverride: (name, data) async {
        if (name == 'submitTestAttempt') {
          submitted = data;
          return <String, dynamic>{
            'attemptId': data['attemptId'],
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
        throw StateError('unexpected $name');
      },
    );
    final service = TestService(attemptApi: api, repository: TestRepository())
      ..serverAttemptId = 'attempt-stmt';
    final test = await mapQuestions(service, [
      statementStudentQuestion(statementCount: 3),
    ]);
    final attempts = service.startTest(test);
    service.saveAnswer(attempt: attempts.single, optionLabel: 'B');

    await service.submitTest(
      test: test,
      attempts: attempts,
      timeTaken: const Duration(seconds: 12),
    );

    expect(submitted, isNotNull);
    expect(submitted!.keys.toList()..sort(), ['attemptId', 'selectedAnswers']);
    final answers = submitted!['selectedAnswers'] as List;
    expect(answers, hasLength(1));
    expect((answers.single as Map).keys.toList()..sort(), [
      'questionId',
      'selectedOption',
    ]);
    expect(answers.single['questionId'], 'stmt-q');
    expect(answers.single['selectedOption'], 'B');
    expect(submitted!.containsKey('statements'), isFalse);
    expect(submitted!.containsKey('itemFormat'), isFalse);
    expect(submitted!.containsKey('undefined'), isFalse);
  });

  testWidgets('G: reveal keeps bilingual statements on the attempt screen', (
    tester,
  ) async {
    final service = TestService(repository: TestRepository());
    final test = await mapQuestions(service, [
      statementStudentQuestion(statementCount: 3),
    ]);
    service.applyRevealedQuestionSnapshots(test, [
      <String, dynamic>{
        'questionId': 'stmt-q',
        'text': englishQuestion,
        'correctOption': 'B',
        'explanation': 'Statement 2 is incorrect.',
        'options': [
          <String, dynamic>{'label': 'A', 'text': '1 and 3 only'},
          <String, dynamic>{'label': 'B', 'text': '2 and 3 only'},
          <String, dynamic>{'label': 'C', 'text': '1 and 2 only'},
          <String, dynamic>{'label': 'D', 'text': '1, 2 and 3'},
        ],
      },
    ]);

    expect(test.questions.single.content!.en.statements, hasLength(3));
    expect(test.questions.single.content!.te!.statements, hasLength(3));
    expect(test.questions.single.teluguText, teluguQuestion);

    await pumpAttempt(tester, test, service: service);
    expect(find.byKey(const ValueKey('statement-section')), findsOneWidget);
    expect(find.text('English statement 2.'), findsOneWidget);
    expect(find.text('Telugu statement 2.'), findsOneWidget);
    expect(find.text(teluguQuestion), findsOneWidget);
  });

  testWidgets(
    'H: retry rebuilds from studentQuestions and still shows statements',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var startCalls = 0;
      final api = TestAttemptApi(
        callOverride: (name, data) async {
          if (name == 'startTestAttempt') {
            startCalls += 1;
            return <String, dynamic>{
              'attemptId': 'attempt-retry-$startCalls',
              'testId': 'stmt-attempt',
              'courseId': 'group-ii',
              'totalMarks': 1,
              'negativeMarks': 0,
              'totalQuestions': 1,
              'durationSeconds': 600,
              'studentQuestions': [statementStudentQuestion(statementCount: 4)],
            };
          }
          if (name == 'submitTestAttempt') {
            return <String, dynamic>{
              'attemptId': data['attemptId'],
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
              'questionSnapshots': [
                <String, dynamic>{
                  'questionId': 'stmt-q',
                  'text': englishQuestion,
                  'correctOption': 'B',
                  'explanation': 'B',
                  'options': [
                    <String, dynamic>{'label': 'A', 'text': '1 and 3 only'},
                    <String, dynamic>{'label': 'B', 'text': '2 and 3 only'},
                    <String, dynamic>{'label': 'C', 'text': '1 and 2 only'},
                    <String, dynamic>{'label': 'D', 'text': '1, 2 and 3'},
                  ],
                },
              ],
            };
          }
          throw StateError('unexpected $name');
        },
      );
      final service = TestService(
        attemptApi: api,
        repository: TestRepository(),
      );
      final initial = await mapQuestions(service, [
        statementStudentQuestion(statementCount: 4),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: TestAttemptFlowScreen(
            test: initial,
            serverAttemptId: 'attempt-seed',
            skipInstructions: true,
            engineService: service,
            startAttempt:
                ({required String testId, required String startRequestId}) {
                  return service.startServerAttempt(
                    testId: testId,
                    startRequestId: startRequestId,
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('statement-section')), findsOneWidget);
      expect(find.text('English statement 4.'), findsOneWidget);

      final submit = find.byKey(const ValueKey('submit-attempt'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Retry Test'), findsNothing);
      expect(find.text('Review Answers'), findsOneWidget);
      expect(find.text('Back to Unit'), findsOneWidget);

      final flowState = tester.state<TestAttemptFlowScreenState>(
        find.byType(TestAttemptFlowScreen),
      );
      await flowState.retryAttempt();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start Test'));
      await tester.tap(find.text('Start Test'));
      await tester.pumpAndSettle();

      expect(startCalls, 1);
      expect(find.byKey(const ValueKey('statement-section')), findsOneWidget);
      expect(find.text(englishQuestion), findsOneWidget);
      expect(find.text(teluguQuestion), findsOneWidget);
      expect(find.text('English statement 1.'), findsOneWidget);
      expect(find.text('Telugu statement 4.'), findsOneWidget);
      final optionA = tester.widget<AttemptOptionTile>(
        find.byKey(const ValueKey('attempt-option-A')),
      );
      expect(optionA.optionText, '1 and 3 only');
    },
  );

  testWidgets(
    'exam controls: compact Review/Palette on top, Previous/Submit at bottom',
    (tester) async {
      var openedReview = false;
      var submitted = false;
      final service = TestService(repository: TestRepository());
      final test = await mapQuestions(service, [
        statementStudentQuestion(statementCount: 6, questionId: 'q1'),
        statementStudentQuestion(statementCount: 2, questionId: 'q2'),
      ]);
      final controller = await pumpAttempt(
        tester,
        test,
        service: service,
        onOpenReview: () => openedReview = true,
        onSubmit: () async => submitted = true,
      );

      expect(find.byKey(const ValueKey('open-review')), findsOneWidget);
      expect(find.byKey(const ValueKey('open-palette')), findsOneWidget);
      expect(find.byKey(const ValueKey('go-next')), findsOneWidget);
      expect(find.byKey(const ValueKey('submit-attempt')), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Submit'), findsWidgets);
      expect(find.widgetWithText(AppPrimaryButton, 'Review'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Palette'), findsNothing);

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, isA<EdgeInsets>());
      expect((listView.padding! as EdgeInsets).bottom, AppSpacing.massive);

      await tester.tap(find.byKey(const ValueKey('open-review')));
      await tester.pump();
      expect(openedReview, isTrue);

      await tester.tap(find.byKey(const ValueKey('open-palette')));
      await tester.pumpAndSettle();
      expect(find.text('Question Palette'), findsOneWidget);
      Navigator.of(tester.element(find.text('Question Palette'))).pop();
      await tester.pumpAndSettle();

      expect(controller.questionNumber, 1);
      await tester.tap(find.byKey(const ValueKey('go-next')));
      await tester.pumpAndSettle();
      expect(controller.questionNumber, 2);
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(controller.questionNumber, 1);

      await tester.ensureVisible(find.byKey(const ValueKey('attempt-option-D')));
      final optionBox = tester.getRect(
        find.byKey(const ValueKey('attempt-option-D')),
      );
      final previousBox = tester.getRect(find.text('Previous'));
      expect(optionBox.bottom, lessThanOrEqualTo(previousBox.top));

      await tester.tap(find.byKey(const ValueKey('attempt-option-B')));
      await tester.pumpAndSettle();
      expect(controller.currentAttempt.selectedOption, 'B');

      await tester.tap(find.byKey(const ValueKey('submit-attempt')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();
      expect(submitted, isTrue);
    },
  );
}
