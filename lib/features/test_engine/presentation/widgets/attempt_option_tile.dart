import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class AttemptOptionTile extends StatelessWidget {
  const AttemptOptionTile({
    super.key,
    required this.label,
    required this.optionText,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String optionText;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      showShadow: selected,
      showBorder: !selected,
      backgroundColor: selected
          ? AppColors.lavender
          : AppColors.surface,
      child: Row(
        children: [
          Container(
            width: AppSpacing.huge,
            height: AppSpacing.huge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected ? AppColors.primaryGradient : null,
              color: selected ? null : AppColors.surfaceVariant,
              borderRadius: AppRadius.mdAll,
            ),
            child: Text(
              label,
              style: AppTextStyles.label(context).copyWith(
                color: selected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(optionText, style: AppTextStyles.bodyLarge(context)),
          ),
        ],
      ),
    );
  }
}
