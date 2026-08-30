import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Home-only visual tokens. Do not import from other features.
///
/// Palette is aligned with the Home redesign direction while spacing/radii
/// reuse [AppSpacing] and [AppRadius].
abstract final class HomeVisual {
  static const Color primary = Color(0xFF6C4DFF);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color lightPurple = Color(0xFFA78BFA);
  static const Color lavender = Color(0xFFEDE9FE);

  static const Color heroStart = Color(0xFF4F3BE8);
  static const Color heroMid = Color(0xFF6C4DFF);
  static const Color heroEnd = Color(0xFF8B5CF6);

  static const Color ctaStart = primary;
  static const Color ctaEnd = secondary;
  static const Color ctaDeep = primary;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color page = Color(0xFFF6F5FF);
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color gaugeTrack = Color(0xFFEDE9FE);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color pillFill = Color(0xFFF4F2FF);
  static const Color tileTarget = Color(0xFFDBEAFE);
  static const Color tileRemaining = Color(0xFFE8F8EF);

  static const Color tileChapter = Color(0xFFE8EEFF);
  static const Color tileTests = Color(0xFFDFF6FA);
  static const Color tileAffairs = Color(0xFFFDE8F0);
  static const Color tilePapers = Color(0xFFEDE7FA);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [heroStart, heroMid, heroEnd],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, secondary],
  );

  static const LinearGradient gaugeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const double cardRadius = AppRadius.lg;
  static const double tileRadius = AppRadius.md;
  static const double pillRadius = AppRadius.pill;
  static const double overlap = 20;
  static const double pagePadding = AppSpacing.xl;
  static const double sectionGap = AppSpacing.md;

  /// Viewport-anchored hero fill; covers the compact hero plus pull-down.
  static const double heroBackdropHeight = 220;

  /// Body below the status inset for the expanded hero.
  static const double heroBodyHeight = 124;

  /// Body below the status inset for the compact pinned header (Prashna + bell).
  static const double heroCollapsedBodyHeight = 48;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.07),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: ink.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get featuredShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.14),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: ink.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get ctaShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.28),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];
}
