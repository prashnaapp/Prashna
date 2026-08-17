import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design_system/design_system.dart';
import 'app_nav_item.dart';
import 'app_nav_metrics.dart';

/// Floating, premium bottom navigation for Prashna.
class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.items = AppNavItems.all,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppNavItem> items;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: AppShadows.medium,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: safeBottom),
          child: Semantics(
            container: true,
            label: 'Main navigation',
            child: SizedBox(
              height: AppNavMetrics.barHeight,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavDestination(
                        item: items[i],
                        selected: i == currentIndex,
                        onTap: () {
                          if (i == currentIndex) return;
                          HapticFeedback.selectionClick();
                          onDestinationSelected(i);
                        },
                      ),
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

class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? AppColors.textOnPrimary
        : AppColors.textTertiary;
    final labelColor = selected
        ? AppColors.primaryStrong
        : AppColors.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: SizedBox(
            height: AppNavMetrics.barHeight,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppNavMetrics.itemMinSize,
                  minHeight: AppNavMetrics.itemMinSize,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: AppAnimations.navigation,
                      curve: AppAnimations.curveStandard,
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryStrong
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: TweenAnimationBuilder<Color?>(
                        duration: AppAnimations.navigation,
                        curve: AppAnimations.curveStandard,
                        tween: ColorTween(end: iconColor),
                        builder: (context, color, _) {
                          return Icon(item.icon, size: 22, color: color);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedDefaultTextStyle(
                      duration: AppAnimations.navigation,
                      curve: AppAnimations.curveStandard,
                      style: AppTextStyles.caption(context).copyWith(
                        color: labelColor,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
}
