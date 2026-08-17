import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';

void main() {
  final now = DateTime(2026, 8, 15);

  Question question({
    required String id,
    required String courseId,
    required String paperId,
    String? partId,
    String? syllabusUnitId,
    String topicId = '',
    String? majorStudyAreaId,
  }) {
    return Question(
      id: id,
      courseId: courseId,
      paperId: paperId,
      topicId: topicId,
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
      question: id,
      options: const ['A', 'B', 'C', 'D'],
      syllabus: QuestionSyllabusAttribution(
        courseId: courseId,
        paperId: paperId,
        partId: partId,
        topicId: topicId.isEmpty ? null : topicId,
        syllabusUnitId: syllabusUnitId,
        majorStudyAreaId: majorStudyAreaId,
      ),
    );
  }

  QuestionService serviceFor(List<Question> bank) {
    return QuestionService(
      repository: QuestionRepository(
        cloudRepository: QuestionCloudRepository.withHandlers(
          loadQuestions: (filter) async {
            return [
              for (final item in bank)
                if ((filter?.courseId == null ||
                        item.courseId == filter!.courseId) &&
                    (filter?.paperId == null ||
                        item.paperId == filter!.paperId) &&
                    (filter?.partId == null || item.partId == filter!.partId))
                  item,
            ];
          },
        ),
      ),
    );
  }

  const giiPaper = 'group-ii-paper-ii';
  const giiPart = 'group-ii-paper-ii-part-01';
  const giiUnit = 'group-ii-paper-ii-part-01-topic-04';
  const giiOtherUnit = 'group-ii-paper-ii-part-01-topic-05';
  const giiOtherPart = 'group-ii-paper-ii-part-02';

  const giiiPaper = 'group-iii-paper-ii';
  const giiiPart = 'group-iii-paper-ii-part-i';
  const giiiUnit = 'group-iii-paper-ii-part-i-unit-02';
  const giiiOtherUnit = 'group-iii-paper-ii-part-i-unit-01';

  List<Question> groupIiBank() {
    return [
      question(
        id: 'gii-u1-a',
        courseId: 'group-ii',
        paperId: giiPaper,
        partId: giiPart,
        topicId: giiUnit,
      ),
      question(
        id: 'gii-u1-b',
        courseId: 'group-ii',
        paperId: giiPaper,
        partId: giiPart,
        topicId: giiUnit,
      ),
      question(
        id: 'gii-other-unit',
        courseId: 'group-ii',
        paperId: giiPaper,
        partId: giiPart,
        topicId: giiOtherUnit,
      ),
      question(
        id: 'gii-other-part',
        courseId: 'group-ii',
        paperId: giiPaper,
        partId: giiOtherPart,
        topicId: 'group-ii-paper-ii-part-02-topic-01',
      ),
    ];
  }

  List<Question> groupIiiBank() {
    return [
      question(
        id: 'giii-u1-a',
        courseId: 'group-iii',
        paperId: giiiPaper,
        partId: giiiPart,
        syllabusUnitId: giiiUnit,
      ),
      question(
        id: 'giii-u1-b',
        courseId: 'group-iii',
        paperId: giiiPaper,
        partId: giiiPart,
        syllabusUnitId: giiiUnit,
      ),
      question(
        id: 'giii-other-unit',
        courseId: 'group-iii',
        paperId: giiiPaper,
        partId: giiiPart,
        syllabusUnitId: giiiOtherUnit,
      ),
      question(
        id: 'giii-other-paper',
        courseId: 'group-iii',
        paperId: 'group-iii-paper-i',
        syllabusUnitId: 'group-iii-paper-i-unit-01',
      ),
    ];
  }

  test(
    'A/E/F: enough Group-II unit questions succeed and stay in unit',
    () async {
      final selected = await serviceFor(groupIiBank()).getQuestionsForTest(
        count: 2,
        courseId: 'group-ii',
        paperId: giiPaper,
        partId: giiPart,
        syllabusUnitId: giiUnit,
        randomizeOrder: false,
      );
      expect(selected.map((q) => q.id), ['gii-u1-a', 'gii-u1-b']);
      expect(
        selected.every((q) => QuestionService.matchesSyllabusUnit(q, giiUnit)),
        isTrue,
      );
      expect(selected.any((q) => q.id == 'gii-other-unit'), isFalse);
    },
  );

  test('B: fewer questions than required in exact unit fails', () async {
    await expectLater(
      serviceFor(groupIiBank()).getQuestionsForTest(
        count: 3,
        courseId: 'group-ii',
        paperId: giiPaper,
        partId: giiPart,
        syllabusUnitId: giiUnit,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Not enough questions in the selected syllabus scope.'),
        ),
      ),
    );
  });

  test('C: other unit having enough questions still fails', () async {
    await expectLater(
      serviceFor(groupIiBank()).getQuestionsForTest(
        count: 3,
        courseId: 'group-ii',
        paperId: giiPaper,
        partId: giiPart,
        syllabusUnitId: giiUnit,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('D: same paper having enough questions still fails', () async {
    await expectLater(
      serviceFor(groupIiBank()).getQuestionsForTest(
        count: 3,
        courseId: 'group-ii',
        paperId: giiPaper,
        partId: giiPart,
        syllabusUnitId: giiUnit,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('G: Group-III exact unit works and does not leak other units', () async {
    final selected = await serviceFor(groupIiiBank()).getQuestionsForTest(
      count: 2,
      courseId: 'group-iii',
      paperId: giiiPaper,
      partId: giiiPart,
      syllabusUnitId: giiiUnit,
      randomizeOrder: false,
    );
    expect(selected.map((q) => q.id), ['giii-u1-a', 'giii-u1-b']);
    expect(selected.any((q) => q.id == 'giii-other-unit'), isFalse);
    expect(selected.any((q) => q.id == 'giii-other-paper'), isFalse);
  });

  test('G: Group-III undersized unit fails even when paper is full', () async {
    await expectLater(
      serviceFor(groupIiiBank()).getQuestionsForTest(
        count: 3,
        courseId: 'group-iii',
        paperId: giiiPaper,
        partId: giiiPart,
        syllabusUnitId: giiiUnit,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Not enough questions in the selected syllabus scope.'),
        ),
      ),
    );
  });

  test('unscoped course selection still allows a thin bank', () async {
    final selected = await serviceFor(groupIiBank()).getQuestionsForTest(
      count: 50,
      courseId: 'group-ii',
      randomizeOrder: false,
    );
    expect(selected.length, lessThan(50));
    expect(selected.every((q) => q.courseId == 'group-ii'), isTrue);
  });
}
