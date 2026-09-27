import 'package:flutter/material.dart';

import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../data/admin_question_scope.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_hierarchy_header.dart';
import '../widgets/admin_ui/admin_nav_tile.dart';
import '../widgets/admin_ui/admin_page_header.dart';
import '../widgets/admin_ui/admin_surface.dart';

/// Test Series Questions navigation foundation.
///
/// Course → Paper-wise | Grand Tests | Previous Papers.
/// Does not load Questions.
class AdminTestSeriesQuestionsBrowserScreen extends StatelessWidget {
  const AdminTestSeriesQuestionsBrowserScreen({
    super.key,
    this.syllabusService,
    this.courseId,
    this.testSeriesCategory,
    this.embeddedInShell = false,
  });

  final SyllabusService? syllabusService;
  final String? courseId;
  final String? testSeriesCategory;
  final bool embeddedInShell;

  SyllabusService get _syllabus => syllabusService ?? SyllabusService.instance;

  AdminQuestionScope get scope => AdminQuestionScope(
    contentArea: AdminQuestionScope.contentAreaTestSeries,
    courseId: courseId,
    testSeriesCategory: testSeriesCategory,
  );

  List<SyllabusCourse> get _courses => [
    for (final course in _syllabus.getAvailableCourses())
      if (course.papers.isNotEmpty) course,
  ];

  void _open(
    BuildContext context, {
    String? courseId,
    String? testSeriesCategory,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminTestSeriesQuestionsBrowserScreen(
          syllabusService: _syllabus,
          courseId: courseId ?? this.courseId,
          testSeriesCategory: testSeriesCategory,
          embeddedInShell: embeddedInShell,
        ),
      ),
    );
  }

  String get _title {
    if (testSeriesCategory != null) {
      return AdminQuestionScope.labelForCategory(testSeriesCategory);
    }
    if (courseId != null) return 'Test Series Questions';
    return 'Test Series Questions';
  }

  String? get _contextPath {
    final id = courseId;
    if (id == null) return null;
    final course = _syllabus.getCourseById(id);
    final name = course?.name ?? id;
    final category = AdminQuestionScope.labelForCategory(testSeriesCategory);
    if (category.isEmpty) return name;
    return '$name  ›  $category';
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

    return ListView(
      padding: const EdgeInsets.all(AdminSpacing.pagePadding),
      children: [
        AdminSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.name,
                key: const ValueKey('test-series-questions-course-name'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: AdminSpacing.xs),
              Text(
                AdminQuestionScope.labelForCategory(testSeriesCategory),
                key: const ValueKey('test-series-questions-category-label'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
