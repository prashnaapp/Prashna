import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../../tests/data/models/test_models.dart';
import '../../admin_routes.dart';
import '../../data/admin_test_hierarchy.dart';
import '../../data/admin_test_scope.dart';
import '../../services/admin_test_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_managed_test_list.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_hierarchy_header.dart';
import '../widgets/admin_ui/admin_loading_surface.dart';
import '../widgets/admin_ui/admin_nav_tile.dart';
import '../widgets/admin_ui/admin_page_header.dart';
import '../widgets/admin_ui/admin_surface.dart';

/// Admin CHAPTERS browser.
///
/// Course → Paper → Part (when the syllabus has Parts) → Chapter/Topic → Test.
class AdminChaptersBrowserScreen extends StatefulWidget {
  const AdminChaptersBrowserScreen({
    super.key,
    this.service,
    this.syllabusService,
    this.courseId,
    this.paperId,
    this.partId,
    this.unitId,
    this.embeddedInShell = false,
  });

  final AdminTestService? service;
  final SyllabusService? syllabusService;
  final String? courseId;
  final String? paperId;
  final String? partId;
  final String? unitId;
  final bool embeddedInShell;

  @override
  State<AdminChaptersBrowserScreen> createState() =>
      _AdminChaptersBrowserScreenState();
}

class _AdminChaptersBrowserScreenState extends State<AdminChaptersBrowserScreen> {
  late final AdminTestService _service;
  SyllabusService get _syllabus =>
      widget.syllabusService ?? SyllabusService.instance;

  List<Course> _courses = const [];
  List<TestModel> _tests = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminTestService.instance;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final courses = await _service.loadCourses();
      var tests = const <TestModel>[];
      final courseId = widget.courseId;
      if (courseId != null) {
        tests = await _service.loadTests(courseId);
      }
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _tests = tests;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load Chapters: $error';
      });
    }
  }

  void _open({
    String? courseId,
    String? paperId,
    String? partId,
    String? unitId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminChaptersBrowserScreen(
          service: _service,
          syllabusService: _syllabus,
          courseId: courseId,
          paperId: paperId,
          partId: partId,
          unitId: unitId,
          embeddedInShell: widget.embeddedInShell,
        ),
      ),
    );
  }

  Future<void> _create() async {
    final courseId = widget.courseId;
    final paperId = widget.paperId;
    final unitId = widget.unitId;
    if (courseId == null || paperId == null || unitId == null) return;
    await Navigator.of(context).pushNamed(
      AdminRoutes.testCreate,
      arguments: AdminTestScope(
        category: TestCategoryType.chapterTests,
        courseId: courseId,
        paperId: paperId,
        partId: widget.partId,
        syllabusUnitId: unitId,
      ),
    );
    if (mounted) await _load();
  }

  String get _title {
    if (widget.unitId != null) return 'Tests';
    if (widget.partId != null) return 'Chapters';
    if (widget.paperId != null) {
      final paper = _syllabus.getPaper(
        courseId: widget.courseId ?? '',
        paperId: widget.paperId!,
      );
      return paper != null && paper.hasCanonicalParts ? 'Parts' : 'Chapters';
    }
    if (widget.courseId != null) return 'Papers';
    return 'Chapters';
  }

  bool _isManagedCourse(Course course) {
    final syllabus = _syllabus.getCourseById(course.courseId);
    return syllabus != null && syllabus.papers.isNotEmpty;
  }

  String? get _contextPath {
    final parts = <String>[];
    final courseId = widget.courseId;
    if (courseId == null) return null;
    final course = _syllabus.getCourseById(courseId);
    parts.add(course?.name ?? courseId);
    final paperId = widget.paperId;
    if (paperId != null) {
      final paper = _syllabus.getPaper(courseId: courseId, paperId: paperId);
      parts.add(paper?.title ?? paperId);
    }
    final partId = widget.partId;
    if (partId != null) {
      final part = _syllabus.getPart(
        courseId: courseId,
        paperId: paperId ?? '',
        partId: partId,
      );
      parts.add(part?.displayName ?? partId);
    }
    final unitId = widget.unitId;
    if (unitId != null) {
      final units = () {
        final paper = paperId == null
            ? null
            : _syllabus.getPaper(courseId: courseId, paperId: paperId);
        if (paper == null) return const <SyllabusUnit>[];
        if (paper.hasCanonicalParts) {
          return _syllabus
                  .getPart(
                    courseId: courseId,
                    paperId: paperId!,
                    partId: partId ?? '',
                  )
                  ?.syllabusUnits ??
              const <SyllabusUnit>[];
        }
        return paper.syllabusUnits;
      }();
      final match = units.where((unit) => unit.id == unitId);
      parts.add(match.isEmpty ? unitId : match.first.displayName);
    }
    return parts.join('  ›  ');
  }

  @override
  Widget build(BuildContext context) {
    final embedded = widget.embeddedInShell;
    final atRoot = widget.courseId == null;
    return Scaffold(
      backgroundColor: AdminColors.backgroundTop,
      // When embedded, shell chrome owns top navigation — avoid nested AppBar.
      appBar: embedded ? null : AppBar(title: Text(_title)),
      body: Center(
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
                  child: AdminPageHeader(
                    title: 'Chapters',
                    subtitle:
                        'Browse syllabus hierarchy and manage chapter tests',
                  ),
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
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AdminLoadingSurface();
    if (_error != null) {
      return AdminEmptyState(
        title: 'Unable to load Chapters',
        message: _error!,
        icon: Icons.error_outline,
        action: FilledButton.tonal(
          onPressed: _load,
          child: const Text('Retry'),
        ),
      );
    }

    final courseId = widget.courseId;
    if (courseId == null) {
      return _tileList(
        items: [
          for (final course in _courses)
            if (_isManagedCourse(course))
              _NavItem(
                title: course.title,
                subtitle: course.courseId,
                icon: Icons.school_outlined,
                onTap: () => _open(courseId: course.courseId),
              ),
        ],
      );
    }

    final course = _syllabus.getCourseById(courseId);
    if (course == null) {
      return const AdminEmptyState(
        title: 'Course unavailable',
        message: 'Course is not in the syllabus catalog.',
        icon: Icons.school_outlined,
      );
    }

    final paperId = widget.paperId;
    if (paperId == null) {
      return _tileList(
        items: [
          for (final paper in course.papers)
            _NavItem(
              title: AdminTestHierarchy.paperLabel(paper),
              subtitle: paper.hasCanonicalParts
                  ? '${paper.parts.length} parts'
                  : '${paper.syllabusUnits.length} chapters',
              icon: Icons.description_outlined,
              onTap: () => _open(courseId: courseId, paperId: paper.id),
            ),
        ],
      );
    }

    final paper = _syllabus.getPaper(courseId: courseId, paperId: paperId);
    if (paper == null) {
      return const AdminEmptyState(
        title: 'Paper not found',
        message: 'Paper was not found.',
        icon: Icons.description_outlined,
      );
    }

    if (paper.hasCanonicalParts && widget.partId == null) {
      return _tileList(
        items: [
          for (final part in paper.parts)
            _NavItem(
              title: part.displayName,
              subtitle: '${part.syllabusUnits.length} chapters',
              icon: Icons.folder_outlined,
              onTap: () => _open(
                courseId: courseId,
                paperId: paperId,
                partId: part.id,
              ),
            ),
        ],
      );
    }

    if (widget.unitId == null) {
      final units = paper.hasCanonicalParts
          ? (_syllabus
                    .getPart(
                      courseId: courseId,
                      paperId: paperId,
                      partId: widget.partId ?? '',
                    )
                    ?.syllabusUnits ??
                const <SyllabusUnit>[])
          : paper.syllabusUnits;
      return _tileList(
        items: [
          for (final unit in units)
            _NavItem(
              title: unit.displayName,
              subtitle: 'Tests',
              icon: Icons.menu_book_outlined,
              onTap: () => _open(
                courseId: courseId,
                paperId: paperId,
                partId: widget.partId,
                unitId: unit.id,
              ),
            ),
        ],
      );
    }

    final tests = AdminTestHierarchy.chapters(
      tests: _tests,
      courseId: courseId,
      paperId: paperId,
      partId: widget.partId,
      syllabusUnitId: widget.unitId!,
    );
    return ListView(
      padding: const EdgeInsets.all(AdminSpacing.pagePadding),
      children: [
        AdminManagedTestList(
          tests: tests,
          service: _service,
          onChanged: _load,
          onCreate: _create,
          scopeLabel: _contextPath,
        ),
      ],
    );
  }

  Widget _tileList({required List<_NavItem> items}) {
    if (items.isEmpty) {
      return const AdminEmptyState(
        title: 'Nothing to show',
        message: 'Nothing to show at this level.',
        icon: Icons.inbox_outlined,
      );
    }
    // Context path is shown in AdminHierarchyHeader when embedded.
    final showCrumb = !widget.embeddedInShell && _contextPath != null;
    final path = _contextPath;
    return ListView.separated(
      padding: const EdgeInsets.all(AdminSpacing.pagePadding),
      itemCount: items.length + (showCrumb ? 1 : 0),
      separatorBuilder: (_, index) => const SizedBox(height: AdminSpacing.md),
      itemBuilder: (context, index) {
        if (showCrumb && index == 0) {
          return AdminSurface(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: Text(
              path!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AdminColors.textSecondary,
              ),
            ),
          );
        }
        final item = items[showCrumb ? index - 1 : index];
        return AdminNavTile(
          title: item.title,
          subtitle: item.subtitle,
          icon: item.icon,
          onTap: item.onTap,
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon = Icons.folder_outlined,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
}
