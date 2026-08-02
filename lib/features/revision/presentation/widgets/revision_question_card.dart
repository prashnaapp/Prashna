import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/revision_models.dart';
import '../revision_navigation.dart';

class RevisionQuestionCard extends StatelessWidget {
  const RevisionQuestionCard({
    super.key,
    required this.item,
  });

  final RevisionQuestionItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => RevisionNavigation.openQuestion(
        context,
        questionId: item.questionId,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${item.paperName} · ${item.chapterName}',
                  style: AppTextStyles.bodyMedium(context),
                ),
                if (item.wrongCount != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Incorrect ${item.wrongCount}×',
                    style: AppTextStyles.caption(context),
                  ),
                ],
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
}
