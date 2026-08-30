import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import 'package:telangana_prep/features/progress_cloud/repository/unit_performance_cloud_repository.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_home_screen.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_unit_tests_screen.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/test_attempt_api.dart';
import 'package:telangana_prep/features/test_engine/presentation/screens/test_attempt_flow_screen.dart';
import 'package:telangana_prep/features/test_engine/presentation/test_engine_navigation.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart'
    as engine;
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_instructions_screen.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';
import 'package:telangana_prep/navigation/main_navigation_screen.dart';

void main() {
  const unitTestTitle = 'Kakatiya Unit Drill';
  const kakatiyaTopicId = 'group-ii-paper-ii-part-01-topic-04';

  TestModel catalogTest() {
    return const TestModel(
      id: 'unit-drill-kakatiya-001',
      examId: 'group-ii',
      category: TestCategoryType.chapterTests,
      title: unitTestTitle,
      questionCount: 1,
      marks: 1,
      durationMinutes: 10,
      negativeMarking: '0',
      difficulty: 'Medium',
      status: TestPublicationStatus.published,
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-01',
      syllabusUnitId: kakatiyaTopicId,
    );
  }

  TestService catalogService() {
    return TestService(
      cloudRepository: TestCloudRepository.withLoader((courseId) async {
        if (courseId != 'group-ii') return const [];
        return [catalogTest()];
      }),
    );
  }

  List<Map<String, dynamic>> studentQuestions() {
    return [
      <String, dynamic>{
        'questionId': 'q1',
        'position': 0,
        'text': 'Capital of Telangana?',
        'options': [
          <String, dynamic>{'label': 'A', 'text': 'Hyderabad'},
          <String, dynamic>{'label': 'B', 'text': 'Warangal'},
          <String, dynamic>{'label': 'C', 'text': 'Nizamabad'},
          <String, dynamic>{'label': 'D', 'text': 'Karimnagar'},
        ],
        'content': <String, dynamic>{
          'en': <String, dynamic>{
            'question': 'Capital of Telangana?',
            'options': [
              <String, dynamic>{'text': 'Hyderabad'},
              <String, dynamic>{'text': 'Warangal'},
              <String, dynamic>{'text': 'Nizamabad'},
              <String, dynamic>{'text': 'Karimnagar'},
            ],
          },
        },
        'courseId': 'group-ii',
        'paperId': 'group-ii-paper-ii',
      },
    ];
  }

  Map<String, dynamic> startPayload(String attemptId) {
    return <String, dynamic>{
      'attemptId': attemptId,
      'testId': catalogTest().id,
      'courseId': 'group-ii',
      'questionIds': ['q1'],
      'studentQuestions': studentQuestions(),
      'totalMarks': 1,
      'negativeMarks': 0,
      'totalQuestions': 1,
      'durationSeconds': 600,
    };
  }

  Map<String, dynamic> submitPayload(String attemptId) {
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

  engine.TestService engineService() {
    return engine.TestService(
      attemptApi: TestAttemptApi(
        callOverride: (name, data) async {
          if (name == 'submitTestAttempt') {
            return submitPayload(data['attemptId'] as String);
          }
          throw StateError('unexpected $name');
        },
      ),
    );
  }

  Future<Test> engineTest(engine.TestService service) {
    return service.createTestFromStudentSafeQuestions(
      id: catalogTest().id,
      title: catalogTest().title,
      courseId: 'group-ii',
      studentQuestions: studentQuestions(),
      duration: const Duration(minutes: 10),
      totalMarks: 1,
      negativeMarks: 0,
    );
  }

  Future<void> submitFromExam(WidgetTester tester) async {
    final submit = find.byKey(const ValueKey('submit-attempt'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();
  }

  testWidgets('Result keeps Review Answers and Back to Unit, hides Retry Test', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = engineService();
    final test = await engineTest(service);
    await tester.pumpWidget(
      MaterialApp(
        home: TestAttemptFlowScreen(
          test: test,
          serverAttemptId: 'attempt-result-ui',
          skipInstructions: true,
          engineService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await submitFromExam(tester);

    expect(find.text('Result'), findsOneWidget);
    expect(find.text('Retry Test'), findsNothing);
    expect(find.text('Review Answers'), findsOneWidget);
    expect(find.text('Back to Unit'), findsOneWidget);

    await tester.tap(find.text('Review Answers'));
    await tester.pumpAndSettle();
    expect(find.text('Detailed Analysis'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Result'), findsOneWidget);
    expect(find.text('Detailed Analysis'), findsNothing);
  });

  testWidgets(
    'Back to Unit returns to the existing SyllabusUnitTestsScreen',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navigatorKey = GlobalKey<NavigatorState>();
      final engine = engineService();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(
            key: ValueKey('app-shell'),
            body: Center(child: Text('Chapters landing')),
          ),
        ),
      );

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SyllabusUnitTestsScreen(
            courseId: 'group-ii',
            paperId: 'group-ii-paper-ii',
            partId: 'group-ii-paper-ii-part-01',
            unitId: kakatiyaTopicId,
            testService: catalogService(),
            unitPerformanceRepository: UnitPerformanceCloudRepository(
              store: InMemoryUnitPerformanceDocumentStore(),
              currentUid: () => 'student-a',
            ),
            syllabusCompletionRepository: SyllabusCompletionCloudRepository(
              store: InMemorySyllabusCompletionDocumentStore(),
              currentUid: () => 'student-a',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SyllabusUnitTestsScreen), findsOneWidget);
      expect(find.text('Tests in this Unit'), findsOneWidget);
      expect(find.text(unitTestTitle), findsOneWidget);
      expect(find.text('Chapters landing'), findsNothing);

      navigatorKey.currentState!.push(
        TestEngineNavigation.catalogInstructionsRoute(
          (_) => TestInstructionsScreen(
            test: catalogTest(),
            startAttempt: ({required testId, required startRequestId}) async {
              return startPayload('attempt-unit-nav');
            },
            engineService: engine,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Test Instructions'), findsOneWidget);

      final start = find.byKey(const ValueKey('start-test'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();

      expect(find.text('Capital of Telangana?'), findsOneWidget);
      await submitFromExam(tester);

      expect(find.text('Result'), findsOneWidget);
      expect(find.text('Retry Test'), findsNothing);
      expect(find.text('Review Answers'), findsOneWidget);
      expect(find.text('Back to Unit'), findsOneWidget);

      await tester.tap(find.text('Review Answers'));
      await tester.pumpAndSettle();
      expect(find.text('Detailed Analysis'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Result'), findsOneWidget);

      await tester.tap(find.text('Back to Unit'));
      await tester.pumpAndSettle();

      expect(find.byType(SyllabusUnitTestsScreen), findsOneWidget);
      expect(find.text('Tests in this Unit'), findsOneWidget);
      expect(find.text(unitTestTitle), findsOneWidget);
      expect(find.text('Ancient and Medieval Telangana'), findsWidgets);
      expect(find.text('Result'), findsNothing);
      expect(find.text('Test Instructions'), findsNothing);
      expect(find.text('Chapters landing'), findsNothing);
      expect(find.byType(MainNavigationScreen), findsNothing);
      expect(find.byType(SyllabusHomeScreen), findsNothing);
    },
  );

  testWidgets(
    'Back to Unit pops only the named attempt when there is no catalog instructions route',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navigatorKey = GlobalKey<NavigatorState>();
      final service = engineService();
      final test = await engineTest(service);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Chapters landing')),
          ),
        ),
      );

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Practice parent')),
            body: Center(
              child: TextButton(
                onPressed: () {
                  TestEngineNavigation.openTest(
                    context,
                    test: test,
                    serverAttemptId: 'attempt-practice',
                    skipInstructions: true,
                    engineService: service,
                  );
                },
                child: const Text('Open attempt'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open attempt'));
      await tester.pumpAndSettle();

      await submitFromExam(tester);
      expect(find.text('Result'), findsOneWidget);

      await tester.tap(find.text('Back to Unit'));
      await tester.pumpAndSettle();

      expect(find.text('Practice parent'), findsOneWidget);
      expect(find.text('Result'), findsNothing);
      expect(find.text('Chapters landing'), findsNothing);
    },
  );
}
