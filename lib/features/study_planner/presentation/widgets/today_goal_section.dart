import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/study_planner_models.dart';

class TodayGoalSection extends StatelessWidget {
  const TodayGoalSection({super.key, required this.goal});

  final TodayGoalPlan? goal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: "Today's Goal"),
        const SizedBox(height: AppSpacing.lg),
        if (goal == null)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              'No chapter goals right now.',
              style: AppTextStyles.bodyMedium(context),
            ),
          )
        else
          AppCard(
            onTap: () {},
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  goal!.paperLabel,
                  style: AppTextStyles.titleLarge(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  goal!.majorStudyAreaLabel ?? goal!.partLabel,
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  goal!.contentTopicLabel ?? goal!.chapterLabel,
                  style: AppTextStyles.label(context),
                ),
                if (goal!.lessonLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(goal!.lessonLabel!, style: AppTextStyles.label(context)),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '${goal!.questionCount} Questions',
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Estimated Time  ${goal!.estimatedMinutes} Minutes',
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Continue →',
                  style: AppTextStyles.label(
                    context,
                  ).copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
