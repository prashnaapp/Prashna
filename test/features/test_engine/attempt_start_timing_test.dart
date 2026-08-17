import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/test_engine/data/test_attempt_api.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart'
    as engine;
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_instructions_screen.dart';

void main() {
  TestModel publishedTest({String examId = 'group-ii'}) {
    return TestModel(
      id: 'test-$examId-001',
      examId: examId,
      category: TestCategoryType.chapterTests,
      title: '$examId published',
      questionCount: 1,
      marks: 1,
      durationMinutes: 10,
      negativeMarking: '0',
      difficulty: 'Medium',
      status: TestPublicationStatus.published,
    );
  }

  Question bankQuestion({required String id, required String courseId}) {
    final now = DateTime(2026, 8, 15);
    return Question(
      id: id,
      courseId: courseId,
      paperId: '$courseId-paper-i',
      question: 'Capital of Telangana?',
      options: const ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar'],
      correctOption: 'A',
      explanation: 'Hyderabad is the capital.',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );
  }

  engine.TestService fakeEngine(List<Question> bank) {
    return engine.TestService(
      questionService: QuestionService(
        repository: QuestionRepository(
          cloudRepository: QuestionCloudRepository.withHandlers(
            loadQuestions: (_) async => bank,
            getByIds: (ids) async {
              final byId = {for (final question in bank) question.id: question};
              return [
                for (final id in ids)
                  if (byId[id] != null) byId[id]!,
              ];
            },
          ),
        ),
      ),
      attemptApi: TestAttemptApi(
        callOverride: (name, data) async => <String, dynamic>{
          'attemptId': data['attemptId'],
        },
      ),
    );
  }

  Map<String, dynamic> startPayload(String attemptId, String courseId) {
    return <String, dynamic>{
      'attemptId': attemptId,
      'questionIds': ['q1'],
      'studentQuestions': [
        {
          'questionId': 'q1',
          'position': 0,
          'text': 'Capital of Telangana?',
          'options': [
            {'label': 'A', 'text': 'Hyderabad'},
            {'label': 'B', 'text': 'Warangal'},
            {'label': 'C', 'text': 'Nizamabad'},
            {'label': 'D', 'text': 'Karimnagar'},
          ],
          'courseId': courseId,
        },
      ],
      'testSnapshot': {
        'testId': 'test-$courseId-001',
        'title': '$courseId published',
        'courseId': courseId,
        'totalMarks': 1,
        'durationSeconds': 600,
        'negativeMarks': 0.0,
        'instructions': ['Read carefully'],
        'scoringVersion': 'v1',
      },
      'snapshotSchemaVersion': 1,
      'totalMarks': 1,
      'durationSeconds': 600,
      'negativeMarks': 0.0,
      'courseId': courseId,
    };
  }

  testWidgets('1: opening instructions creates no attempt', (tester) async {
    var started = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TestInstructionsScreen(
          test: publishedTest(),
          startAttempt: ({required testId, required startRequestId}) async {
            started += 1;
            return startPayload('a1', 'group-ii');
          },
          engineService: fakeEngine([
            bankQuestion(id: 'q1', courseId: 'group-ii'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test Instructions'), findsOneWidget);
    expect(find.text('Start Test'), findsOneWidget);
    expect(started, 0);
  });

  testWidgets('2: leaving instructions creates no attempt', (tester) async {
    var started = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TestInstructionsScreen(
                      test: publishedTest(),
                      startAttempt: ({required testId, required startRequestId}) async {
                        started += 1;
                        return startPayload('a1', 'group-ii');
                      },
                    ),
                  ),
                );
              },
              child: const Text('open-instructions'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open-instructions'));
    await tester.pumpAndSettle();
    expect(find.text('Start Test'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(started, 0);
    expect(find.text('Start Test'), findsNothing);
  });

  testWidgets(
    '3/15: START TEST creates one Group-II attempt and opens the engine',
    (tester) async {
      final started = <String>[];
      const examId = 'group-ii';
      await tester.pumpWidget(
        MaterialApp(
          home: TestInstructionsScreen(
            test: publishedTest(examId: examId),
            startAttempt: ({required testId, required startRequestId}) async {
              started.add(testId);
              return startPayload('attempt-$examId', examId);
            },
            engineService: fakeEngine([
              bankQuestion(id: 'q1', courseId: examId),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final start = find.byKey(const ValueKey('start-test'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pump();
      await tester.pump();
      expect(started, ['test-$examId-001']);
      expect(find.text('Capital of Telangana?'), findsOneWidget);
      expect(find.text('Start Test'), findsNothing);
    },
  );

  testWidgets(
    '16: START TEST creates one Group-III attempt and opens the engine',
    (tester) async {
      final started = <String>[];
      const examId = 'group-iii';
      await tester.pumpWidget(
        MaterialApp(
          home: TestInstructionsScreen(
            test: publishedTest(examId: examId),
            startAttempt: ({required testId, required startRequestId}) async {
              started.add(testId);
              return startPayload('attempt-$examId', examId);
            },
            engineService: fakeEngine([
              bankQuestion(id: 'q1', courseId: examId),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final start = find.byKey(const ValueKey('start-test'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pump();
      await tester.pump();
      expect(started, ['test-$examId-001']);
      expect(find.text('Capital of Telangana?'), findsOneWidget);
      expect(find.text('Start Test'), findsNothing);
    },
  );

  testWidgets('4: double START creates one attempt', (tester) async {
    var started = 0;
    final gate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: TestInstructionsScreen(
          test: publishedTest(),
          startAttempt: ({required testId, required startRequestId}) async {
            started += 1;
            await gate.future;
            return startPayload('a1', 'group-ii');
          },
          engineService: fakeEngine([
            bankQuestion(id: 'q1', courseId: 'group-ii'),
          ]),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('start-test')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('start-test')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(started, 1);
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(started, 1);
  });

  testWidgets('5: attempt creation failure can be retried', (tester) async {
    var started = 0;
    var fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: TestInstructionsScreen(
          test: publishedTest(),
          startAttempt: ({required testId, required startRequestId}) async {
            started += 1;
            if (fail) throw StateError('callable failed');
            return startPayload('a-retry', 'group-ii');
          },
          engineService: fakeEngine([
            bankQuestion(id: 'q1', courseId: 'group-ii'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final start = find.byKey(const ValueKey('start-test'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(started, 1);
    expect(find.byKey(const ValueKey('start-test-error')), findsOneWidget);
    expect(
      find.text('Unable to start the test. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Capital of Telangana?'), findsNothing);

    fail = false;
    final retry = find.byKey(const ValueKey('retry-start-test'));
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pump();
    await tester.pump();
    expect(started, 2);
    expect(find.text('Capital of Telangana?'), findsOneWidget);
  });
}
