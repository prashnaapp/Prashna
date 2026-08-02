import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle get _base => GoogleFonts.plusJakartaSans(
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle display(BuildContext context) =>
      _base.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.15,
      );

  static TextStyle headline(BuildContext context) =>
      _base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  static TextStyle titleLarge(BuildContext context) =>
      _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      );

  static TextStyle titleMedium(BuildContext context) =>
      _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle bodyLarge(BuildContext context) =>
      _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle bodyMedium(BuildContext context) =>
      _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: AppColors.textSecondary,
      );

  static TextStyle label(BuildContext context) =>
      _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle caption(BuildContext context) =>
      _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        height: 1.35,
      );

  static TextTheme textTheme(BuildContext context) => TextTheme(
        displaySmall: display(context),
        headlineMedium: headline(context),
        titleLarge: titleLarge(context),
        titleMedium: titleMedium(context),
        bodyLarge: bodyLarge(context),
        bodyMedium: bodyMedium(context),
        labelLarge: label(context),
        bodySmall: caption(context),
      );
}
