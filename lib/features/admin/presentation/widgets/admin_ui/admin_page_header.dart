import 'package:flutter/material.dart';

import '../../../theme/admin_colors.dart';
import '../../../theme/admin_spacing.dart';

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: AdminSpacing.sm),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AdminColors.textSecondary,
            ),
          ),
        ],
      ],
    );

    final actionBlock = actions.isEmpty
        ? null
        : Wrap(
            spacing: AdminSpacing.sm,
            runSpacing: AdminSpacing.sm,
            children: actions,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              actionBlock != null && constraints.maxWidth < 860;
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: AdminSpacing.lg),
                actionBlock,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              if (actionBlock != null) ...[
                const SizedBox(width: AdminSpacing.lg),
                actionBlock,
              ],
            ],
          );
        },
      ),
    );
  }
}
