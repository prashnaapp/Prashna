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
    final lines = optionText.split('\n');
    final primaryText = lines.first;
    final secondaryText = lines.length < 2
        ? null
        : lines
              .skip(1)
              .where((line) => line.trim().isNotEmpty)
              .join('\n');

    return Material(
      color: selected ? AppColors.lavender : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.smAll,
        side: BorderSide(
          color: selected
              ? AppColors.primaryStrong.withValues(alpha: 0.55)
              : AppColors.divider,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _OptionLetter(label: label, selected: selected),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryText,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      if (secondaryText != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          secondaryText,
                          style: AppTextStyles.bodyMedium(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionLetter extends StatelessWidget {
  const _OptionLetter({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.xxl,
      height: AppSpacing.xxl,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primaryStrong : AppColors.surface,
        border: Border.all(
          color: selected ? AppColors.primaryStrong : AppColors.divider,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.label(context).copyWith(
          color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
