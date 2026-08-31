import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/app_nav_metrics.dart';
import '../../../progress/data/models/syllabus_completion.dart';
import '../../../progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import '../../../progress_cloud/repository/unit_performance_cloud_repository.dart';
import '../../../subscription/service/course_open_guard.dart';
import '../../data/models/canonical_scope.dart';
import '../../data/models/syllabus_models.dart';
import '../../services/syllabus_service.dart';
import '../syllabus_visual.dart';
import '../syllabus_browser_sequence.dart';
import '../widgets/syllabus_browser_header.dart';
import '../widgets/syllabus_browser_pill.dart';
import '../widgets/syllabus_swipe_surface.dart';
import '../widgets/syllabus_unit_row_card.dart';
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
  final ScrollController _scrollController = ScrollController();
  int _slideDirection = 0;

  @override
  void initState() {
    super.initState();
    _courseId = widget.courseId;
    _applySelection(
      paperId: widget.initialPaperId,
      partId: widget.initialPartId,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    setState(() {
      _slideDirection = 0;
      _applySelection(paperId: paper.id);
    });
    _scrollToTop();
  }

  void _selectPart(SyllabusPart part) {
    if (_partId == part.id) return;
    setState(() {
      _slideDirection = 0;
      _applySelection(paperId: _paperId, partId: part.id);
    });
    _scrollToTop();
  }

  Future<void> _selectCourse(SyllabusCourse course) async {
    if (course.id == _courseId) return;
    await CourseOpenGuard.attemptOpen(
      context: context,
      courseId: course.id,
      onAllowed: () {
        setState(() {
          _courseId = course.id;
          _slideDirection = 0;
          _applySelection();
        });
        _scrollToTop();
      },
    );
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  void _moveBy(int delta) {
    final stops = SyllabusBrowserSequence.fromPapers(_papers);
    if (stops.isEmpty) return;
    final index = SyllabusBrowserSequence.indexOf(
      stops,
      paperId: _paperId,
      partId: _partId,
    );
    final next = index + delta;
    if (next < 0 || next >= stops.length) return;
    final stop = stops[next];
    setState(() {
      _slideDirection = delta;
      _applySelection(paperId: stop.paperId, partId: stop.partId);
    });
    _scrollToTop();
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

    final bottomInset = AppNavMetrics.contentBottomInset(context);

    return Scaffold(
      backgroundColor: SyllabusVisual.page,
      body: ColoredBox(
        color: SyllabusVisual.page,
        child: Column(
          children: [
            SyllabusBrowserHeader(
              courseName: course?.name ?? 'Syllabus',
              courses: _availableCourses,
              selectedCourseId: _courseId,
              onBack: () => Navigator.maybePop(context),
              onCourseSelected: _selectCourse,
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  SyllabusVisual.pagePadding,
                  AppSpacing.sm,
                  SyllabusVisual.pagePadding,
                  bottomInset,
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (papers.isNotEmpty) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < papers.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.sm),
                            SyllabusBrowserPill(
                              key: ValueKey('syllabus-paper-${papers[i].id}'),
                              label: papers[i].title,
                              selected: papers[i].id == paper?.id,
                              onTap: () => _selectPaper(papers[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (_showParts) ...[
                    Text(
                      'Select Part',
                      style: AppTextStyles.titleMedium(context).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: SyllabusVisual.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < parts.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.sm),
                            SyllabusBrowserPill(
                              key: ValueKey('syllabus-part-${parts[i].id}'),
                              label: _partPillLabel(i, parts[i].displayName),
                              selected: parts[i].id == _partId,
                              onTap: () => _selectPart(parts[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  SyllabusSwipeSurface(
                    key: const ValueKey('syllabus-swipe-surface'),
                    onSwipeForward: () => _moveBy(1),
                    onSwipeBack: () => _moveBy(-1),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            ...previousChildren,
                            ?currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        final dir = _slideDirection.toDouble();
                        final begin =
                            animation.status == AnimationStatus.reverse
                            ? Offset(-dir, 0)
                            : Offset(dir, 0);
                        return ClipRect(
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: begin,
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey('${_paperId ?? ''}|${_partId ?? ''}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (paper != null) ...[
                              Text(
                                paper.title,
                                style: AppTextStyles.titleMedium(context)
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: SyllabusVisual.accent,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            FutureBuilder<Map<String, _UnitMetrics>>(
                              future: _metrics,
                              builder: (context, snapshot) {
                                final metrics = snapshot.data ?? const {};
                                return Column(
                                  children: [
                                    for (var i = 0; i < units.length; i++) ...[
                                      if (i > 0)
                                        const SizedBox(height: AppSpacing.xl),
                                      SyllabusUnitRowCard(
                                        unitId: units[i].id,
                                        title: units[i].displayName,
                                        index: i,
                                        progress:
                                            metrics[units[i].id]?.progress ??
                                            0,
                                        completed:
                                            metrics[units[i].id]?.completed ??
                                            false,
                                        onTap: () => _openUnit(units[i]),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
