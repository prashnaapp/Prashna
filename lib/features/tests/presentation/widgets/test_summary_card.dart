import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_models.dart';

class TestSummaryCard extends StatelessWidget {
  const TestSummaryCard({
    super.key,
    required this.instructions,
  });

  final InstructionModel instructions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Row(label: 'Questions', value: '${instructions.questionCount}'),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Marks', value: '${instructions.marks}'),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Duration', value: instructions.durationLabel),
          const SizedBox(height: AppSpacing.md),
          _Row(
            label: 'Negative Marking',
            value: instructions.negativeMarking,
          ),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Difficulty', value: instructions.difficulty),
        ],
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
