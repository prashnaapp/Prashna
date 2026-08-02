import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/revision_models.dart';

class RevisionWeakTopicCard extends StatelessWidget {
  const RevisionWeakTopicCard({
    super.key,
    required this.topic,
    required this.onTap,
  });

  final WeakTopicRevision topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topic.topicName,
                  style: AppTextStyles.titleMedium(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  topic.paperName,
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${topic.accuracy.toStringAsFixed(0)}% accuracy · ${topic.attempts} attempts',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.play_circle_outline_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
