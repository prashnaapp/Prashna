import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../../tests/data/models/test_models.dart';
import '../../admin_routes.dart';
import '../../data/admin_test_hierarchy.dart';
import '../../data/admin_test_scope.dart';
import '../../services/admin_test_service.dart';
import '../widgets/admin_managed_test_list.dart';

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
  });

  final AdminTestService? service;
  final SyllabusService? syllabusService;
  final String? courseId;
  final String? paperId;
  final String? partId;
  final String? unitId;

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

    final courseId = widget.courseId;
    if (courseId == null) {
      return _tileList(
        items: [
          for (final course in _courses)
            if (_isManagedCourse(course))
              _NavItem(
                title: course.title,
                subtitle: course.courseId,
                onTap: () => _open(courseId: course.courseId),
              ),
        ],
      );
    }

    final course = _syllabus.getCourseById(courseId);
    if (course == null) {
      return const Center(child: Text('Course is not in the syllabus catalog.'));
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
              onTap: () => _open(courseId: courseId, paperId: paper.id),
            ),
        ],
      );
    }

    final paper = _syllabus.getPaper(courseId: courseId, paperId: paperId);
    if (paper == null) {
      return const Center(child: Text('Paper was not found.'));
    }

    if (paper.hasCanonicalParts && widget.partId == null) {
      return _tileList(
        items: [
          for (final part in paper.parts)
            _NavItem(
              title: part.displayName,
              subtitle: '${part.syllabusUnits.length} chapters',
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
      padding: const EdgeInsets.all(24),
      children: [
        AdminManagedTestList(
          tests: tests,
          service: _service,
          onChanged: _load,
          onCreate: _create,
        ),
      ],
    );
  }

  Widget _tileList({required List<_NavItem> items}) {
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
