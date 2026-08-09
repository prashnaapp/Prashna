import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/services/admin_test_service.dart';
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
    bool isPublished = false,
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
      isPublished: isPublished,
    );
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
      sampleTest(isPublished: true),
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
      sampleTest(isPublished: false),
      documentId: 't1',
    );
    final published = TestCloudMapper.toFirestore(
      sampleTest(isPublished: true),
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
    final repo = TestCloudRepository.withLoader(
      (_) async => const [],
      setPublished: ({required testId, required isPublished}) async {
        published = isPublished;
      },
    );
    final service = AdminTestService(testRepository: repo);
    await service.publishTest('test-1');
    expect(published, isTrue);
    expect(
      TestCloudMapper.toPublishMap(isPublished: true)['isPublished'],
      isTrue,
    );
  });

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
      sampleTest(title: 'New Test', isPublished: true),
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
    expect(updatedData!.containsKey('questionIds'), isFalse);
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
}
