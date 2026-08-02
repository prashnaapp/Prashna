import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class CircularProgressWidget extends StatelessWidget {
  const CircularProgressWidget({
    super.key,
    required this.percent,
    this.size = AppSpacing.section,
    this.strokeWidth = AppSpacing.sm,
  });

  final double percent;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: AppAnimations.slow,
      curve: AppAnimations.curveStandard,
      builder: (context, animatedValue, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AppCircularProgress(
                value: animatedValue,
                size: size,
                strokeWidth: strokeWidth,
              ),
              Text(
                '${percent.round()}%',
                style: AppTextStyles.titleMedium(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
