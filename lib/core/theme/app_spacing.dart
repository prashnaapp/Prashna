import 'package:flutter/material.dart';

/// Consistent spacing scale for padding, gaps, and insets.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
  static const double section = 64;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: xxl,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}
