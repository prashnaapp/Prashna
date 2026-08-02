import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import 'circular_progress_widget.dart';
import 'linear_progress_widget.dart';

class OverallProgressCard extends StatelessWidget {
  const OverallProgressCard({
    super.key,
    required this.title,
    required this.coveredMarks,
    required this.maxMarks,
    required this.progressPercent,
  });

  final String title;
  final double coveredMarks;
  final double maxMarks;
  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTextStyles.titleLarge(context)),
          const SizedBox(height: AppSpacing.lg),
          CircularProgressWidget(percent: progressPercent),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${_format(coveredMarks)} / ${_format(maxMarks)} Marks',
            style: AppTextStyles.titleMedium(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${progressPercent.round()}%',
            style: AppTextStyles.bodyMedium(context),
          ),
          const SizedBox(height: AppSpacing.lg),
          LinearProgressWidget(value: progressPercent / 100),
        ],
      ),
    );
  }

  String _format(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}
