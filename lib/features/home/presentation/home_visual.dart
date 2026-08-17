import 'package:flutter/material.dart';

/// Home-only visual tokens. Do not import from other features.
abstract final class HomeVisual {
  static const Color heroStart = Color(0xFF241A9F);
  static const Color heroMid = Color(0xFF3926D6);
  static const Color heroEnd = Color(0xFF6548F5);
  static const Color ctaStart = Color(0xFF7B83EB);
  static const Color ctaEnd = Color(0xFF8A87F9);
  static const Color ctaDeep = Color(0xFF7356F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color page = Color(0xFFF5F4FF);
  static const Color ink = Color(0xFF111A3A);
  static const Color muted = Color(0xFF68769A);
  static const Color gaugeTrack = Color(0xFFE8E7F8);
  static const Color accentBlue = Color(0xFF4C8DFF);
  static const Color pillFill = Color(0xFFF3F2FA);
  static const Color star = Color(0xFFFFE082);

  static const Color tileChapter = Color(0xFFE8EEFF);
  static const Color tileTests = Color(0xFFDFF6FA);
  static const Color tileAffairs = Color(0xFFFDE8F0);
  static const Color tilePapers = Color(0xFFEDE7FA);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomRight,
    colors: [heroStart, heroMid, heroEnd],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [ctaStart, ctaDeep],
  );

  static const LinearGradient gaugeGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [ctaDeep, accentBlue],
  );

  static const double cardRadius = 22;
  static const double tileRadius = 16;
  static const double pillRadius = 999;
  static const double overlap = 36;
  static const double pagePadding = 20;
  static const double sectionGap = 16;

  /// Viewport-anchored hero fill; must cover the scrolling hero plus pull-down.
  static const double heroBackdropHeight = 400;

  /// Body below the status inset for the expanded hero (~330–390 total).
  static const double heroBodyHeight = 310;

  /// Body below the status inset for the compact pinned header (Prashna + bell).
  /// Total collapsed height ≈ topInset + this (~75–90 on typical phones).
  static const double heroCollapsedBodyHeight = 44;

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: ctaDeep.withValues(alpha: 0.10),
      blurRadius: 24,
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
      color: ctaDeep.withValues(alpha: 0.28),
      blurRadius: 14,
      offset: const Offset(0, 7),
    ),
  ];
}
