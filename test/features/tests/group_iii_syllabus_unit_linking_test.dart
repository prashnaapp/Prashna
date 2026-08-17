import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/data/test_cloud_mapper.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';

void main() {
  const kakatiyaUnitId = 'group-iii-paper-ii-part-i-unit-02';

  TestModel groupIiiUnitTest({
    String id = 'giii-kakatiya-1',
    TestPublicationStatus status = TestPublicationStatus.published,
  }) {
    return TestModel(
      id: id,
      examId: 'group-iii',
      category: TestCategoryType.chapterTests,
      title: 'Test 1 — Establishment of Kakatiya Kingdom',
      questionCount: 30,
      marks: 30,
      durationMinutes: 30,
      negativeMarking: '0',
      difficulty: 'Medium',
      questionIds: const [],
      status: status,
      paperId: 'group-iii-paper-ii',
      partId: 'group-iii-paper-ii-part-i',
      syllabusUnitId: kakatiyaUnitId,
    );
  }

  test('mapper persists Group-III syllabus location fields', () {
    final data = TestCloudMapper.toFirestore(
      groupIiiUnitTest(),
      documentId: 'giii-kakatiya-1',
    );

    expect(data['courseId'], 'group-iii');
    expect(data['paperId'], 'group-iii-paper-ii');
    expect(data['partId'], 'group-iii-paper-ii-part-i');
    expect(data['syllabusUnitId'], kakatiyaUnitId);
    expect(data.containsKey('lessonId'), isFalse);
  });

  test('mapper restores Group-III syllabus location fields', () {
    final data = TestCloudMapper.toFirestore(
      groupIiiUnitTest(),
      documentId: 'giii-kakatiya-1',
    );
    final mapped = TestCloudMapper.fromFirestore('giii-kakatiya-1', data)!;

    expect(mapped.paperId, 'group-iii-paper-ii');
    expect(mapped.partId, 'group-iii-paper-ii-part-i');
    expect(mapped.syllabusUnitId, kakatiyaUnitId);
  });

  test('Group-II Paper-I writes syllabus location fields', () {
    final data = TestCloudMapper.toFirestore(
      const TestModel(
        id: 'gii-1',
        examId: 'group-ii',
        category: TestCategoryType.chapterTests,
        title: 'Group-II Practice',
        questionCount: 10,
        marks: 10,
        durationMinutes: 30,
        negativeMarking: '0',
        difficulty: 'Medium',
        status: TestPublicationStatus.published,
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01',
      ),
      documentId: 'gii-1',
    );

    expect(data['paperId'], 'group-ii-paper-i');
    expect(data.containsKey('partId'), isFalse);
    expect(data['syllabusUnitId'], 'group-ii-paper-i-area-01');
  });

  test(
    'Group-II Paper-II Part-I preserves its syllabus unit on create',
    () async {
      Map<String, dynamic>? created;
      final repository = TestCloudRepository.withLoader(
        (_) async => const [],
        idGenerator: () => 'gii-part-test',
        create: ({required testId, required data}) async => created = data,
      );
      await repository.createTest(
        const TestModel(
          id: '',
          examId: 'group-ii',
          category: TestCategoryType.chapterTests,
          title: 'Paper II Part I',
          questionCount: 1,
          marks: 1,
          durationMinutes: 1,
          negativeMarking: '0',
          difficulty: 'Medium',
          paperId: 'group-ii-paper-ii',
          partId: 'group-ii-paper-ii-part-01',
          syllabusUnitId: 'group-ii-paper-ii-part-01-topic-04',
        ),
      );
      expect(created?['paperId'], 'group-ii-paper-ii');
      expect(created?['partId'], 'group-ii-paper-ii-part-01');
      expect(created?['syllabusUnitId'], 'group-ii-paper-ii-part-01-topic-04');
    },
  );

  test('student unit query returns only matching syllabusUnitId', () async {
    final service = TestService(
      cloudRepository: TestCloudRepository.withLoader((courseId) async {
        expect(courseId, 'group-iii');
        return [
          groupIiiUnitTest(),
          groupIiiUnitTest(id: 'other-unit').copyWithLocation(
            syllabusUnitId: 'group-iii-paper-ii-part-i-unit-01',
            title: 'Other unit test',
          ),
          const TestModel(
            id: 'unlinked',
            examId: 'group-iii',
            category: TestCategoryType.chapterTests,
            title: 'Unlinked',
            questionCount: 5,
            marks: 5,
            durationMinutes: 10,
            negativeMarking: '0',
            difficulty: 'Medium',
            status: TestPublicationStatus.published,
          ),
        ];
      }),
    );

    final tests = await service.getTestsForSyllabusUnit(
      courseId: 'group-iii',
      paperId: 'group-iii-paper-ii',
      partId: 'group-iii-paper-ii-part-i',
      syllabusUnitId: kakatiyaUnitId,
    );

    expect(tests, hasLength(1));
    expect(tests.single.id, 'giii-kakatiya-1');
    expect(tests.single.title, 'Test 1 — Establishment of Kakatiya Kingdom');
  });
}

extension on TestModel {
  TestModel copyWithLocation({String? syllabusUnitId, String? title}) {
    return TestModel(
      id: id,
      examId: examId,
      category: category,
      title: title ?? this.title,
      description: description,
      questionCount: questionCount,
      marks: marks,
      durationMinutes: durationMinutes,
      negativeMarking: negativeMarking,
      difficulty: difficulty,
      questionIds: questionIds,
      status: status,
      paperId: paperId,
      partId: partId,
      syllabusUnitId: syllabusUnitId ?? this.syllabusUnitId,
    );
  }
}
