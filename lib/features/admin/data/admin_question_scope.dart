/// Locked create/browse context for Admin Question navigation.
///
/// Values come from hierarchical navigation. Wire category values match
/// Phase 3A `testSeriesCategory`: part | mock | previousyear.
class AdminQuestionScope {
  const AdminQuestionScope({
    required this.contentArea,
    this.courseId,
    this.testSeriesCategory,
  });

  /// `chapter` or `testSeries`.
  final String contentArea;
  final String? courseId;

  /// `part` (Paper-wise), `mock` (Grand Tests), `previousyear` (Previous Papers).
  final String? testSeriesCategory;

  static const contentAreaChapter = 'chapter';
  static const contentAreaTestSeries = 'testSeries';

  static const categoryPart = 'part';
  static const categoryMock = 'mock';
  static const categoryPreviousYear = 'previousyear';

  bool get isChapter => contentArea == contentAreaChapter;
  bool get isTestSeries => contentArea == contentAreaTestSeries;

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
