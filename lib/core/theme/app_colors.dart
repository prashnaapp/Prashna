import 'package:flutter/material.dart';

/// Premium Prashna color tokens. Use these instead of raw [Color] literals.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF7B83EB);
  static const Color primaryStrong = Color(0xFF6C5CE7);
  static const Color primaryDark = primaryStrong;
  static const Color primaryLight = Color(0xFFB8BDF5);
  static const Color lavender = Color(0xFFEBE9FE);

  static const Color secondary = primaryStrong;
  static const Color secondaryLight = Color(0xFFB8BDF5);

  static const Color accent = Color(0xFF4C8DFF);
  static const Color accentWarm = Color(0xFFF5A623);
  static const Color accentTeal = Color(0xFF2BB8A8);
  static const Color accentPink = Color(0xFFE56BA0);
  static const Color hero = Color(0xFF5348C7);

  // Surfaces
  static const Color background = Color(0xFFF7F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F0FA);

  // Semantic
  static const Color success = Color(0xFF22A06B);
  static const Color successSurface = Color(0xFFE8F7F0);
  static const Color warning = Color(0xFFF5A623);
  static const Color warningSurface = Color(0xFFFFF6E8);
  static const Color error = Color(0xFFEF5350);
  static const Color errorSurface = Color(0xFFFDECEC);

  static const Color divider = Color(0xFFE6E4F4);

  // Text
  static const Color textPrimary = Color(0xFF111936);
  static const Color textSecondary = Color(0xFF68769A);
  static const Color textTertiary = Color(0xFF9AA3BE);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Premium
  static const Color premiumGold = Color(0xFFEAB308);
  static const Color premiumGoldDark = Color(0xFFCA8A04);
  static const Color premiumGoldSurface = Color(0xFFFEFCE8);

  static const Color scrim = Color(0x99111936);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryStrong],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [hero, primaryStrong],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color accentAt(int index) {
    const accents = [primaryStrong, accent, accentTeal, accentWarm, accentPink];
    return accents[index.abs() % accents.length];
  }
}
