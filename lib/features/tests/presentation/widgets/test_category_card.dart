import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class TestCategoryCard extends StatelessWidget {
  const TestCategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor,
    this.icon,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accentColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primaryStrong;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          AppAccentIcon(icon: icon ?? Icons.quiz_rounded, color: accent),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.titleMedium(context)),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.bodyMedium(context)),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
