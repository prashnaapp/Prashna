import '../../tests/data/models/test_models.dart';
import '../../tests/data/test_cloud_mapper.dart';
import 'admin_question_scope.dart';

/// Server equality filters for Tests that can receive a Question from one bank.
///
/// Paper-wise matches course + category + paper. It does not filter partId.
/// Grand matches course + category + seriesId and ignores the legacy Test
/// paperId. Previous matches course + category + year and ignores paperId.
class AdminCompatibleTestQuery {
  const AdminCompatibleTestQuery({
    required this.courseId,
    required this.category,
    this.paperId,
    this.seriesId,
    this.year,
  });

  final String courseId;
  final String category;
  final String? paperId;
  final String? seriesId;
  final int? year;

  static AdminCompatibleTestQuery fromScope(AdminQuestionScope scope) {
    if (!scope.isQuestionBank) {
      throw const FormatException(
        'Compatible tests require a Test Series question bank.',
      );
    }
    final courseId = scope.courseId!.trim();
    return switch (scope.testSeriesCategory) {
      AdminQuestionScope.categoryPart => AdminCompatibleTestQuery(
        courseId: courseId,
        category: AdminQuestionScope.categoryPart,
        paperId: scope.paperId!.trim(),
      ),
      AdminQuestionScope.categoryMock => AdminCompatibleTestQuery(
        courseId: courseId,
        category: AdminQuestionScope.categoryMock,
        seriesId: scope.seriesId!.trim(),
      ),
      AdminQuestionScope.categoryPreviousYear => AdminCompatibleTestQuery(
        courseId: courseId,
        category: AdminQuestionScope.categoryPreviousYear,
        year: scope.year,
      ),
      _ => throw const FormatException('Unsupported Test Series category.'),
    };
  }

  List<({String field, Object value})> get equalityFilters {
    final filters = <({String field, Object value})>[
      (field: 'courseId', value: courseId),
      (field: 'category', value: category),
    ];
    switch (category) {
      case AdminQuestionScope.categoryPart:
        filters.add((field: 'paperId', value: paperId!));
      case AdminQuestionScope.categoryMock:
        filters.add((field: 'seriesId', value: seriesId!));
      case AdminQuestionScope.categoryPreviousYear:
        filters.add((field: 'year', value: year!));
    }
    return filters;
  }

  bool matches(TestModel test) {
    if (test.examId != courseId) return false;
    if (TestCloudMapper.categoryToFirestore(test.category) != category) {
      return false;
    }
    return switch (category) {
      AdminQuestionScope.categoryPart => test.paperId == paperId,
      AdminQuestionScope.categoryMock => test.seriesId == seriesId,
      AdminQuestionScope.categoryPreviousYear => test.year == year,
      _ => false,
    };
  }
}
