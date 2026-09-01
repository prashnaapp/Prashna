import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';
import '../../data/models/test_models.dart';

class TestSummaryCard extends StatelessWidget {
  const TestSummaryCard({super.key, required this.instructions});

  final InstructionModel instructions;

  @override
  Widget build(BuildContext context) {
    final rows = <_MetaSpec>[
      _MetaSpec(
        icon: Icons.help_outline_rounded,
        iconTint: SyllabusVisual.tileBlue,
        label: 'Questions',
        value: '${instructions.questionCount}',
      ),
      _MetaSpec(
        icon: Icons.star_outline_rounded,
        iconTint: SyllabusVisual.tileAmber,
        label: 'Marks',
        value: '${instructions.marks}',
      ),
      _MetaSpec(
        icon: Icons.timer_outlined,
        iconTint: SyllabusVisual.tileTeal,
        label: 'Duration',
        value: instructions.durationLabel,
      ),
      _MetaSpec(
        icon: Icons.remove_circle_outline_rounded,
        iconTint: SyllabusVisual.tilePink,
        label: 'Negative Marking',
        value: instructions.negativeMarking,
      ),
      _MetaSpec(
        icon: Icons.bar_chart_rounded,
        iconTint: SyllabusVisual.tileLavender,
        label: 'Difficulty',
        value: instructions.difficulty,
        valueAsBadge: true,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: SyllabusVisual.surface,
        borderRadius: BorderRadius.circular(SyllabusVisual.cardRadius),
        boxShadow: SyllabusVisual.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++)
              _MetaRow(spec: rows[i], showDivider: i < rows.length - 1),
          ],
        ),
      ),
    );
  }
}

class _MetaSpec {
  const _MetaSpec({
    required this.icon,
    required this.iconTint,
    required this.label,
    required this.value,
    this.valueAsBadge = false,
  });

  final IconData icon;
  final Color iconTint;
  final String label;
  final String value;
  final bool valueAsBadge;
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.spec, required this.showDivider});

  final _MetaSpec spec;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: spec.iconTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(spec.icon, size: 17, color: SyllabusVisual.accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spec.label,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: SyllabusVisual.muted,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: spec.valueAsBadge
                          ? _DifficultyBadge(value: spec.value)
                          : _Value(spec.value),
                    ),
                  ],
                ),
                if (showDivider) ...[
                  const SizedBox(height: 8),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTextStyles.label(context).copyWith(
        color: SyllabusVisual.ink,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SyllabusVisual.tileLavender,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.label(context).copyWith(
              color: SyllabusVisual.accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
