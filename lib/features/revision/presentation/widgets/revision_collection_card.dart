import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/revision_models.dart';

class RevisionCollectionCard extends StatelessWidget {
  const RevisionCollectionCard({
    super.key,
    required this.collection,
    required this.onStart,
  });

  final RevisionCollection collection;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final enabled = collection.isNotEmpty;
    return AppCard(
      onTap: enabled ? onStart : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Row(
          children: [
            Container(
              width: AppSpacing.huge,
              height: AppSpacing.huge,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _colorFor(collection.type).withValues(alpha: 0.12),
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(
                _iconFor(collection.type),
                color: _colorFor(collection.type),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.title,
                    style: AppTextStyles.titleMedium(context),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    collection.subtitle,
                    style: AppTextStyles.bodyMedium(context),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    enabled
                        ? '${collection.count} questions'
                        : 'No questions yet',
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              enabled ? Icons.play_circle_outline : Icons.lock_outline,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(RevisionCollectionType type) {
    switch (type) {
      case RevisionCollectionType.wrongQuestions:
        return Icons.close_rounded;
      case RevisionCollectionType.bookmarked:
        return Icons.bookmark_rounded;
      case RevisionCollectionType.weakTopics:
        return Icons.trending_down_rounded;
      case RevisionCollectionType.unattempted:
        return Icons.radio_button_unchecked;
      case RevisionCollectionType.frequentlyWrong:
        return Icons.replay_rounded;
      case RevisionCollectionType.recentMistakes:
        return Icons.history_rounded;
    }
  }

  Color _colorFor(RevisionCollectionType type) {
    switch (type) {
      case RevisionCollectionType.wrongQuestions:
        return AppColors.error;
      case RevisionCollectionType.bookmarked:
        return AppColors.accentWarm;
      case RevisionCollectionType.weakTopics:
        return AppColors.warning;
      case RevisionCollectionType.unattempted:
        return AppColors.textSecondary;
      case RevisionCollectionType.frequentlyWrong:
        return AppColors.secondary;
      case RevisionCollectionType.recentMistakes:
        return AppColors.primary;
    }
  }
}
