import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_colors.dart';

/// Admin-only typography helpers (Plus Jakarta via google_fonts).
abstract final class AdminTypography {
  static TextTheme textTheme(Brightness brightness) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    final primary = AdminColors.textPrimary;
    final secondary = AdminColors.textSecondary;
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
      // Body defaults to primary so content is not globally washed out.
      // Supporting copy should explicitly use textSecondary.
      bodyLarge: base.bodyLarge?.copyWith(color: primary, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(color: primary, height: 1.45),
      bodySmall: base.bodySmall?.copyWith(color: secondary, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: secondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
