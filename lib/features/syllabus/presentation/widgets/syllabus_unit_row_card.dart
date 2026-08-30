import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';
import 'syllabus_unit_visual.dart';

/// Compact syllabus subject/unit card for the Syllabus Browser.
class SyllabusUnitRowCard extends StatelessWidget {
  const SyllabusUnitRowCard({
    super.key,
    required this.unitId,
    required this.title,
    required this.index,
    required this.onTap,
    this.progress = 0,
    this.completed = false,
  });

  final String unitId;
  final String title;
  final int index;
  final VoidCallback onTap;
  final double progress;
  final bool completed;

  bool get _hasProgress {
    final value = progress.clamp(0.0, 1.0);
    return completed || value > 0;
  }

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    final percent = (value * 100).round();
    final visual = SyllabusUnitVisualCatalog.resolve(
      unitId: unitId,
      displayName: title,
      index: index,
    );
    final shownTitle = visual.cardTitle ?? title;
    final radius = BorderRadius.circular(AppRadius.md);
    final barColor = SyllabusVisual.accent;
    final percentColor = _hasProgress
        ? SyllabusVisual.accent
        : SyllabusVisual.muted;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _hasProgress
            ? SyllabusVisual.clickableCardShadow
            : SyllabusVisual.cardShadow,
      ),
      child: Material(
        color: SyllabusVisual.surface,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: visual.background,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(visual.icon, color: visual.foreground, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shownTitle,
                        maxLines: 3,
                        overflow: TextOverflow.clip,
                        style: AppTextStyles.titleMedium(context).copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: SyllabusVisual.ink,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE8E7F8),
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percent%',
                      style: AppTextStyles.label(context).copyWith(
                        color: percentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: SyllabusVisual.accent,
                      size: 22,
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
