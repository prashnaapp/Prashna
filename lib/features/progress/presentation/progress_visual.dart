import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../syllabus/presentation/syllabus_visual.dart';

/// Visual tokens for the Progress tab.
///
/// Deliberately mirrors the Chapters / Test Series language — purple hero,
/// lavender page, white cards lifted by a soft purple-tinted shadow — so the
/// tab reads as the same app. Layout values stay in the widgets; only shared
/// colour, radius, and elevation live here.
abstract final class ProgressVisual {
  static const Color page = SyllabusVisual.page;
  static const Color ink = Color(0xFF130F2B);
  static const Color accent = SyllabusVisual.accent;
  static const Color muted = SyllabusVisual.muted;

  /// Tint every Progress shadow shares, matching the Available cards.
  static const Color shadowTint = Color(0xFF4A3AB0);

  static const double pagePadding = SyllabusVisual.pagePadding;
  static const double cardRadius = 20;
  static const double statRadius = 16;

  /// Feature cards (Revision Center, course rows): clear but soft lift.
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: shadowTint.withValues(alpha: 0.10),
      blurRadius: 22,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: shadowTint.withValues(alpha: 0.14),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  /// Statistic tiles and the analytics button: quieter, so the dense grid
  /// does not read as six heavy feature cards.
  static List<BoxShadow> get statShadow => [
    BoxShadow(
      color: shadowTint.withValues(alpha: 0.08),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static Border get cardBorder =>
      Border.all(color: shadowTint.withValues(alpha: 0.07));

  static TextStyle sectionTitle(BuildContext context) =>
      AppTextStyles.titleMedium(context).copyWith(
        color: SyllabusVisual.ink,
        fontWeight: FontWeight.w800,
        fontSize: 17,
      );
}
