import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
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
    String? majorStudyAreaId,
    String? contentTopicId,
    String? topicId,
    String? lessonId,
    bool isActive = true,
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
      isActive: isActive,
      status: QuestionPublicationStatus.published,
      question: id,
      options: const ['A', 'B', 'C', 'D'],
      syllabus: QuestionSyllabusAttribution(
        courseId: courseId,
        paperId: paperId,
        partId: partId,
        syllabusUnitId: syllabusUnitId,
        majorStudyAreaId: majorStudyAreaId,
        contentTopicId: contentTopicId,
        topicId: topicId,
        lessonId: lessonId,
      ),
    );
  }

  CanonicalScope groupIiiPaperUnit() {
    return CanonicalScope.validated(
      courseId: 'group-iii',
      paperId: 'group-iii-paper-i',
      syllabusUnitId: 'group-iii-paper-i-unit-01',
      shape: CanonicalScopeShape.groupIiiPaperUnit,
    );
  }

  CanonicalScope groupIiiPartUnit() {
    return CanonicalScope.validated(
      courseId: 'group-iii',
      paperId: 'group-iii-paper-ii',
      partId: 'group-iii-paper-ii-part-i',
      syllabusUnitId: 'group-iii-paper-ii-part-i-unit-02',
      shape: CanonicalScopeShape.groupIiiPartUnit,
    );
  }

  CanonicalScope groupIiPaperUnit() {
    return CanonicalScope.validated(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      syllabusUnitId: 'group-ii-paper-i-area-01',
      shape: CanonicalScopeShape.groupIiPaperI,
      majorStudyAreaId: 'group-ii-paper-i-area-01',
    );
  }

  CanonicalScope groupIiPartUnit() {
    return CanonicalScope.validated(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-01',
      syllabusUnitId: 'group-ii-paper-ii-part-01-topic-04',
      shape: CanonicalScopeShape.groupIiPartUnit,
      canonicalTopicId: 'group-ii-paper-ii-part-01-topic-04',
    );
  }

  CanonicalQuestionInventoryService inventory(List<Question> questions) {
    final cloud = QuestionCloudRepository.withHandlers(
      loadQuestions: (_) async => questions,
    );
    return CanonicalQuestionInventoryService(
      questionService: QuestionService(
        repository: QuestionRepository(cloudRepository: cloud),
      ),
    );
  }

  test('1/4/7: exact Group-III Paper-I unit count is isolated', () async {
    final scope = groupIiiPaperUnit();
    final count = await (inventory([
      question(
        id: 'same-1',
        courseId: 'group-iii',
        paperId: 'group-iii-paper-i',
        syllabusUnitId: scope.syllabusUnitId,
      ),
      question(
        id: 'same-2',
        courseId: 'group-iii',
        paperId: 'group-iii-paper-i',
        syllabusUnitId: scope.syllabusUnitId,
      ),
      question(
        id: 'other-unit',
        courseId: 'group-iii',
        paperId: 'group-iii-paper-i',
        syllabusUnitId: 'group-iii-paper-i-unit-02',
      ),
      question(
        id: 'other-paper',
        courseId: 'group-iii',
        paperId: 'group-iii-paper-ii',
        partId: 'group-iii-paper-ii-part-i',
        syllabusUnitId: scope.syllabusUnitId,
      ),
      question(
        id: 'other-course',
        courseId: 'group-ii',
        paperId: 'group-iii-paper-i',
        syllabusUnitId: scope.syllabusUnitId,
      ),
    ])).getCanonicalQuestionCount(scope);

    expect(count, 2);
  });

  test('2/5/6: exact Group-III Part/Unit count excludes part siblings', () async {
    final scope = groupIiiPartUnit();
    final count = await (inventory([
      question(
        id: 'same-1',
        courseId: 'group-iii',
        paperId: scope.paperId,
        partId: scope.partId,
        syllabusUnitId: scope.syllabusUnitId,
      ),
      question(
        id: 'same-2',
        courseId: 'group-iii',
        paperId: scope.paperId,
        partId: scope.partId,
        syllabusUnitId: scope.syllabusUnitId,
      ),
      question(
        id: 'other-unit',
        courseId: 'group-iii',
        paperId: scope.paperId,
        partId: scope.partId,
        syllabusUnitId: 'group-iii-paper-ii-part-i-unit-03',
      ),
      question(
        id: 'other-part',
        courseId: 'group-iii',
        paperId: scope.paperId,
        partId: 'group-iii-paper-ii-part-ii',
        syllabusUnitId: scope.syllabusUnitId,
      ),
    ])).getCanonicalQuestionCount(scope);

    expect(count, 2);
  });

  test('3: a canonical unit with zero questions returns zero', () async {
    expect(
      await (inventory(const [])).getCanonicalQuestionCount(groupIiiPartUnit()),
      0,
    );
  });

  test('8: Group-II Paper-I counts its area, not contentTopicId', () async {
    final scope = groupIiPaperUnit();
    final count = await (inventory([
      question(
        id: 'area',
        courseId: 'group-ii',
        paperId: scope.paperId,
        majorStudyAreaId: scope.syllabusUnitId,
      ),
      question(
        id: 'content-only',
        courseId: 'group-ii',
        paperId: scope.paperId,
        contentTopicId: 'group-ii-paper-i-area-01-topic-01',
      ),
      question(
        id: 'other-area',
        courseId: 'group-ii',
        paperId: scope.paperId,
        majorStudyAreaId: 'group-ii-paper-i-area-02',
      ),
    ])).getCanonicalQuestionCount(scope);

    expect(count, 1);
  });

  test('9/10/11/12: Group-II Part/Unit requires explicit syllabusUnitId', () async {
    final scope = groupIiPartUnit();
    final count = await (inventory([
      question(
        id: 'explicit-unit',
        courseId: 'group-ii',
        paperId: scope.paperId,
        partId: scope.partId,
        syllabusUnitId: scope.syllabusUnitId,
      ),
      question(
        id: 'topic-only',
        courseId: 'group-ii',
        paperId: scope.paperId,
        partId: scope.partId,
        topicId: scope.syllabusUnitId,
      ),
      question(
        id: 'lesson-only',
        courseId: 'group-ii',
        paperId: scope.paperId,
        partId: scope.partId,
        topicId: scope.syllabusUnitId,
        lessonId: '${scope.syllabusUnitId}-lesson-01',
      ),
      question(
        id: 'missing-unit',
        courseId: 'group-ii',
        paperId: scope.paperId,
        partId: scope.partId,
      ),
    ])).getCanonicalQuestionCount(scope);

    expect(count, 1);
  });

  test('13/14: canonical and legacy counts coexist', () async {
    final legacyTopic = 'group-ii-paper-iii-part-01-topic-01';
    final legacyQuestion = question(
      id: 'legacy',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-iii',
      partId: 'group-ii-paper-iii-part-01',
      topicId: legacyTopic,
      lessonId: '$legacyTopic-lesson-01',
    );
    final cloud = QuestionCloudRepository.withHandlers(
      loadQuestions: (_) async => [legacyQuestion],
    );
    final questionService = QuestionService(
      repository: QuestionRepository(cloudRepository: cloud),
    );
    final canonical = CanonicalQuestionInventoryService(
      questionService: questionService,
    );
    final scope = CanonicalScope.validated(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-iii',
      partId: 'group-ii-paper-iii-part-01',
      syllabusUnitId: legacyTopic,
      shape: CanonicalScopeShape.groupIiPartUnit,
      canonicalTopicId: legacyTopic,
    );

    expect(
      (await questionService.fetchQuestions(
        filter: QuestionFilter(topicId: legacyTopic),
      )),
      hasLength(1),
    );
    expect(await canonical.getCanonicalQuestionCount(scope), 0);
  });

  test('15/17: inactive and duplicate questions follow repository semantics', () async {
    final scope = groupIiiPaperUnit();
    final count = await (inventory([
      question(
        id: 'active-1',
        courseId: scope.courseId,
        paperId: scope.paperId,
        syllabusUnitId: scope.syllabusUnitId,
      ),
      question(
        id: 'active-duplicate',
        courseId: scope.courseId,
        paperId: scope.paperId,
        syllabusUnitId: scope.syllabusUnitId,
      ),
      question(
        id: 'inactive',
        courseId: scope.courseId,
        paperId: scope.paperId,
        syllabusUnitId: scope.syllabusUnitId,
        isActive: false,
      ),
    ])).getCanonicalQuestionCount(scope);

    expect(count, 2);
  });

  test('16: invalid CanonicalScope is rejected', () async {
    const invalid = CanonicalScope(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      syllabusUnitId: 'group-ii-paper-i-area-01',
      shape: CanonicalScopeShape.groupIiPaperI,
    );

    expect(
      () => (inventory(const [])).getCanonicalQuestionCount(invalid),
      throwsA(isA<CanonicalScopeValidationException>()),
    );
  });

  test('18: CanonicalPlannerItem obtains inventory through canonical path', () async {
    final item = CanonicalPlannerService()
        .getCanonicalPlannerItemsForPaper(
          courseId: 'group-iii',
          paperId: 'group-iii-paper-i',
        )
        .first;
    final count = await (inventory([
      question(
        id: 'item-question',
        courseId: item.courseId,
        paperId: item.paperId,
        syllabusUnitId: item.syllabusUnitId,
      ),
    ])).getCanonicalQuestionCountForItem(item);

    expect(count, 1);
  });
}
