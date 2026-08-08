import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/data/test_cloud_mapper.dart';

void main() {
  Question q({
    required String id,
    required String courseId,
    String text = 'Question text',
  }) {
    final now = DateTime(2026, 1, 1);
    return Question(
      id: id,
      courseId: courseId,
      paperId: 'paper-1',
      sectionId: 'section-1',
      topicId: 'topic-1',
      question: text,
      options: const ['A1', 'A2', 'A3', 'A4'],
      correctOption: 'A',
      explanation: 'Because.',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      language: 'en',
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
    );
  }

  QuestionService bankService(List<Question> bank) {
    final cloud = QuestionCloudRepository.withHandlers(
      loadQuestions: (filter) async {
        final courseId = filter?.courseId;
        if (courseId == null || courseId.isEmpty) {
          throw StateError('courseId required');
        }
        return [
          for (final question in bank)
            if (question.courseId == courseId && question.isActive) question,
        ];
      },
      getById: (id) async {
        for (final question in bank) {
          if (question.id == id) return question;
        }
        return null;
      },
      getByIds: (ids) async {
        final byId = {for (final question in bank) question.id: question};
        return [
          for (final id in ids)
            if (byId[id] != null) byId[id]!,
        ];
      },
    );
    return QuestionService(
      repository: QuestionRepository(cloudRepository: cloud),
    );
  }

  TestService engine(QuestionService questions) {
    return TestService(questionService: questions);
  }

  group('TestModel / mapper questionIds', () {
    test('1: TestModel parses questionIds', () {
      final model = TestCloudMapper.fromFirestore('t1', {
        'courseId': 'group-ii',
        'title': 'Fixed',
        'category': 'chapter',
        'questionCount': 2,
        'totalMarks': 2,
        'durationMinutes': 5,
        'negativeMarks': 0,
        'isPublished': true,
        'questionIds': ['q003', 'q001', 'q002'],
      });

      expect(model, isNotNull);
      expect(model!.questionIds, ['q003', 'q001', 'q002']);
    });

    test('2: missing questionIds defaults to []', () {
      final model = TestCloudMapper.fromFirestore('t1', {
        'courseId': 'group-ii',
        'title': 'Dynamic',
        'category': 'chapter',
        'questionCount': 1,
        'totalMarks': 1,
        'durationMinutes': 1,
        'negativeMarks': 0,
        'isPublished': true,
      });

      expect(model!.questionIds, isEmpty);
      expect(const TestModel(
        id: 'x',
        examId: 'group-ii',
        category: TestCategoryType.chapterTests,
        title: 'X',
        questionCount: 1,
        marks: 1,
        durationMinutes: 1,
        negativeMarking: '0',
        difficulty: 'Medium',
      ).questionIds, isEmpty);
    });
  });

  group('Fixed question assignment via createTestFromQuestionIds', () {
    late List<Question> bank;
    late QuestionService questions;
    late TestService service;

    setUp(() {
      bank = [
        q(id: 'q001', courseId: 'group-ii', text: 'First'),
        q(id: 'q002', courseId: 'group-ii', text: 'Second'),
        q(id: 'q003', courseId: 'group-ii', text: 'Third'),
        q(id: 'q-iii', courseId: 'group-iii', text: 'Other course'),
        q(
          id: 'q-test-group-ii-001',
          courseId: 'group-ii',
          text: 'What is the capital of Telangana?',
        ),
      ];
      questions = bankService(bank);
      service = engine(questions);
    });

    test('3: fixed test loads exact question IDs', () async {
      final test = await service.createTestFromQuestionIds(
        id: 'test-fixed',
        title: 'Fixed',
        courseId: 'group-ii',
        questionIds: const ['q001', 'q002'],
        mode: TestMode.topic,
        duration: const Duration(minutes: 5),
        totalMarks: 2,
        requireCompleteSet: true,
        requireCourseMatch: true,
        expectedCount: 2,
      );

      expect(test.questions.map((e) => e.id), ['q001', 'q002']);
      expect(test.totalQuestions, 2);
      expect(test.totalMarks, 2);
    });

    test('4: fixed question order is preserved', () async {
      final test = await service.createTestFromQuestionIds(
        id: 'test-order',
        title: 'Ordered',
        courseId: 'group-ii',
        questionIds: const ['q003', 'q001', 'q002'],
        mode: TestMode.topic,
        duration: const Duration(minutes: 5),
        totalMarks: 3,
        requireCompleteSet: true,
        requireCourseMatch: true,
        expectedCount: 3,
      );

      expect(test.questions.map((e) => e.id), ['q003', 'q001', 'q002']);
    });

    test('5: missing assigned question causes clear failure', () async {
      await expectLater(
        service.createTestFromQuestionIds(
          id: 'test-missing',
          title: 'Missing',
          courseId: 'group-ii',
          questionIds: const ['q001', 'q-missing', 'q002'],
          mode: TestMode.topic,
          duration: const Duration(minutes: 5),
          totalMarks: 3,
          requireCompleteSet: true,
          requireCourseMatch: true,
          expectedCount: 3,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('one or more assigned questions are missing'),
          ),
        ),
      );
    });

    test('6: Group-II test cannot use Group-III question', () async {
      await expectLater(
        service.createTestFromQuestionIds(
          id: 'test-cross',
          title: 'Cross',
          courseId: 'group-ii',
          questionIds: const ['q001', 'q-iii'],
          mode: TestMode.topic,
          duration: const Duration(minutes: 5),
          totalMarks: 2,
          requireCompleteSet: true,
          requireCourseMatch: true,
          expectedCount: 2,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('same course as the test'),
          ),
        ),
      );
    });

    test('7: questionIds.length mismatch with questionCount errors', () async {
      await expectLater(
        service.createTestFromQuestionIds(
          id: 'test-count',
          title: 'Count',
          courseId: 'group-ii',
          questionIds: const ['q001'],
          mode: TestMode.topic,
          duration: const Duration(minutes: 5),
          totalMarks: 5,
          requireCompleteSet: true,
          requireCourseMatch: true,
          expectedCount: 5,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('does not match questionCount'),
          ),
        ),
      );
    });

    test('8/10: empty questionIds path still uses dynamic selection', () async {
      final dynamicTest = await service.createConfiguredTest(
        id: 'test-dynamic',
        title: 'Dynamic',
        courseId: 'group-ii',
        mode: TestMode.topic,
        duration: const Duration(minutes: 1),
        totalQuestions: 1,
        totalMarks: 1,
        negativeMarks: 0,
      );

      expect(dynamicTest.questions, hasLength(1));
      expect(dynamicTest.courseId, 'group-ii');
      // Dynamic selection never pulls Group-III.
      expect(
        dynamicTest.questions.every((tq) => tq.id != 'q-iii'),
        isTrue,
      );
      // And it is not the fixed-ID path (may be any group-ii question).
      expect(
        dynamicTest.questions.every(
          (tq) => bank.any((b) => b.id == tq.id && b.courseId == 'group-ii'),
        ),
        isTrue,
      );
    });

    test('9: no all-course fallback for fixed tests', () async {
      // Only request a missing ID — must fail, not fill from course bank.
      await expectLater(
        service.createTestFromQuestionIds(
          id: 'test-no-fallback',
          title: 'No fallback',
          courseId: 'group-ii',
          questionIds: const ['q-does-not-exist'],
          mode: TestMode.topic,
          duration: const Duration(minutes: 1),
          totalMarks: 1,
          requireCompleteSet: true,
          requireCourseMatch: true,
          expectedCount: 1,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('one or more assigned questions are missing'),
          ),
        ),
      );
    });

    test('manual fixture: capital of Telangana via fixed ID', () async {
      final test = await service.createTestFromQuestionIds(
        id: 'test-group-ii-001',
        title: 'Group-II Practice Test 1',
        courseId: 'group-ii',
        questionIds: const ['q-test-group-ii-001'],
        mode: TestMode.topic,
        duration: const Duration(minutes: 1),
        totalMarks: 1,
        requireCompleteSet: true,
        requireCourseMatch: true,
        expectedCount: 1,
      );

      expect(test.questions, hasLength(1));
      expect(test.questions.single.id, 'q-test-group-ii-001');
      expect(
        test.questions.single.text,
        'What is the capital of Telangana?',
      );
    });
  });
}
