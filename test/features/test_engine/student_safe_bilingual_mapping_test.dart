import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/test_attempt_api.dart';
import 'package:telangana_prep/features/test_engine/presentation/screens/test_attempt_flow_screen.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

Map<String, dynamic> _bilingualStudentQuestion({
  required String questionId,
  bool includeOptionTeluguText = true,
}) {
  return <String, dynamic>{
    'questionId': questionId,
    'position': 0,
    'text':
        'National Disaster Response Force (NDRF) is a specialized disaster response force under which ministry?',
    'options': [
      <String, dynamic>{
        'label': 'A',
        'text': 'Ministry of Urban Development',
        if (includeOptionTeluguText)
          'teluguText': 'పట్టణాభివృద్ధి మంత్రిత్వ శాఖ',
      },
      <String, dynamic>{
        'label': 'B',
        'text': 'Ministry of Home Affairs',
        if (includeOptionTeluguText) 'teluguText': 'హోం వ్యవహారాల మంత్రిత్వ శాఖ',
      },
      <String, dynamic>{
        'label': 'C',
        'text': 'Ministry of Defence',
        if (includeOptionTeluguText) 'teluguText': 'రక్షణ మంత్రిత్వ శాఖ',
      },
      <String, dynamic>{
        'label': 'D',
        'text': 'Ministry of Environment, Forest and Climate Change',
        if (includeOptionTeluguText)
          'teluguText': 'పర్యావరణ, అటవీ మరియు వాతావరణ మార్పుల మంత్రిత్వ శాఖ',
      },
    ],
    'content': <String, dynamic>{
      'en': <String, dynamic>{
        'question':
            'National Disaster Response Force (NDRF) is a specialized disaster response force under which ministry?',
        'options': [
          <String, dynamic>{'text': 'Ministry of Urban Development'},
          <String, dynamic>{'text': 'Ministry of Home Affairs'},
          <String, dynamic>{'text': 'Ministry of Defence'},
          <String, dynamic>{
            'text': 'Ministry of Environment, Forest and Climate Change',
          },
        ],
      },
      'te': <String, dynamic>{
        'question':
            'నేషనల్ డిజాస్టర్ రెస్పాన్స్ ఫోర్స్ (NDRF) అనేది ఏ మంత్రిత్వ శాఖ పరిధిలోని ప్రత్యేక విపత్తు ప్రతిస్పందన దళం?',
        'options': [
          <String, dynamic>{'text': 'పట్టణాభివృద్ధి మంత్రిత్వ శాఖ'},
          <String, dynamic>{'text': 'హోం వ్యవహారాల మంత్రిత్వ శాఖ'},
          <String, dynamic>{'text': 'రక్షణ మంత్రిత్వ శాఖ'},
          <String, dynamic>{
            'text': 'పర్యావరణ, అటవీ మరియు వాతావరణ మార్పుల మంత్రిత్వ శాఖ',
          },
        ],
      },
    },
    'courseId': 'group-ii',
    'paperId': 'group-ii-paper-i',
    'syllabusUnitId': 'group-ii-paper-i-area-01',
    'majorStudyAreaId': 'group-ii-paper-i-area-01',
  };
}

void main() {
  group('createTestFromStudentSafeQuestions bilingual mapping', () {
    test('maps Telugu question and options from snapshot content', () async {
      final service = TestService();
      final test = await service.createTestFromStudentSafeQuestions(
        id: 'snap-test',
        title: 'Home',
        courseId: 'group-ii',
        studentQuestions: [_bilingualStudentQuestion(questionId: 'ndrf-q')],
      );

      final question = test.questions.single;
      expect(question.text, contains('National Disaster Response Force'));
      expect(
        question.teluguText,
        'నేషనల్ డిజాస్టర్ రెస్పాన్స్ ఫోర్స్ (NDRF) అనేది ఏ మంత్రిత్వ శాఖ పరిధిలోని ప్రత్యేక విపత్తు ప్రతిస్పందన దళం?',
      );
      expect(question.options[0].text, 'Ministry of Urban Development');
      expect(question.options[0].teluguText, 'పట్టణాభివృద్ధి మంత్రిత్వ శాఖ');
      expect(question.options[1].teluguText, 'హోం వ్యవహారాల మంత్రిత్వ శాఖ');
      expect(question.correctOption, isEmpty);
      expect(question.explanation, isEmpty);
    });

    test('English-only snapshot still maps without Telugu', () async {
      final service = TestService();
      final test = await service.createTestFromStudentSafeQuestions(
        id: 'en-only-test',
        title: 'English',
        courseId: 'group-ii',
        studentQuestions: [
          <String, dynamic>{
            'questionId': 'en-q',
            'position': 0,
            'text': 'English only question?',
            'options': [
              <String, dynamic>{'label': 'A', 'text': 'One'},
              <String, dynamic>{'label': 'B', 'text': 'Two'},
              <String, dynamic>{'label': 'C', 'text': 'Three'},
              <String, dynamic>{'label': 'D', 'text': 'Four'},
            ],
            'courseId': 'group-ii',
            'paperId': 'group-ii-paper-i',
          },
        ],
      );

      final question = test.questions.single;
      expect(question.text, 'English only question?');
      expect(question.teluguText, isNull);
      expect(question.options.every((o) => o.teluguText == null), isTrue);
      expect(question.options.length, 4);
    });
  });

  group('applyRevealedQuestionSnapshots preserves Telugu options', () {
    test('keeps teluguText when reveal payload omits it', () async {
      final service = TestService();
      final test = await service.createTestFromStudentSafeQuestions(
        id: 'reveal-test',
        title: 'Home',
        courseId: 'group-ii',
        studentQuestions: [_bilingualStudentQuestion(questionId: 'ndrf-q')],
      );

      // Reveal snapshots often omit teluguText on options.
      service.applyRevealedQuestionSnapshots(test, [
        <String, dynamic>{
          'questionId': 'ndrf-q',
          'text':
              'National Disaster Response Force (NDRF) is a specialized disaster response force under which ministry?',
          'correctOption': 'B',
          'explanation': 'Ministry of Home Affairs',
          'options': [
            <String, dynamic>{
              'label': 'A',
              'text': 'Ministry of Urban Development',
            },
            <String, dynamic>{
              'label': 'B',
              'text': 'Ministry of Home Affairs',
            },
            <String, dynamic>{'label': 'C', 'text': 'Ministry of Defence'},
            <String, dynamic>{
              'label': 'D',
              'text': 'Ministry of Environment, Forest and Climate Change',
            },
          ],
        },
      ]);

      final question = test.questions.single;
      expect(question.correctOption, 'B');
      expect(question.explanation, 'Ministry of Home Affairs');
      expect(question.teluguText, isNotNull);
      expect(question.options[0].teluguText, 'పట్టణాభివృద్ధి మంత్రిత్వ శాఖ');
      expect(question.options[1].teluguText, 'హోం వ్యవహారాల మంత్రిత్వ శాఖ');
    });

    test('prefers raw teluguText when present on reveal payload', () async {
      final service = TestService();
      final test = await service.createTestFromStudentSafeQuestions(
        id: 'reveal-raw',
        title: 'Home',
        courseId: 'group-ii',
        studentQuestions: [_bilingualStudentQuestion(questionId: 'ndrf-q')],
      );

      service.applyRevealedQuestionSnapshots(test, [
        <String, dynamic>{
          'questionId': 'ndrf-q',
          'text': 'English question',
          'correctOption': 'A',
          'explanation': 'Why',
          'options': [
            <String, dynamic>{
              'label': 'A',
              'text': 'One',
              'teluguText': 'ఒకటి',
            },
            <String, dynamic>{
              'label': 'B',
              'text': 'Two',
              'teluguText': 'రెండు',
            },
            <String, dynamic>{
              'label': 'C',
              'text': 'Three',
              'teluguText': 'మూడు',
            },
            <String, dynamic>{
              'label': 'D',
              'text': 'Four',
              'teluguText': 'నాలుగు',
            },
          ],
        },
      ]);

      expect(test.questions.single.options[0].teluguText, 'ఒకటి');
      expect(test.questions.single.options[1].teluguText, 'రెండు');
    });

    test('English-only reveal still works without Telugu', () async {
      final service = TestService();
      final test = Test(
        id: 'en-reveal',
        title: 'English',
        courseId: 'group-ii',
        duration: const Duration(minutes: 10),
        totalQuestions: 1,
        totalMarks: 1,
        negativeMarks: 0,
        instructions: const ['Read'],
        mode: TestMode.topic,
        questions: [
          const TestQuestion(
            id: 'en-q',
            text: 'English only?',
            options: [
              TestOption(label: 'A', text: 'One'),
              TestOption(label: 'B', text: 'Two'),
              TestOption(label: 'C', text: 'Three'),
              TestOption(label: 'D', text: 'Four'),
            ],
            correctOption: '',
            explanation: '',
            content: QuestionContent(
              en: QuestionLocalizedContent(
                question: 'English only?',
                options: [
                  QuestionOption(text: 'One'),
                  QuestionOption(text: 'Two'),
                  QuestionOption(text: 'Three'),
                  QuestionOption(text: 'Four'),
                ],
                explanation: '',
              ),
            ),
          ),
        ],
      );

      service.applyRevealedQuestionSnapshots(test, [
        <String, dynamic>{
          'questionId': 'en-q',
          'text': 'English only?',
          'correctOption': 'B',
          'explanation': 'Two',
          'options': [
            <String, dynamic>{'label': 'A', 'text': 'One'},
            <String, dynamic>{'label': 'B', 'text': 'Two'},
            <String, dynamic>{'label': 'C', 'text': 'Three'},
            <String, dynamic>{'label': 'D', 'text': 'Four'},
          ],
        },
      ]);

      final question = test.questions.single;
      expect(question.correctOption, 'B');
      expect(question.options.every((o) => o.teluguText == null), isTrue);
    });
  });

  group('Retry Test rebuilds from new studentQuestions', () {
    test(
      'retry remapping uses createTestFromStudentSafeQuestions (same as fresh start)',
      () async {
        final service = TestService();
        final previous = await service.createTestFromStudentSafeQuestions(
          id: 'home-test',
          title: 'Home',
          courseId: 'group-ii',
          studentQuestions: [_bilingualStudentQuestion(questionId: 'ndrf-q')],
        );
        // Simulate post-submit reveal without option teluguText.
        service.applyRevealedQuestionSnapshots(previous, [
          <String, dynamic>{
            'questionId': 'ndrf-q',
            'text': previous.questions.single.text,
            'correctOption': 'B',
            'explanation': 'Ministry of Home Affairs',
            'options': [
              for (final o in previous.questions.single.options)
                <String, dynamic>{'label': o.label, 'text': o.text},
            ],
          },
        ]);
        expect(previous.questions.single.correctOption, 'B');
        expect(previous.questions.single.options[0].teluguText, isNotNull);

        // New start payload with distinct Telugu options — must not reuse
        // the mutated previous Test.
        final retryQuestions = [
          _bilingualStudentQuestion(questionId: 'ndrf-q'),
        ];
        (retryQuestions.single['options'] as List)[0]['teluguText'] =
            'కొత్త పట్టణాభివృద్ధి మంత్రిత్వ శాఖ';
        (retryQuestions.single['content'] as Map)['te']['options'][0]['text'] =
            'కొత్త పట్టణాభివృద్ధి మంత్రిత్వ శాఖ';

        final rebuilt = await service.createTestFromStudentSafeQuestions(
          id: previous.id,
          title: previous.title,
          courseId: previous.courseId,
          studentQuestions: retryQuestions,
          mode: previous.mode,
          duration: previous.duration,
          totalMarks: previous.totalMarks,
          negativeMarks: previous.negativeMarks,
          instructions: previous.instructions,
        );

        expect(rebuilt.questions.single.correctOption, isEmpty);
        expect(
          rebuilt.questions.single.options[0].teluguText,
          'కొత్త పట్టణాభివృద్ధి మంత్రిత్వ శాఖ',
        );
        expect(
          previous.questions.single.options[0].teluguText,
          isNot(equals('కొత్త పట్టణాభివృద్ధి మంత్రిత్వ శాఖ')),
        );
      },
    );

    testWidgets(
      'Retry Test remaps bilingual options from a new start snapshot',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        var startCalls = 0;
        final api = TestAttemptApi(
          callOverride: (name, data) async {
            if (name == 'startTestAttempt') {
              startCalls += 1;
              final studentQuestions = [
                _bilingualStudentQuestion(questionId: 'ndrf-q'),
              ];
              // Distinct Telugu so we prove rebuild, not reuse of mutated test.
              (studentQuestions.single['options'] as List)[0]['teluguText'] =
                  'కొత్త పట్టణాభివృద్ధి మంత్రిత్వ శాఖ';
              return <String, dynamic>{
                'attemptId': 'attempt-$startCalls',
                'testId': 'home-test',
                'courseId': 'group-ii',
                'questionIds': ['ndrf-q'],
                'studentQuestions': studentQuestions,
                'totalMarks': 1,
                'negativeMarks': 0,
                'totalQuestions': 1,
                'durationSeconds': 600,
                'duplicate': false,
              };
            }
            if (name == 'submitTestAttempt') {
              return <String, dynamic>{
                'attemptId': data['attemptId'],
                'duplicate': false,
                'totalQuestions': 1,
                'attempted': 0,
                'correct': 0,
                'wrong': 0,
                'skipped': 1,
                'score': 0.0,
                'accuracy': 0.0,
                'percentage': 0.0,
                'passed': false,
                'authority': 'server_verified',
                'questionSnapshots': [
                  <String, dynamic>{
                    'questionId': 'ndrf-q',
                    'text':
                        'National Disaster Response Force (NDRF) is a specialized disaster response force under which ministry?',
                    'correctOption': 'B',
                    'explanation': 'Ministry of Home Affairs',
                    'options': [
                      <String, dynamic>{
                        'label': 'A',
                        'text': 'Ministry of Urban Development',
                      },
                      <String, dynamic>{
                        'label': 'B',
                        'text': 'Ministry of Home Affairs',
                      },
                      <String, dynamic>{
                        'label': 'C',
                        'text': 'Ministry of Defence',
                      },
                      <String, dynamic>{
                        'label': 'D',
                        'text':
                            'Ministry of Environment, Forest and Climate Change',
                      },
                    ],
                  },
                ],
              };
            }
            throw StateError('Unexpected callable $name');
          },
        );
        final service = TestService(attemptApi: api);
        final initial = await service.createTestFromStudentSafeQuestions(
          id: 'home-test',
          title: 'Home',
          courseId: 'group-ii',
          studentQuestions: [_bilingualStudentQuestion(questionId: 'ndrf-q')],
          duration: const Duration(minutes: 10),
          totalMarks: 1,
          negativeMarks: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TestAttemptFlowScreen(
              test: initial,
              serverAttemptId: 'attempt-seed',
              skipInstructions: true,
              engineService: service,
              startAttempt: ({
                required String testId,
                required String startRequestId,
              }) {
                return service.startServerAttempt(
                  testId: testId,
                  startRequestId: startRequestId,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('పట్టణాభివృద్ధి'),
          findsWidgets,
        );
        expect(find.textContaining('కొత్త పట్టణాభివృద్ధి'), findsNothing);

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

        final start = find.text('Start Test');
        expect(start, findsOneWidget);
        await tester.ensureVisible(start);
        await tester.tap(start);
        await tester.pumpAndSettle();

        expect(startCalls, 1);
        expect(
          find.textContaining('నేషనల్ డిజాస్టర్ రెస్పాన్స్ ఫోర్స్'),
          findsOneWidget,
        );
        expect(
          find.textContaining('కొత్త పట్టణాభివృద్ధి మంత్రిత్వ శాఖ'),
          findsOneWidget,
        );
      },
    );
  });
}
