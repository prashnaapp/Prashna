import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';

/// Large clickable category row for the Group-II / Group-III test dashboard.
class ExamCategoryTile extends StatelessWidget {
  const ExamCategoryTile({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.height,
    required this.onTap,
    this.surface,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final double height;
  final VoidCallback onTap;

  /// Subtle pastel fill. Defaults to a light blend of [accent] on white.
  final Color? surface;

  static const Color _titleColor = Color(0xFF130F2B);

  @override
  Widget build(BuildContext context) {
    final circle = (height * 0.58).clamp(44.0, 56.0);
    final iconSize = (circle * 0.48).clamp(20.0, 26.0);
    final fill =
        surface ?? Color.alphaBlend(accent.withValues(alpha: 0.08), Colors.white);
    final pastel = accent.withValues(alpha: 0.16);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.xlAll,
        boxShadow: SyllabusVisual.clickableCardShadow,
      ),
      child: Material(
        color: fill,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadius.xlAll,
          ),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  SizedBox(
                    width: circle,
                    height: circle,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: pastel,
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Center(
                        child: Icon(icon, color: accent, size: iconSize),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium(context).copyWith(
                        color: _titleColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        height: 1.15,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: SyllabusVisual.accent.withValues(alpha: 0.55),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
