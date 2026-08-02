import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/practice_models.dart';

class PracticeSummaryCard extends StatelessWidget {
  const PracticeSummaryCard({
    super.key,
    required this.session,
    this.heroTag,
  });

  final PracticeSessionModel session;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final card = AppCard(
      child: Column(
        children: [
          _Row(label: 'Chapter', value: session.chapterLabel),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Questions', value: '${session.questionCount}'),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Marks', value: '${session.marks}'),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Time Limit', value: session.timeLimitLabel),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Negative Marking', value: session.negativeMarking),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Difficulty', value: session.difficulty),
        ],
      ),
    );

    if (heroTag == null) return card;

    return Hero(
      tag: heroTag!,
      child: Material(
        color: Colors.transparent,
        child: card,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMedium(context)),
        ),
        Text(value, style: AppTextStyles.label(context)),
      ],
    );
  }
}
