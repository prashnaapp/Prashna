import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class OptionTile extends StatelessWidget {
  const OptionTile({
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
      showShadow: false,
      backgroundColor:
          selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
      child: Row(
        children: [
          Container(
            width: AppSpacing.huge,
            height: AppSpacing.huge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : AppColors.surfaceVariant,
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
            child: Text(
              optionText,
              style: AppTextStyles.bodyLarge(context),
            ),
          ),
        ],
      ),
    );
  }
}
