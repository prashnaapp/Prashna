import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import 'linear_progress_widget.dart';

class ChapterProgressCard extends StatelessWidget {
  const ChapterProgressCard({
    super.key,
    required this.title,
    required this.coveredMarks,
    required this.maxMarks,
    required this.progressPercent,
    this.onTap,
  });

  final String title;
  final double coveredMarks;
  final double maxMarks;
  final double progressPercent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.titleMedium(context)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${_format(coveredMarks)} / ${_format(maxMarks)}',
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${progressPercent.round()}%',
                  style: AppTextStyles.caption(context),
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressWidget(value: progressPercent / 100),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }

  String _format(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}
