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
        : lines.skip(1).where((line) => line.trim().isNotEmpty).join('\n');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? AppColors.lavender : AppColors.surface,
        borderRadius: AppRadius.mdAll,
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: selected
              ? AppColors.primaryStrong.withValues(alpha: 0.45)
              : AppColors.divider.withValues(alpha: 0.7),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OptionLetter(label: label, selected: selected),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            primaryText,
                            style: AppTextStyles.bodyLarge(context).copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                          if (secondaryText != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              secondaryText,
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primaryStrong : AppColors.lavender,
      ),
      child: Text(
        label,
        style: AppTextStyles.label(context).copyWith(
          color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
