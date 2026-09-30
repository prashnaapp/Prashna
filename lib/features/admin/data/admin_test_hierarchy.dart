import '../../syllabus/data/models/syllabus_models.dart';
import '../../tests/data/previous_paper_years.dart';
import '../../tests/data/models/test_models.dart';

/// Filters Admin catalog tests by explicit metadata only.
abstract final class AdminTestHierarchy {
  static List<TestModel> chapters({
    required List<TestModel> tests,
    required String courseId,
    required String paperId,
    String? partId,
    required String syllabusUnitId,
  }) {
    return [
      for (final test in tests)
        if (test.examId == courseId &&
            test.category == TestCategoryType.chapterTests &&
            test.paperId == paperId &&
            test.syllabusUnitId == syllabusUnitId &&
            (partId == null || partId.isEmpty || test.partId == partId))
          test,
    ];
  }

  static List<TestModel> paperWise({
    required List<TestModel> tests,
    required String courseId,
    required String paperId,
  }) {
    return [
      for (final test in tests)
        if (test.examId == courseId &&
            test.category == TestCategoryType.partTests &&
            test.paperId == paperId)
          test,
    ];
  }

  static List<TestModel> grandTests({
    required List<TestModel> tests,
    required String courseId,
    required String seriesId,
  }) {
    return [
      for (final test in tests)
        if (test.examId == courseId &&
            test.category == TestCategoryType.mockTests &&
            test.seriesId == seriesId)
          test,
    ];
  }

  static List<TestModel> previousPapers({
    required List<TestModel> tests,
    required String courseId,
    required int year,
  }) {
    return [
      for (final test in tests)
        if (test.examId == courseId &&
            test.category == TestCategoryType.previousYear &&
            test.year == year)
          test,
    ];
  }

  static List<String> seriesIds({
    required List<TestModel> tests,
    required String courseId,
  }) {
    final ids = <String>{};
    for (final test in tests) {
      if (test.examId != courseId) continue;
      if (test.category != TestCategoryType.mockTests) continue;
      final seriesId = test.seriesId?.trim();
      if (seriesId == null || seriesId.isEmpty) continue;
      ids.add(seriesId);
    }
    final list = ids.toList()..sort();
    return list;
  }

  /// Configured product years. These are navigation metadata, not documents.
  static List<int> years({
    required List<TestModel> tests,
    required String courseId,
  }) {
    return List<int>.of(PreviousPaperYears.forExam(courseId));
  }

  static String paperLabel(SyllabusPaper paper) =>
      paper.title.replaceFirst(RegExp(r'^Paper-'), 'Paper ');
}
