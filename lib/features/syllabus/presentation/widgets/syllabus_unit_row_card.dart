import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';
import 'syllabus_unit_visual.dart';

enum SyllabusUnitCardState { idle, active, completed }

class SyllabusUnitRowCard extends StatelessWidget {
  const SyllabusUnitRowCard({
    super.key,
    required this.unitId,
    required this.title,
    required this.index,
    required this.onTap,
    this.questionCount,
    this.progress = 0,
    this.completed = false,
  });

  final String unitId;
  final String title;
  final int index;
  final VoidCallback onTap;
  final int? questionCount;
  final double progress;
  final bool completed;

  SyllabusUnitCardState get _state {
    final value = progress.clamp(0.0, 1.0);
    if (completed || value >= 1.0) return SyllabusUnitCardState.completed;
    if (value > 0) return SyllabusUnitCardState.active;
    return SyllabusUnitCardState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    final visual = SyllabusUnitVisualCatalog.resolve(
      unitId: unitId,
      displayName: title,
      index: index,
    );
    final state = _state;
    final highlighted = state != SyllabusUnitCardState.idle;
    final fillColor = switch (state) {
      SyllabusUnitCardState.completed => SyllabusVisual.completedFill,
      SyllabusUnitCardState.active => SyllabusVisual.activeFill,
      SyllabusUnitCardState.idle => SyllabusVisual.surface,
    };
    final borderColor = switch (state) {
      SyllabusUnitCardState.completed => SyllabusVisual.completedOutline,
      SyllabusUnitCardState.active => SyllabusVisual.activeOutline,
      SyllabusUnitCardState.idle => null,
    };
    final barColor = switch (state) {
      SyllabusUnitCardState.completed => AppColors.success,
      SyllabusUnitCardState.active => SyllabusVisual.activeOutline,
      SyllabusUnitCardState.idle => SyllabusVisual.accent,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SyllabusVisual.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(SyllabusVisual.cardRadius),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor, width: 1.5),
            boxShadow: highlighted
                ? AppShadows.colored(
                    borderColor ?? SyllabusVisual.completedOutline,
                  )
                : SyllabusVisual.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: visual.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(visual.icon, color: visual.foreground, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium(context).copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: SyllabusVisual.ink,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        questionCount == null
                            ? 'Questions'
                            : '$questionCount Questions',
                        style: AppTextStyles.caption(context).copyWith(
                          color: SyllabusVisual.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: const Color(0xFFE8E7F8),
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percent%',
                      style: AppTextStyles.label(context).copyWith(
                        color: barColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (state == SyllabusUnitCardState.completed)
                      const CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.success,
                        child: Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: SyllabusVisual.faint,
                        size: 26,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
