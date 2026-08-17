import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

/// Syllabus-only visual tokens. Do not import Home visuals here.
abstract final class SyllabusVisual {
  static const Color page = Color(0xFFF7F6FF);
  static const Color surface = AppColors.surface;
  static const Color ink = AppColors.textPrimary;
  static const Color muted = AppColors.textSecondary;
  static const Color faint = AppColors.textTertiary;
  static const Color accent = AppColors.primaryStrong;
  static const Color headerOn = Color(0xFFFFFFFF);
  static const Color headerOnMuted = Color(0xDEFFFFFF);
  static const Color headerStart = Color(0xFF241A9F);
  static const Color headerMid = Color(0xFF3926D6);
  static const Color headerEnd = Color(0xFF6548F5);
  static const Color wave = AppColors.lavender;
  static const Color completedOutline = AppColors.accentWarm;
  static const Color completedFill = Color(0xFFFFF6F0);
  static const Color activeOutline = Color(0xFFF0A070);
  static const Color activeFill = Color(0xFFFFF8F2);

  static const Color tileBlue = Color(0xFFE8EEFF);
  static const Color tileTeal = Color(0xFFD8F3F0);
  static const Color tilePink = Color(0xFFFDE8F0);
  static const Color tileLavender = Color(0xFFEDE7FA);
  static const Color tileAmber = Color(0xFFFFF1D6);

  static const double cardRadius = 20;
  static const double pillRadius = 999;
  static const double pagePadding = 20;

  static const LinearGradient progressGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFEDE6FF), Color(0xFFFFE4F1), Color(0xFFE8F0FF)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerStart, headerMid, headerEnd],
  );

  static List<BoxShadow> get cardShadow => AppShadows.soft;

  /// Soft purple glow so Available cards read as tappable (reference).
  static List<BoxShadow> get clickableCardShadow => [
    BoxShadow(
      color: accent.withValues(alpha: 0.16),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: accent.withValues(alpha: 0.07),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Launching Soon cards — lighter lift so they stay distinct but quieter.
  static List<BoxShadow> get lockedCardShadow => [
    BoxShadow(
      color: accent.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get bannerShadow => [
    BoxShadow(
      color: accent.withValues(alpha: 0.14),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get selectedShadow => [
    BoxShadow(
      color: accent.withValues(alpha: 0.22),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static Color pastelAt(int index) {
    const tiles = [tileBlue, tileTeal, tilePink, tileLavender, tileAmber];
    return tiles[index.abs() % tiles.length];
  }

  static Color iconAt(int index) {
    const colors = [
      AppColors.accent,
      AppColors.accentTeal,
      AppColors.accentPink,
      AppColors.primaryStrong,
      AppColors.accentWarm,
    ];
    return colors[index.abs() % colors.length];
  }
}
