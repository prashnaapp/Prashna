import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_cloud_mapper.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';

void main() {
  Map<String, dynamic> firestoreDoc({
    String id = 'q-test-group-ii-001',
    String courseId = 'group-ii',
    bool isActive = true,
    String questionType = 'practice',
    Object? marks = 1,
    Object? negativeMarks = 0,
    Object? estimatedTimeSeconds = 60,
  }) {
    return {
      'id': id,
      'courseId': courseId,
      'question': 'What is the capital of Telangana?',
      'options': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar'],
      'correctOption': 'A',
      'explanation': 'Hyderabad is the capital of Telangana.',
      'questionType': questionType,
      'isActive': isActive,
      'estimatedTimeSeconds': estimatedTimeSeconds,
      'negativeMarks': negativeMarks,
      'difficulty': 'easy',
      'language': 'en',
      'marks': marks,
      'paperId': 'paper-1',
      'sectionId': 'section-1',
      'topicId': 'topic-1',
      'tags': ['Telangana', 'Geography'],
      'examName': 'Group-II',
    };
  }

  group('QuestionCloudMapper', () {
    test('1: maps q-test-group-ii-001 into Question', () {
      final question = QuestionCloudMapper.fromFirestore(
        'q-test-group-ii-001',
        firestoreDoc(),
      );

      expect(question, isNotNull);
      expect(question!.id, 'q-test-group-ii-001');
      expect(question.courseId, 'group-ii');
      expect(question.question, 'What is the capital of Telangana?');
      expect(question.options, [
        'Hyderabad',
        'Warangal',
        'Nizamabad',
        'Karimnagar',
      ]);
      expect(question.correctOption, 'A');
      expect(question.questionType, QuestionType.practice);
      expect(question.difficulty, QuestionDifficulty.easy);
      expect(question.isActive, isTrue);
      expect(question.marks, 1);
      expect(question.negativeMarks, 0);
      expect(question.estimatedTime, const Duration(seconds: 60));
      expect(question.paperId, 'paper-1');
      expect(question.sectionId, 'section-1');
      expect(question.topicId, 'topic-1');
      expect(question.tags, ['Telangana', 'Geography']);
      expect(question.examName, 'Group-II');
    });

    test('7/8/9: numeric safety, correctOption, option order', () {
      final question = QuestionCloudMapper.fromFirestore(
        'q1',
        firestoreDoc(
          marks: 1.0,
          negativeMarks: 0.0,
          estimatedTimeSeconds: 60.0,
        ),
      );

      expect(question, isNotNull);
      expect(question!.marks, 1.0);
      expect(question.negativeMarks, 0.0);
      expect(question.estimatedTime.inSeconds, 60);
      expect(question.correctOption, 'A');
      expect(question.options[0], 'Hyderabad');
      expect(question.options[1], 'Warangal');
      expect(question.options[2], 'Nizamabad');
      expect(question.options[3], 'Karimnagar');
    });

    test('4: inactive questions still map isActive=false', () {
      final question = QuestionCloudMapper.fromFirestore(
        'inactive',
        firestoreDoc(isActive: false),
      );
      expect(question, isNotNull);
      expect(question!.isActive, isFalse);
    });
  });

  group('QuestionService + cloud repository', () {
    late List<Question> bank;

    setUp(() {
      bank = [
        QuestionCloudMapper.fromFirestore(
          'q-test-group-ii-001',
          firestoreDoc(),
        )!,
        QuestionCloudMapper.fromFirestore(
          'q-group-iii-001',
          firestoreDoc(
            id: 'q-group-iii-001',
            courseId: 'group-iii',
          ),
        )!,
        QuestionCloudMapper.fromFirestore(
          'q-inactive',
          firestoreDoc(id: 'q-inactive', isActive: false),
        )!,
        QuestionCloudMapper.fromFirestore(
          'q-mock',
          firestoreDoc(id: 'q-mock', questionType: 'mock'),
        )!,
      ];
    });

    QuestionCloudRepository repo() {
      return QuestionCloudRepository.withHandlers(
        loadQuestions: (filter) async {
          final courseId = filter?.courseId;
          if (courseId == null || courseId.isEmpty) {
            throw StateError('courseId required');
          }
          return [
            for (final q in bank)
              if (q.courseId == courseId &&
                  (filter?.activeOnly == false || q.isActive) &&
                  (filter?.questionType == null ||
                      q.questionType == filter!.questionType))
                q,
          ];
        },
        getById: (id) async {
          for (final q in bank) {
            if (q.id == id) return q;
          }
          return null;
        },
        getByIds: (ids) async {
          final byId = {for (final q in bank) q.id: q};
          return [
            for (final id in ids)
              if (byId[id] != null) byId[id]!,
          ];
        },
      );
    }

    QuestionService service() {
      return QuestionService(
        repository: QuestionRepository(cloudRepository: repo()),
      );
    }

    test('2: Group-II question returned for courseId=group-ii', () async {
      final questions = await service().getQuestionsForTest(
        count: 1,
        courseId: 'group-ii',
        questionType: QuestionType.practice,
        randomizeOrder: false,
      );

      expect(questions, hasLength(1));
      expect(questions.single.id, 'q-test-group-ii-001');
      expect(questions.single.courseId, 'group-ii');
      expect(
        questions.single.question,
        'What is the capital of Telangana?',
      );
    });

    test('3: Group-III question NOT returned for group-ii', () async {
      final questions = await service().getQuestionsForTest(
        count: 10,
        courseId: 'group-ii',
        randomizeOrder: false,
      );

      expect(questions.every((q) => q.courseId == 'group-ii'), isTrue);
      expect(questions.any((q) => q.courseId == 'group-iii'), isFalse);
      expect(questions.map((q) => q.id), isNot(contains('q-group-iii-001')));
    });

    test('4: inactive questions excluded by default', () async {
      final questions = await service().fetchQuestions(
        filter: const QuestionFilter(courseId: 'group-ii'),
      );

      expect(questions.any((q) => q.id == 'q-inactive'), isFalse);
      expect(questions.every((q) => q.isActive), isTrue);
    });

    test('5: questionType filtering works', () async {
      final practice = await service().fetchQuestions(
        filter: const QuestionFilter(
          courseId: 'group-ii',
          questionType: QuestionType.practice,
        ),
      );
      expect(practice.map((q) => q.id), contains('q-test-group-ii-001'));
      expect(practice.map((q) => q.id), isNot(contains('q-mock')));

      final mocks = await service().fetchQuestions(
        filter: const QuestionFilter(
          courseId: 'group-ii',
          questionType: QuestionType.mock,
        ),
      );
      expect(mocks.map((q) => q.id), ['q-mock']);
    });

    test('6: getByIds preserves stable IDs and order', () async {
      final questions = await service().getByIds([
        'q-mock',
        'q-test-group-ii-001',
        'missing',
        'q-test-group-ii-001',
      ]);

      expect(questions.map((q) => q.id), [
        'q-mock',
        'q-test-group-ii-001',
        'q-test-group-ii-001',
      ]);
    });

    test('course isolation: never fills count from other courses', () async {
      final questions = await service().getQuestionsForTest(
        count: 50,
        courseId: 'group-ii',
        questionType: QuestionType.practice,
        randomizeOrder: false,
      );

      // Thin bank → fewer than requested is OK; still only group-ii.
      expect(questions.length, lessThan(50));
      expect(questions.every((q) => q.courseId == 'group-ii'), isTrue);
    });

    test('Firestore errors propagate (no dummy fallback)', () async {
      final broken = QuestionService(
        repository: QuestionRepository(
          cloudRepository: QuestionCloudRepository.withHandlers(
            loadQuestions: (_) async {
              throw StateError('network down');
            },
          ),
        ),
      );

      await expectLater(
        broken.getQuestionsForTest(count: 1, courseId: 'group-ii'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
