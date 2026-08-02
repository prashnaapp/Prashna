import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_engine_models.dart';

class AttemptSummaryGrid extends StatelessWidget {
  const AttemptSummaryGrid({
    super.key,
    required this.counts,
  });

  final Map<QuestionStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Tile('Answered', counts[QuestionStatus.answered] ?? 0, AppColors.success),
      _Tile(
        'Not Answered',
        counts[QuestionStatus.notAnswered] ?? 0,
        AppColors.warning,
      ),
      _Tile(
        'Marked',
        counts[QuestionStatus.markedForReview] ?? 0,
        AppColors.secondary,
      ),
      _Tile(
        'Not Visited',
        counts[QuestionStatus.notVisited] ?? 0,
        AppColors.textTertiary,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.7,
      children: [
        for (final tile in tiles)
          AppCard(
            showShadow: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${tile.value}',
                  style: AppTextStyles.headline(context).copyWith(
                    color: tile.color,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(tile.label, style: AppTextStyles.bodyMedium(context)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Tile {
  const _Tile(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}
