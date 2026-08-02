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
    final maxWidth = MediaQuery.sizeOf(context).width;
    final isTablet = maxWidth >= 600;
    final horizontalMargin = isTablet
        ? AppSpacing.section
        : AppNavMetrics.horizontalMargin;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalMargin,
          0,
          horizontalMargin,
          AppNavMetrics.bottomMargin,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppNavMetrics.barRadius,
                boxShadow: AppShadows.medium,
              ),
              child: SizedBox(
                height: AppNavMetrics.barHeight,
                child: Semantics(
                  container: true,
                  label: 'Main navigation',
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
    final iconColor =
        selected ? AppColors.textOnPrimary : AppColors.textSecondary;
    final labelColor =
        selected ? AppColors.primary : AppColors.textSecondary;

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppNavMetrics.pillHorizontalPadding,
                        vertical: AppNavMetrics.pillVerticalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: AppRadius.xxlAll,
                      ),
                      child: TweenAnimationBuilder<Color?>(
                        duration: AppAnimations.navigation,
                        curve: AppAnimations.curveStandard,
                        tween: ColorTween(end: iconColor),
                        builder: (context, color, _) {
                          return Icon(
                            item.icon,
                            size: AppNavMetrics.iconSize,
                            color: color,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedDefaultTextStyle(
                      duration: AppAnimations.navigation,
                      curve: AppAnimations.curveStandard,
                      style: AppTextStyles.caption(context).copyWith(
                        color: labelColor,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
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
