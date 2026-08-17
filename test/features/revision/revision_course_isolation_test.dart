import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/revision/data/models/revision_models.dart';
import 'package:telangana_prep/features/revision/data/repositories/revision_repository.dart';
import 'package:telangana_prep/features/revision/services/revision_service.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

void main() {
  final now = DateTime(2026, 8, 15);

  Question question({
    required String id,
    required String courseId,
    String paperId = 'paper-i',
  }) {
    return Question(
      id: id,
      courseId: courseId,
      paperId: paperId,
      correctOption: 'A',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 30),
      createdAt: now,
      updatedAt: now,
      isActive: true,
      status: QuestionPublicationStatus.published,
      question: 'Q $id',
      options: const ['A', 'B', 'C', 'D'],
      syllabus: QuestionSyllabusAttribution(
        courseId: courseId,
        paperId: paperId,
      ),
    );
  }

  RevisionService buildService(List<Question> questions) {
    final cloud = QuestionCloudRepository.withHandlers(
      loadQuestions: (_) async => questions,
      getById: (id) async {
        for (final q in questions) {
          if (q.id == id) return q;
        }
        return null;
      },
      getByIds: (ids) async => [
        for (final id in ids)
          for (final q in questions)
            if (q.id == id) q,
      ],
    );
    return RevisionService(
      questionService: QuestionService(
        repository: QuestionRepository(cloudRepository: cloud),
      ),
      testService: TestService(),
      repository: RevisionRepository(),
      cloudSync: (_) async {},
    );
  }

  test('P1-5.27 Group-II revision excludes Group-III questions', () async {
    final service = buildService([
      question(id: 'gii-1', courseId: 'group-ii'),
      question(id: 'giii-1', courseId: 'group-iii'),
    ]);

    final test = await service.buildRevisionTest(
      collection: const RevisionCollection(
        type: RevisionCollectionType.wrongQuestions,
        title: 'Wrong',
        subtitle: 'Wrong questions',
        questionIds: ['gii-1', 'giii-1'],
      ),
      courseId: 'group-ii',
    );

    expect(test, isNotNull);
    expect(test!.questions.map((q) => q.id), ['gii-1']);
  });

  test('P1-5.28 Group-III revision excludes Group-II questions', () async {
    final service = buildService([
      question(id: 'gii-1', courseId: 'group-ii'),
      question(id: 'giii-1', courseId: 'group-iii'),
    ]);

    final test = await service.buildRevisionTest(
      collection: const RevisionCollection(
        type: RevisionCollectionType.wrongQuestions,
        title: 'Wrong',
        subtitle: 'Wrong questions',
        questionIds: ['gii-1', 'giii-1'],
      ),
      courseId: 'group-iii',
    );

    expect(test, isNotNull);
    expect(test!.questions.map((q) => q.id), ['giii-1']);
  });

  test('P1-5.29 buildRevisionTest verifies course ownership', () async {
    final service = buildService([
      question(id: 'giii-only', courseId: 'group-iii'),
    ]);

    final test = await service.buildRevisionTest(
      collection: const RevisionCollection(
        type: RevisionCollectionType.wrongQuestions,
        title: 'Wrong',
        subtitle: 'Wrong questions',
        questionIds: ['giii-only'],
      ),
      courseId: 'group-ii',
    );

    expect(test, isNull);
  });

  test('P1-5.30 unattributed legacy ids are excluded safely', () async {
    final service = buildService([
      question(id: 'known', courseId: 'group-ii'),
    ]);

    final test = await service.buildRevisionTest(
      collection: const RevisionCollection(
        type: RevisionCollectionType.wrongQuestions,
        title: 'Wrong',
        subtitle: 'Wrong questions',
        questionIds: ['known', 'missing-unattributed'],
      ),
      courseId: 'group-ii',
    );

    expect(test, isNotNull);
    expect(test!.questions.map((q) => q.id), ['known']);
  });
}
