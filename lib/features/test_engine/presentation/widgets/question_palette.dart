import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_engine_models.dart';

Color questionStatusColor(QuestionStatus status) {
  switch (status) {
    case QuestionStatus.answered:
      return AppColors.success;
    case QuestionStatus.notAnswered:
      return AppColors.surface;
    case QuestionStatus.markedForReview:
      return AppColors.secondary;
    case QuestionStatus.notVisited:
      return AppColors.surfaceVariant;
  }
}

Color questionStatusForeground(QuestionStatus status) {
  switch (status) {
    case QuestionStatus.answered:
    case QuestionStatus.markedForReview:
      return AppColors.textOnPrimary;
    case QuestionStatus.notAnswered:
    case QuestionStatus.notVisited:
      return AppColors.textPrimary;
  }
}

class QuestionPalette extends StatelessWidget {
  const QuestionPalette({
    super.key,
    required this.attempts,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<QuestionAttempt> attempts;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attempts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final status = attempts[index].status;
        final selected = index == currentIndex;
        return Material(
          color: questionStatusColor(status),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: AppRadius.mdAll,
            onTap: () => onSelect(index),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppTextStyles.label(context).copyWith(
                  color: questionStatusForeground(status),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class QuestionStatusLegend extends StatelessWidget {
  const QuestionStatusLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      (QuestionStatus.answered, 'Answered'),
      (QuestionStatus.notAnswered, 'Not Answered'),
      (QuestionStatus.markedForReview, 'Marked for Review'),
      (QuestionStatus.notVisited, 'Not Visited'),
    ];

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: questionStatusColor(item.$1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.divider),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(item.$2, style: AppTextStyles.caption(context)),
            ],
          ),
      ],
    );
  }
}
