import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';

class SyllabusPaperProgressBanner extends StatelessWidget {
  const SyllabusPaperProgressBanner({
    super.key,
    required this.paperTitle,
    required this.progress,
  });

  final String paperTitle;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    final percent = (value * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: SyllabusVisual.progressGradient,
        borderRadius: BorderRadius.circular(SyllabusVisual.cardRadius),
        boxShadow: [
          BoxShadow(
            color: SyllabusVisual.accent.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Progress in $paperTitle',
                  style: AppTextStyles.titleMedium(context).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SyllabusVisual.ink,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.72),
                    color: SyllabusVisual.accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$percent% complete',
                  style: AppTextStyles.caption(context).copyWith(
                    color: SyllabusVisual.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.55),
                    boxShadow: [
                      BoxShadow(
                        color: SyllabusVisual.accent.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 7,
                    color: SyllabusVisual.accent,
                    backgroundColor: AppColors.lavender,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '$percent%',
                  style: AppTextStyles.titleMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: SyllabusVisual.ink,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
