import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../revision/presentation/revision_navigation.dart';

/// Entry card into Revision Center (Progress tab).
class RevisionCenterCard extends StatelessWidget {
  const RevisionCenterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => RevisionNavigation.openRevisionCenter(context),
      child: Row(
        children: [
          Container(
            width: AppSpacing.huge,
            height: AppSpacing.huge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Revision Center',
                  style: AppTextStyles.titleMedium(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Wrong, bookmarked, weak topics & more',
                  style: AppTextStyles.bodyMedium(context),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
