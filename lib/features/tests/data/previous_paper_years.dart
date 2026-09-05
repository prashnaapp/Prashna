/// Fixed Previous Papers year selectors by exam.
///
/// These are product year tabs, not derived from catalog [TestModel]s.
/// Child cards are published tests whose [TestModel.year] equals a selected
/// value from [forExam].
abstract final class PreviousPaperYears {
  static const List<int> groupIi = [2016, 2024];
  static const List<int> groupIii = [2018, 2024];

  /// Approved years for [examId]. Empty when the exam has no product years.
  static List<int> forExam(String examId) {
    return switch (examId.trim()) {
      'group-ii' => groupIi,
      'group-iii' => groupIii,
      _ => const [],
    };
  }

  /// First product year for [examId], or null when none are defined.
  static int? initialYear(String examId) {
    final years = forExam(examId);
    return years.isEmpty ? null : years.first;
  }

  static String tabId(int year) => 'year:$year';
}
