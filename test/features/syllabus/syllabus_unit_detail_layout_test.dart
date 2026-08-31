import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/progress/data/models/unit_performance.dart';
import 'package:telangana_prep/features/progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import 'package:telangana_prep/features/progress_cloud/repository/unit_performance_cloud_repository.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_unit_tests_screen.dart';
import 'package:telangana_prep/features/syllabus/presentation/syllabus_visual.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/unit_detail_performance_card.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/unit_detail_test_card.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_instructions_screen.dart';
import 'package:telangana_prep/features/tests/presentation/widgets/test_card.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';
import 'package:telangana_prep/widgets/common/app_progress_ring.dart';

void main() {
  const kakatiyaUnitId = 'group-ii-paper-ii-part-01-topic-04';
  const groupIiiPaperIUnit = 'group-iii-paper-i-unit-01';
  const groupIiiPaperIiUnit = 'group-iii-paper-ii-part-i-unit-02';

  UnitPerformance seededPerformance({
    required String scopeKey,
    required String courseId,
    required String paperId,
    String? partId,
    required String unitId,
  }) {
    return UnitPerformance(
      scopeKey: scopeKey,
      courseId: courseId,
      paperId: paperId,
      partId: partId,
      syllabusUnitId: unitId,
      testsAttempted: 21,
      testsCompleted: 21,
      questionsAttempted: 10,
      correct: 9,
      wrong: 1,
      skipped: 11,
      totalMarks: 100,
      marksObtained: 90,
      accuracy: 90,
      percentage: 90,
      bestMarks: 100,
      bestPercentage: 43,
      latestAttemptAt: DateTime.utc(2026, 8, 15, 12, 0),
      authority: 'server_verified',
    );
  }

  TestModel publishedTest({
    required String id,
    required String courseId,
    required String paperId,
    String? partId,
    required String unitId,
    String title = 'Unit Test 1',
    int questionCount = 20,
    int marks = 20,
  }) {
    return TestModel(
      id: id,
      examId: courseId,
      category: TestCategoryType.chapterTests,
      title: title,
      questionCount: questionCount,
      marks: marks,
      durationMinutes: 20,
      negativeMarking: '0',
      difficulty: 'Medium',
      status: TestPublicationStatus.published,
      paperId: paperId,
      partId: partId,
      syllabusUnitId: unitId,
    );
  }

  TestService catalog(List<TestModel> tests) {
    return TestService(
      cloudRepository: TestCloudRepository.withLoader((courseId) async {
        return [
          for (final test in tests)
            if (test.examId == courseId) test,
        ];
      }),
    );
  }

  SyllabusCompletionCloudRepository emptyCompletion() {
    return SyllabusCompletionCloudRepository(
      store: InMemorySyllabusCompletionDocumentStore(),
      currentUid: () => 'student-a',
      mutationClient: _NoopCompletionMutationClient(),
    );
  }

  UnitPerformanceCloudRepository performanceRepo({
    UnitPerformance? performance,
  }) {
    final store = InMemoryUnitPerformanceDocumentStore();
    if (performance != null) {
      store.seed(
        'student-a',
        performance.scopeKey,
        performance.toMap()..['uid'] = 'student-a',
      );
    }
    return UnitPerformanceCloudRepository(
      store: store,
      currentUid: () => 'student-a',
    );
  }

  Future<FlutterErrorDetails?> pumpAt(
    WidgetTester tester,
    Size size, {
    required Widget home,
  }) async {
    final view = tester.view;
    view.physicalSize = size;
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    FlutterErrorDetails? overflow;
    final old = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflow ??= details;
      }
      old?.call(details);
    };
    addTearDown(() => FlutterError.onError = old);

    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pumpAndSettle();
    return overflow;
  }

  Widget groupIiScreen({
    List<TestModel>? tests,
    UnitPerformance? performance,
  }) {
    return SyllabusUnitTestsScreen(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-01',
      unitId: kakatiyaUnitId,
      testService: catalog(
        tests ??
            [
              publishedTest(
                id: 't1',
                courseId: 'group-ii',
                paperId: 'group-ii-paper-ii',
                partId: 'group-ii-paper-ii-part-01',
                unitId: kakatiyaUnitId,
              ),
            ],
      ),
      unitPerformanceRepository: performanceRepo(performance: performance),
      syllabusCompletionRepository: emptyCompletion(),
    );
  }

  testWidgets('header shows unit title and course/paper context', (
    tester,
  ) async {
    final overflow = await pumpAt(
      tester,
      const Size(390, 844),
      home: groupIiScreen(),
    );
    expect(overflow, isNull, reason: overflow?.exceptionAsString());

    expect(find.text('Ancient and Medieval Telangana'), findsOneWidget);
    expect(find.text('Group-II · Paper II'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      SyllabusVisual.page,
    );
  });

  testWidgets('Group-III Paper-I uses H2.2.1 display aliases', (tester) async {
    await pumpAt(
      tester,
      const Size(390, 844),
      home: SyllabusUnitTestsScreen(
        courseId: 'group-iii',
        paperId: 'group-iii-paper-i',
        unitId: groupIiiPaperIUnit,
        testService: catalog(const []),
        unitPerformanceRepository: performanceRepo(),
        syllabusCompletionRepository: emptyCompletion(),
      ),
    );

    expect(find.text('Current Affairs'), findsOneWidget);
    expect(find.text('Group-III · Paper-I'), findsOneWidget);
    expect(
      find.text('Current Affairs – Regional, National & International'),
      findsNothing,
    );
  });

  testWidgets('Performance card is compact and uses existing values', (
    tester,
  ) async {
    const scopeKey =
        'v1|group-ii|group-ii-paper-ii|group-ii-paper-ii-part-01|'
        '$kakatiyaUnitId';
    await pumpAt(
      tester,
      const Size(390, 844),
      home: groupIiScreen(
        performance: seededPerformance(
          scopeKey: scopeKey,
          courseId: 'group-ii',
          paperId: 'group-ii-paper-ii',
          partId: 'group-ii-paper-ii-part-01',
          unitId: kakatiyaUnitId,
        ),
      ),
    );

    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('Best %'), findsOneWidget);
    expect(find.text('43%'), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('Best Score'), findsOneWidget);
    expect(find.text('100'), findsWidgets);
    expect(find.text('Tests'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(find.text('Questions'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('Wrong'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Skipped'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(find.byIcon(Icons.assignment_rounded), findsOneWidget);
    expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(find.byType(AppProgressRing), findsNothing);
    expect(find.text('Latest Attempt'), findsNothing);
    expect(find.text('Unit Completion'), findsNothing);

    final card = tester.getSize(find.byType(UnitDetailPerformanceCard));
    expect(card.height, lessThan(340));
    expect(card.height, greaterThan(120));
  });

  testWidgets('no-attempt state is compact and has no zero stats', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const Size(390, 844),
      home: groupIiScreen(),
    );

    expect(find.text('No attempts yet'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    expect(find.text('Best %'), findsNothing);
    expect(find.text('Correct'), findsNothing);
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('test card shows Start and opens catalog instructions', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const Size(390, 844),
      home: groupIiScreen(),
    );

    expect(find.text('Tests in this Unit'), findsOneWidget);
    expect(find.byType(UnitDetailTestCard), findsOneWidget);
    expect(find.byType(TestCard), findsNothing);
    expect(find.text('Unit Test 1'), findsOneWidget);
    expect(find.text('20 Questions • 20 Marks'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.byIcon(Icons.description_rounded), findsOneWidget);

    final start = tester.widget<Material>(
      find.byKey(const ValueKey('unit-detail-start-button')),
    );
    expect(start.color, SyllabusVisual.accent);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.byType(TestInstructionsScreen), findsOneWidget);
    expect(find.text('Test Instructions'), findsOneWidget);
  });

  testWidgets('tapping the test card also opens catalog instructions', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const Size(390, 844),
      home: groupIiScreen(),
    );

    await tester.tap(find.text('Unit Test 1'));
    await tester.pumpAndSettle();
    expect(find.byType(TestInstructionsScreen), findsOneWidget);
  });

  testWidgets('empty tests keep meaning without a Start button', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const Size(390, 844),
      home: groupIiScreen(tests: const []),
    );

    expect(find.text('No tests available'), findsOneWidget);
    expect(
      find.text('There are no published tests in this syllabus unit yet.'),
      findsOneWidget,
    );
    expect(find.text('Start'), findsNothing);
    expect(find.byType(UnitDetailTestCard), findsNothing);
  });

  testWidgets('back navigation pops to the previous route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => groupIiScreen(),
                  ),
                );
              },
              child: const Text('open unit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open unit'));
    await tester.pumpAndSettle();
    expect(find.byType(SyllabusUnitTestsScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(SyllabusUnitTestsScreen), findsNothing);
    expect(find.text('open unit'), findsOneWidget);
  });

  testWidgets('responsive layouts at 360/390/430 including long names', (
    tester,
  ) async {
    const scopeKey =
        'v1|group-iii|group-iii-paper-ii|group-iii-paper-ii-part-i|'
        '$groupIiiPaperIiUnit';
    final longTest = publishedTest(
      id: 'long',
      courseId: 'group-iii',
      paperId: 'group-iii-paper-ii',
      partId: 'group-iii-paper-ii-part-i',
      unitId: groupIiiPaperIiUnit,
      title:
          'Very Long Telangana History Revision Test With Extra Words For Wrap',
    );

    for (final size in [
      const Size(360, 740),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      final overflow = await pumpAt(
        tester,
        size,
        home: SyllabusUnitTestsScreen(
          courseId: 'group-iii',
          paperId: 'group-iii-paper-ii',
          partId: 'group-iii-paper-ii-part-i',
          unitId: groupIiiPaperIiUnit,
          testService: catalog([longTest]),
          unitPerformanceRepository: performanceRepo(
            performance: seededPerformance(
              scopeKey: scopeKey,
              courseId: 'group-iii',
              paperId: 'group-iii-paper-ii',
              partId: 'group-iii-paper-ii-part-i',
              unitId: groupIiiPaperIiUnit,
            ),
          ),
          syllabusCompletionRepository: emptyCompletion(),
        ),
      );
      expect(overflow, isNull, reason: '${size.width}: ${overflow?.exceptionAsString()}');
      expect(find.text('Performance'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.byType(UnitDetailTestCard), findsOneWidget);
    }
  });
}

class _NoopCompletionMutationClient implements SyllabusCompletionMutationClient {
  @override
  Future<Map<String, dynamic>> setCompletionStatus({
    required String courseId,
    required String paperId,
    String? partId,
    required String syllabusUnitId,
    required String status,
  }) async {
    return {
      'status': status,
      'completion': null,
      'scopeKey': 'v1|$courseId|$paperId|${partId ?? ''}|$syllabusUnitId',
    };
  }
}
