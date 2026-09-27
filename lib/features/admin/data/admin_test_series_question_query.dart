import 'admin_question_scope.dart';

/// Server-side Test Series Question Bank query.
///
/// First page only. No cursor. [pageSize] is the centralized read bound.
class AdminTestSeriesQuestionQuery {
  const AdminTestSeriesQuestionQuery({
    required this.courseId,
    required this.testSeriesCategory,
    this.paperId,
    this.seriesId,
    this.year,
  });

  /// Bounded first page. Not an unlimited course read.
  static const int pageSize = 50;

  final String courseId;
  final String testSeriesCategory;
  final String? paperId;
  final String? seriesId;
  final int? year;

  factory AdminTestSeriesQuestionQuery.fromScope(AdminQuestionScope scope) {
    if (!scope.isQuestionBank) {
      throw const FormatException(
        'Test Series Question Bank scope is incomplete.',
      );
    }
    final category = scope.testSeriesCategory!;
    return AdminTestSeriesQuestionQuery(
      courseId: scope.courseId!.trim(),
      testSeriesCategory: category,
      paperId: category == AdminQuestionScope.categoryPart
          ? scope.paperId!.trim()
          : null,
      seriesId: category == AdminQuestionScope.categoryMock
          ? scope.seriesId!.trim()
          : null,
      year: category == AdminQuestionScope.categoryPreviousYear
          ? scope.year
          : null,
    );
  }

  /// Equality filters applied by Firestore. No client-side course scan.
  List<({String field, Object value})> get equalityFilters {
    final filters = <({String field, Object value})>[
      (field: 'contentArea', value: AdminQuestionScope.contentAreaTestSeries),
      (field: 'testSeriesCategory', value: testSeriesCategory),
      (field: 'courseId', value: courseId),
    ];
    switch (testSeriesCategory) {
      case AdminQuestionScope.categoryPart:
        filters.add((field: 'paperId', value: paperId!));
      case AdminQuestionScope.categoryMock:
        filters.add((field: 'seriesId', value: seriesId!));
      case AdminQuestionScope.categoryPreviousYear:
        filters.add((field: 'year', value: year!));
    }
    return filters;
  }
}
