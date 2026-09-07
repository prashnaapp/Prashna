import 'package:flutter/material.dart';

import '../../../theme/admin_colors.dart';
import '../../../theme/admin_spacing.dart';
import 'admin_surface.dart';

/// Calm empty-state panel for Admin list screens.
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = AdminSurface(
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.xxl,
            vertical: AdminSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AdminColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AdminColors.primary, size: 24),
              ),
              const SizedBox(height: AdminSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AdminSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AdminColors.textSecondary,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: AdminSpacing.lg),
                action!,
              ],
            ],
          ),
        );

        final bounded = constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight < 360;

        final child = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: content,
        );

        if (bounded) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: child),
            ),
          );
        }

        return Center(child: child);
      },
    );
  }
}
