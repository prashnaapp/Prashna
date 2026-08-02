import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/quiz_statistics.dart';

class QuizStats extends StatelessWidget {
  const QuizStats({
    super.key,
    required this.statistics,
  });

  final QuizStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showShadow: false,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _Chip(
            label: 'Score',
            value: '${statistics.score}',
          ),
          const SizedBox(width: AppSpacing.md),
          _Chip(
            label: 'Correct',
            value: '${statistics.correctAnswers}',
          ),
          const SizedBox(width: AppSpacing.md),
          _Chip(
            label: 'Wrong',
            value: '${statistics.wrongAnswers}',
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption(context)),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.label(context)),
        ],
      ),
    );
  }
}
