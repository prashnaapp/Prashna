import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class RevisionEmptyState extends StatelessWidget {
  const RevisionEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.check_circle_outline_rounded,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium(context),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
