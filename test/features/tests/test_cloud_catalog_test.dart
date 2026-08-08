import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/data/test_cloud_mapper.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';

void main() {
  group('TestCloudMapper', () {
    test('A: maps test-group-ii-001 document to TestModel', () {
      final model = TestCloudMapper.fromFirestore('test-group-ii-001', {
        'id': 'test-group-ii-001',
        'courseId': 'group-ii',
        'title': 'Group-II Practice Test 1',
        'category': 'chapter',
        'questionCount': 1,
        'totalMarks': 1,
        'durationMinutes': 1,
        'negativeMarks': 0,
        'instructions': ['Read each question carefully.'],
        'isPublished': true,
      });

      expect(model, isNotNull);
      expect(model!.id, 'test-group-ii-001');
      expect(model.examId, 'group-ii');
      expect(model.title, 'Group-II Practice Test 1');
      expect(model.category, TestCategoryType.chapterTests);
      expect(model.questionCount, 1);
      expect(model.marks, 1);
      expect(model.durationMinutes, 1);
      expect(model.negativeMarking, '0');
      expect(model.difficulty, 'Medium');
      expect(model.questionIds, isEmpty);
    });

    test('parses questionIds from Firestore list', () {
      final model = TestCloudMapper.fromFirestore('test-group-ii-001', {
        'id': 'test-group-ii-001',
        'courseId': 'group-ii',
        'title': 'Group-II Practice Test 1',
        'category': 'chapter',
        'questionCount': 1,
        'totalMarks': 1,
        'durationMinutes': 1,
        'negativeMarks': 0,
        'isPublished': true,
        'questionIds': ['q-test-group-ii-001'],
      });

      expect(model, isNotNull);
      expect(model!.questionIds, ['q-test-group-ii-001']);
    });

    test('missing questionIds defaults to empty list', () {
      final model = TestCloudMapper.fromFirestore('t1', {
        'courseId': 'group-ii',
        'title': 'T',
        'category': 'chapter',
        'questionCount': 1,
        'totalMarks': 1,
        'durationMinutes': 1,
        'negativeMarks': 0,
        'isPublished': true,
      });

      expect(model, isNotNull);
      expect(model!.questionIds, isEmpty);
    });

    test('null / malformed questionIds entries are ignored safely', () {
      expect(TestCloudMapper.parseQuestionIds(null), isEmpty);
      expect(TestCloudMapper.parseQuestionIds('not-a-list'), isEmpty);
      expect(
        TestCloudMapper.parseQuestionIds([
          'q1',
          42,
          '',
          '  ',
          'q2',
          null,
        ]),
        ['q1', 'q2'],
      );
    });

    test('maps numeric fields that arrive as double', () {
      final model = TestCloudMapper.fromFirestore('t1', {
        'courseId': 'group-ii',
        'title': 'T',
        'category': 'chapter',
        'questionCount': 1.0,
        'totalMarks': 1.0,
        'durationMinutes': 1.0,
        'negativeMarks': 0.25,
        'isPublished': true,
      });

      expect(model, isNotNull);
      expect(model!.questionCount, 1);
      expect(model.marks, 1);
      expect(model.durationMinutes, 1);
      expect(model.negativeMarking, '0.25');
    });

    test('B: unpublished documents map to null', () {
      final model = TestCloudMapper.fromFirestore('unpublished', {
        'courseId': 'group-ii',
        'title': 'Hidden',
        'category': 'chapter',
        'questionCount': 1,
        'totalMarks': 1,
        'durationMinutes': 1,
        'negativeMarks': 0,
        'isPublished': false,
      });

      expect(model, isNull);
    });

    test('skips documents with unknown category', () {
      final model = TestCloudMapper.fromFirestore('bad', {
        'courseId': 'group-ii',
        'title': 'Bad',
        'category': 'unknown',
        'questionCount': 1,
        'totalMarks': 1,
        'durationMinutes': 1,
        'negativeMarks': 0,
        'isPublished': true,
      });

      expect(model, isNull);
    });
  });

  group('TestCloudRepository.loadPublishedTests filtering', () {
    TestModel cloudTest({
      required String id,
      required String courseId,
      required TestCategoryType category,
      String title = 'T',
    }) {
      return TestModel(
        id: id,
        examId: courseId,
        category: category,
        title: title,
        questionCount: 1,
        marks: 1,
        durationMinutes: 1,
        negativeMarking: '0',
        difficulty: 'Medium',
      );
    }

    test('Group-II published tests load', () async {
      final repo = TestCloudRepository.withLoader((courseId) async {
        expect(courseId, 'group-ii');
        return [
          cloudTest(
            id: 'test-group-ii-001',
            courseId: 'group-ii',
            category: TestCategoryType.chapterTests,
            title: 'Group-II Practice Test 1',
          ),
        ];
      });

      final tests = await repo.loadPublishedTests('group-ii');
      expect(tests, hasLength(1));
      expect(tests.single.id, 'test-group-ii-001');
      expect(tests.single.examId, 'group-ii');
      expect(tests.single.title, 'Group-II Practice Test 1');
    });

    test('unpublished tests are excluded by mapper', () {
      expect(
        TestCloudMapper.fromFirestore('unpublished', {
          'id': 'unpublished',
          'courseId': 'group-ii',
          'title': 'Hidden',
          'category': 'chapter',
          'questionCount': 1,
          'totalMarks': 1,
          'durationMinutes': 1,
          'negativeMarks': 0,
          'isPublished': false,
        }),
        isNull,
      );
    });

    test('courseId filtering remains intact', () async {
      final repo = TestCloudRepository.withLoader((courseId) async {
        // Simulate Firestore where clause: only matching courseId.
        final all = [
          cloudTest(
            id: 'test-group-ii-001',
            courseId: 'group-ii',
            category: TestCategoryType.chapterTests,
          ),
          cloudTest(
            id: 'test-group-iii-001',
            courseId: 'group-iii',
            category: TestCategoryType.chapterTests,
          ),
        ];
        return [
          for (final test in all)
            if (test.examId == courseId) test,
        ];
      });

      final groupIi = await repo.loadPublishedTests('group-ii');
      expect(groupIi.every((t) => t.examId == 'group-ii'), isTrue);
      expect(groupIi.map((t) => t.id), isNot(contains('test-group-iii-001')));

      final groupIii = await repo.loadPublishedTests('group-iii');
      expect(groupIii.every((t) => t.examId == 'group-iii'), isTrue);
      expect(groupIii.map((t) => t.id), isNot(contains('test-group-ii-001')));
    });
  });

  group('TestService.getTests (Firestore catalog)', () {
    TestModel cloudTest({
      required String id,
      required String courseId,
      required TestCategoryType category,
      String title = 'T',
    }) {
      return TestModel(
        id: id,
        examId: courseId,
        category: category,
        title: title,
        questionCount: 1,
        marks: 1,
        durationMinutes: 1,
        negativeMarking: '0',
        difficulty: 'Medium',
      );
    }

    test('A: returns mapped chapter test for group-ii', () async {
      final service = TestService(
        cloudRepository: TestCloudRepository.withLoader((courseId) async {
          expect(courseId, 'group-ii');
          return [
            cloudTest(
              id: 'test-group-ii-001',
              courseId: 'group-ii',
              category: TestCategoryType.chapterTests,
              title: 'Group-II Practice Test 1',
            ),
          ];
        }),
      );

      final tests = await service.getTests(
        examId: 'group-ii',
        category: TestCategoryType.chapterTests,
      );

      expect(tests, hasLength(1));
      expect(tests.single.id, 'test-group-ii-001');
      expect(tests.single.examId, 'group-ii');
      expect(tests.single.title, 'Group-II Practice Test 1');
      expect(tests.single.questionCount, 1);
      expect(tests.single.marks, 1);
      expect(tests.single.durationMinutes, 1);
      expect(tests.single.negativeMarking, '0');
    });

    test('C: group-iii tests are not returned when loading group-ii', () async {
      final service = TestService(
        cloudRepository: TestCloudRepository.withLoader((courseId) async {
          if (courseId != 'group-ii') {
            return [
              cloudTest(
                id: 'test-group-iii-001',
                courseId: 'group-iii',
                category: TestCategoryType.chapterTests,
              ),
            ];
          }
          return [
            cloudTest(
              id: 'test-group-ii-001',
              courseId: 'group-ii',
              category: TestCategoryType.chapterTests,
            ),
          ];
        }),
      );

      final tests = await service.getTests(
        examId: 'group-ii',
        category: TestCategoryType.chapterTests,
      );

      expect(tests.every((t) => t.examId == 'group-ii'), isTrue);
      expect(tests.any((t) => t.examId == 'group-iii'), isFalse);
      expect(tests.map((t) => t.id), isNot(contains('test-group-iii-001')));
    });

    test('filters by category within the same course', () async {
      final service = TestService(
        cloudRepository: TestCloudRepository.withLoader(
          (courseId) async => [
            cloudTest(
              id: 'chapter-1',
              courseId: courseId,
              category: TestCategoryType.chapterTests,
            ),
            cloudTest(
              id: 'mock-1',
              courseId: courseId,
              category: TestCategoryType.mockTests,
            ),
          ],
        ),
      );

      final chapter = await service.getTests(
        examId: 'group-ii',
        category: TestCategoryType.chapterTests,
      );
      expect(chapter.map((t) => t.id), ['chapter-1']);

      final mocks = await service.getTests(
        examId: 'group-ii',
        category: TestCategoryType.mockTests,
      );
      expect(mocks.map((t) => t.id), ['mock-1']);
    });

    test('propagates repository errors (no dummy fallback)', () async {
      final service = TestService(
        cloudRepository: TestCloudRepository.withLoader((_) async {
          throw StateError('network down');
        }),
      );

      await expectLater(
        service.getTests(
          examId: 'group-ii',
          category: TestCategoryType.chapterTests,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('D: exam summary / category APIs remain sync and unchanged', () {
      final service = TestService(
        cloudRepository: TestCloudRepository.withLoader((_) async => const []),
      );

      expect(service.getExamSummaries(), isNotEmpty);
      expect(service.getCategories('group-ii'), isNotEmpty);
      expect(
        service.getCategories('group-ii').map((c) => c.type),
        contains(TestCategoryType.chapterTests),
      );
    });
  });
}
