import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Metrics for the floating bottom navigation bar.
abstract final class AppNavMetrics {
  static const double barHeight = 72;
  static const double horizontalMargin = AppSpacing.lg;
  static const double contentGap = 28;
  static const double itemMinSize = AppSpacing.massive;
  static const double pillHorizontalPadding = AppSpacing.md;
  static const double pillVerticalPadding = AppSpacing.sm;
  static const double iconSize = AppSpacing.xxl;

  static const BorderRadius barRadius = BorderRadius.all(Radius.circular(28));

  static const BorderRadius topRadius = BorderRadius.vertical(
    top: Radius.circular(AppRadius.xl),
  );

  /// Space reserved under tab content so lists clear the floating bar.
  static double contentBottomInset(BuildContext context) {
    return bottomNavigationHeight(context) + contentGap;
  }

  /// Height occupied by the fixed bar and its safe-area offset.
  static double bottomNavigationHeight(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return barHeight + safeBottom;
  }
}
