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
import '../widgets/admin_managed_test_list.dart';

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
  });

  final AdminTestService? service;
  final SyllabusService? syllabusService;
  final String? courseId;
  final AdminTestSeriesMode mode;
  final String? paperId;
  final String? partId;
  final String? seriesId;
  final int? year;

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
        ),
      ),
    );
  }

  Future<void> _create(AdminTestScope scope) async {
    await Navigator.of(
      context,
    ).pushNamed(AdminRoutes.testCreate, arguments: scope);
    if (mounted) await _load();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    if (widget.courseId == null) {
      return _tileList([
        for (final course in _courses)
          if (_isManagedCourse(course))
            _NavItem(
              title: course.title,
              subtitle: course.courseId,
              onTap: () => _open(
                courseId: course.courseId,
                mode: AdminTestSeriesMode.categories,
              ),
            ),
      ]);
    }

    final course = _syllabus.getCourseById(widget.courseId!);
    if (course == null) {
      return const Center(child: Text('Course is not in the syllabus catalog.'));
    }

    return switch (widget.mode) {
      AdminTestSeriesMode.home || AdminTestSeriesMode.categories => _tileList([
        _NavItem(
          title: 'Paper-wise Tests',
          subtitle: 'Paper → Part → Test',
          onTap: () => _open(mode: AdminTestSeriesMode.paperWise),
        ),
        _NavItem(
          title: 'Grand Tests',
          subtitle: 'Grand Test → Paper → Test',
          onTap: () => _open(mode: AdminTestSeriesMode.grandTests),
        ),
        _NavItem(
          title: 'Previous Papers',
          subtitle: 'Examination year → Paper → Test',
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
      return const Center(child: Text('Paper was not found.'));
    }

    if (paper.hasCanonicalParts && widget.partId == null) {
      return _tileList([
        for (final part in paper.parts)
          _NavItem(
            title: part.displayName,
            subtitle: 'Actual test',
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminManagedTestList(
          tests: tests,
          service: _service,
          onChanged: _load,
          onCreate: () => _create(
            AdminTestScope(
              category: TestCategoryType.partTests,
              courseId: course.id,
              paperId: paper.id,
              partId: widget.partId,
            ),
          ),
        ),
      ],
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
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final id in ids) ...[
            Card(
              child: ListTile(
                title: Text(id),
                subtitle: const Text('Paper → Actual test'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(
                  mode: AdminTestSeriesMode.grandTests,
                  seriesId: id,
                ),
              ),
            ),
            const SizedBox(height: 8),
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminManagedTestList(
          tests: tests,
          service: _service,
          onChanged: _load,
          onCreate: () => _create(
            AdminTestScope(
              category: TestCategoryType.mockTests,
              courseId: course.id,
              paperId: widget.paperId,
              seriesId: widget.seriesId,
            ),
          ),
        ),
      ],
    );
  }

  Widget _previousPapers(SyllabusCourse course) {
    if (widget.year == null) {
      final years = AdminTestHierarchy.years(
        tests: _tests,
        courseId: course.id,
      );
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _addYear,
              icon: const Icon(Icons.add),
              label: const Text('+ Examination year'),
            ),
          ),
          const SizedBox(height: 16),
          if (years.isEmpty)
            const Text(
              'No examination years yet. Add the year the exam was conducted, '
              'then add one test per paper.',
            )
          else
            for (final year in years) ...[
              Card(
                child: ListTile(
                  title: Text('$year'),
                  subtitle: const Text('Paper → Actual test'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(
                    mode: AdminTestSeriesMode.previousPapers,
                    year: year,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminManagedTestList(
          tests: tests,
          service: _service,
          onChanged: _load,
          onCreate: () => _create(
            AdminTestScope(
              category: TestCategoryType.previousYear,
              courseId: course.id,
              paperId: widget.paperId,
              year: widget.year,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tileList(List<_NavItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Nothing to show at this level.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            title: Text(item.title),
            subtitle: item.subtitle == null ? null : Text(item.subtitle!),
            trailing: const Icon(Icons.chevron_right),
            onTap: item.onTap,
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({required this.title, required this.onTap, this.subtitle});

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}
