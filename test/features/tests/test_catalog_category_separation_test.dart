import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/data/test_series_browser_groups.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';

void main() {
  TestModel testModel({
    required String id,
    required String examId,
    required TestCategoryType category,
    String? paperId,
    String? partId,
    String? syllabusUnitId,
    String? seriesId,
    int? year,
  }) {
    return TestModel(
      id: id,
      examId: examId,
      category: category,
      title: 'Test $id',
      questionCount: 10,
      marks: 10,
      durationMinutes: 15,
      negativeMarking: '0',
      difficulty: 'Medium',
      status: TestPublicationStatus.published,
      paperId: paperId,
      partId: partId,
      syllabusUnitId: syllabusUnitId,
      seriesId: seriesId,
      year: year,
    );
  }

  TestService serviceFor(List<TestModel> catalog) {
    return TestService(
      cloudRepository: TestCloudRepository.withLoader(
        (courseId) async => [
          for (final test in catalog)
            if (test.examId == courseId) test,
        ],
      ),
    );
  }

  group('Paper-wise catalog excludes chapter tests', () {
    for (final courseId in ['group-ii', 'group-iii']) {
      test('$courseId paper-wise getTests excludes chapterTests', () async {
        final papers = SyllabusService.instance.getCourseById(courseId)!.papers;
        final catalog = <TestModel>[
          for (final paper in papers)
            testModel(
              id: 'chapter-${paper.id}',
              examId: courseId,
              category: TestCategoryType.chapterTests,
              paperId: paper.id,
              syllabusUnitId: '${paper.id}-unit',
            ),
          for (final paper in papers)
            testModel(
              id: 'part-${paper.id}',
              examId: courseId,
              category: TestCategoryType.partTests,
              paperId: paper.id,
            ),
        ];
        final service = serviceFor(catalog);
        final paperWise = await service.getTests(
          examId: courseId,
          category: TestCategoryType.partTests,
        );
        expect(
          paperWise.every((t) => t.category == TestCategoryType.partTests),
          isTrue,
        );
        expect(paperWise.map((t) => t.id).toSet(), {
          for (final paper in papers) 'part-${paper.id}',
        });
      });
    }

    test('Group-II paper-wise tabs exclude chapter rows per paper', () {
      final papers = SyllabusService.instance.getCourseById('group-ii')!.papers;
      final mixed = [
        for (final paper in papers) ...[
          testModel(
            id: 'ch-${paper.id}',
            examId: 'group-ii',
            category: TestCategoryType.chapterTests,
            paperId: paper.id,
          ),
          testModel(
            id: 'pw-${paper.id}',
            examId: 'group-ii',
            category: TestCategoryType.partTests,
            paperId: paper.id,
          ),
        ],
      ];
      final tabs = TestSeriesBrowserGroups.paperWise(
        papers: papers,
        tests: mixed,
      );
      expect(tabs, hasLength(4));
      for (final tab in tabs) {
        expect(
          tab.tests.every((t) => t.category == TestCategoryType.partTests),
          isTrue,
        );
        expect(tab.tests.map((t) => t.id), ['pw-${tab.id}']);
      }
    });
  });

  test('Grand Tests remain mockTests only', () async {
    final service = serviceFor([
      testModel(
        id: 'mock-1',
        examId: 'group-ii',
        category: TestCategoryType.mockTests,
        seriesId: 'grand-ii',
      ),
      testModel(
        id: 'chapter-1',
        examId: 'group-ii',
        category: TestCategoryType.chapterTests,
        paperId: 'group-ii-paper-i',
      ),
      testModel(
        id: 'part-1',
        examId: 'group-ii',
        category: TestCategoryType.partTests,
        paperId: 'group-ii-paper-i',
      ),
    ]);
    final grand = await service.getTests(
      examId: 'group-ii',
      category: TestCategoryType.mockTests,
    );
    expect(grand.map((t) => t.id), ['mock-1']);
  });

  test('Previous Papers remain previousYear only', () async {
    final service = serviceFor([
      testModel(
        id: 'prev-1',
        examId: 'group-ii',
        category: TestCategoryType.previousYear,
        year: 2024,
      ),
      testModel(
        id: 'chapter-1',
        examId: 'group-ii',
        category: TestCategoryType.chapterTests,
        paperId: 'group-ii-paper-i',
      ),
    ]);
    final previous = await service.getTests(
      examId: 'group-ii',
      category: TestCategoryType.previousYear,
    );
    expect(previous.map((t) => t.id), ['prev-1']);
  });

  group('Chapter syllabus unit loader', () {
    const unitId = 'group-ii-paper-i-area-01';
    const paperId = 'group-ii-paper-i';

    test('includes chapterTests only for matching unit', () async {
      final service = serviceFor([
        testModel(
          id: 'chapter-match',
          examId: 'group-ii',
          category: TestCategoryType.chapterTests,
          paperId: paperId,
          syllabusUnitId: unitId,
        ),
        testModel(
          id: 'part-same-paper',
          examId: 'group-ii',
          category: TestCategoryType.partTests,
          paperId: paperId,
          syllabusUnitId: unitId,
        ),
        testModel(
          id: 'mock-same-paper',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          paperId: paperId,
          syllabusUnitId: unitId,
        ),
        testModel(
          id: 'prev-same-paper',
          examId: 'group-ii',
          category: TestCategoryType.previousYear,
          paperId: paperId,
          syllabusUnitId: unitId,
          year: 2020,
        ),
      ]);
      final tests = await service.getTestsForSyllabusUnit(
        courseId: 'group-ii',
        paperId: paperId,
        syllabusUnitId: unitId,
      );
      expect(tests.map((t) => t.id), ['chapter-match']);
    });
  });
}
