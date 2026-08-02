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
    final color = urgent ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.label(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
