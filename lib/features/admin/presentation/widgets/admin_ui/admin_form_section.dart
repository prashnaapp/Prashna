import 'package:flutter/material.dart';

import '../../../theme/admin_colors.dart';
import '../../../theme/admin_spacing.dart';
import 'admin_surface.dart';

/// Premium labeled section for Admin CMS editors.
class AdminFormSection extends StatelessWidget {
  const AdminFormSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? AdminSpacing.lg : AdminSpacing.xl),
      child: AdminSurface(
        padding: EdgeInsets.all(compact ? AdminSpacing.lg : AdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AdminColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AdminSpacing.xs),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AdminColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
            SizedBox(height: compact ? AdminSpacing.md : AdminSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}
