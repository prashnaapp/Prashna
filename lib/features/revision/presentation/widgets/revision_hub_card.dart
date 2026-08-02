import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/revision_models.dart';

class RevisionHubCard extends StatelessWidget {
  const RevisionHubCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final RevisionHubItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: AppSpacing.huge,
            height: AppSpacing.huge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(_icon, color: _color),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.titleMedium(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.subtitle,
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.count == 0
                      ? 'Empty'
                      : item.type == RevisionHubType.weakTopics
                          ? '${item.count} topics'
                          : '${item.count} questions',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    switch (item.type) {
      case RevisionHubType.wrongQuestions:
        return Icons.close_rounded;
      case RevisionHubType.weakTopics:
        return Icons.trending_down_rounded;
      case RevisionHubType.bookmarked:
        return Icons.star_rounded;
      case RevisionHubType.frequentlyIncorrect:
        return Icons.replay_rounded;
    }
  }

  Color get _color {
    switch (item.type) {
      case RevisionHubType.wrongQuestions:
        return AppColors.error;
      case RevisionHubType.weakTopics:
        return AppColors.warning;
      case RevisionHubType.bookmarked:
        return AppColors.accentWarm;
      case RevisionHubType.frequentlyIncorrect:
        return AppColors.secondary;
    }
  }
}
