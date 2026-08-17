import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/progress/data/models/syllabus_completion.dart';
import 'package:telangana_prep/features/progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/study_planner/data/models/canonical_planner_models.dart';
import 'package:telangana_prep/features/study_planner/data/services/canonical_planner_aggregation_service.dart';
import 'package:telangana_prep/features/study_planner/data/services/canonical_planner_service.dart';
import 'package:telangana_prep/features/study_planner/data/services/canonical_question_inventory_service.dart';
import 'package:telangana_prep/features/syllabus/data/models/canonical_scope.dart';

void main() {
  final now = DateTime(2026, 8, 15);

  Question question({
    required String id,
    required String courseId,
    required String paperId,
    String? partId,
    String? syllabusUnitId,
    String? topicId,
    String? lessonId,
  }) {
    return Question(
      id: id,
      courseId: courseId,
      paperId: paperId,
      topicId: topicId ?? '',
      correctOption: 'A',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      isActive: true,
      status: QuestionPublicationStatus.published,
      question: id,
      options: const ['A', 'B', 'C', 'D'],
      syllabus: QuestionSyllabusAttribution(
        courseId: courseId,
        paperId: paperId,
        partId: partId,
        syllabusUnitId: syllabusUnitId,
        topicId: topicId,
        lessonId: lessonId,
      ),
    );
  }

  CanonicalPlannerAggregationService aggregation({
    List<Question> Function()? readBank,
    SyllabusCompletionDocumentStore? completionStore,
  }) {
    final cloud = QuestionCloudRepository.withHandlers(
      loadQuestions: (_) async => readBank?.call() ?? const [],
    );
    final questionService = QuestionService(
      repository: QuestionRepository(cloudRepository: cloud),
    );
    final completionRepository = SyllabusCompletionCloudRepository(
      store: completionStore ?? InMemorySyllabusCompletionDocumentStore(),
      currentUid: () => 'student-a',
    );
    return CanonicalPlannerAggregationService(
      plannerService: CanonicalPlannerService(),
      questionInventoryService: CanonicalQuestionInventoryService(
        questionService: questionService,
      ),
      completionRepository: completionRepository,
    );
  }

  void seedCompletion(
    InMemorySyllabusCompletionDocumentStore store,
    CanonicalScope scope,
    SyllabusCompletionStatus status,
  ) {
    store.seed('student-a', scope.scopeKey, {
      'scopeKey': scope.scopeKey,
      'courseId': scope.courseId,
      'paperId': scope.paperId,
      if (scope.partId != null) 'partId': scope.partId,
      'syllabusUnitId': scope.syllabusUnitId,
      'status': status.wireValue,
    });
  }

  test('1/2/3/4/5/6: Group-II and Group-III counts are complete', () async {
    final service = aggregation();
    final groupIi = await service.getCanonicalPlannerEntries('group-ii');
    final groupIii = await service.getCanonicalPlannerEntries('group-iii');

    expect(groupIi, hasLength(61));
    expect(groupIi.where((entry) => entry.paperId == 'group-ii-paper-i'), hasLength(11));
    expect(groupIi.where((entry) => entry.paperId == 'group-ii-paper-ii'), hasLength(20));
    expect(groupIi.where((entry) => entry.paperId == 'group-ii-paper-iii'), hasLength(15));
    expect(groupIi.where((entry) => entry.paperId == 'group-ii-paper-iv'), hasLength(15));

    expect(groupIii, hasLength(46));
    expect(groupIii.where((entry) => entry.paperId == 'group-iii-paper-i'), hasLength(11));
    expect(groupIii.where((entry) => entry.paperId == 'group-iii-paper-ii'), hasLength(20));
    expect(groupIii.where((entry) => entry.paperId == 'group-iii-paper-iii'), hasLength(15));
  });

  test('3/4/9/10/11/12/18: entries preserve identity, scope, and order', () async {
    final service = aggregation();
    final entries = await service.getCanonicalPlannerEntries('group-iii');
    final keys = entries.map((entry) => entry.scopeKey).toSet();

    expect(keys, hasLength(entries.length));
    for (final entry in entries) {
      entry.item.scope.validate();
      expect(entry.scopeKey, entry.item.scope.scopeKey);
      expect(entry.displayName, isNotEmpty);
      expect(entry.syllabusUnitId, isNotEmpty);
      if (entry.paperId == 'group-iii-paper-i') {
        expect(entry.partId, isNull);
      } else {
        expect(entry.partId, isNotNull);
      }
    }

    expect(
      entries.map((entry) => entry.syllabusUnitId).take(3),
      [
        'group-iii-paper-i-unit-01',
        'group-iii-paper-i-unit-02',
        'group-iii-paper-i-unit-03',
      ],
    );
  });

  test('5/6/7/8/13/14/15: exact question counts and no fallbacks', () async {
    final scope = CanonicalScope.validated(
      courseId: 'group-iii',
      paperId: 'group-iii-paper-ii',
      partId: 'group-iii-paper-ii-part-i',
      syllabusUnitId: 'group-iii-paper-ii-part-i-unit-02',
      shape: CanonicalScopeShape.groupIiiPartUnit,
    );
    final service = aggregation(
      readBank: () => [
        question(
          id: 'exact-1',
          courseId: scope.courseId,
          paperId: scope.paperId,
          partId: scope.partId,
          syllabusUnitId: scope.syllabusUnitId,
        ),
        question(
          id: 'exact-2',
          courseId: scope.courseId,
          paperId: scope.paperId,
          partId: scope.partId,
          syllabusUnitId: scope.syllabusUnitId,
        ),
        question(
          id: 'other-unit',
          courseId: scope.courseId,
          paperId: scope.paperId,
          partId: scope.partId,
          syllabusUnitId: 'group-iii-paper-ii-part-i-unit-03',
        ),
        question(
          id: 'legacy-topic',
          courseId: scope.courseId,
          paperId: scope.paperId,
          partId: scope.partId,
          topicId: scope.syllabusUnitId,
          lessonId: '${scope.syllabusUnitId}-lesson-01',
        ),
      ],
    );
    final entry = (await service.getCanonicalPlannerEntriesForPart(
      courseId: scope.courseId,
      paperId: scope.paperId,
      partId: scope.partId!,
    )).singleWhere((candidate) => candidate.scopeKey == scope.scopeKey);

    expect(entry.questionCount, 2);
    expect(entry.completionStatus, SyllabusCompletionStatus.notStarted);
    expect(entry.item.scope.canonicalTopicId, isNull);
    expect(entry.item.scope.lessonId, isNull);
  });

  test('6/7/16: completion is read separately and changes are reflected', () async {
    final store = InMemorySyllabusCompletionDocumentStore();
    final scope = CanonicalPlannerService()
        .getCanonicalPlannerItemsForPaper(
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
        )
        .first
        .scope;
    final service = aggregation(completionStore: store);

    var entry = (await service.getCanonicalPlannerEntriesForPaper(
      courseId: scope.courseId,
      paperId: scope.paperId,
    )).first;
    expect(entry.completionStatus, SyllabusCompletionStatus.notStarted);

    seedCompletion(store, scope, SyllabusCompletionStatus.inProgress);
    entry = (await service.getCanonicalPlannerEntriesForPaper(
      courseId: scope.courseId,
      paperId: scope.paperId,
    )).first;
    expect(entry.completionStatus, SyllabusCompletionStatus.inProgress);

    seedCompletion(store, scope, SyllabusCompletionStatus.completed);
    entry = (await service.getCanonicalPlannerEntriesForPaper(
      courseId: scope.courseId,
      paperId: scope.paperId,
    )).first;
    expect(entry.completionStatus, SyllabusCompletionStatus.completed);
  });

  test('17: question count changes are reflected without caching', () async {
    final bank = <Question>[];
    final service = aggregation(readBank: () => bank);
    final item = CanonicalPlannerService()
        .getCanonicalPlannerItemsForPaper(
          courseId: 'group-iii',
          paperId: 'group-iii-paper-i',
        )
        .first;

    var entry = await service.getCanonicalPlannerEntryForItem(item);
    expect(entry.questionCount, 0);

    bank.add(
      question(
        id: 'new-question',
        courseId: item.courseId,
        paperId: item.paperId,
        syllabusUnitId: item.syllabusUnitId,
      ),
    );
    entry = await service.getCanonicalPlannerEntryForItem(item);
    expect(entry.questionCount, 1);
  });

  test('19: invalid scope is rejected', () async {
    const invalidScope = CanonicalScope(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      syllabusUnitId: 'group-ii-paper-i-area-01',
      shape: CanonicalScopeShape.groupIiPaperI,
    );
    const invalidItem = CanonicalPlannerItem(
      scope: invalidScope,
      displayName: 'Invalid',
    );

    expect(
      () => aggregation().getCanonicalPlannerEntryForItem(invalidItem),
      throwsA(isA<CanonicalScopeValidationException>()),
    );
  });

  test('20: completion read failures are surfaced', () async {
    final service = aggregation(completionStore: _FailingCompletionStore());

    expect(
      () => service.getCanonicalPlannerEntriesForPaper(
        courseId: 'group-iii',
        paperId: 'group-iii-paper-i',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('21/22: legacy planner remains separate and both groups share service', () async {
    final service = aggregation();
    final groupIi = await service.getCanonicalPlannerEntriesForPaper(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
    );
    final groupIii = await service.getCanonicalPlannerEntriesForPaper(
      courseId: 'group-iii',
      paperId: 'group-iii-paper-i',
    );

    expect(groupIi.every((entry) => entry.item.scope.shape == CanonicalScopeShape.groupIiPaperI), isTrue);
    expect(groupIii.every((entry) => entry.item.scope.shape == CanonicalScopeShape.groupIiiPaperUnit), isTrue);
  });
}

class _FailingCompletionStore implements SyllabusCompletionDocumentStore {
  @override
  Future<Map<String, dynamic>?> getCompletion(
    String uid,
    String scopeKey,
  ) async {
    throw StateError('completion read failed');
  }
}
