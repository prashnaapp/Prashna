import 'package:flutter/material.dart';

import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../../tests/data/grand_test_series.dart';
import '../../../tests/data/previous_paper_years.dart';
import '../../data/admin_question_scope.dart';
import '../../data/admin_test_hierarchy.dart';
import '../../services/admin_question_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_hierarchy_header.dart';
import '../widgets/admin_ui/admin_nav_tile.dart';
import '../widgets/admin_ui/admin_page_header.dart';
import 'admin_test_series_question_bank_screen.dart';

/// Test Series Questions browser.
///
/// Course → Paper-wise | Grand Tests | Previous Papers
/// → Paper | Grand container | Year → Question Bank.
class AdminTestSeriesQuestionsBrowserScreen extends StatelessWidget {
  const AdminTestSeriesQuestionsBrowserScreen({
    super.key,
    this.syllabusService,
    this.questionService,
    this.courseId,
    this.testSeriesCategory,
    this.paperId,
    this.seriesId,
    this.year,
    this.embeddedInShell = false,
  });

  final SyllabusService? syllabusService;
  final AdminQuestionService? questionService;
  final String? courseId;
  final String? testSeriesCategory;
  final String? paperId;
  final String? seriesId;
  final int? year;
  final bool embeddedInShell;

  SyllabusService get _syllabus => syllabusService ?? SyllabusService.instance;

  AdminQuestionScope get scope => AdminQuestionScope(
    contentArea: AdminQuestionScope.contentAreaTestSeries,
    courseId: courseId,
    testSeriesCategory: testSeriesCategory,
    paperId: paperId,
    seriesId: seriesId,
    year: year,
  );

  List<SyllabusCourse> get _courses => [
    for (final course in _syllabus.getAvailableCourses())
      if (course.papers.isNotEmpty) course,
  ];

  void _open(
    BuildContext context, {
    String? courseId,
    String? testSeriesCategory,
    String? paperId,
    String? seriesId,
    int? year,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminTestSeriesQuestionsBrowserScreen(
          syllabusService: _syllabus,
          questionService: questionService,
          courseId: courseId ?? this.courseId,
          testSeriesCategory: testSeriesCategory ?? this.testSeriesCategory,
          paperId: paperId,
          seriesId: seriesId,
          year: year,
          embeddedInShell: embeddedInShell,
        ),
      ),
    );
  }

  String get _title {
    if (scope.isQuestionBank) return 'Question Bank';
    if (testSeriesCategory != null) {
      return AdminQuestionScope.labelForCategory(testSeriesCategory);
    }
    return 'Test Series Questions';
  }

  String? get _contextPath {
    final id = courseId;
    if (id == null) return null;
    final course = _syllabus.getCourseById(id);
    final parts = <String>[course?.name ?? id];
    final category = AdminQuestionScope.labelForCategory(testSeriesCategory);
    final selectedPaper = paperId;
    final selectedSeries = seriesId?.trim();
    final hasDiscriminator =
        (selectedPaper != null && selectedPaper.isNotEmpty) ||
        (selectedSeries != null && selectedSeries.isNotEmpty) ||
        year != null;
    if (!hasDiscriminator) return course?.name ?? id;
    if (category.isNotEmpty) parts.add(category);
    if (selectedPaper != null && selectedPaper.isNotEmpty) {
      final paper = _syllabus.getPaper(courseId: id, paperId: selectedPaper);
      parts.add(
        paper == null ? selectedPaper : AdminTestHierarchy.paperLabel(paper),
      );
    }
    if (selectedSeries != null && selectedSeries.isNotEmpty) {
      parts.add(selectedSeries);
    }
    if (year != null) parts.add('$year');
    return parts.join('  ›  ');
  }

  @override
  Widget build(BuildContext context) {
    final embedded = embeddedInShell;
    final atRoot = courseId == null;
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          children: [
            if (embedded && atRoot)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AdminSpacing.pagePadding,
                  AdminSpacing.pagePadding,
                  AdminSpacing.pagePadding,
                  0,
                ),
                child: AdminPageHeader(title: 'Test Series Questions'),
              ),
            if (embedded && !atRoot)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AdminSpacing.pagePadding,
                  AdminSpacing.pagePadding,
                  AdminSpacing.pagePadding,
                  0,
                ),
                child: AdminHierarchyHeader(
                  title: _title,
                  contextPath: _contextPath,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: AdminColors.backgroundTop,
      appBar: AppBar(title: Text(_title)),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (courseId == null) {
      return _tileList([
        for (final course in _courses)
          AdminNavTile(
            key: ValueKey('test-series-questions-course-${course.id}'),
            title: course.name,
            icon: Icons.school_outlined,
            onTap: () => _open(context, courseId: course.id),
          ),
      ]);
    }

    final course = _syllabus.getCourseById(courseId!);
    if (course == null) {
      return const AdminEmptyState(
        title: 'Course not found',
        message: 'This course is not in the canonical syllabus.',
        icon: Icons.school_outlined,
      );
    }

    if (testSeriesCategory == null) {
      return _tileList([
        AdminNavTile(
          key: const ValueKey('test-series-questions-category-part'),
          title: 'Paper-wise',
          icon: Icons.article_outlined,
          onTap: () => _open(
            context,
            testSeriesCategory: AdminQuestionScope.categoryPart,
          ),
        ),
        AdminNavTile(
          key: const ValueKey('test-series-questions-category-mock'),
          title: 'Grand Tests',
          icon: Icons.emoji_events_outlined,
          onTap: () => _open(
            context,
            testSeriesCategory: AdminQuestionScope.categoryMock,
          ),
        ),
        AdminNavTile(
          key: const ValueKey('test-series-questions-category-previousyear'),
          title: 'Previous Papers',
          icon: Icons.history_edu_outlined,
          onTap: () => _open(
            context,
            testSeriesCategory: AdminQuestionScope.categoryPreviousYear,
          ),
        ),
      ]);
    }

    if (scope.isQuestionBank) {
      return AdminTestSeriesQuestionBankScreen(
        scope: scope,
        service: questionService,
      );
    }

    return switch (testSeriesCategory) {
      AdminQuestionScope.categoryPart => _tileList([
        for (final paper in course.papers)
          AdminNavTile(
            key: ValueKey('test-series-questions-paper-${paper.id}'),
            title: AdminTestHierarchy.paperLabel(paper),
            icon: Icons.description_outlined,
            onTap: () => _open(context, paperId: paper.id),
          ),
      ]),
      AdminQuestionScope.categoryMock => _tileList([
        for (final seriesId in GrandTestSeries.ids)
          AdminNavTile(
            key: ValueKey('test-series-questions-series-$seriesId'),
            title: seriesId,
            icon: Icons.emoji_events_outlined,
            onTap: () => _open(context, seriesId: seriesId),
          ),
      ]),
      AdminQuestionScope.categoryPreviousYear => _yearTiles(context, course),
      _ => const AdminEmptyState(
        title: 'Unknown category',
        message: 'This Test Series category is not supported.',
        icon: Icons.folder_off_outlined,
      ),
    };
  }

  Widget _yearTiles(BuildContext context, SyllabusCourse course) {
    final years = PreviousPaperYears.forExam(course.id);
    if (years.isEmpty) {
      return const AdminEmptyState(
        title: 'No examination years',
        message: 'No Previous Paper years are defined for this course.',
        icon: Icons.history_edu_outlined,
      );
    }
    return _tileList([
      for (final year in years)
        AdminNavTile(
          key: ValueKey('test-series-questions-year-$year'),
          title: '$year',
          icon: Icons.history_edu_outlined,
          onTap: () => _open(context, year: year),
        ),
    ]);
  }

  Widget _tileList(List<Widget> tiles) {
    return ListView.separated(
      padding: const EdgeInsets.all(AdminSpacing.pagePadding),
      itemCount: tiles.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AdminSpacing.md),
      itemBuilder: (context, index) => tiles[index],
    );
  }
}
