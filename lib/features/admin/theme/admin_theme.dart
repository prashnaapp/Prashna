import 'package:flutter/material.dart';

import 'admin_colors.dart';
import 'admin_spacing.dart';
import 'admin_typography.dart';

/// Admin-only [ThemeData]. Must not mutate Student [AppTheme].
abstract final class AdminTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: AdminColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AdminColors.primarySoft,
      secondary: AdminColors.accent,
      onSecondary: Colors.white,
      surface: AdminColors.surfaceElevated,
      onSurface: AdminColors.textPrimary,
      error: AdminColors.danger,
      outline: AdminColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: AdminTypography.textTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AdminColors.surfaceElevated.withValues(alpha: 0.92),
        foregroundColor: AdminColors.textPrimary,
        titleTextStyle: AdminTypography.textTheme(Brightness.light).titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AdminColors.surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AdminColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.lg,
          vertical: AdminSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.xl,
            vertical: AdminSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.textPrimary,
          side: const BorderSide(color: AdminColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AdminColors.primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AdminColors.surfaceMuted,
        side: const BorderSide(color: AdminColors.border),
        labelStyle: const TextStyle(
          color: AdminColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dividerColor: AdminColors.border,
      dialogTheme: DialogThemeData(
        backgroundColor: AdminColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
