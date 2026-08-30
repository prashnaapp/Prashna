import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/models/home_models.dart';
import '../home_visual.dart';
import 'home_decorations.dart';

class TodayGoalCard extends StatelessWidget {
  const TodayGoalCard({super.key, required this.goal});

  final TodayGoalModel goal;

  @override
  Widget build(BuildContext context) {
    final remaining = (goal.targetQuestions - goal.completedQuestions).clamp(
      0,
      goal.targetQuestions,
    );
    final narrow = MediaQuery.sizeOf(context).width < 370;
    final ringSize = narrow ? 100.0 : 112.0;

    return HomeSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeSectionTitle('Your Preparation'),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              HomeProgressArc(
                progress: goal.progress,
                label: '${goal.progressPercent}%',
                caption: "Today's Goal",
                size: ringSize,
              ),
              SizedBox(width: narrow ? AppSpacing.md : AppSpacing.lg),
              Expanded(
                child: SizedBox(
                  height: ringSize,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatRow(
                        icon: Icons.calendar_today_rounded,
                        iconTint: HomeVisual.lavender,
                        iconColor: HomeVisual.primary,
                        label: 'Questions Today',
                        value: '${goal.completedQuestions}',
                        valueColor: HomeVisual.primary,
                      ),
                      _StatRow(
                        icon: Icons.flag_rounded,
                        iconTint: HomeVisual.tileTarget,
                        iconColor: HomeVisual.accentBlue,
                        label: 'Daily Target',
                        value: '${goal.targetQuestions}',
                        valueColor: HomeVisual.accentBlue,
                      ),
                      _StatRow(
                        icon: Icons.checklist_rounded,
                        iconTint: HomeVisual.tileRemaining,
                        iconColor: HomeVisual.accentGreen,
                        label: 'Remaining',
                        value: '$remaining',
                        valueColor: HomeVisual.accentGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.iconTint,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconTint;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: HomeVisual.muted,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
