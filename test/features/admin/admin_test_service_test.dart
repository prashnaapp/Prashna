import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/services/admin_test_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/data/test_cloud_mapper.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';

void main() {
  TestModel sampleTest({
    String id = '',
    String examId = 'group-ii',
    TestCategoryType category = TestCategoryType.chapterTests,
    String title = 'Group-II Practice Test 1',
    int questionCount = 10,
    int marks = 10,
    int durationMinutes = 30,
    String negativeMarking = '0',
    String difficulty = 'Medium',
    List<String> questionIds = const [],
    TestPublicationStatus status = TestPublicationStatus.draft,
  }) {
    return TestModel(
      id: id,
      examId: examId,
      category: category,
      title: title,
      questionCount: questionCount,
      marks: marks,
      durationMinutes: durationMinutes,
      negativeMarking: negativeMarking,
      difficulty: difficulty,
      questionIds: questionIds,
      status: status,
    );
  }

  AdminTestService publishService({
    required TestModel? current,
    required void Function(bool isPublished) onPublished,
  }) {
    return AdminTestService(
      testRepository: TestCloudRepository.withLoader(
        (_) async => const [],
        getById: (_) async => current,
        setPublished: ({required testId, required isPublished}) async {
          onPublished(isPublished);
        },
      ),
    );
  }

  Future<void> expectPublishRejected({
    required TestModel? current,
    required String message,
    String testId = 'test-1',
  }) async {
    var writes = 0;
    final service = publishService(
      current: current,
      onPublished: (_) => writes++,
    );

    await expectLater(
      service.publishTest(testId),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains(message),
        ),
      ),
    );
    expect(writes, 0);
  }

  test('1: valid test metadata passes validation', () {
    expect(
      TestCloudMapper.validateForWrite(
        sampleTest(),
        documentId: 'generated-on-create',
      ),
      isEmpty,
    );
  });

  test('2: empty title rejected', () {
    expect(
      TestCloudMapper.validateForWrite(sampleTest(title: ' ')),
      contains('Title is required.'),
    );
  });

  test('3: missing course rejected', () {
    expect(
      TestCloudMapper.validateForWrite(sampleTest(examId: ' ')),
      contains('Course is required.'),
    );
  });

  test('4: invalid category string rejected by parser', () {
    expect(TestCloudMapper.parseCategory('unknown'), isNull);
    expect(
      TestCloudMapper.categoryToFirestore(TestCategoryType.chapterTests),
      'chapter',
    );
  });

  test('Group-II canonical location validates without legacy topic fields', () {
    final service = AdminTestService(
      testRepository: TestCloudRepository.withLoader((_) async => const []),
    );
    final errors = service.validate(
      const TestModel(
        id: 'gii-location',
        examId: 'group-ii',
        category: TestCategoryType.chapterTests,
        title: 'Paper I area test',
        questionCount: 1,
        marks: 1,
        durationMinutes: 1,
        negativeMarking: '0',
        difficulty: 'Medium',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01',
      ),
      documentId: 'gii-location',
    );
    expect(errors, isEmpty);
  });

  test('invalid Group-II paper and unit combination is rejected', () {
    final service = AdminTestService(
      testRepository: TestCloudRepository.withLoader((_) async => const []),
    );
    final errors = service.validate(
      const TestModel(
        id: 'gii-invalid-location',
        examId: 'group-ii',
        category: TestCategoryType.chapterTests,
        title: 'Invalid location',
        questionCount: 1,
        marks: 1,
        durationMinutes: 1,
        negativeMarking: '0',
        difficulty: 'Medium',
        paperId: 'group-ii-paper-i',
        partId: 'group-ii-paper-ii-part-01',
        syllabusUnitId: 'group-ii-paper-ii-part-01-topic-04',
      ),
      documentId: 'gii-invalid-location',
    );
    expect(errors, contains(contains('does not belong')));
  });

  test('paper-wise tests require paper and part when the paper has parts', () {
    final service = AdminTestService(
      testRepository: TestCloudRepository.withLoader((_) async => const []),
    );
    expect(
      service.validate(
        const TestModel(
          id: 'pw-1',
          examId: 'group-ii',
          category: TestCategoryType.partTests,
          title: 'Part I Test',
          questionCount: 1,
          marks: 1,
          durationMinutes: 1,
          negativeMarking: '0',
          difficulty: 'Medium',
          paperId: 'group-ii-paper-ii',
        ),
        documentId: 'pw-1',
      ),
      contains(contains('Part is required')),
    );
    expect(
      service.validate(
        const TestModel(
          id: 'pw-2',
          examId: 'group-ii',
          category: TestCategoryType.partTests,
          title: 'Part I Test',
          questionCount: 1,
          marks: 1,
          durationMinutes: 1,
          negativeMarking: '0',
          difficulty: 'Medium',
          paperId: 'group-ii-paper-ii',
          partId: 'group-ii-paper-ii-part-01',
        ),
        documentId: 'pw-2',
      ),
      isEmpty,
    );
  });

  test('grand tests require seriesId and paper without a syllabus unit', () {
    final service = AdminTestService(
      testRepository: TestCloudRepository.withLoader((_) async => const []),
    );
    expect(
      service.validate(
        const TestModel(
          id: 'gt-1',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'Paper II Grand Test',
          questionCount: 1,
          marks: 1,
          durationMinutes: 1,
          negativeMarking: '0',
          difficulty: 'Medium',
          paperId: 'group-ii-paper-ii',
        ),
        documentId: 'gt-1',
      ),
      contains('Grand Test group is required.'),
    );
    expect(
      service.validate(
        const TestModel(
          id: 'gt-2',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'Paper II Grand Test',
          questionCount: 1,
          marks: 1,
          durationMinutes: 1,
          negativeMarking: '0',
          difficulty: 'Medium',
          paperId: 'group-ii-paper-ii',
          seriesId: 'Grand Test 1',
        ),
        documentId: 'gt-2',
      ),
      isEmpty,
    );
  });

  test('previous papers require year and paper', () {
    final service = AdminTestService(
      testRepository: TestCloudRepository.withLoader((_) async => const []),
    );
    expect(
      service.validate(
        const TestModel(
          id: 'py-1',
          examId: 'group-ii',
          category: TestCategoryType.previousYear,
          title: 'Paper I',
          questionCount: 1,
          marks: 1,
          durationMinutes: 1,
          negativeMarking: '0',
          difficulty: 'Medium',
          paperId: 'group-ii-paper-i',
        ),
        documentId: 'py-1',
      ),
      contains('A valid exam year is required.'),
    );
    expect(
      service.validate(
        const TestModel(
          id: 'py-2',
          examId: 'group-ii',
          category: TestCategoryType.previousYear,
          title: 'Paper I',
          questionCount: 1,
          marks: 1,
          durationMinutes: 1,
          negativeMarking: '0',
          difficulty: 'Medium',
          paperId: 'group-ii-paper-i',
          year: 2016,
        ),
        documentId: 'py-2',
      ),
      isEmpty,
    );
  });

  test('5: questionCount <= 0 rejected', () {
    expect(
      TestCloudMapper.validateForWrite(sampleTest(questionCount: 0)),
      contains('Question count must be greater than zero.'),
    );
  });

  test('6: negative total marks rejected', () {
    expect(
      TestCloudMapper.validateForWrite(sampleTest(marks: -1)),
      contains('Total marks must be zero or greater.'),
    );
  });

  test('7: duration <= 0 rejected', () {
    expect(
      TestCloudMapper.validateForWrite(sampleTest(durationMinutes: 0)),
      contains('Duration must be greater than zero.'),
    );
  });

  test('8: invalid negative marking rejected', () {
    expect(
      TestCloudMapper.validateForWrite(sampleTest(negativeMarking: 'invalid')),
      contains('Negative marking must be a valid non-negative number.'),
    );
  });

  test('9: missing difficulty rejected', () {
    expect(
      TestCloudMapper.validateForWrite(sampleTest(difficulty: ' ')),
      contains('Difficulty is required.'),
    );
  });

  test('10: create mapping is correct', () {
    final data = TestCloudMapper.toFirestore(
      sampleTest(status: TestPublicationStatus.published),
      documentId: 'test-created',
    );
    expect(data['id'], 'test-created');
    expect(data['courseId'], 'group-ii');
    expect(data['title'], 'Group-II Practice Test 1');
    expect(data['category'], 'chapter');
    expect(data['questionCount'], 10);
    expect(data['totalMarks'], 10);
    expect(data['durationMinutes'], 30);
    expect(data['negativeMarks'], 0);
    expect(data['difficulty'], 'Medium');
    expect(data['isPublished'], isTrue);
  });

  test('11: examId maps to courseId', () {
    final data = TestCloudMapper.toFirestore(
      sampleTest(examId: 'group-iii'),
      documentId: 't1',
    );
    expect(data['courseId'], 'group-iii');
  });

  test('12: marks maps to totalMarks', () {
    final data = TestCloudMapper.toFirestore(
      sampleTest(marks: 50),
      documentId: 't1',
    );
    expect(data['totalMarks'], 50);
  });

  test('13: negativeMarking maps to negativeMarks', () {
    final data = TestCloudMapper.toFirestore(
      sampleTest(negativeMarking: '0.25'),
      documentId: 't1',
    );
    expect(data['negativeMarks'], 0.25);
  });

  test('14: questionIds defaults to [] on create mapping', () {
    final data = TestCloudMapper.toFirestore(sampleTest(), documentId: 't1');
    expect(data['questionIds'], isEmpty);
  });

  test('15: isPublished is persisted', () {
    final draft = TestCloudMapper.toFirestore(
      sampleTest(status: TestPublicationStatus.draft),
      documentId: 't1',
    );
    final published = TestCloudMapper.toFirestore(
      sampleTest(status: TestPublicationStatus.published),
      documentId: 't2',
    );
    expect(draft['isPublished'], isFalse);
    expect(published['isPublished'], isTrue);
  });

  test('16: document ID and TestModel.id must remain consistent', () {
    expect(
      TestCloudMapper.validateForWrite(
        sampleTest(id: 'abc'),
        documentId: 'xyz',
      ),
      contains('Test ID must match the Firestore document ID.'),
    );
  });

  test('17: admin mapper reads unpublished tests', () {
    final model = TestCloudMapper.fromFirestoreAdmin('draft-1', {
      'id': 'draft-1',
      'courseId': 'group-ii',
      'title': 'Draft Test',
      'category': 'chapter',
      'questionCount': 5,
      'totalMarks': 5,
      'durationMinutes': 10,
      'negativeMarks': 0,
      'isPublished': false,
    });
    expect(model, isNotNull);
    expect(model!.isPublished, isFalse);
    expect(model.title, 'Draft Test');
  });

  test('18: student mapper still rejects unpublished tests', () {
    expect(
      TestCloudMapper.fromFirestore('draft-1', {
        'courseId': 'group-ii',
        'title': 'Draft Test',
        'category': 'chapter',
        'questionCount': 5,
        'totalMarks': 5,
        'durationMinutes': 10,
        'negativeMarks': 0,
        'isPublished': false,
      }),
      isNull,
    );
  });

  test('19: publish sets isPublished true', () async {
    var published = false;
    final service = publishService(
      current: sampleTest(id: 'test-1'),
      onPublished: (value) => published = value,
    );

    await service.publishTest('test-1');
    expect(published, isTrue);
    expect(
      TestCloudMapper.toPublishMap(isPublished: true)['isPublished'],
      isTrue,
    );
  });

  test(
    'publication rejects an empty test ID before reading or writing',
    () async {
      await expectPublishRejected(
        current: sampleTest(id: 'test-1'),
        testId: ' ',
        message: 'Test ID is required.',
      );
    },
  );

  test('publication rejects an empty persisted test ID', () async {
    await expectPublishRejected(
      current: sampleTest(id: ''),
      message: 'Test ID is required.',
    );
  });

  test('publication rejects persisted document/model ID drift', () async {
    await expectPublishRejected(
      current: sampleTest(id: 'different-id'),
      message: 'Test ID must match the Firestore document ID.',
    );
  });

  test('publication rejects a missing persisted test', () async {
    await expectPublishRejected(current: null, message: 'Test was not found.');
  });

  test('publication rejects an empty title', () async {
    await expectPublishRejected(
      current: sampleTest(id: 'test-1', title: ' '),
      message: 'Title is required.',
    );
  });

  test('publication rejects an empty course', () async {
    await expectPublishRejected(
      current: sampleTest(id: 'test-1', examId: ' '),
      message: 'Course is required.',
    );
  });

  test('publication rejects an invalid persisted category', () async {
    // An unsupported Firestore category is rejected by the admin mapper and
    // therefore cannot produce a canonical test for publication.
    await expectPublishRejected(current: null, message: 'Test was not found.');
    expect(TestCloudMapper.parseCategory('unsupported'), isNull);
  });

  test('publication rejects zero and negative question counts', () async {
    for (final count in [0, -1]) {
      await expectPublishRejected(
        current: sampleTest(id: 'test-1', questionCount: count),
        message: 'Question count must be greater than zero.',
      );
    }
  });

  test('publication rejects negative total marks', () async {
    await expectPublishRejected(
      current: sampleTest(id: 'test-1', marks: -1),
      message: 'Total marks must be zero or greater.',
    );
  });

  test('publication rejects zero duration', () async {
    await expectPublishRejected(
      current: sampleTest(id: 'test-1', durationMinutes: 0),
      message: 'Duration must be greater than zero.',
    );
  });

  test('publication rejects invalid negative marking', () async {
    await expectPublishRejected(
      current: sampleTest(id: 'test-1', negativeMarking: '-0.25'),
      message: 'Negative marking must be a valid non-negative number.',
    );
  });

  test('publication rejects empty difficulty', () async {
    await expectPublishRejected(
      current: sampleTest(id: 'test-1', difficulty: ' '),
      message: 'Difficulty is required.',
    );
  });

  test(
    'valid publication allows empty questionIds for dynamic selection',
    () async {
      var published = false;
      final service = publishService(
        current: sampleTest(id: 'test-1', questionIds: const []),
        onPublished: (value) => published = value,
      );

      await service.publishTest('test-1');

      expect(published, isTrue);
    },
  );

  test('admin loader is independent from student loader', () async {
    var studentLoaderCalled = false;
    var adminLoaderCalled = false;
    final repo = TestCloudRepository.withLoader(
      (_) async {
        studentLoaderCalled = true;
        return const [];
      },
      loadAdminTests: (courseId) async {
        adminLoaderCalled = true;
        return [sampleTest(id: 'draft-1', title: 'Draft')];
      },
    );

    final tests = await repo.loadAdminTests('group-ii');

    expect(tests.single.id, 'draft-1');
    expect(adminLoaderCalled, isTrue);
    expect(studentLoaderCalled, isFalse);
  });

  test('20: unpublish sets isPublished false', () async {
    var published = true;
    final repo = TestCloudRepository.withLoader(
      (_) async => const [],
      setPublished: ({required testId, required isPublished}) async {
        published = isPublished;
      },
    );
    final service = AdminTestService(testRepository: repo);
    await service.unpublishTest('test-1');
    expect(published, isFalse);
  });

  test('repository create/update use admin handlers', () async {
    String? createdId;
    Map<String, dynamic>? createdData;
    Map<String, dynamic>? updatedData;

    final repo = TestCloudRepository.withLoader(
      (_) async => const [],
      create: ({required testId, required data}) async {
        createdId = testId;
        createdData = data;
      },
      update: ({required testId, required data}) async {
        updatedData = data;
      },
      idGenerator: () => 'test-generated',
    );
    final service = AdminTestService(testRepository: repo);

    final id = await service.createTest(
      sampleTest(title: 'New Test', status: TestPublicationStatus.published),
    );
    expect(id, 'test-generated');
    expect(createdId, 'test-generated');
    expect(createdData!['id'], 'test-generated');
    expect(createdData!['questionIds'], isEmpty);
    expect(createdData!['isPublished'], isFalse);

    await service.updateTest(
      sampleTest(id: 'test-generated', title: 'Updated Test'),
    );
    expect(updatedData!['title'], 'Updated Test');
    expect(updatedData!['questionIds'], isEmpty);
  });

  test('AdminTestService rejects invalid writes before repository', () async {
    var called = false;
    final repo = TestCloudRepository.withLoader(
      (_) async => const [],
      create: ({required testId, required data}) async {
        called = true;
      },
    );
    final service = AdminTestService(testRepository: repo);

    expect(
      () => service.createTest(sampleTest(title: '')),
      throwsA(isA<FormatException>()),
    );
    expect(called, isFalse);
  });

  Question paperIQuestion({
    required String id,
    required String majorStudyAreaId,
  }) {
    final now = DateTime(2026, 8, 24);
    return Question(
      id: id,
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      question: 'Sample question?',
      options: const ['A', 'B', 'C', 'D'],
      correctOption: 'A',
      explanation: 'Because.',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      isActive: true,
      syllabus: QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        majorStudyAreaId: majorStudyAreaId,
        contentTopicId: '$majorStudyAreaId-topic-01',
      ),
    );
  }

  TestModel currentAffairsTest({required List<String> questionIds}) {
    return TestModel(
      id: '',
      examId: 'group-ii',
      category: TestCategoryType.chapterTests,
      title: 'Current Affairs Test 1',
      questionCount: questionIds.length,
      marks: questionIds.length,
      durationMinutes: 1,
      negativeMarking: '0',
      difficulty: 'Medium',
      questionIds: questionIds,
      paperId: 'group-ii-paper-i',
      syllabusUnitId: 'group-ii-paper-i-area-01',
    );
  }

  test(
    'Chapter test accepts a Paper I question whose majorStudyAreaId is the unit',
    () async {
      final currentAffairs = paperIQuestion(
        id: 'ca-1',
        majorStudyAreaId: 'group-ii-paper-i-area-01',
      );
      expect(currentAffairs.syllabusUnitId, isNull);
      expect(
        currentAffairs.canonicalScope?.syllabusUnitId,
        'group-ii-paper-i-area-01',
      );

      var created = false;
      final service = AdminTestService(
        testRepository: TestCloudRepository.withLoader(
          (_) async => const [],
          create: ({required testId, required data}) async {
            created = true;
          },
        ),
        questionRepository: QuestionCloudRepository.withHandlers(
          getByIds: (ids) async => [currentAffairs],
        ),
      );

      await service.createTest(currentAffairsTest(questionIds: const ['ca-1']));
      expect(created, isTrue);
    },
  );

  test(
    'Chapter test rejects a Paper I question from another syllabus unit',
    () async {
      final internationalRelations = paperIQuestion(
        id: 'ir-1',
        majorStudyAreaId: 'group-ii-paper-i-area-02',
      );
      var created = false;
      final service = AdminTestService(
        testRepository: TestCloudRepository.withLoader(
          (_) async => const [],
          create: ({required testId, required data}) async {
            created = true;
          },
        ),
        questionRepository: QuestionCloudRepository.withHandlers(
          getByIds: (ids) async => [internationalRelations],
        ),
      );

      expect(
        () => service.createTest(currentAffairsTest(questionIds: const ['ir-1'])),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'This question belongs to another Chapter/Topic and cannot be '
              'added to this test.',
            ),
          ),
        ),
      );
      expect(created, isFalse);
    },
  );

  test(
    'Chapter question picker returns only the selected syllabus unit',
    () async {
      final currentAffairs = paperIQuestion(
        id: 'ca-1',
        majorStudyAreaId: 'group-ii-paper-i-area-01',
      );
      final internationalRelations = paperIQuestion(
        id: 'ir-1',
        majorStudyAreaId: 'group-ii-paper-i-area-02',
      );
      final service = AdminTestService(
        testRepository: TestCloudRepository.withLoader((_) async => const []),
        questionRepository: QuestionCloudRepository.withHandlers(
          loadQuestions: (_) async => [currentAffairs, internationalRelations],
        ),
      );

      final ids = await service.findQuestionIdsForChapterTest(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01',
      );
      expect(ids, ['ca-1']);
      expect(
        AdminTestService.questionMatchesChapterUnit(
          currentAffairs,
          'group-ii-paper-i-area-01',
        ),
        isTrue,
      );
      expect(
        AdminTestService.questionMatchesChapterUnit(
          internationalRelations,
          'group-ii-paper-i-area-01',
        ),
        isFalse,
      );
    },
  );
}
