import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class QuestionProgress extends StatelessWidget {
  const QuestionProgress({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = current / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question $current of $total',
          style: AppTextStyles.titleMedium(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        TweenAnimationBuilder<double>(
          tween: Tween(end: progress),
          duration: AppAnimations.medium,
          curve: AppAnimations.curveStandard,
          builder: (context, value, _) {
            return AppLinearProgress(value: value, height: AppSpacing.sm);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text(
              'Current Question',
              style: AppTextStyles.bodyMedium(context),
            ),
            const Spacer(),
            Text(
              '$current / $total',
              style: AppTextStyles.label(context),
            ),
          ],
        ),
      ],
    );
  }
}
