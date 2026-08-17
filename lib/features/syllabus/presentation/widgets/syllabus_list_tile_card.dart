import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class SyllabusListTileCard extends StatelessWidget {
  const SyllabusListTileCard({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.trailing,
    this.accentColor,
    this.icon,
    this.highlighted = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget? trailing;
  final Color? accentColor;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primaryStrong;
    return AppCard(
      onTap: enabled ? onTap : null,
      showBorder: true,
      backgroundColor: AppColors.surface,
      child: DecoratedBox(
        decoration: highlighted
            ? BoxDecoration(
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: accent, width: 1.5),
              )
            : const BoxDecoration(),
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Row(
            children: [
              AppAccentIcon(
                icon: icon ?? Icons.auto_stories_rounded,
                color: accent,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium(context)),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(subtitle!, style: AppTextStyles.bodyMedium(context)),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    enabled ? Icons.chevron_right_rounded : Icons.lock_rounded,
                    color: AppColors.textTertiary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
