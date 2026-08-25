import '../../tests/data/models/test_models.dart';

/// Locked create/edit context for Admin test forms.
///
/// Values come from hierarchical navigation, not from parsing titles.
class AdminTestScope {
  const AdminTestScope({
    required this.category,
    required this.courseId,
    this.paperId,
    this.partId,
    this.syllabusUnitId,
    this.seriesId,
    this.year,
  });

  final TestCategoryType category;
  final String courseId;
  final String? paperId;
  final String? partId;
  final String? syllabusUnitId;
  final String? seriesId;
  final int? year;

  factory AdminTestScope.fromTest(TestModel test) {
    return AdminTestScope(
      category: test.category,
      courseId: test.examId,
      paperId: test.paperId,
      partId: test.partId,
      syllabusUnitId: test.syllabusUnitId,
      seriesId: test.seriesId,
      year: test.year,
    );
  }
}
