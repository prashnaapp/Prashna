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
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Row(
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
                ],
              ),
            ),
            trailing ??
                Icon(
                  enabled
                      ? Icons.chevron_right_rounded
                      : Icons.lock_rounded,
                  color: AppColors.textTertiary,
                ),
          ],
        ),
      ),
    );
  }
}
