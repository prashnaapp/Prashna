/// Locked create/browse context for Admin Question navigation.
///
/// Values come from hierarchical navigation. Wire category values match
/// Phase 3A `testSeriesCategory`: part | mock | previousyear.
class AdminQuestionScope {
  const AdminQuestionScope({
    required this.contentArea,
    this.courseId,
    this.testSeriesCategory,
    this.paperId,
    this.seriesId,
    this.year,
  });

  /// `chapter` or `testSeries`.
  final String contentArea;
  final String? courseId;

  /// `part` (Paper-wise), `mock` (Grand Tests), `previousyear` (Previous Papers).
  final String? testSeriesCategory;

  /// Paper-wise bank discriminator. Not a Part folder.
  final String? paperId;

  /// Grand bank discriminator. Canonical [GrandTestSeries] id.
  final String? seriesId;

  /// Previous Papers bank discriminator.
  final int? year;

  static const contentAreaChapter = 'chapter';
  static const contentAreaTestSeries = 'testSeries';

  static const categoryPart = 'part';
  static const categoryMock = 'mock';
  static const categoryPreviousYear = 'previousyear';

  bool get isChapter => contentArea == contentAreaChapter;
  bool get isTestSeries => contentArea == contentAreaTestSeries;

  /// A Test-Series bank needs course, category, and exactly one discriminator.
  /// Paper-wise uses [paperId] only. [partId] is not part of this scope.
  bool get isQuestionBank {
    final course = courseId?.trim() ?? '';
    if (!isTestSeries || course.isEmpty) return false;
    return switch (testSeriesCategory) {
      categoryPart => paperId?.trim().isNotEmpty ?? false,
      categoryMock => seriesId?.trim().isNotEmpty ?? false,
      categoryPreviousYear => year != null,
      _ => false,
    };
  }

  /// Rebuilds a bank scope from a stored Test Series question.
  ///
  /// Used when Edit opens the shared form without an explicit navigation scope.
  static AdminQuestionScope? fromQuestion({
    required String? contentArea,
    required String? courseId,
    required String? testSeriesCategory,
    String? paperId,
    String? seriesId,
    int? year,
  }) {
    if (contentArea != contentAreaTestSeries) return null;
    final scope = AdminQuestionScope(
      contentArea: contentAreaTestSeries,
      courseId: courseId,
      testSeriesCategory: testSeriesCategory,
      paperId: paperId,
      seriesId: seriesId,
      year: year,
    );
    return scope.isQuestionBank ? scope : null;
  }

  String get categoryLabel => labelForCategory(testSeriesCategory);

  static String labelForCategory(String? category) {
    return switch (category) {
      categoryPart => 'Paper-wise',
      categoryMock => 'Grand Tests',
      categoryPreviousYear => 'Previous Papers',
      _ => '',
    };
  }
}
