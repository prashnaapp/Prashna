import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_models.dart';

class TestSummaryCard extends StatelessWidget {
  const TestSummaryCard({super.key, required this.instructions});

  final InstructionModel instructions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Row(
            icon: Icons.help_outline_rounded,
            label: 'Questions',
            value: '${instructions.questionCount}',
          ),
          const SizedBox(height: AppSpacing.md),
          _Row(
            icon: Icons.star_outline_rounded,
            label: 'Marks',
            value: '${instructions.marks}',
          ),
          const SizedBox(height: AppSpacing.md),
          _Row(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: instructions.durationLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          _Row(
            icon: Icons.remove_circle_outline_rounded,
            label: 'Negative Marking',
            value: instructions.negativeMarking,
          ),
          const SizedBox(height: AppSpacing.md),
          _Row(
            icon: Icons.speed_rounded,
            label: 'Difficulty',
            value: instructions.difficulty,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryStrong),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium(context))),
        Text(value, style: AppTextStyles.label(context)),
      ],
    );
  }
}
