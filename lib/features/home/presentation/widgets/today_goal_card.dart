import 'package:flutter/material.dart';

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

    return HomeSurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeSectionTitle('Your Preparation'),
          const SizedBox(height: 10),
          Row(
            children: [
              HomeProgressArc(
                progress: goal.progress,
                label: '${goal.progressPercent}%',
                size: 116,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Questions Today',
                      value: '${goal.completedQuestions}',
                    ),
                    const SizedBox(height: 7),
                    _StatRow(
                      label: 'Daily Target',
                      value: '${goal.targetQuestions}',
                    ),
                    const SizedBox(height: 7),
                    _StatRow(label: 'Remaining', value: '$remaining'),
                  ],
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
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: HomeVisual.muted,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 40),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: HomeVisual.pillFill,
            borderRadius: BorderRadius.circular(HomeVisual.pillRadius),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: HomeVisual.ctaDeep,
            ),
          ),
        ),
      ],
    );
  }
}
