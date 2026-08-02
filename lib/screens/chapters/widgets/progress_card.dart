import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

/// Chapter dashboard progress summary.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.weightage,
    required this.marksCovered,
    required this.remaining,
    required this.progressPercent,
    required this.status,
  });

  final String weightage;
  final String marksCovered;
  final String remaining;
  final String progressPercent;
  final String status;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chapter Progress', style: AppTextStyles.titleMedium(context)),
          const SizedBox(height: AppSpacing.lg),
          _Row(label: 'Weightage', value: weightage),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Marks Covered', value: marksCovered),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Remaining', value: remaining),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Progress %', value: progressPercent),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Status', value: status),
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
