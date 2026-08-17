import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';

/// Presentation-only visual identity for one syllabus unit.
///
/// Never changes unit data — only maps id/title → icon + colors.
class SyllabusUnitVisual {
  const SyllabusUnitVisual({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}

/// Resolves a meaningful illustration per unit without inventing syllabus data.
abstract final class SyllabusUnitVisualCatalog {
  static SyllabusUnitVisual resolve({
    required String unitId,
    required String displayName,
    required int index,
  }) {
    final byId = _byUnitId[unitId];
    if (byId != null) return byId;

    final byKeyword = _fromKeywords(displayName);
    if (byKeyword != null) return byKeyword;

    return _fallback(index);
  }

  static SyllabusUnitVisual? _fromKeywords(String raw) {
    final text = raw.toLowerCase();

    if (_matches(text, const [
      'kakatiya',
      'warangal',
      'fort',
      'medieval telangana',
    ])) {
      return const SyllabusUnitVisual(
        icon: Icons.castle_rounded,
        background: SyllabusVisual.tileAmber,
        foreground: Color(0xFFC47A1A),
      );
    }
    if (_matches(text, const ['vijayanagara'])) {
      return const SyllabusUnitVisual(
        icon: Icons.workspace_premium_rounded,
        background: SyllabusVisual.tilePink,
        foreground: Color(0xFFC44B7A),
      );
    }
    if (_matches(text, const ['bahmani', 'bahamani'])) {
      return const SyllabusUnitVisual(
        icon: Icons.emoji_events_rounded,
        background: SyllabusVisual.tileLavender,
        foreground: AppColors.primaryStrong,
      );
    }
    if (_matches(text, const ['qutb', 'qutub', 'golconda', 'dome', 'mosque'])) {
      return const SyllabusUnitVisual(
        icon: Icons.mosque_rounded,
        background: SyllabusVisual.tileTeal,
        foreground: AppColors.accentTeal,
      );
    }
    if (_matches(text, const ['asaf', 'nizam', 'gateway', 'charminar'])) {
      return const SyllabusUnitVisual(
        icon: Icons.account_balance_rounded,
        background: SyllabusVisual.tileBlue,
        foreground: AppColors.accent,
      );
    }
    if (_matches(text, const [
      'satavahana',
      'ikshvaku',
      'chalukya',
      'ancient',
      'dynasty',
    ])) {
      return const SyllabusUnitVisual(
        icon: Icons.temple_hindu_rounded,
        background: SyllabusVisual.tileAmber,
        foreground: Color(0xFFC47A1A),
      );
    }
    if (_matches(text, const [
      'constitution',
      'fundamental right',
      'federal',
      'amendment',
      'judici',
      'electoral',
      'governance',
    ])) {
      return const SyllabusUnitVisual(
        icon: Icons.gavel_rounded,
        background: SyllabusVisual.tileBlue,
        foreground: AppColors.accent,
      );
    }
    if (_matches(text, const [
      'economy',
      'agriculture',
      'industry',
      'finance',
      'development',
    ])) {
      return const SyllabusUnitVisual(
        icon: Icons.trending_up_rounded,
        background: SyllabusVisual.tileTeal,
        foreground: AppColors.accentTeal,
      );
    }
    if (_matches(text, const [
      'science',
      'environment',
      'geography',
      'disaster',
    ])) {
      return const SyllabusUnitVisual(
        icon: Icons.science_rounded,
        background: SyllabusVisual.tileLavender,
        foreground: AppColors.primaryStrong,
      );
    }
    if (_matches(text, const [
      'current affairs',
      'international',
      'relation',
    ])) {
      return const SyllabusUnitVisual(
        icon: Icons.public_rounded,
        background: SyllabusVisual.tileBlue,
        foreground: AppColors.accent,
      );
    }
    if (_matches(text, const [
      'society',
      'social',
      'awakening',
      'movement',
      'culture',
      'heritage',
    ])) {
      return const SyllabusUnitVisual(
        icon: Icons.groups_rounded,
        background: SyllabusVisual.tilePink,
        foreground: AppColors.accentPink,
      );
    }
    if (_matches(text, const ['english', 'language', 'literature'])) {
      return const SyllabusUnitVisual(
        icon: Icons.translate_rounded,
        background: SyllabusVisual.tileLavender,
        foreground: AppColors.primaryStrong,
      );
    }
    if (_matches(text, const ['reason', 'data', 'logic'])) {
      return const SyllabusUnitVisual(
        icon: Icons.psychology_alt_rounded,
        background: SyllabusVisual.tileTeal,
        foreground: AppColors.accentTeal,
      );
    }
    if (_matches(text, const ['policy', 'policies', 'rights', 'inclusion'])) {
      return const SyllabusUnitVisual(
        icon: Icons.policy_rounded,
        background: SyllabusVisual.tilePink,
        foreground: AppColors.accentPink,
      );
    }
    if (_matches(text, const ['formation', 'integration', 'telangana state'])) {
      return const SyllabusUnitVisual(
        icon: Icons.flag_rounded,
        background: SyllabusVisual.tileAmber,
        foreground: Color(0xFFC47A1A),
      );
    }
    if (_matches(text, const ['history', 'heritage'])) {
      return const SyllabusUnitVisual(
        icon: Icons.history_edu_rounded,
        background: SyllabusVisual.tileAmber,
        foreground: Color(0xFFC47A1A),
      );
    }

    return null;
  }

  static bool _matches(String text, List<String> needles) {
    for (final needle in needles) {
      if (text.contains(needle)) return true;
    }
    return false;
  }

  static SyllabusUnitVisual _fallback(int index) {
    const icons = <IconData>[
      Icons.account_balance_rounded,
      Icons.castle_rounded,
      Icons.temple_hindu_rounded,
      Icons.mosque_rounded,
      Icons.landscape_rounded,
      Icons.public_rounded,
      Icons.gavel_rounded,
      Icons.science_rounded,
      Icons.groups_rounded,
      Icons.flag_rounded,
    ];
    return SyllabusUnitVisual(
      icon: icons[index.abs() % icons.length],
      background: SyllabusVisual.pastelAt(index),
      foreground: SyllabusVisual.iconAt(index),
    );
  }

  /// Explicit overrides for known canonical unit IDs.
  static final Map<String, SyllabusUnitVisual> _byUnitId = {
    'group-iii-paper-ii-part-i-unit-01': const SyllabusUnitVisual(
      icon: Icons.temple_hindu_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: Color(0xFFC47A1A),
    ),
    'group-iii-paper-ii-part-i-unit-02': const SyllabusUnitVisual(
      icon: Icons.castle_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: Color(0xFFC47A1A),
    ),
    'group-iii-paper-ii-part-i-unit-03': const SyllabusUnitVisual(
      icon: Icons.account_balance_rounded,
      background: SyllabusVisual.tileBlue,
      foreground: AppColors.accent,
    ),
    'group-iii-paper-ii-part-i-unit-04': const SyllabusUnitVisual(
      icon: Icons.groups_rounded,
      background: SyllabusVisual.tilePink,
      foreground: AppColors.accentPink,
    ),
    'group-iii-paper-ii-part-i-unit-05': const SyllabusUnitVisual(
      icon: Icons.flag_rounded,
      background: SyllabusVisual.tileLavender,
      foreground: AppColors.primaryStrong,
    ),
    'group-ii-paper-ii-part-01-topic-04': const SyllabusUnitVisual(
      icon: Icons.castle_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: Color(0xFFC47A1A),
    ),
  };
}
