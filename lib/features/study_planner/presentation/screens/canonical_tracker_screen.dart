import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../progress/data/models/syllabus_completion.dart';
import '../../../progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import '../../../progress_cloud/repository/unit_performance_cloud_repository.dart';
import '../../../syllabus/presentation/screens/syllabus_unit_tests_screen.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../../tests/services/test_service.dart';
import '../../data/models/canonical_planner_entry.dart';
import '../../data/services/canonical_planner_aggregation_service.dart';

/// Canonical student tracker for courses with final SyllabusUnit data.
///
/// The screen consumes [CanonicalPlannerEntry] only. It does not calculate
/// completion, count questions, or traverse Topic/Lesson data.
class CanonicalTrackerScreen extends StatefulWidget {
  const CanonicalTrackerScreen({
    super.key,
    required this.courseId,
    this.aggregationService,
    this.testService,
    this.unitPerformanceRepository,
    this.syllabusCompletionRepository,
  });

  final String courseId;
  final CanonicalPlannerAggregationService? aggregationService;
  final TestService? testService;
  final UnitPerformanceCloudRepository? unitPerformanceRepository;
  final SyllabusCompletionCloudRepository? syllabusCompletionRepository;

  @override
  State<CanonicalTrackerScreen> createState() => _CanonicalTrackerScreenState();
}

class _CanonicalTrackerScreenState extends State<CanonicalTrackerScreen> {
  late Future<List<CanonicalPlannerEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  Future<List<CanonicalPlannerEntry>> _loadEntries() {
    final service =
        widget.aggregationService ?? CanonicalPlannerAggregationService();
    return service.getCanonicalPlannerEntries(widget.courseId);
  }

  void _retry() {
    setState(() => _entriesFuture = _loadEntries());
  }

  @override
  Widget build(BuildContext context) {
    final course = SyllabusService.instance.getCourseById(widget.courseId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(course?.name ?? widget.courseId)),
      body: FutureBuilder<List<CanonicalPlannerEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AppCircularProgress());
          }
          if (snapshot.hasError) {
            return _TrackerMessage(
              title: 'Unable to load syllabus tracker',
              message: 'Please check your connection and try again.',
              actionLabel: 'Retry',
              onAction: _retry,
            );
          }

          final entries = snapshot.data ?? const <CanonicalPlannerEntry>[];
          if (entries.isEmpty) {
            return const _TrackerMessage(
              title: 'No syllabus units available',
              message: 'There are no canonical syllabus units for this course.',
            );
          }

          return _CanonicalEntriesBody(
            courseId: widget.courseId,
            entries: entries,
            testService: widget.testService,
            unitPerformanceRepository: widget.unitPerformanceRepository,
            syllabusCompletionRepository: widget.syllabusCompletionRepository,
          );
        },
      ),
    );
  }
}

class _CanonicalEntriesBody extends StatelessWidget {
  const _CanonicalEntriesBody({
    required this.courseId,
    required this.entries,
    this.testService,
    this.unitPerformanceRepository,
    this.syllabusCompletionRepository,
  });

  final String courseId;
  final List<CanonicalPlannerEntry> entries;
  final TestService? testService;
  final UnitPerformanceCloudRepository? unitPerformanceRepository;
  final SyllabusCompletionCloudRepository? syllabusCompletionRepository;

  @override
  Widget build(BuildContext context) {
    final paperGroups = <String, List<CanonicalPlannerEntry>>{};
    for (final entry in entries) {
      paperGroups.putIfAbsent(entry.paperId, () => []).add(entry);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (final paperGroup in paperGroups.entries) ...[
          if (paperGroup.key != paperGroups.keys.first)
            const SizedBox(height: AppSpacing.xxl),
          SectionHeader(title: _paperTitle(courseId, paperGroup.key)),
          const SizedBox(height: AppSpacing.md),
          ..._buildPaperEntries(context, paperGroup.key, paperGroup.value),
        ],
      ],
    );
  }

  List<Widget> _buildPaperEntries(
    BuildContext context,
    String paperId,
    List<CanonicalPlannerEntry> paperEntries,
  ) {
    final directEntries = paperEntries
        .where((entry) => entry.partId == null)
        .toList(growable: false);
    final partGroups = <String, List<CanonicalPlannerEntry>>{};
    for (final entry in paperEntries.where((entry) => entry.partId != null)) {
      partGroups.putIfAbsent(entry.partId!, () => []).add(entry);
    }

    final widgets = <Widget>[];
    for (final entry in directEntries) {
      widgets.add(
        _UnitRow(
          courseId: courseId,
          entry: entry,
          testService: testService,
          unitPerformanceRepository: unitPerformanceRepository,
          syllabusCompletionRepository: syllabusCompletionRepository,
        ),
      );
      widgets.add(const SizedBox(height: AppSpacing.sm));
    }
    for (final partGroup in partGroups.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            _partTitle(courseId, paperId, partGroup.key),
            style: AppTextStyles.titleMedium(context),
          ),
        ),
      );
      for (final entry in partGroup.value) {
        widgets.add(
          _UnitRow(
            courseId: courseId,
            entry: entry,
            testService: testService,
            unitPerformanceRepository: unitPerformanceRepository,
            syllabusCompletionRepository: syllabusCompletionRepository,
          ),
        );
        widgets.add(const SizedBox(height: AppSpacing.sm));
      }
    }
    if (widgets.isNotEmpty) widgets.removeLast();
    return widgets;
  }

  String _paperTitle(String courseId, String paperId) {
    return SyllabusService.instance
            .getPaper(courseId: courseId, paperId: paperId)
            ?.title ??
        paperId;
  }

  String _partTitle(String courseId, String paperId, String partId) {
    return SyllabusService.instance
            .getPart(courseId: courseId, paperId: paperId, partId: partId)
            ?.displayName ??
        partId;
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.courseId,
    required this.entry,
    this.testService,
    this.unitPerformanceRepository,
    this.syllabusCompletionRepository,
  });

  final String courseId;
  final CanonicalPlannerEntry entry;
  final TestService? testService;
  final UnitPerformanceCloudRepository? unitPerformanceRepository;
  final SyllabusCompletionCloudRepository? syllabusCompletionRepository;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showShadow: false,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(entry.displayName),
          subtitle: Text(
            '${entry.questionCount} questions · ${_statusLabel(entry.completionStatus)}',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SyllabusUnitTestsScreen(
                  courseId: entry.courseId,
                  paperId: entry.paperId,
                  partId: entry.partId,
                  unitId: entry.syllabusUnitId,
                  testService: testService,
                  unitPerformanceRepository: unitPerformanceRepository,
                  syllabusCompletionRepository: syllabusCompletionRepository,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(SyllabusCompletionStatus status) {
    switch (status) {
      case SyllabusCompletionStatus.notStarted:
        return 'Not Started';
      case SyllabusCompletionStatus.inProgress:
        return 'In Progress';
      case SyllabusCompletionStatus.completed:
        return 'Completed';
    }
  }
}

class _TrackerMessage extends StatelessWidget {
  const _TrackerMessage({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTextStyles.titleMedium(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
