import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class QuizHeader extends StatelessWidget {
  const QuizHeader({
    super.key,
    required this.timerSeconds,
  });

  final int timerSeconds;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.xxlAll,
        ),
        child: Text(
          '⏱ $timerSeconds',
          style: AppTextStyles.label(context),
        ),
      ),
    );
  }
}
