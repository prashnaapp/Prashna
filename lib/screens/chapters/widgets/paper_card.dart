import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.title,
    this.subtitle,
    this.comingSoon = false,
    this.onTap,
    this.heroTag,
  });

  final String title;
  final String? subtitle;
  final bool comingSoon;
  final VoidCallback? onTap;
  final String? heroTag;

  bool get enabled => !comingSoon && onTap != null;

  @override
  Widget build(BuildContext context) {
    final content = AppCard(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium(context)),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle!, style: AppTextStyles.bodyMedium(context)),
                  ],
                  if (comingSoon) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const AppBadge(
                      label: 'Coming Soon',
                      variant: AppBadgeVariant.neutral,
                    ),
                  ],
                ],
              ),
            ),
            if (enabled)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );

    if (heroTag == null || !enabled) return content;

    return Hero(
      tag: heroTag!,
      child: Material(
        color: Colors.transparent,
        child: content,
      ),
    );
  }
}
