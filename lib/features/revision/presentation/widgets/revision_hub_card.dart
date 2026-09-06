import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/revision_models.dart';

/// Premium Revision Center destination card.
///
/// Layout: tinted circular icon · title · count badge · chevron.
/// No secondary descriptive text. Destination screens own empty/error copy.
class RevisionHubCard extends StatelessWidget {
  const RevisionHubCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final RevisionHubItem item;
  final VoidCallback onTap;

  static const double _minHeight = 88;
  static const BorderRadius _radius = AppRadius.xlAll;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryStrong.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: _radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: _radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: _radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface,
                  AppColors.surfaceVariant.withValues(alpha: 0.55),
                ],
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _color.withValues(alpha: 0.13),
                        boxShadow: [
                          BoxShadow(
                            color: _color.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(_icon, color: _color, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CountBadge(count: item.count, color: _color),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    switch (item.type) {
      case RevisionHubType.wrongQuestions:
        return Icons.close_rounded;
      case RevisionHubType.weakTopics:
        return Icons.trending_down_rounded;
      case RevisionHubType.bookmarked:
        return Icons.star_rounded;
      case RevisionHubType.frequentlyIncorrect:
        return Icons.replay_rounded;
    }
  }

  Color get _color {
    switch (item.type) {
      case RevisionHubType.wrongQuestions:
        return AppColors.error;
      case RevisionHubType.weakTopics:
        return AppColors.warning;
      case RevisionHubType.bookmarked:
        return AppColors.accentWarm;
      case RevisionHubType.frequentlyIncorrect:
        return AppColors.secondary;
    }
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.color,
  });

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        '$count',
        style: AppTextStyles.label(context).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
