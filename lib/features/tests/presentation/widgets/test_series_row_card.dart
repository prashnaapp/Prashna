import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';

/// Test Series list card. Mirrors the Chapters unit card geometry so both
/// tabs read as the same application.
class TestSeriesRowCard extends StatelessWidget {
  const TestSeriesRowCard({
    super.key,
    required this.title,
    required this.questionCount,
    required this.marks,
    required this.onTap,
    this.progress = 0,
    this.showProgress = true,
    this.showStart = false,
  });

  final String title;
  final int questionCount;
  final int marks;
  final double progress;
  final VoidCallback onTap;

  /// When false, the card omits the percent label and progress bar.
  final bool showProgress;

  /// Compact purple Start control. The whole card remains the tap target.
  final bool showStart;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    final percent = (value * 100).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SyllabusVisual.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: SyllabusVisual.surface,
            borderRadius: BorderRadius.circular(SyllabusVisual.cardRadius),
            boxShadow: SyllabusVisual.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
            child: Row(
              children: [
                Container(
                  width: showStart ? 42 : 64,
                  height: showStart ? 42 : 64,
                  decoration: BoxDecoration(
                    color: SyllabusVisual.tileLavender,
                    borderRadius: BorderRadius.circular(showStart ? 12 : 16),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: AppColors.primaryStrong,
                    size: showStart ? 22 : 32,
                  ),
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
                        '$questionCount Questions • $marks Marks',
                        style: AppTextStyles.caption(context).copyWith(
                          color: SyllabusVisual.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (showProgress) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE8E7F8),
                            color: SyllabusVisual.accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (showStart)
                  const IgnorePointer(child: _StartButton())
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        style: AppTextStyles.label(context).copyWith(
                          color: SyllabusVisual.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
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

class _StartButton extends StatelessWidget {
  const _StartButton();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppRadius.sm));
    return Material(
      color: SyllabusVisual.accent,
      shape: const RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40, minWidth: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Center(
            child: Text(
              'Start',
              style: AppTextStyles.label(context).copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
