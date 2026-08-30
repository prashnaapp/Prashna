import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';

/// Compact Chapters landing course card.
///
/// White surface, pastel icon, title, marks/papers rows, and a thin
/// accent bar. Height is intrinsic — it does not stretch to fill leftover
/// viewport space.
class ChaptersCourseCard extends StatelessWidget {
  const ChaptersCourseCard({
    super.key,
    required this.title,
    required this.marks,
    required this.papers,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final int marks;
  final int papers;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pastel = accent.withValues(alpha: 0.14);

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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: pastel,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accent, size: 24),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium(context).copyWith(
                        color: SyllabusVisual.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
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
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _MetaRow(
                      icon: Icons.content_paste_rounded,
                      label: '$papers Papers',
                      accent: accent,
                      pastel: pastel,
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
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Color pastel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: pastel,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: accent),
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
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
