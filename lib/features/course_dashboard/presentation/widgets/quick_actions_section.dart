import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    required this.onPracticeBits,
    required this.onTestSeries,
    required this.onRevision,
    required this.onBookmarks,
  });

  final VoidCallback onPracticeBits;
  final VoidCallback onTestSeries;
  final VoidCallback onRevision;
  final VoidCallback onBookmarks;

  @override
  Widget build(BuildContext context) {
    final actions = <({String title, IconData icon, VoidCallback onTap})>[
      (
        title: 'Practice Bits',
        icon: Icons.menu_book_rounded,
        onTap: onPracticeBits,
      ),
      (
        title: 'Test Series',
        icon: Icons.quiz_rounded,
        onTap: onTestSeries,
      ),
      (
        title: 'Revision',
        icon: Icons.replay_rounded,
        onTap: onRevision,
      ),
      (
        title: 'Bookmarks',
        icon: Icons.bookmark_outline_rounded,
        onTap: onBookmarks,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < actions.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ActionTile(
                  title: actions[i].title,
                  icon: actions[i].icon,
                  onTap: actions[i].onTap,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: i + 1 < actions.length
                    ? _ActionTile(
                        title: actions[i + 1].title,
                        icon: actions[i + 1].icon,
                        onTap: actions[i + 1].onTap,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium(context),
          ),
        ],
      ),
    );
  }
}
