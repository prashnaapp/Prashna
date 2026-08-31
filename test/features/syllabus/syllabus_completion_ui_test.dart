import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/progress/data/models/syllabus_completion.dart';
import 'package:telangana_prep/features/progress/presentation/widgets/syllabus_completion_card.dart';
import 'package:telangana_prep/features/progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import 'package:telangana_prep/features/progress_cloud/repository/unit_performance_cloud_repository.dart';
import 'package:telangana_prep/features/syllabus/data/models/canonical_scope.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_unit_tests_screen.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestModel publishedTest() {
    return TestModel(
      id: 't1',
      examId: 'group-iii',
      category: TestCategoryType.chapterTests,
      title: 'Unit Test',
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

  group('SyllabusCompletionCard', () {
    testWidgets('21: displays Not Started / In Progress / Completed', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyllabusCompletionCard(
              completion: SyllabusCompletion(
                scopeKey: 'k',
                courseId: 'group-ii',
                paperId: 'group-ii-paper-i',
                syllabusUnitId: 'group-ii-paper-i-area-01',
                status: SyllabusCompletionStatus.notStarted,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Completion: Not Started'), findsOneWidget);
      expect(find.text('Mark as In Progress'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyllabusCompletionCard(
              completion: SyllabusCompletion(
                scopeKey: 'k',
                courseId: 'group-ii',
                paperId: 'group-ii-paper-i',
                syllabusUnitId: 'group-ii-paper-i-area-01',
                status: SyllabusCompletionStatus.inProgress,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Completion: In Progress'), findsOneWidget);
      expect(find.text('Mark as Completed'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyllabusCompletionCard(
              completion: SyllabusCompletion(
                scopeKey: 'k',
                courseId: 'group-ii',
                paperId: 'group-ii-paper-i',
                syllabusUnitId: 'group-ii-paper-i-area-01',
                status: SyllabusCompletionStatus.completed,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Completion: Completed'), findsOneWidget);
      expect(find.text('Mark as In Progress'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });
  });

  group('SyllabusUnitTestsScreen completion', () {
    testWidgets('H2.3: completion card is not shown; tests remain', (
      tester,
    ) async {
      final store = InMemorySyllabusCompletionDocumentStore();
      final completionRepo = SyllabusCompletionCloudRepository(
        store: store,
        currentUid: () => 'student-a',
        mutationClient: _FakeMutationClient(store, uid: 'student-a'),
      );
      final performanceRepo = UnitPerformanceCloudRepository(
        store: InMemoryUnitPerformanceDocumentStore(),
        currentUid: () => 'student-a',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SyllabusUnitTestsScreen(
            courseId: 'group-iii',
            paperId: 'group-iii-paper-ii',
            partId: 'group-iii-paper-ii-part-i',
            unitId: 'group-iii-paper-ii-part-i-unit-02',
            testService: catalog([publishedTest()]),
            unitPerformanceRepository: performanceRepo,
            syllabusCompletionRepository: completionRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unit Completion'), findsNothing);
      expect(find.text('Completion: Not Started'), findsNothing);
      expect(find.text('Mark as In Progress'), findsNothing);
      expect(find.byType(SyllabusCompletionCard), findsNothing);
      expect(find.text('Performance'), findsOneWidget);
      expect(find.text('Unit Test'), findsOneWidget);
      expect(
        store.lastScopeKey,
        'v1|group-iii|group-iii-paper-ii|group-iii-paper-ii-part-i|'
        'group-iii-paper-ii-part-i-unit-02',
      );
    });

    testWidgets('21/23: Group-II Paper-I still loads completion by scopeKey', (
      tester,
    ) async {
      final store = InMemorySyllabusCompletionDocumentStore();
      final completionRepo = SyllabusCompletionCloudRepository(
        store: store,
        currentUid: () => 'student-a',
        mutationClient: _FakeMutationClient(store, uid: 'student-a'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SyllabusUnitTestsScreen(
            courseId: 'group-ii',
            paperId: 'group-ii-paper-i',
            unitId: 'group-ii-paper-i-area-01',
            testService: catalog(const []),
            unitPerformanceRepository: UnitPerformanceCloudRepository(
              store: InMemoryUnitPerformanceDocumentStore(),
              currentUid: () => 'student-a',
            ),
            syllabusCompletionRepository: completionRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SyllabusCompletionCard), findsNothing);
      expect(find.text('Mark as In Progress'), findsNothing);
      expect(
        store.lastScopeKey,
        'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01',
      );
    });

    testWidgets('22: completion read failure is hidden; tests remain', (
      tester,
    ) async {
      final completionRepo = SyllabusCompletionCloudRepository(
        store: _FailingCompletionStore(),
        currentUid: () => 'student-a',
        mutationClient: _FakeMutationClient(
          InMemorySyllabusCompletionDocumentStore(),
          uid: 'student-a',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SyllabusUnitTestsScreen(
            courseId: 'group-iii',
            paperId: 'group-iii-paper-ii',
            partId: 'group-iii-paper-ii-part-i',
            unitId: 'group-iii-paper-ii-part-i-unit-02',
            testService: catalog([publishedTest()]),
            unitPerformanceRepository: UnitPerformanceCloudRepository(
              store: InMemoryUnitPerformanceDocumentStore(),
              currentUid: () => 'student-a',
            ),
            syllabusCompletionRepository: completionRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load unit completion.'), findsNothing);
      expect(find.text('Unit Test'), findsOneWidget);
    });

    testWidgets('18/20: performance empty does not auto-complete', (
      tester,
    ) async {
      final store = InMemorySyllabusCompletionDocumentStore();
      final completionRepo = SyllabusCompletionCloudRepository(
        store: store,
        currentUid: () => 'student-a',
        mutationClient: _FakeMutationClient(store, uid: 'student-a'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SyllabusUnitTestsScreen(
            courseId: 'group-iii',
            paperId: 'group-iii-paper-ii',
            partId: 'group-iii-paper-ii-part-i',
            unitId: 'group-iii-paper-ii-part-i-unit-02',
            testService: catalog([publishedTest()]),
            unitPerformanceRepository: UnitPerformanceCloudRepository(
              store: InMemoryUnitPerformanceDocumentStore(),
              currentUid: () => 'student-a',
            ),
            syllabusCompletionRepository: completionRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No attempts yet'), findsOneWidget);
      expect(find.text('Mark as Completed'), findsNothing);
      expect(find.text('Completion: Completed'), findsNothing);
      expect(find.text('0%'), findsNothing);
    });
  });
}

class _FailingCompletionStore implements SyllabusCompletionDocumentStore {
  @override
  Future<Map<String, dynamic>?> getCompletion(
    String uid,
    String scopeKey,
  ) async {
    throw StateError('simulated read failure');
  }
}

class _FakeMutationClient implements SyllabusCompletionMutationClient {
  _FakeMutationClient(this.store, {required this.uid});

  final InMemorySyllabusCompletionDocumentStore store;
  final String uid;

  @override
  Future<Map<String, dynamic>> setCompletionStatus({
    required String courseId,
    required String paperId,
    String? partId,
    required String syllabusUnitId,
    required String status,
  }) async {
    final scope = CanonicalScope.tryFromSyllabusUnit(
      courseId: courseId,
      paperId: paperId,
      partId: partId,
      syllabusUnitId: syllabusUnitId,
    )!;
    if (status == 'not_started') {
      store.remove(uid, scope.scopeKey);
      return {
        'status': 'not_started',
        'completion': null,
        'scopeKey': scope.scopeKey,
      };
    }
    final data = {
      'uid': uid,
      'scopeKey': scope.scopeKey,
      'courseId': courseId,
      'paperId': paperId,
      'partId': ?partId,
      'syllabusUnitId': syllabusUnitId,
      'status': status,
      'updatedAt': '2026-08-15T12:00:00.000Z',
      if (status == 'completed') 'completedAt': '2026-08-15T12:00:00.000Z',
    };
    store.seed(uid, scope.scopeKey, data);
    return {'status': status, 'completion': data, 'scopeKey': scope.scopeKey};
  }
}
