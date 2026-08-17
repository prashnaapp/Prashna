import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../profile_visual.dart';

/// Reusable white row used by every Profile section.
///
/// Icon inside a soft circular container, title, optional subtitle, and a
/// chevron unless the caller supplies its own [trailing] (e.g. a plan badge).
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.iconColor,
    this.trailing,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Color? iconColor;

  /// Replaces the chevron. Pass [SizedBox.shrink] for a row with no affordance.
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? ProfileVisual.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ProfileVisual.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(ProfileVisual.cardRadius),
            border: ProfileVisual.rowBorder,
            boxShadow: ProfileVisual.rowShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 21),
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
                          color: ProfileVisual.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: ProfileVisual.muted,
                            fontWeight: FontWeight.w500,
                            fontSize: 12.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: ProfileVisual.accent.withValues(alpha: 0.55),
                      size: 24,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
