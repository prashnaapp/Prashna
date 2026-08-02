import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class QuizTimer extends StatelessWidget {
  const QuizTimer({
    super.key,
    required this.secondsRemaining,
  });

  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.curveStandard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: secondsRemaining <= 10
              ? AppColors.errorSurface
              : AppColors.surfaceVariant,
          borderRadius: AppRadius.xxlAll,
        ),
        child: AnimatedSwitcher(
          duration: AppAnimations.fast,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            '⏱ $secondsRemaining',
            key: ValueKey(secondsRemaining),
            style: AppTextStyles.label(context).copyWith(
              color: secondsRemaining <= 10
                  ? AppColors.error
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
