import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';

/// Large clickable category row for the Group-II / Group-III test dashboard.
class ExamCategoryTile extends StatelessWidget {
  const ExamCategoryTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.height,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final double height;
  final VoidCallback onTap;

  static const Color _titleColor = Color(0xFF130F2B);
  static const Color _shadowTint = Color(0xFF4A3AB0);
  static const double _radius = 22;

  @override
  Widget build(BuildContext context) {
    final circle = (height * 0.58).clamp(48.0, 64.0);
    final iconSize = (circle * 0.48).clamp(24.0, 30.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _shadowTint.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: _shadowTint.withValues(alpha: 0.15),
                blurRadius: 26,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: _shadowTint.withValues(alpha: 0.22),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                SizedBox(
                  width: circle,
                  height: circle,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: iconSize),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: SyllabusVisual.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          height: 1.2,
                        ),
                      ),
                    ],
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
    );
  }
}
