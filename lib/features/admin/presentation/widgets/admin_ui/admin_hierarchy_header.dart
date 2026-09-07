import 'package:flutter/material.dart';

import '../../../theme/admin_colors.dart';
import '../../../theme/admin_spacing.dart';

/// Compact hierarchy chrome for Chapters / Test Series drill-down.
///
/// Used when embedded in [AdminShell] so nested Material AppBars do not
/// duplicate shell navigation chrome. Preserves an explicit Back control.
class AdminHierarchyHeader extends StatelessWidget {
  const AdminHierarchyHeader({
    super.key,
    required this.title,
    this.contextPath,
    this.onBack,
  });

  final String title;
  final String? contextPath;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (onBack != null) ...[
                IconButton(
                  key: const ValueKey('admin-hierarchy-back'),
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: AdminSpacing.xs),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (contextPath != null && contextPath!.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.xs),
            Padding(
              padding: EdgeInsets.only(
                left: onBack != null ? 48 : 0,
              ),
              child: Text(
                contextPath!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AdminColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
