import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import 'linear_progress_widget.dart';

class PaperProgressCard extends StatelessWidget {
  const PaperProgressCard({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: AppTextStyles.titleMedium(context)),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${_format(coveredMarks)} / ${_format(maxMarks)}',
            style: AppTextStyles.label(context),
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
    );
  }

  String _format(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}
