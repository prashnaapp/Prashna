import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../study_planner/presentation/study_planner_navigation.dart';

/// Home entry — Smart Study Planner.
class HomeStudyPlannerSection extends StatelessWidget {
  const HomeStudyPlannerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'Study Planner'),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          onTap: () => openStudyPlanner(context),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Smart Study Plan',
                      style: AppTextStyles.titleMedium(context),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Know exactly what to study next.',
                      style: AppTextStyles.bodyMedium(context),
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
        ),
      ],
    );
  }
}
