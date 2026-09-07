import 'package:flutter/material.dart';

import '../../../theme/admin_colors.dart';
import '../../../theme/admin_spacing.dart';
import 'admin_surface.dart';

/// Premium navigation tile for hierarchy browsers (Test Series / Chapters).
class AdminNavTile extends StatelessWidget {
  const AdminNavTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon = Icons.folder_outlined,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdminSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.lg,
        vertical: AdminSpacing.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AdminColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AdminColors.primary, size: 22),
          ),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AdminColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AdminColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
