import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../progress_visual.dart';

/// Compact course row on the Progress tab — same card quality as Chapters.
class ExamTrackerCard extends StatelessWidget {
  const ExamTrackerCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(ProgressVisual.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(ProgressVisual.cardRadius),
            border: ProgressVisual.cardBorder,
            boxShadow: enabled
                ? ProgressVisual.cardShadow
                : ProgressVisual.statShadow,
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium(context).copyWith(
                            color: ProgressVisual.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: ProgressVisual.muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (enabled) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: ProgressVisual.accent.withValues(alpha: 0.55),
                      size: 26,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
