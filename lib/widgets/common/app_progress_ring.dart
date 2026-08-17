import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';

class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.progress,
    this.size = AppSizes.progressRing,
    this.strokeWidth = 8,
    this.label,
    this.caption,
    this.color,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final String? label;
  final String? caption;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final ringColor = color ?? AppColors.primaryStrong;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: clamped,
              strokeWidth: strokeWidth,
              color: ringColor,
              backgroundColor: AppColors.lavender,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label ?? '${(clamped * 100).round()}%',
                style: AppTextStyles.titleMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: AppTextStyles.caption(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
