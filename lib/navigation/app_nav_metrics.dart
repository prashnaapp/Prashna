import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Metrics for the floating bottom navigation bar.
abstract final class AppNavMetrics {
  static const double barHeight = 72;
  static const double horizontalMargin = AppSpacing.lg;
  static const double bottomMargin = AppSpacing.md;
  static const double itemMinSize = AppSpacing.massive;
  static const double pillHorizontalPadding = AppSpacing.md;
  static const double pillVerticalPadding = AppSpacing.sm;
  static const double iconSize = AppSpacing.xxl;

  static const BorderRadius barRadius = BorderRadius.all(
    Radius.circular(AppRadius.xl),
  );

  static const BorderRadius topRadius = BorderRadius.vertical(
    top: Radius.circular(AppRadius.xl),
  );

  /// Space reserved under tab content so lists clear the floating bar.
  ///
  /// Matches [CustomBottomNavigation] height (bar + margin + safe area)
  /// plus a small breathing gap. Do not inflate further.
  static double contentBottomInset(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return barHeight + bottomMargin + safeBottom + AppSpacing.md;
  }
}
