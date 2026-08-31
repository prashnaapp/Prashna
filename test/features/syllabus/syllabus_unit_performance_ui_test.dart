import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/progress/data/models/unit_performance.dart';
import 'package:telangana_prep/features/progress/presentation/widgets/unit_performance_card.dart';
import 'package:telangana_prep/features/progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import 'package:telangana_prep/features/progress_cloud/repository/unit_performance_cloud_repository.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_unit_tests_screen.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/unit_detail_performance_card.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UnitPerformance performance({
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
      testsAttempted: 2,
      testsCompleted: 2,
      questionsAttempted: 8,
      correct: 5,
      wrong: 2,
      skipped: 1,
      totalMarks: 8,
      marksObtained: 5,
      accuracy: 71.4,
      percentage: 62.5,
      bestMarks: 5,
      bestPercentage: 100,
      latestAttemptAt: DateTime.utc(2026, 8, 15, 12, 0),
      authority: 'server_verified',
    );
  }

  TestModel publishedTest(String id) {
    return TestModel(
      id: id,
      examId: 'group-iii',
      category: TestCategoryType.chapterTests,
      title: 'Unit Test $id',
      questionCount: 10,
      marks: 10,
      durationMinutes: 10,
      negativeMarking: '0',
      difficulty: 'Medium',
      status: TestPublicationStatus.published,
      paperId: 'group-iii-paper-ii',
      partId: 'group-iii-paper-ii-part-i',
      syllabusUnitId: 'group-iii-paper-ii-part-i-unit-02',
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

  group('UnitPerformanceCard', () {
    testWidgets('7: renders all approved metrics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitPerformanceCard(
              performance: performance(
                scopeKey:
                    'v1|group-iii|group-iii-paper-ii|group-iii-paper-ii-part-i|'
                    'group-iii-paper-ii-part-i-unit-02',
                courseId: 'group-iii',
                paperId: 'group-iii-paper-ii',
                partId: 'group-iii-paper-ii-part-i',
                unitId: 'group-iii-paper-ii-part-i-unit-02',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tests Attempted'), findsOneWidget);
      expect(find.text('Questions Attempted'), findsOneWidget);
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('Wrong'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('Best Percentage'), findsOneWidget);
      expect(find.text('Latest Attempt'), findsOneWidget);
      expect(find.text('No attempts yet'), findsNothing);
      expect(find.textContaining('Weak'), findsNothing);
      expect(find.textContaining('Streak'), findsNothing);
    });

    testWidgets('3: empty state shows No attempts yet without zeros', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: UnitPerformanceCard())),
      );

      expect(find.text('No attempts yet'), findsOneWidget);
      expect(find.text('Tests Attempted'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('4: error state shows Retry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitPerformanceCard(
              errorMessage: 'Unable to load unit performance.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Unable to load unit performance.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  group('SyllabusUnitTestsScreen', () {
    SyllabusCompletionCloudRepository emptyCompletionRepo() {
      return SyllabusCompletionCloudRepository(
        store: InMemorySyllabusCompletionDocumentStore(),
        currentUid: () => 'student-a',
        mutationClient: _NoopCompletionMutationClient(),
      );
    }

    testWidgets(
      '5/6/16: tests remain visible while performance loads/fails; shared card',
      (tester) async {
        final gate = Completer<Map<String, dynamic>?>();
        final repo = UnitPerformanceCloudRepository(
          store: _GatedStore(gate),
          currentUid: () => 'student-a',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SyllabusUnitTestsScreen(
              courseId: 'group-iii',
              paperId: 'group-iii-paper-ii',
              partId: 'group-iii-paper-ii-part-i',
              unitId: 'group-iii-paper-ii-part-i-unit-02',
              testService: catalog([publishedTest('t-1')]),
              unitPerformanceRepository: repo,
              syllabusCompletionRepository: emptyCompletionRepo(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        expect(find.text('Unit Test t-1'), findsOneWidget);
        expect(find.text('Performance'), findsOneWidget);
        expect(find.byType(UnitDetailPerformanceCard), findsOneWidget);

        gate.completeError(Exception('network down'));
        await tester.pumpAndSettle();

        expect(find.text('Unit Test t-1'), findsOneWidget);
        expect(find.text('Unable to load unit performance.'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      },
    );

    testWidgets('14: does not fall back to legacy progress text', (
      tester,
    ) async {
      final store = InMemoryUnitPerformanceDocumentStore();
      final repo = UnitPerformanceCloudRepository(
        store: store,
        currentUid: () => 'student-a',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SyllabusUnitTestsScreen(
            courseId: 'group-ii',
            paperId: 'group-ii-paper-i',
            unitId: 'group-ii-paper-i-area-01',
            testService: catalog(const []),
            unitPerformanceRepository: repo,
            syllabusCompletionRepository: emptyCompletionRepo(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No attempts yet'), findsOneWidget);
      expect(find.textContaining('chapter'), findsNothing);
      expect(find.textContaining('legacy'), findsNothing);
      expect(find.text('Tests Attempted'), findsNothing);
    });

    testWidgets('historical performance remains when no published tests', (
      tester,
    ) async {
      const scopeKey =
          'v1|group-ii|group-ii-paper-ii|group-ii-paper-ii-part-01|'
          'group-ii-paper-ii-part-01-topic-04';
      final store = InMemoryUnitPerformanceDocumentStore();
      store.seed(
        'student-a',
        scopeKey,
        performance(
          scopeKey: scopeKey,
          courseId: 'group-ii',
          paperId: 'group-ii-paper-ii',
          partId: 'group-ii-paper-ii-part-01',
          unitId: 'group-ii-paper-ii-part-01-topic-04',
        ).toMap()..['uid'] = 'student-a',
      );
      final repo = UnitPerformanceCloudRepository(
        store: store,
        currentUid: () => 'student-a',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SyllabusUnitTestsScreen(
            courseId: 'group-ii',
            paperId: 'group-ii-paper-ii',
            partId: 'group-ii-paper-ii-part-01',
            unitId: 'group-ii-paper-ii-part-01-topic-04',
            testService: catalog(const []),
            unitPerformanceRepository: repo,
            syllabusCompletionRepository: emptyCompletionRepo(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tests'), findsOneWidget);
      expect(find.text('Best Score'), findsOneWidget);
      expect(find.text('No tests available'), findsOneWidget);
      expect(find.text('No attempts yet'), findsNothing);
    });
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

class _GatedStore implements UnitPerformanceDocumentStore {
  _GatedStore(this.gate);

  final Completer<Map<String, dynamic>?> gate;

  @override
  Future<Map<String, dynamic>?> getUnitPerformance(
    String uid,
    String scopeKey,
  ) {
    return gate.future;
  }
}
