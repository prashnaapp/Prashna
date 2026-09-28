import 'package:flutter/material.dart';

import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../data/admin_chapter_question_context.dart';
import '../../data/admin_test_hierarchy.dart';
import '../../services/admin_question_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_hierarchy_header.dart';
import '../widgets/admin_ui/admin_nav_tile.dart';
import '../widgets/admin_ui/admin_page_header.dart';
import 'admin_question_import_screen.dart';
import 'admin_question_list_screen.dart';

/// How a terminal Chapter node is opened.
enum AdminChapterBrowserPurpose { bank, import }

/// Chapter Questions browser.
///
/// Course → syllabus branch used by persisted Chapter Questions → Question Bank
/// or a scoped Import workspace.
class AdminChapterQuestionsBrowserScreen extends StatelessWidget {
  const AdminChapterQuestionsBrowserScreen({
    super.key,
    this.syllabusService,
    this.questionService,
    this.location = const AdminChapterQuestionContext(),
    this.purpose = AdminChapterBrowserPurpose.bank,
    this.embeddedInShell = false,
  });

  final SyllabusService? syllabusService;
  final AdminQuestionService? questionService;
  final AdminChapterQuestionContext location;
  final AdminChapterBrowserPurpose purpose;
  final bool embeddedInShell;

  SyllabusService get _syllabus => syllabusService ?? SyllabusService.instance;

  List<SyllabusCourse> get _courses => [
    for (final course in _syllabus.getAvailableCourses())
      if (course.papers.isNotEmpty) course,
  ];

  void _open(BuildContext context, AdminChapterQuestionContext next) {
    if (next.isTerminal(_syllabus)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => purpose == AdminChapterBrowserPurpose.import
              ? AdminQuestionImportScreen(chapterContext: next)
              : AdminQuestionListScreen(
                  service: questionService,
                  syllabusService: _syllabus,
                  chapterContext: next,
                  embeddedInShell: embeddedInShell,
                ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminChapterQuestionsBrowserScreen(
          syllabusService: _syllabus,
          questionService: questionService,
          location: next,
          purpose: purpose,
          embeddedInShell: embeddedInShell,
        ),
      ),
    );
  }

  String get _title {
    final courseId = location.courseId;
    final paperId = location.paperId;
    if (courseId == null) return 'Chapter Questions';
    if (paperId == null) return 'Papers';
    final paper = _syllabus.getPaper(courseId: courseId, paperId: paperId);
    if (paper == null) return 'Chapter Questions';
    if (courseId == 'group-iii') {
      if (paper.hasDirectSyllabusUnits) return 'Syllabus Units';
      if (location.partId == null) return 'Parts';
      return 'Syllabus Units';
    }
    if (paper.hasCanonicalPaperIContent) {
      return location.majorStudyAreaId == null
          ? 'Major Study Areas'
          : 'Content Topics';
    }
    if (location.partId == null) return 'Parts';
    return 'Topics';
  }

  @override
  Widget build(BuildContext context) {
    final atRoot = location.courseId == null;
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          children: [
            if (embeddedInShell && atRoot)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AdminSpacing.pagePadding,
                  AdminSpacing.pagePadding,
                  AdminSpacing.pagePadding,
                  0,
                ),
                child: AdminPageHeader(title: 'Chapter Questions'),
              ),
            if (embeddedInShell && !atRoot)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AdminSpacing.pagePadding,
                  AdminSpacing.pagePadding,
                  AdminSpacing.pagePadding,
                  0,
                ),
                child: AdminHierarchyHeader(
                  title: _title,
                  contextPath: location.pathLabel(_syllabus),
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );

    if (embeddedInShell) return body;
    return Scaffold(
      backgroundColor: AdminColors.backgroundTop,
      appBar: AppBar(title: Text(_title)),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final courseId = location.courseId;
    if (courseId == null) {
      return _tileList([
        for (final course in _courses)
          AdminNavTile(
            key: ValueKey('chapter-questions-course-${course.id}'),
            title: course.name,
            icon: Icons.school_outlined,
            onTap: () => _open(
              context,
              AdminChapterQuestionContext(courseId: course.id),
            ),
          ),
      ]);
    }

    final course = _syllabus.getCourseById(courseId);
    if (course == null) {
      return const AdminEmptyState(
        title: 'Course not found',
        message: 'This course is not in the canonical syllabus.',
        icon: Icons.school_outlined,
      );
    }

    final paperId = location.paperId;
    if (paperId == null) {
      return _tileList([
        for (final paper in course.papers)
          AdminNavTile(
            key: ValueKey('chapter-questions-paper-${paper.id}'),
            title: AdminTestHierarchy.paperLabel(paper),
            icon: Icons.description_outlined,
            onTap: () => _open(context, location.copyWith(paperId: paper.id)),
          ),
      ]);
    }

    final paper = _syllabus.getPaper(courseId: courseId, paperId: paperId);
    if (paper == null) {
      return const AdminEmptyState(
        title: 'Paper not found',
        message: 'This paper is not in the canonical syllabus.',
        icon: Icons.description_outlined,
      );
    }

    if (courseId == 'group-iii') {
      return _groupIiiTiles(context, paper);
    }
    if (paper.hasCanonicalPaperIContent) {
      return _paperITiles(context, paper);
    }
    if (paper.hasCanonicalParts) {
      return _partTiles(context, paper);
    }
    return const AdminEmptyState(
      title: 'No syllabus mapping',
      message: 'This paper has no Chapter Question hierarchy.',
      icon: Icons.folder_off_outlined,
    );
  }

  Widget _paperITiles(BuildContext context, SyllabusPaper paper) {
    final areaId = location.majorStudyAreaId;
    if (areaId == null) {
      return _tileList([
        for (final area in paper.majorStudyAreas)
          AdminNavTile(
            key: ValueKey('chapter-questions-area-${area.id}'),
            title: area.displayName,
            icon: Icons.account_tree_outlined,
            onTap: () {
              final topic = paperISameNameContentTopic(area);
              _open(
                context,
                location.copyWith(
                  majorStudyAreaId: area.id,
                  contentTopicId: topic?.id,
                ),
              );
            },
          ),
      ]);
    }
    final area = paper.majorStudyAreas
        .where((item) => item.id == areaId)
        .firstOrNull;
    if (area == null) {
      return const AdminEmptyState(
        title: 'Major Study Area not found',
        message: 'This area is not in the canonical syllabus.',
        icon: Icons.account_tree_outlined,
      );
    }
    return _tileList([
      for (final topic in area.contentTopics)
        AdminNavTile(
          key: ValueKey('chapter-questions-content-topic-${topic.id}'),
          title: topic.displayName,
          icon: Icons.topic_outlined,
          onTap: () =>
              _open(context, location.copyWith(contentTopicId: topic.id)),
        ),
    ]);
  }

  Widget _partTiles(BuildContext context, SyllabusPaper paper) {
    final partId = location.partId;
    if (partId == null) {
      return _tileList([
        for (final part in paper.parts)
          AdminNavTile(
            key: ValueKey('chapter-questions-part-${part.id}'),
            title: part.displayName,
            icon: Icons.segment_outlined,
            onTap: () => _open(context, location.copyWith(partId: part.id)),
          ),
      ]);
    }
    final part = paper.parts.where((item) => item.id == partId).firstOrNull;
    if (part == null) {
      return const AdminEmptyState(
        title: 'Part not found',
        message: 'This part is not in the canonical syllabus.',
        icon: Icons.segment_outlined,
      );
    }
    return _tileList([
      for (final topic in part.topics)
        AdminNavTile(
          key: ValueKey('chapter-questions-topic-${topic.id}'),
          title: topic.resolvedDisplayName,
          icon: Icons.topic_outlined,
          onTap: () => _open(context, location.copyWith(topicId: topic.id)),
        ),
    ]);
  }

  Widget _groupIiiTiles(BuildContext context, SyllabusPaper paper) {
    if (paper.hasDirectSyllabusUnits) {
      return _unitTiles(context, paper.syllabusUnits);
    }
    final partId = location.partId;
    if (partId == null) {
      return _tileList([
        for (final part in paper.parts)
          AdminNavTile(
            key: ValueKey('chapter-questions-part-${part.id}'),
            title: part.displayName,
            icon: Icons.segment_outlined,
            onTap: () => _open(context, location.copyWith(partId: part.id)),
          ),
      ]);
    }
    final part = paper.parts.where((item) => item.id == partId).firstOrNull;
    if (part == null) {
      return const AdminEmptyState(
        title: 'Part not found',
        message: 'This part is not in the canonical syllabus.',
        icon: Icons.segment_outlined,
      );
    }
    return _unitTiles(context, part.syllabusUnits);
  }

  Widget _unitTiles(BuildContext context, List<SyllabusUnit> units) {
    if (units.isEmpty) {
      return const AdminEmptyState(
        title: 'No syllabus units',
        message: 'This paper has no Group-III syllabus units.',
        icon: Icons.folder_off_outlined,
      );
    }
    return _tileList([
      for (final unit in units)
        AdminNavTile(
          key: ValueKey('chapter-questions-unit-${unit.id}'),
          title: unit.displayName,
          icon: Icons.folder_outlined,
          onTap: () =>
              _open(context, location.copyWith(syllabusUnitId: unit.id)),
        ),
    ]);
  }

  Widget _tileList(List<Widget> tiles) {
    if (tiles.isEmpty) {
      return const AdminEmptyState(
        title: 'Nothing to browse',
        message: 'This syllabus folder has no children.',
        icon: Icons.folder_off_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AdminSpacing.pagePadding),
      itemCount: tiles.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AdminSpacing.md),
      itemBuilder: (context, index) => tiles[index],
    );
  }
}
