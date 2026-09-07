import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../../tests/data/grand_test_series.dart';
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

enum AdminTestSeriesMode { home, categories, paperWise, grandTests, previousPapers }

/// Admin TEST SERIES browser. Completely separate from Chapters.
///
/// Course → Paper-wise Tests | Grand Tests | Previous Papers
class AdminTestSeriesBrowserScreen extends StatefulWidget {
  const AdminTestSeriesBrowserScreen({
    super.key,
    this.service,
    this.syllabusService,
    this.courseId,
    this.mode = AdminTestSeriesMode.home,
    this.paperId,
    this.partId,
    this.seriesId,
    this.year,
    this.embeddedInShell = false,
  });

  final AdminTestService? service;
  final SyllabusService? syllabusService;
  final String? courseId;
  final AdminTestSeriesMode mode;
  final String? paperId;
  final String? partId;
  final String? seriesId;
  final int? year;
  final bool embeddedInShell;

  @override
  State<AdminTestSeriesBrowserScreen> createState() =>
      _AdminTestSeriesBrowserScreenState();
}

class _AdminTestSeriesBrowserScreenState
    extends State<AdminTestSeriesBrowserScreen> {
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
        _error = 'Unable to load Test Series: $error';
      });
    }
  }

  void _open({
    String? courseId,
    required AdminTestSeriesMode mode,
    String? paperId,
    String? partId,
    String? seriesId,
    int? year,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminTestSeriesBrowserScreen(
          service: _service,
          syllabusService: _syllabus,
          courseId: courseId ?? widget.courseId,
          mode: mode,
          paperId: paperId,
          partId: partId,
          seriesId: seriesId,
          year: year,
          embeddedInShell: widget.embeddedInShell,
        ),
      ),
    );
  }

  Future<void> _create(AdminTestScope scope) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AdminRoutes.testCreate, arguments: scope);
    if (mounted && changed == true) await _load();
  }

  Future<void> _addYear() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Examination year'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Year',
            hintText: '2016',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    final year = int.tryParse(value ?? '');
    if (year == null || year < 1900 || year > 2100) return;
    _open(mode: AdminTestSeriesMode.previousPapers, year: year);
  }

  String get _paperWiseTitle {
    if (widget.paperId == null) return 'Paper-wise Tests';
    if (widget.partId != null) return 'Tests';
    final paper = _syllabus.getPaper(
      courseId: widget.courseId ?? '',
      paperId: widget.paperId!,
    );
    if (paper != null && paper.hasCanonicalParts) return 'Parts';
    return 'Tests';
  }

  bool _isManagedCourse(Course course) {
    final syllabus = _syllabus.getCourseById(course.courseId);
    return syllabus != null && syllabus.papers.isNotEmpty;
  }

  String get _title {
    return switch (widget.mode) {
      AdminTestSeriesMode.home => 'Test Series',
      AdminTestSeriesMode.categories => 'Test Series',
      AdminTestSeriesMode.paperWise => _paperWiseTitle,
      AdminTestSeriesMode.grandTests => widget.seriesId == null
          ? 'Grand Tests'
          : (widget.paperId == null ? widget.seriesId! : 'Tests'),
      AdminTestSeriesMode.previousPapers => widget.year == null
          ? 'Previous Papers'
          : (widget.paperId == null ? '${widget.year}' : 'Tests'),
    };
  }

  String? get _contextPath {
    final parts = <String>[];
    final courseId = widget.courseId;
    if (courseId != null) {
      final course = _syllabus.getCourseById(courseId);
      parts.add(course?.name ?? courseId);
    }
    switch (widget.mode) {
      case AdminTestSeriesMode.home:
        break;
      case AdminTestSeriesMode.categories:
        parts.add('Modes');
      case AdminTestSeriesMode.paperWise:
        parts.add('Paper-wise Tests');
        if (widget.paperId != null) {
          final paper = _syllabus.getPaper(
            courseId: courseId ?? '',
            paperId: widget.paperId!,
          );
          parts.add(paper?.title ?? widget.paperId!);
        }
        if (widget.partId != null) {
          final part = _syllabus.getPart(
            courseId: courseId ?? '',
            paperId: widget.paperId ?? '',
            partId: widget.partId!,
          );
          parts.add(part?.displayName ?? widget.partId!);
        }
      case AdminTestSeriesMode.grandTests:
        parts.add('Grand Tests');
        if (widget.seriesId != null) parts.add(widget.seriesId!);
        if (widget.paperId != null) {
          final paper = _syllabus.getPaper(
            courseId: courseId ?? '',
            paperId: widget.paperId!,
          );
          parts.add(paper?.title ?? widget.paperId!);
        }
      case AdminTestSeriesMode.previousPapers:
        parts.add('Previous Papers');
        if (widget.year != null) parts.add('${widget.year}');
        if (widget.paperId != null) {
          final paper = _syllabus.getPaper(
            courseId: courseId ?? '',
            paperId: widget.paperId!,
          );
          parts.add(paper?.title ?? widget.paperId!);
        }
    }
    if (parts.isEmpty) return null;
    return parts.join('  ›  ');
  }

  @override
  Widget build(BuildContext context) {
    final embedded = widget.embeddedInShell;
    final atRoot =
        widget.courseId == null && widget.mode == AdminTestSeriesMode.home;
    final showDepthHeader = embedded && !atRoot;
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
                    title: 'Test Series',
                    subtitle:
                        'Manage paper-wise, grand tests and previous papers',
                  ),
                ),
              if (showDepthHeader)
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
        title: 'Unable to load Test Series',
        message: _error!,
        icon: Icons.error_outline,
        action: FilledButton.tonal(
          onPressed: _load,
          child: const Text('Retry'),
        ),
      );
    }

    if (widget.courseId == null) {
      return _tileList([
        for (final course in _courses)
          if (_isManagedCourse(course))
            _NavItem(
              title: course.title,
              subtitle: course.courseId,
              icon: Icons.school_outlined,
              onTap: () => _open(
                courseId: course.courseId,
                mode: AdminTestSeriesMode.categories,
              ),
            ),
      ]);
    }

    final course = _syllabus.getCourseById(widget.courseId!);
    if (course == null) {
      return const AdminEmptyState(
        title: 'Course unavailable',
        message: 'Course is not in the syllabus catalog.',
        icon: Icons.school_outlined,
      );
    }

    return switch (widget.mode) {
      AdminTestSeriesMode.home || AdminTestSeriesMode.categories => _tileList([
        _NavItem(
          title: 'Paper-wise Tests',
          subtitle: 'Paper → Part → Test',
          icon: Icons.article_outlined,
          onTap: () => _open(mode: AdminTestSeriesMode.paperWise),
        ),
        _NavItem(
          title: 'Grand Tests',
          subtitle: 'Grand Test → Paper → Test',
          icon: Icons.emoji_events_outlined,
          onTap: () => _open(mode: AdminTestSeriesMode.grandTests),
        ),
        _NavItem(
          title: 'Previous Papers',
          subtitle: 'Examination year → Paper → Test',
          icon: Icons.history_edu_outlined,
          onTap: () => _open(mode: AdminTestSeriesMode.previousPapers),
        ),
      ]),
      AdminTestSeriesMode.paperWise => _paperWise(course),
      AdminTestSeriesMode.grandTests => _grandTests(course),
      AdminTestSeriesMode.previousPapers => _previousPapers(course),
    };
  }

  Widget _paperWise(SyllabusCourse course) {
    if (widget.paperId == null) {
      return _tileList([
        for (final paper in course.papers)
          _NavItem(
            title: AdminTestHierarchy.paperLabel(paper),
            subtitle: paper.hasCanonicalParts
                ? '${paper.parts.length} parts'
                : 'Tests',
            icon: Icons.description_outlined,
            onTap: () => _open(
              mode: AdminTestSeriesMode.paperWise,
              paperId: paper.id,
            ),
          ),
      ]);
    }

    final paper = _syllabus.getPaper(
      courseId: course.id,
      paperId: widget.paperId!,
    );
    if (paper == null) {
      return const AdminEmptyState(
        title: 'Paper not found',
        message: 'Paper was not found.',
        icon: Icons.description_outlined,
      );
    }

    if (paper.hasCanonicalParts && widget.partId == null) {
      return _tileList([
        for (final part in paper.parts)
          _NavItem(
            title: part.displayName,
            subtitle: 'Actual test',
            icon: Icons.folder_outlined,
            onTap: () => _open(
              mode: AdminTestSeriesMode.paperWise,
              paperId: paper.id,
              partId: part.id,
            ),
          ),
      ]);
    }

    final tests = AdminTestHierarchy.paperWise(
      tests: _tests,
      courseId: course.id,
      paperId: paper.id,
      partId: widget.partId,
    );
    return _managedList(
      tests: tests,
      onCreate: () => _create(
        AdminTestScope(
          category: TestCategoryType.partTests,
          courseId: course.id,
          paperId: paper.id,
          partId: widget.partId,
        ),
      ),
    );
  }

  Widget _grandTests(SyllabusCourse course) {
    if (widget.seriesId == null) {
      // Fixed approved containers first. Legacy seriesIds from catalog remain
      // visible so existing production values are not hidden or rewritten.
      final catalogIds = AdminTestHierarchy.seriesIds(
        tests: _tests,
        courseId: course.id,
      );
      final legacy = [
        for (final id in catalogIds)
          if (!GrandTestSeries.isApproved(id)) id,
      ];
      final ids = [...GrandTestSeries.ids, ...legacy];
      return _tileList([
        for (final id in ids)
          _NavItem(
            title: id,
            subtitle: 'Paper → Actual test',
            icon: Icons.emoji_events_outlined,
            onTap: () => _open(
              mode: AdminTestSeriesMode.grandTests,
              seriesId: id,
            ),
          ),
      ]);
    }

    if (widget.paperId == null) {
      return _tileList([
        for (final paper in course.papers)
          _NavItem(
            title: AdminTestHierarchy.paperLabel(paper),
            subtitle: 'Actual test',
            icon: Icons.description_outlined,
            onTap: () => _open(
              mode: AdminTestSeriesMode.grandTests,
              seriesId: widget.seriesId,
              paperId: paper.id,
            ),
          ),
      ]);
    }

    final tests = AdminTestHierarchy.grandTests(
      tests: _tests,
      courseId: course.id,
      seriesId: widget.seriesId!,
      paperId: widget.paperId!,
    );
    return _managedList(
      tests: tests,
      onCreate: () => _create(
        AdminTestScope(
          category: TestCategoryType.mockTests,
          courseId: course.id,
          paperId: widget.paperId,
          seriesId: widget.seriesId,
        ),
      ),
    );
  }

  Widget _previousPapers(SyllabusCourse course) {
    if (widget.year == null) {
      final years = AdminTestHierarchy.years(
        tests: _tests,
        courseId: course.id,
      );
      return ListView(
        padding: const EdgeInsets.all(AdminSpacing.pagePadding),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _addYear,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ Examination year'),
            ),
          ),
          const SizedBox(height: AdminSpacing.lg),
          if (years.isEmpty)
            const AdminEmptyState(
              title: 'No examination years yet',
              message:
                  'Add the year the exam was conducted, then add one test '
                  'per paper.',
              icon: Icons.history_edu_outlined,
            )
          else
            for (final year in years) ...[
              AdminNavTile(
                title: '$year',
                subtitle: 'Paper → Actual test',
                icon: Icons.calendar_today_outlined,
                onTap: () => _open(
                  mode: AdminTestSeriesMode.previousPapers,
                  year: year,
                ),
              ),
              const SizedBox(height: AdminSpacing.md),
            ],
        ],
      );
    }

    if (widget.paperId == null) {
      return _tileList([
        for (final paper in course.papers)
          _NavItem(
            title: AdminTestHierarchy.paperLabel(paper),
            subtitle: 'Actual test',
            icon: Icons.description_outlined,
            onTap: () => _open(
              mode: AdminTestSeriesMode.previousPapers,
              year: widget.year,
              paperId: paper.id,
            ),
          ),
      ]);
    }

    final tests = AdminTestHierarchy.previousPapers(
      tests: _tests,
      courseId: course.id,
      year: widget.year!,
      paperId: widget.paperId!,
    );
    return _managedList(
      tests: tests,
      onCreate: () => _create(
        AdminTestScope(
          category: TestCategoryType.previousYear,
          courseId: course.id,
          paperId: widget.paperId,
          year: widget.year,
        ),
      ),
    );
  }

  Widget _managedList({
    required List<TestModel> tests,
    required VoidCallback onCreate,
  }) {
    return ListView(
      padding: const EdgeInsets.all(AdminSpacing.pagePadding),
      children: [
        AdminManagedTestList(
          tests: tests,
          service: _service,
          onChanged: _load,
          onCreate: onCreate,
          scopeLabel: _contextPath,
        ),
      ],
    );
  }

  Widget _tileList(List<_NavItem> items) {
    if (items.isEmpty) {
      return const AdminEmptyState(
        title: 'Nothing to show',
        message: 'Nothing to show at this level.',
        icon: Icons.inbox_outlined,
      );
    }
    // Context path is shown in AdminHierarchyHeader when embedded.
    final showCrumb = !widget.embeddedInShell && _contextPath != null;
    return ListView.separated(
      padding: const EdgeInsets.all(AdminSpacing.pagePadding),
      itemCount: items.length + (showCrumb ? 1 : 0),
      separatorBuilder: (_, index) => const SizedBox(height: AdminSpacing.md),
      itemBuilder: (context, index) {
        if (showCrumb && index == 0) {
          return AdminSurface(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: Text(
              _contextPath!,
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
