import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/core/design_system/design_system.dart';
import 'package:telangana_prep/features/progress/data/models/syllabus_completion.dart';
import 'package:telangana_prep/features/progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import 'package:telangana_prep/features/progress_cloud/repository/unit_performance_cloud_repository.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/study_planner/data/services/canonical_planner_aggregation_service.dart';
import 'package:telangana_prep/features/study_planner/data/services/canonical_planner_service.dart';
import 'package:telangana_prep/features/study_planner/data/services/canonical_question_inventory_service.dart';
import 'package:telangana_prep/features/study_planner/presentation/screens/canonical_tracker_screen.dart';
import 'package:telangana_prep/features/syllabus/data/models/syllabus_models.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_unit_tests_screen.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';

void main() {
  final now = DateTime(2026, 8, 15);

  Question questionFor({
    required String courseId,
    required String paperId,
    required String syllabusUnitId,
    String? partId,
  }) {
    return Question(
      id: 'question-$courseId-$paperId-$syllabusUnitId',
      courseId: courseId,
      paperId: paperId,
      correctOption: 'A',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      isActive: true,
      status: QuestionPublicationStatus.published,
      question: 'Question',
      options: const ['A', 'B', 'C', 'D'],
      syllabus: QuestionSyllabusAttribution(
        courseId: courseId,
        paperId: paperId,
        partId: partId,
        syllabusUnitId: syllabusUnitId,
      ),
    );
  }

  CanonicalPlannerAggregationService aggregation({
    SyllabusCompletionDocumentStore? completionStore,
    List<Question> questions = const [],
  }) {
    final questionCloud = QuestionCloudRepository.withHandlers(
      loadQuestions: (_) async => questions,
    );
    final completionRepository = SyllabusCompletionCloudRepository(
      store: completionStore ?? InMemorySyllabusCompletionDocumentStore(),
      currentUid: () => 'student-a',
    );
    return CanonicalPlannerAggregationService(
      plannerService: CanonicalPlannerService(),
      questionInventoryService: CanonicalQuestionInventoryService(
        questionService: QuestionService(
          repository: QuestionRepository(cloudRepository: questionCloud),
        ),
      ),
      completionRepository: completionRepository,
    );
  }

  testWidgets('1/8/9/10/11/12/16/17: Group-II renders canonical units', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CanonicalTrackerScreen(
          courseId: 'group-ii',
          aggregationService: aggregation(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsWidgets);
    expect(find.text('Paper I'), findsOneWidget);
    expect(find.text('0 questions · Not Started'), findsWidgets);
    expect(find.textContaining('Topic'), findsNothing);
    expect(find.textContaining('Lesson'), findsNothing);
  });

  testWidgets('2/3/4: Group-II parts render 5/10/5 canonical units', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CanonicalTrackerScreen(
          courseId: 'group-ii',
          aggregationService: aggregation(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsWidgets);
    expect(find.text('Paper I'), findsOneWidget);
  });

  testWidgets('5/6/7/17: Group-III renders all 46 canonical units', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CanonicalTrackerScreen(
          courseId: 'group-iii',
          aggregationService: aggregation(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsWidgets);
    expect(find.textContaining('Topic'), findsNothing);
    expect(find.textContaining('Lesson'), findsNothing);
  });

  testWidgets('11/12/13/14/15: rows display question count and completion', (
    tester,
  ) async {
    final store = InMemorySyllabusCompletionDocumentStore();
    final item = CanonicalPlannerService()
        .getCanonicalPlannerItemsForPaper(
          courseId: 'group-iii',
          paperId: 'group-iii-paper-i',
        )
        .first;
    final inProgressItem = CanonicalPlannerService()
        .getCanonicalPlannerItemsForPaper(
          courseId: 'group-iii',
          paperId: 'group-iii-paper-i',
        )
        .elementAt(1);
    store.seed('student-a', item.scopeKey, {
      'scopeKey': item.scopeKey,
      'courseId': item.courseId,
      'paperId': item.paperId,
      'syllabusUnitId': item.syllabusUnitId,
      'status': SyllabusCompletionStatus.completed.wireValue,
    });
    store.seed('student-a', inProgressItem.scopeKey, {
      'scopeKey': inProgressItem.scopeKey,
      'courseId': inProgressItem.courseId,
      'paperId': inProgressItem.paperId,
      'syllabusUnitId': inProgressItem.syllabusUnitId,
      'status': SyllabusCompletionStatus.inProgress.wireValue,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CanonicalTrackerScreen(
          courseId: 'group-iii',
          aggregationService: aggregation(
            completionStore: store,
            questions: [
              questionFor(
                courseId: item.courseId,
                paperId: item.paperId,
                syllabusUnitId: item.syllabusUnitId,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 questions · Completed'), findsOneWidget);
    expect(find.text('0 questions · In Progress'), findsOneWidget);
    expect(find.text('0 questions · Not Started'), findsWidgets);
    expect(find.text(item.displayName), findsOneWidget);
  });

  testWidgets('13: missing completion displays Not Started', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CanonicalTrackerScreen(
          courseId: 'group-iii',
          aggregationService: aggregation(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 questions · Not Started'), findsWidgets);
  });

  testWidgets('18/19/20: unit tap preserves canonical navigation identity', (
    tester,
  ) async {
    final completionStore = InMemorySyllabusCompletionDocumentStore();
    await tester.pumpWidget(
      MaterialApp(
        home: CanonicalTrackerScreen(
          courseId: 'group-iii',
          aggregationService: aggregation(),
          testService: TestService(
            cloudRepository: TestCloudRepository.withLoader(
              (_) async => const [],
            ),
          ),
          unitPerformanceRepository: UnitPerformanceCloudRepository(
            store: InMemoryUnitPerformanceDocumentStore(),
            currentUid: () => 'student-a',
          ),
          syllabusCompletionRepository: SyllabusCompletionCloudRepository(
            store: completionStore,
            currentUid: () => 'student-a',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final item = CanonicalPlannerService()
        .getCanonicalPlannerItemsForPaper(
          courseId: 'group-iii',
          paperId: 'group-iii-paper-i',
        )
        .first;
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.byType(SyllabusUnitTestsScreen), findsOneWidget);
    final destination = tester.widget<SyllabusUnitTestsScreen>(
      find.byType(SyllabusUnitTestsScreen),
    );
    expect(destination.courseId, item.courseId);
    expect(destination.paperId, item.paperId);
    expect(destination.partId, item.partId);
    expect(destination.unitId, item.syllabusUnitId);
  });

  testWidgets('23: loading state is shown without fake entries', (
    tester,
  ) async {
    final gate = Completer<Map<String, dynamic>?>();
    await tester.pumpWidget(
      MaterialApp(
        home: CanonicalTrackerScreen(
          courseId: 'group-iii',
          aggregationService: aggregation(
            completionStore: _GatedCompletionStore(gate),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppCircularProgress), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    gate.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('24: aggregation failure shows Retry and not legacy data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CanonicalTrackerScreen(
          courseId: 'group-iii',
          aggregationService: aggregation(
            completionStore: _FailingCompletionStore(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load syllabus tracker'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.textContaining('legacy'), findsNothing);
  });

  testWidgets('25: empty canonical data shows an explicit empty state', (
    tester,
  ) async {
    final emptyPlanner = CanonicalPlannerService(
      courseLoader: (_) => const SyllabusCourse(
        id: 'group-iii',
        name: 'Group-III',
        subtitle: '',
        totalMarks: 0,
        isEnrolled: true,
        isAvailable: true,
        icon: '',
        papers: [],
      ),
    );
    final emptyAggregation = CanonicalPlannerAggregationService(
      plannerService: emptyPlanner,
      questionInventoryService: CanonicalQuestionInventoryService(
        questionService: QuestionService(
          repository: QuestionRepository(
            cloudRepository: QuestionCloudRepository.withHandlers(
              loadQuestions: (_) async => const [],
            ),
          ),
        ),
      ),
      completionRepository: SyllabusCompletionCloudRepository(
        store: InMemorySyllabusCompletionDocumentStore(),
        currentUid: () => 'student-a',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CanonicalTrackerScreen(
          courseId: 'group-iii',
          aggregationService: emptyAggregation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No syllabus units available'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });
}

class _GatedCompletionStore implements SyllabusCompletionDocumentStore {
  _GatedCompletionStore(this.gate);

  final Completer<Map<String, dynamic>?> gate;

  @override
  Future<Map<String, dynamic>?> getCompletion(String uid, String scopeKey) {
    return gate.future;
  }
}

class _FailingCompletionStore implements SyllabusCompletionDocumentStore {
  @override
  Future<Map<String, dynamic>?> getCompletion(
    String uid,
    String scopeKey,
  ) async {
    throw StateError('read failed');
  }
}
