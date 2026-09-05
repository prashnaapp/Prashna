import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../revision/presentation/revision_navigation.dart';
import '../progress_visual.dart';

/// Entry card into Revision Center (Progress tab).
class RevisionCenterCard extends StatelessWidget {
  const RevisionCenterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ProgressVisual.cardRadius);
    // Shadow lives on the rounded DecoratedBox. Material is transparent so
    // InkWell cannot paint a square backing behind the white surface.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: ProgressVisual.cardBorder,
        boxShadow: ProgressVisual.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => RevisionNavigation.openRevisionCenter(context),
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ProgressVisual.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: ProgressVisual.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Revision Center',
                        style: AppTextStyles.titleMedium(context).copyWith(
                          color: ProgressVisual.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wrong, weak topics, bookmarks & repeats',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: ProgressVisual.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: ProgressVisual.accent.withValues(alpha: 0.55),
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
