import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../navigation/app_nav_metrics.dart';

/// Shared shell for tab destinations owned by [MainNavigationScreen].
class TabShell extends StatelessWidget {
  const TabShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: AppResponsivePadding(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppNavMetrics.contentBottomInset(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                child ??
                    EmptyState(
                      title: title,
                      message: subtitle,
                      icon: icon,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
