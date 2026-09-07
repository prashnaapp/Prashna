import 'package:flutter/material.dart';

import '../../../../question_bank/data/models/question_models.dart';
import '../../../theme/admin_colors.dart';
import '../../../theme/admin_spacing.dart';
import 'admin_status_badge.dart';
import 'admin_surface.dart';

/// Dense premium row for one question in Admin Question Bank.
class AdminQuestionRow extends StatelessWidget {
  const AdminQuestionRow({
    super.key,
    required this.question,
    required this.onEdit,
    required this.onRequestStatus,
  });

  final Question question;
  final VoidCallback onEdit;
  final ValueChanged<QuestionPublicationStatus> onRequestStatus;

  static QuestionPublicationStatus effectiveStatus(Question question) {
    return question.status ??
        (question.isActive
            ? QuestionPublicationStatus.published
            : QuestionPublicationStatus.archived);
  }

  static String previewText(Question question) {
    if (question.question.trim().isNotEmpty) return question.question.trim();
    final en = question.content?.en.question.trim() ?? '';
    if (en.isNotEmpty) return en;
    final te = question.content?.te?.question.trim() ?? '';
    return te.isNotEmpty ? te : 'Untitled question';
  }

  static List<String> syllabusPath(Question question) {
    final parts = <String>[];
    void add(String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) parts.add(trimmed);
    }

    add(question.paperId);
    add(question.majorStudyAreaId);
    add(question.contentTopicId);
    add(question.partId);
    add(
      question.syllabus?.topicId?.isNotEmpty == true
          ? question.syllabus!.topicId
          : (question.topicId.isNotEmpty ? question.topicId : null),
    );
    add(question.lessonId);
    add(question.syllabusUnitId);
    return parts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = effectiveStatus(question);
    final (lifecycleLabel, lifecycleIcon, nextStatus) = switch (status) {
      QuestionPublicationStatus.published => (
        'Archive',
        Icons.archive_outlined,
        QuestionPublicationStatus.archived,
      ),
      QuestionPublicationStatus.archived => (
        'Restore',
        Icons.unarchive_outlined,
        QuestionPublicationStatus.published,
      ),
      QuestionPublicationStatus.draft => (
        'Publish',
        Icons.publish_outlined,
        QuestionPublicationStatus.published,
      ),
    };

    final path = syllabusPath(question);
    final metadata = <String>[
      question.difficulty.name,
      question.questionType.name,
      if (question.language.trim().isNotEmpty) question.language,
      if (question.year != null) '${question.year}',
      '${_formatNumber(question.marks)} mark${question.marks == 1 ? '' : 's'}',
    ];

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
          final actions = Wrap(
            spacing: AdminSpacing.xs,
            runSpacing: AdminSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                key: ValueKey('question-edit-${question.id}'),
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              TextButton.icon(
                key: ValueKey('question-lifecycle-${question.id}'),
                onPressed: () => onRequestStatus(nextStatus),
                icon: Icon(lifecycleIcon, size: 18),
                label: Text(lifecycleLabel),
              ),
            ],
          );

          final header = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  previewText(question),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: AdminColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AdminSpacing.sm),
              AdminStatusBadge.question(
                status,
                key: ValueKey('question-status-${question.id}'),
              ),
            ],
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (path.isNotEmpty) ...[
                const SizedBox(height: AdminSpacing.xs),
                Text(
                  path.join('  ›  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AdminColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: AdminSpacing.xs),
              Wrap(
                spacing: AdminSpacing.sm,
                runSpacing: AdminSpacing.xs,
                children: [
                  for (final item in metadata) _MetaChip(label: item),
                  _MetaChip(label: question.id, muted: true),
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

  static String _formatNumber(num value) {
    if (value == value.roundToDouble()) return '${value.toInt()}';
    return value.toString();
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
