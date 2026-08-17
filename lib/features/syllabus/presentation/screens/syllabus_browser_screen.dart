import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../progress/data/models/syllabus_completion.dart';
import '../../../progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import '../../../progress_cloud/repository/unit_performance_cloud_repository.dart';
import '../../../subscription/service/course_open_guard.dart';
import '../../data/models/canonical_scope.dart';
import '../../data/models/syllabus_models.dart';
import '../../services/syllabus_service.dart';
import '../syllabus_visual.dart';
import '../widgets/syllabus_header_band.dart';
import '../widgets/syllabus_paper_progress_banner.dart';
import '../widgets/syllabus_selector_pill.dart';
import '../widgets/syllabus_unit_row_card.dart';
import '../widgets/syllabus_wave_footer.dart';
import 'syllabus_unit_tests_screen.dart';

/// Single-screen course → paper → part → unit browser.
class SyllabusBrowserScreen extends StatefulWidget {
  const SyllabusBrowserScreen({
    super.key,
    required this.courseId,
    this.initialPaperId,
    this.initialPartId,
    this.completionRepository,
    this.performanceRepository,
  });

  final String courseId;
  final String? initialPaperId;
  final String? initialPartId;
  final SyllabusCompletionCloudRepository? completionRepository;
  final UnitPerformanceCloudRepository? performanceRepository;

  @override
  State<SyllabusBrowserScreen> createState() => _SyllabusBrowserScreenState();
}

class _SyllabusBrowserScreenState extends State<SyllabusBrowserScreen> {
  late String _courseId;
  String? _paperId;
  String? _partId;
  Future<Map<String, _UnitMetrics>> _metrics = Future.value(const {});

  @override
  void initState() {
    super.initState();
    _courseId = widget.courseId;
    _applySelection(
      paperId: widget.initialPaperId,
      partId: widget.initialPartId,
    );
  }

  SyllabusCourse? get _course =>
      SyllabusService.instance.getCourseById(_courseId);

  List<SyllabusCourse> get _availableCourses =>
      SyllabusService.instance.getAvailableCourses();

  List<SyllabusPaper> get _papers => _course?.papers ?? const [];

  SyllabusPaper? get _paper {
    final papers = _papers;
    if (papers.isEmpty) return null;
    for (final paper in papers) {
      if (paper.id == _paperId) return paper;
    }
    return papers.first;
  }

  List<SyllabusPart> get _parts => _paper?.parts ?? const [];

  bool get _showParts => _paper?.hasPartSyllabusUnits ?? false;

  List<SyllabusUnit> get _units {
    final paper = _paper;
    if (paper == null) return const [];
    if (!paper.hasPartSyllabusUnits) return paper.syllabusUnits;
    final partId = _partId;
    if (partId == null) return const [];
    final part = SyllabusService.instance.getPart(
      courseId: _courseId,
      paperId: paper.id,
      partId: partId,
    );
    return part?.syllabusUnits ?? const [];
  }

  void _applySelection({String? paperId, String? partId}) {
    final papers =
        SyllabusService.instance.getCourseById(_courseId)?.papers ??
        const <SyllabusPaper>[];
    final paper = _resolvePaper(papers, paperId);
    final nextPartId = _resolvePartId(paper, partId);
    _paperId = paper?.id;
    _partId = nextPartId;
    _metrics = _loadMetrics(paper: paper, partId: nextPartId);
  }

  SyllabusPaper? _resolvePaper(List<SyllabusPaper> papers, String? paperId) {
    if (papers.isEmpty) return null;
    if (paperId != null) {
      for (final paper in papers) {
        if (paper.id == paperId) return paper;
      }
    }
    return papers.first;
  }

  String? _resolvePartId(SyllabusPaper? paper, String? requested) {
    if (paper == null || !paper.hasPartSyllabusUnits) return null;
    final parts = paper.parts;
    if (parts.isEmpty) return null;
    if (requested != null) {
      for (final part in parts) {
        if (part.id == requested) return part.id;
      }
    }
    return parts.first.id;
  }

  Future<Map<String, _UnitMetrics>> _loadMetrics({
    required SyllabusPaper? paper,
    required String? partId,
  }) async {
    if (paper == null) return const {};

    final units = paper.hasPartSyllabusUnits
        ? (SyllabusService.instance
                  .getPart(
                    courseId: _courseId,
                    paperId: paper.id,
                    partId: partId ?? '',
                  )
                  ?.syllabusUnits ??
              const <SyllabusUnit>[])
        : paper.syllabusUnits;

    late final SyllabusCompletionCloudRepository completionRepo;
    late final UnitPerformanceCloudRepository performanceRepo;
    try {
      completionRepo =
          widget.completionRepository ?? SyllabusCompletionCloudRepository();
      performanceRepo =
          widget.performanceRepository ?? UnitPerformanceCloudRepository();
    } catch (_) {
      return {
        for (final unit in units)
          unit.id: const _UnitMetrics(progress: 0, completed: false),
      };
    }

    final paperId = paper.id;
    final entries = await Future.wait(
      units.map((unit) async {
        var progress = 0.0;
        var completed = false;
        final scope = CanonicalScope.tryFromSyllabusUnit(
          courseId: _courseId,
          paperId: paperId,
          partId: partId,
          syllabusUnitId: unit.id,
        );
        if (scope != null) {
          try {
            final completion = await completionRepo.getCompletion(scope: scope);
            completed = completion.status == SyllabusCompletionStatus.completed;
          } catch (_) {}
          try {
            final performance = await performanceRepo.getUnitPerformance(
              scope.scopeKey,
            );
            if (performance != null) {
              progress = (performance.percentage / 100).clamp(0.0, 1.0);
            }
          } catch (_) {}
        }
        return MapEntry(
          unit.id,
          _UnitMetrics(progress: progress, completed: completed),
        );
      }),
    );
    return Map<String, _UnitMetrics>.fromEntries(entries);
  }

  void _selectPaper(SyllabusPaper paper) {
    if (_paperId == paper.id) return;
    setState(() => _applySelection(paperId: paper.id));
  }

  void _selectPart(SyllabusPart part) {
    if (_partId == part.id) return;
    setState(() => _applySelection(paperId: _paperId, partId: part.id));
  }

  Future<void> _selectCourse(SyllabusCourse course) async {
    if (course.id == _courseId) return;
    await CourseOpenGuard.attemptOpen(
      context: context,
      courseId: course.id,
      onAllowed: () {
        setState(() {
          _courseId = course.id;
          _applySelection();
        });
      },
    );
  }

  void _openUnit(SyllabusUnit unit) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SyllabusUnitTestsScreen(
          courseId: _courseId,
          paperId: _paper!.id,
          partId: _showParts ? _partId : null,
          unitId: unit.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    final papers = _papers;
    final paper = _paper;
    final parts = _parts;
    final units = _units;

    return Scaffold(
      backgroundColor: SyllabusVisual.page,
      body: Column(
        children: [
          SyllabusHeaderBand(
            child: _BrowserHeader(
              courseName: course?.name ?? 'Syllabus',
              courses: _availableCourses,
              selectedCourseId: _courseId,
              onBack: () => Navigator.maybePop(context),
              onCourseSelected: _selectCourse,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                SyllabusVisual.pagePadding,
                8,
                SyllabusVisual.pagePadding,
                24,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                if (papers.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < papers.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          SyllabusSelectorPill(
                            label: papers[i].title,
                            selected: papers[i].id == paper?.id,
                            onTap: () => _selectPaper(papers[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (_showParts) ...[
                  Text(
                    'Select Part',
                    style: AppTextStyles.titleMedium(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: SyllabusVisual.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < parts.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          SyllabusSelectorPill(
                            label: _partPillLabel(i, parts[i].displayName),
                            selected: parts[i].id == _partId,
                            onTap: () => _selectPart(parts[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                FutureBuilder<Map<String, _UnitMetrics>>(
                  future: _metrics,
                  builder: (context, snapshot) {
                    final metrics = snapshot.data ?? const {};
                    return Column(
                      children: [
                        for (var i = 0; i < units.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          SyllabusUnitRowCard(
                            unitId: units[i].id,
                            title: units[i].displayName,
                            index: i,
                            questionCount: null,
                            progress: metrics[units[i].id]?.progress ?? 0,
                            completed: metrics[units[i].id]?.completed ?? false,
                            onTap: () => _openUnit(units[i]),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                if (paper != null) ...[
                  const SizedBox(height: 18),
                  FutureBuilder<Map<String, _UnitMetrics>>(
                    future: _metrics,
                    builder: (context, snapshot) {
                      final metrics = snapshot.data ?? const {};
                      return SyllabusPaperProgressBanner(
                        paperTitle: paper.title,
                        progress: _paperProgress(units, metrics),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 8),
                const SyllabusWaveFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _paperProgress(
    List<SyllabusUnit> units,
    Map<String, _UnitMetrics> metrics,
  ) {
    if (units.isEmpty) return 0;
    var total = 0.0;
    for (final unit in units) {
      total += metrics[unit.id]?.progress ?? 0;
    }
    return (total / units.length).clamp(0.0, 1.0);
  }

  String _partPillLabel(int index, String displayName) {
    final compact = displayName.trim();
    if (RegExp(r'^part[\s-]*[ivx]+$', caseSensitive: false).hasMatch(compact)) {
      return compact
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll('Part-', 'Part - ');
    }
    const roman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];
    final label = index < roman.length ? roman[index] : '${index + 1}';
    return 'Part - $label';
  }
}

class _UnitMetrics {
  const _UnitMetrics({required this.progress, required this.completed});

  final double progress;
  final bool completed;
}

class _BrowserHeader extends StatelessWidget {
  const _BrowserHeader({
    required this.courseName,
    required this.courses,
    required this.selectedCourseId,
    required this.onBack,
    required this.onCourseSelected,
  });

  final String courseName;
  final List<SyllabusCourse> courses;
  final String selectedCourseId;
  final VoidCallback onBack;
  final ValueChanged<SyllabusCourse> onCourseSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: SyllabusVisual.headerOn,
            ),
          ),
          Expanded(
            child: PopupMenuButton<String>(
              tooltip: 'Select course',
              onSelected: (id) {
                for (final course in courses) {
                  if (course.id == id) {
                    onCourseSelected(course);
                    return;
                  }
                }
              },
              itemBuilder: (context) => [
                for (final course in courses)
                  PopupMenuItem<String>(
                    value: course.id,
                    child: Row(
                      children: [
                        Expanded(child: Text(course.name)),
                        if (course.id == selectedCourseId)
                          const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: SyllabusVisual.accent,
                          ),
                      ],
                    ),
                  ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      courseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLarge(context).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: SyllabusVisual.headerOn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: SyllabusVisual.headerOn,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
