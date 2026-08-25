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
  });

  final String title;
  final int questionCount;
  final int marks;
  final double progress;
  final VoidCallback onTap;

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
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: SyllabusVisual.tileLavender,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: AppColors.primaryStrong,
                    size: 32,
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
                  ),
                ),
                const SizedBox(width: 10),
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
