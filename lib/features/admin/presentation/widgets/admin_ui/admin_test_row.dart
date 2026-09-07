import 'package:flutter/material.dart';

import '../../../../syllabus/services/syllabus_service.dart';
import '../../../../tests/data/models/test_models.dart';
import '../../../data/admin_test_hierarchy.dart';
import '../../../theme/admin_colors.dart';
import '../../../theme/admin_spacing.dart';
import 'admin_status_badge.dart';
import 'admin_surface.dart';

/// Dense premium row for one managed test in Admin.
class AdminTestRow extends StatelessWidget {
  const AdminTestRow({
    super.key,
    required this.test,
    required this.onEdit,
    this.onPublish,
    this.onUnpublish,
    this.onArchive,
    this.onRestore,
    this.syllabusService,
  });

  final TestModel test;
  final VoidCallback onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onUnpublish;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final SyllabusService? syllabusService;

  static String categoryLabel(TestCategoryType type) {
    switch (type) {
      case TestCategoryType.chapterTests:
        return 'Chapter Tests';
      case TestCategoryType.partTests:
        return 'Paper-wise Tests';
      case TestCategoryType.paperTests:
        return 'Paper Tests';
      case TestCategoryType.mockTests:
        return 'Grand Tests';
      case TestCategoryType.previousYear:
        return 'Previous Papers';
    }
  }

  /// Human-friendly hierarchy crumbs; falls back to IDs when unresolved.
  List<String> _scopeLabels() {
    final syllabus = syllabusService ?? SyllabusService.instance;
    final courseId = test.examId;
    final parts = <String>[];

    final paperId = test.paperId?.trim();
    if (paperId != null && paperId.isNotEmpty) {
      final paper = syllabus.getPaper(courseId: courseId, paperId: paperId);
      parts.add(
        paper == null ? paperId : AdminTestHierarchy.paperLabel(paper),
      );

      final partId = test.partId?.trim();
      if (partId != null && partId.isNotEmpty) {
        final part = syllabus.getPart(
          courseId: courseId,
          paperId: paperId,
          partId: partId,
        );
        parts.add(part?.displayName ?? partId);
      }

      final unitId = test.syllabusUnitId?.trim();
      if (unitId != null && unitId.isNotEmpty) {
        parts.add(_unitLabel(syllabus, courseId, paperId, partId, unitId));
      }
    } else {
      final unitId = test.syllabusUnitId?.trim();
      if (unitId != null && unitId.isNotEmpty) parts.add(unitId);
    }

    final seriesId = test.seriesId?.trim();
    if (seriesId != null && seriesId.isNotEmpty) parts.add(seriesId);

    if (test.year != null) parts.add('${test.year}');
    return parts;
  }

  static String _unitLabel(
    SyllabusService syllabus,
    String courseId,
    String paperId,
    String? partId,
    String unitId,
  ) {
    final paper = syllabus.getPaper(courseId: courseId, paperId: paperId);
    if (paper == null) return unitId;

    for (final area in paper.majorStudyAreas) {
      if (area.id == unitId) return area.displayName;
      for (final topic in area.contentTopics) {
        if (topic.id == unitId) return topic.displayName;
      }
    }
    for (final unit in paper.syllabusUnits) {
      if (unit.id == unitId) return unit.displayName;
    }
    if (partId != null && partId.isNotEmpty) {
      final part = syllabus.getPart(
        courseId: courseId,
        paperId: paperId,
        partId: partId,
      );
      if (part != null) {
        for (final unit in part.syllabusUnits) {
          if (unit.id == unitId) return unit.displayName;
        }
        for (final topic in part.topics) {
          if (topic.id == unitId) return topic.resolvedDisplayName;
        }
      }
    }
    return unitId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scopeParts = _scopeLabels();

    final metadata = <String>[
      categoryLabel(test.category),
      '${test.questionCount} Q',
      '${test.marks} marks',
      '${test.durationMinutes} min',
      if (test.difficulty.trim().isNotEmpty) test.difficulty,
      if (test.negativeMarking.trim().isNotEmpty)
        '−${test.negativeMarking}',
    ];

    final actions = Wrap(
      spacing: AdminSpacing.xs,
      runSpacing: AdminSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          key: ValueKey('test-edit-${test.id}'),
          tooltip: 'Edit',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 20),
        ),
        if (onPublish != null)
          IconButton(
            key: ValueKey('test-publish-${test.id}'),
            tooltip: 'Publish',
            onPressed: onPublish,
            icon: const Icon(Icons.visibility_outlined, size: 20),
          ),
        if (onUnpublish != null)
          IconButton(
            key: ValueKey('test-unpublish-${test.id}'),
            tooltip: 'Unpublish',
            onPressed: onUnpublish,
            icon: const Icon(Icons.visibility_off_outlined, size: 20),
          ),
        if (onRestore != null)
          IconButton(
            key: ValueKey('test-restore-${test.id}'),
            tooltip: 'Restore',
            onPressed: onRestore,
            icon: const Icon(Icons.unarchive_outlined, size: 20),
          ),
        if (onArchive != null)
          IconButton(
            key: ValueKey('test-archive-${test.id}'),
            tooltip: 'Archive',
            onPressed: onArchive,
            icon: const Icon(Icons.archive_outlined, size: 20),
          ),
      ],
    );

    return AdminSurface(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.lg,
        AdminSpacing.md,
        AdminSpacing.md,
        AdminSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final header = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  test.title.isEmpty ? 'Untitled test' : test.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: AdminSpacing.sm),
              AdminStatusBadge.test(
                test.status,
                key: ValueKey('test-status-${test.id}'),
              ),
            ],
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (test.description.trim().isNotEmpty) ...[
                const SizedBox(height: AdminSpacing.xs),
                Text(
                  test.description.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AdminColors.textSecondary,
                  ),
                ),
              ],
              if (scopeParts.isNotEmpty) ...[
                const SizedBox(height: AdminSpacing.xs),
                Text(
                  scopeParts.join('  ›  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AdminColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AdminSpacing.xs),
              Wrap(
                spacing: AdminSpacing.sm,
                runSpacing: AdminSpacing.xs,
                children: [
                  for (final item in metadata) _MetaChip(label: item),
                  _MetaChip(label: test.id, muted: true),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                details,
                const SizedBox(height: AdminSpacing.sm),
                Align(alignment: Alignment.centerLeft, child: actions),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [header, details],
                ),
              ),
              const SizedBox(width: AdminSpacing.md),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted ? Colors.transparent : AdminColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: muted ? AdminColors.border : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: muted ? AdminColors.textTertiary : AdminColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
