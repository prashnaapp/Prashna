import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class AttemptTimerBadge extends StatelessWidget {
  const AttemptTimerBadge({
    super.key,
    required this.label,
    this.urgent = false,
  });

  final String label;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color background;
    if (urgent) {
      color = AppColors.error;
      background = AppColors.errorSurface;
    } else {
      color = AppColors.primaryStrong;
      background = AppColors.lavender;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 15, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.label(context).copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
