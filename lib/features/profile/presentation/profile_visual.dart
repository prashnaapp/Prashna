import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../syllabus/presentation/syllabus_visual.dart';

/// Visual tokens for the Profile tab.
///
/// Mirrors the Chapters / Test Series / Progress language — purple hero,
/// lavender page, white rows lifted by a soft purple-tinted shadow — so the
/// tab reads as the same app. Layout stays in the widgets; only shared colour,
/// radius, and elevation live here.
abstract final class ProfileVisual {
  static const Color page = SyllabusVisual.page;
  static const Color ink = Color(0xFF130F2B);
  static const Color accent = SyllabusVisual.accent;
  static const Color muted = SyllabusVisual.muted;

  /// Tint every Profile shadow shares.
  static const Color shadowTint = Color(0xFF4A3AB0);

  static const double pagePadding = SyllabusVisual.pagePadding;
  static const double cardRadius = 18;

  /// Rows are many and stacked, so their lift stays light.
  static List<BoxShadow> get rowShadow => [
    BoxShadow(
      color: shadowTint.withValues(alpha: 0.07),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// The account card is the one hero element on the sheet.
  static List<BoxShadow> get accountShadow => [
    BoxShadow(
      color: shadowTint.withValues(alpha: 0.22),
      blurRadius: 26,
      offset: const Offset(0, 12),
    ),
  ];

  static Border get rowBorder =>
      Border.all(color: shadowTint.withValues(alpha: 0.07));

  static TextStyle sectionTitle(BuildContext context) =>
      AppTextStyles.titleMedium(context).copyWith(
        color: SyllabusVisual.ink,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      );
}
