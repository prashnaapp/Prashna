import '../../syllabus/data/models/syllabus_models.dart';
import 'models/test_models.dart';

enum TestSeriesBrowserMode { paperWise, grandTests, previousPapers }

class TestSeriesTab {
  const TestSeriesTab({
    required this.id,
    required this.label,
    required this.tests,
  });

  final String id;
  final String label;
  final List<TestModel> tests;
}

/// Builds data-driven tabs for the student Test Series browser.
///
/// Grouping uses explicit metadata only:
/// - Paper-wise: syllabus [paperId] + [TestModel.paperId] / [TestModel.partId]
/// - Grand Tests: [TestModel.seriesId] then [TestModel.paperId]
/// - Previous Papers: [TestModel.year] then [TestModel.paperId]
abstract final class TestSeriesBrowserGroups {
  static List<TestSeriesTab> paperWise({
    required List<SyllabusPaper> papers,
    required List<TestModel> tests,
  }) {
    return [
      for (final paper in papers)
        TestSeriesTab(
          id: paper.id,
          label: _paperLabel(paper.title),
          tests: _sorted([
            for (final test in tests)
              if (test.paperId == paper.id) test,
          ]),
        ),
    ];
  }

  static List<TestSeriesTab> grandTests(List<TestModel> tests) {
    final bySeries = <String, List<TestModel>>{};
    for (final test in tests) {
      final seriesId = test.seriesId?.trim();
      if (seriesId == null || seriesId.isEmpty) continue;
      bySeries.putIfAbsent(seriesId, () => []).add(test);
    }
    final seriesIds = bySeries.keys.toList()..sort();
    return [
      for (final seriesId in seriesIds)
        TestSeriesTab(
          id: 'series:$seriesId',
          label: seriesId,
          tests: _sorted(bySeries[seriesId]!),
        ),
    ];
  }

  static List<TestSeriesTab> previousPapers(List<TestModel> tests) {
    final byYear = <int, List<TestModel>>{};
    for (final test in tests) {
      final year = test.year;
      if (year == null) continue;
      byYear.putIfAbsent(year, () => []).add(test);
    }
    final years = byYear.keys.toList()..sort();
    return [
      for (final year in years)
        TestSeriesTab(
          id: 'year:$year',
          label: '$year',
          tests: _sorted(byYear[year]!),
        ),
    ];
  }

  /// Some canonical courses spell paper titles as "Paper-I". Pills read as
  /// "Paper I" across every course.
  static String _paperLabel(String title) =>
      title.replaceFirst(RegExp(r'^Paper-'), 'Paper ');

  static List<TestModel> _sorted(List<TestModel> tests) {
    final copy = [...tests];
    copy.sort(_compareTests);
    return copy;
  }

  static int _compareTests(TestModel a, TestModel b) {
    final part = (a.partId ?? '').compareTo(b.partId ?? '');
    if (part != 0) return part;
    final paper = (a.paperId ?? '').compareTo(b.paperId ?? '');
    if (paper != 0) return paper;
    return a.id.compareTo(b.id);
  }
}
