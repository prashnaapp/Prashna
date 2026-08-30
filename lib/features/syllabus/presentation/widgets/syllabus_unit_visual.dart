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
    this.cardTitle,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  /// Optional Syllabus Browser card label. Canonical [displayName] is unchanged.
  final String? cardTitle;
}

/// Resolves a meaningful illustration per unit without inventing syllabus data.
abstract final class SyllabusUnitVisualCatalog {
  static const _amberFg = Color(0xFFC47A1A);
  static const _pinkFg = Color(0xFFC44B7A);

  static SyllabusUnitVisual resolve({
    required String unitId,
    required String displayName,
    required int index,
  }) {
    final byId = _byUnitId[unitId];
    final byKeyword = byId == null ? _fromKeywords(displayName) : null;
    final base = byId ?? byKeyword ?? _fallback(index);
    final cardTitle = _cardTitles[unitId];
    if (cardTitle == null) return base;
    return SyllabusUnitVisual(
      icon: base.icon,
      background: base.background,
      foreground: base.foreground,
      cardTitle: cardTitle,
    );
  }

  static SyllabusUnitVisual? _fromKeywords(String raw) {
    final text = raw.toLowerCase();

    for (final rule in _rules) {
      if (_matches(text, rule.needles)) {
        return SyllabusUnitVisual(
          icon: rule.icon,
          background: rule.background,
          foreground: rule.foreground,
        );
      }
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

  static const _rules = <_VisualRule>[
    _VisualRule(
      needles: ['current affairs'],
      icon: Icons.public_rounded,
      background: SyllabusVisual.tileLavender,
      foreground: AppColors.primaryStrong,
    ),
    _VisualRule(
      needles: ['international relation', 'international events'],
      icon: Icons.handshake_rounded,
      background: SyllabusVisual.tileBlue,
      foreground: AppColors.accent,
    ),
    _VisualRule(
      needles: ['science', 'technology'],
      icon: Icons.science_rounded,
      background: SyllabusVisual.tileTeal,
      foreground: AppColors.accentTeal,
    ),
    _VisualRule(
      needles: ['environment', 'disaster', 'environmental'],
      icon: Icons.eco_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
    ),
    _VisualRule(
      needles: ['geography'],
      icon: Icons.terrain_rounded,
      background: SyllabusVisual.tileTeal,
      foreground: AppColors.accentTeal,
    ),
    _VisualRule(
      needles: [
        'telangana society',
        'society, culture, heritage',
        'arts and literature of telangana',
      ],
      icon: Icons.map_rounded,
      background: SyllabusVisual.tileLavender,
      foreground: AppColors.primaryStrong,
    ),
    _VisualRule(
      needles: ['indian history', 'history and cultural heritage', 'heritage'],
      icon: Icons.account_balance_rounded,
      background: SyllabusVisual.tilePink,
      foreground: AppColors.accentPink,
    ),
    _VisualRule(
      needles: ['kakatiya', 'warangal', 'fort', 'medieval telangana'],
      icon: Icons.castle_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
    ),
    _VisualRule(
      needles: ['vijayanagara'],
      icon: Icons.workspace_premium_rounded,
      background: SyllabusVisual.tilePink,
      foreground: _pinkFg,
    ),
    _VisualRule(
      needles: ['bahmani', 'bahamani'],
      icon: Icons.emoji_events_rounded,
      background: SyllabusVisual.tileLavender,
      foreground: AppColors.primaryStrong,
    ),
    _VisualRule(
      needles: ['qutb', 'qutub', 'golconda', 'dome', 'mosque'],
      icon: Icons.mosque_rounded,
      background: SyllabusVisual.tileTeal,
      foreground: AppColors.accentTeal,
    ),
    _VisualRule(
      needles: ['asaf', 'nizam', 'gateway', 'charminar'],
      icon: Icons.account_balance_rounded,
      background: SyllabusVisual.tileBlue,
      foreground: AppColors.accent,
    ),
    _VisualRule(
      needles: [
        'satavahana',
        'ikshvaku',
        'chalukya',
        'ancient telangana',
        'ancient india',
        'dynasty',
      ],
      icon: Icons.temple_hindu_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
    ),
    _VisualRule(
      needles: [
        'constitution',
        'fundamental right',
        'federal',
        'amendment',
        'judici',
        'electoral',
        'governance',
      ],
      icon: Icons.gavel_rounded,
      background: SyllabusVisual.tileBlue,
      foreground: AppColors.accent,
    ),
    _VisualRule(
      needles: ['hrd'],
      icon: Icons.school_rounded,
      background: SyllabusVisual.tileLavender,
      foreground: AppColors.primaryStrong,
    ),
    _VisualRule(
      needles: ['demography'],
      icon: Icons.people_alt_rounded,
      background: SyllabusVisual.tileLavender,
      foreground: AppColors.primaryStrong,
    ),
    _VisualRule(
      needles: ['national income'],
      icon: Icons.payments_rounded,
      background: SyllabusVisual.tileBlue,
      foreground: AppColors.accent,
    ),
    _VisualRule(
      needles: ['primary and secondary'],
      icon: Icons.agriculture_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
    ),
    _VisualRule(
      needles: ['agriculture'],
      icon: Icons.grass_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
    ),
    _VisualRule(
      needles: ['industry and service', 'industry and services'],
      icon: Icons.precision_manufacturing_rounded,
      background: SyllabusVisual.tileTeal,
      foreground: AppColors.accentTeal,
    ),
    _VisualRule(
      needles: [
        'planning',
        'niti',
        'public finance',
        'state finances',
        'budget',
      ],
      icon: Icons.account_balance_wallet_rounded,
      background: SyllabusVisual.tilePink,
      foreground: AppColors.accentPink,
    ),
    _VisualRule(
      needles: ['poverty', 'unemployment'],
      icon: Icons.support_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
    ),
    _VisualRule(
      needles: ['regional inequalit'],
      icon: Icons.location_city_rounded,
      background: SyllabusVisual.tileBlue,
      foreground: AppColors.accent,
    ),
    _VisualRule(
      needles: ['social development'],
      icon: Icons.diversity_3_rounded,
      background: SyllabusVisual.tilePink,
      foreground: AppColors.accentPink,
    ),
    _VisualRule(
      needles: ['growth and development'],
      icon: Icons.insights_rounded,
      background: SyllabusVisual.tileLavender,
      foreground: AppColors.primaryStrong,
    ),
    _VisualRule(
      needles: ['economy', 'industry', 'finance'],
      icon: Icons.domain_rounded,
      background: SyllabusVisual.tileBlue,
      foreground: AppColors.accent,
    ),
    _VisualRule(
      needles: ['english', 'language', 'literature'],
      icon: Icons.translate_rounded,
      background: SyllabusVisual.tileLavender,
      foreground: AppColors.primaryStrong,
    ),
    _VisualRule(
      needles: ['reason', 'data', 'logic', 'analytical'],
      icon: Icons.psychology_alt_rounded,
      background: SyllabusVisual.tileTeal,
      foreground: AppColors.accentTeal,
    ),
    _VisualRule(
      needles: ['social exclusion', 'inclusion', 'inclusive', 'rights issues'],
      icon: Icons.diversity_3_rounded,
      background: SyllabusVisual.tilePink,
      foreground: AppColors.accentPink,
    ),
    _VisualRule(
      needles: ['policy', 'policies'],
      icon: Icons.policy_rounded,
      background: SyllabusVisual.tilePink,
      foreground: AppColors.accentPink,
    ),
    _VisualRule(
      needles: ['formation', 'integration', 'telangana state', 'movement'],
      icon: Icons.flag_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
    ),
    _VisualRule(
      needles: ['history'],
      icon: Icons.history_edu_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
    ),
    _VisualRule(
      needles: [
        'society',
        'social',
        'awakening',
        'culture',
        'women',
        'fairs',
        'festivals',
      ],
      icon: Icons.groups_rounded,
      background: SyllabusVisual.tilePink,
      foreground: AppColors.accentPink,
    ),
  ];

  /// Explicit overrides for known canonical unit IDs.
  static final Map<String, SyllabusUnitVisual> _byUnitId = {
    'group-iii-paper-ii-part-i-unit-01': const SyllabusUnitVisual(
      icon: Icons.temple_hindu_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
    ),
    'group-iii-paper-ii-part-i-unit-02': const SyllabusUnitVisual(
      icon: Icons.castle_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
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
      foreground: _amberFg,
    ),
    'group-ii-paper-iii-part-01-topic-01': const SyllabusUnitVisual(
      icon: Icons.people_alt_rounded,
      background: SyllabusVisual.tileLavender,
      foreground: AppColors.primaryStrong,
    ),
    'group-ii-paper-iii-part-01-topic-02': const SyllabusUnitVisual(
      icon: Icons.payments_rounded,
      background: SyllabusVisual.tileBlue,
      foreground: AppColors.accent,
    ),
    'group-ii-paper-iii-part-01-topic-03': const SyllabusUnitVisual(
      icon: Icons.agriculture_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
    ),
    'group-ii-paper-iii-part-01-topic-04': const SyllabusUnitVisual(
      icon: Icons.precision_manufacturing_rounded,
      background: SyllabusVisual.tileTeal,
      foreground: AppColors.accentTeal,
    ),
    'group-ii-paper-iii-part-01-topic-05': const SyllabusUnitVisual(
      icon: Icons.account_balance_wallet_rounded,
      background: SyllabusVisual.tilePink,
      foreground: AppColors.accentPink,
    ),
    'group-ii-paper-iii-part-02-topic-01': const SyllabusUnitVisual(
      icon: Icons.domain_rounded,
      background: SyllabusVisual.tileBlue,
      foreground: AppColors.accent,
    ),
    'group-ii-paper-iii-part-02-topic-02': const SyllabusUnitVisual(
      icon: Icons.school_rounded,
      background: SyllabusVisual.tileLavender,
      foreground: AppColors.primaryStrong,
    ),
    'group-ii-paper-iii-part-02-topic-03': const SyllabusUnitVisual(
      icon: Icons.grass_rounded,
      background: SyllabusVisual.tileTeal,
      foreground: AppColors.accentTeal,
    ),
    'group-ii-paper-iii-part-02-topic-04': const SyllabusUnitVisual(
      icon: Icons.business_center_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
    ),
    'group-ii-paper-iii-part-02-topic-05': const SyllabusUnitVisual(
      icon: Icons.volunteer_activism_rounded,
      background: SyllabusVisual.tilePink,
      foreground: AppColors.accentPink,
    ),
    'group-ii-paper-iii-part-03-topic-01': const SyllabusUnitVisual(
      icon: Icons.insights_rounded,
      background: SyllabusVisual.tileLavender,
      foreground: AppColors.primaryStrong,
    ),
    'group-ii-paper-iii-part-03-topic-02': const SyllabusUnitVisual(
      icon: Icons.diversity_3_rounded,
      background: SyllabusVisual.tilePink,
      foreground: AppColors.accentPink,
    ),
    'group-ii-paper-iii-part-03-topic-03': const SyllabusUnitVisual(
      icon: Icons.support_rounded,
      background: SyllabusVisual.tileAmber,
      foreground: _amberFg,
    ),
    'group-ii-paper-iii-part-03-topic-04': const SyllabusUnitVisual(
      icon: Icons.location_city_rounded,
      background: SyllabusVisual.tileBlue,
      foreground: AppColors.accent,
    ),
    'group-ii-paper-iii-part-03-topic-05': const SyllabusUnitVisual(
      icon: Icons.eco_rounded,
      background: SyllabusVisual.tileTeal,
      foreground: AppColors.accentTeal,
    ),
  };

  /// Presentation-only card labels keyed by stable unit ID.
  static const _cardTitles = <String, String>{
    'group-iii-paper-i-unit-01': 'Current Affairs',
    'group-iii-paper-i-unit-02': 'International Relations',
    'group-iii-paper-i-unit-03': 'General Science and Technology',
    'group-iii-paper-i-unit-04': 'Environment and Disaster Management',
    'group-iii-paper-i-unit-05': 'Geography',
    'group-iii-paper-i-unit-06': 'Indian History and Heritage',
    'group-iii-paper-i-unit-07': 'Telangana Society and Culture',
  };
}

class _VisualRule {
  const _VisualRule({
    required this.needles,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final List<String> needles;
  final IconData icon;
  final Color background;
  final Color foreground;
}
