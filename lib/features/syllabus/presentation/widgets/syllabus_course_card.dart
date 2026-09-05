import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';

/// Test Series Available card — clean rounded rectangle with marks/papers rows.
class SyllabusCourseCard extends StatelessWidget {
  const SyllabusCourseCard({
    super.key,
    required this.title,
    required this.marks,
    required this.papers,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.circleSize = 48,
    this.iconSize = 24,
    this.titleFontSize = 16,
    this.metaFontSize = 12,
    this.titleColor,
  });

  final String title;
  final int marks;
  final int papers;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final double circleSize;
  final double iconSize;
  final double titleFontSize;
  final double metaFontSize;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final pastel = accent.withValues(alpha: 0.14);
    final ink = titleColor ?? SyllabusVisual.ink;
    final safeCircle = circleSize.clamp(40.0, 56.0);
    final safeIcon = iconSize.clamp(20.0, safeCircle * 0.55);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        boxShadow: SyllabusVisual.clickableCardShadow,
      ),
      child: Material(
        color: SyllabusVisual.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadius.lgAll,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: safeCircle,
                      height: safeCircle,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: pastel,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(icon, color: accent, size: safeIcon),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium(context).copyWith(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        fontSize: titleFontSize,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MetaRow(
                      icon: Icons.workspace_premium_rounded,
                      label: '$marks Marks',
                      accent: accent,
                      pastel: pastel,
                      fontSize: metaFontSize,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _MetaRow(
                      icon: Icons.content_paste_rounded,
                      label: '$papers Papers',
                      accent: accent,
                      pastel: pastel,
                      fontSize: metaFontSize,
                    ),
                  ],
                ),
              ),
              ColoredBox(
                color: accent,
                child: const SizedBox(height: 4, width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.accent,
    required this.pastel,
    required this.fontSize,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Color pastel;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: pastel,
            borderRadius: BorderRadius.circular(7),
          ),
          child: SizedBox(
            width: 26,
            height: 26,
            child: Center(child: Icon(icon, size: 14, color: accent)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              color: SyllabusVisual.muted,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    );
  }
}
