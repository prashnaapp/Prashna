import 'widgets/landing_sheet.dart';

/// Geometry for the "Available" (Group-II / Group-III) cards on the Chapters
/// and Test Series landings.
///
/// Both tabs must render an identical card, so the sizing lives here instead of
/// in either screen. It is anchored to the viewport left over above the bottom
/// navigation — not to each screen's own remaining space — because the two
/// heroes differ in height and would otherwise yield different cards.
class AvailableCardMetrics {
  const AvailableCardMetrics._({
    required this.width,
    required this.height,
    required this.circleSize,
    required this.iconSize,
    required this.titleFontSize,
    required this.subtitleFontSize,
  });

  /// Gap between the two side-by-side cards.
  static const double gap = 14;

  /// Compact envelope (40% of the sheet), bumped 15% and then a further 17%.
  static const double _sizeBump = 1.15 * 1.17;
  static const double _heightFactor = 0.40 * _sizeBump;
  static const double _minHeight = 147;

  // Anchor proportions of the Chapters landing, which the card sizing was
  // tuned against: hero share and the chrome above/below the cards.
  static const double _anchorHeroShare = 0.33;
  static const double _anchorHeroMin = 224;
  static const double _anchorHeroMax = 290;
  static const double _anchorChrome = 128;

  /// [contentWidth] is the sheet width inside its page padding, [contentHeight]
  /// the viewport height above the bottom navigation, and [maxHeight] the space
  /// the calling screen can actually give the cards.
  factory AvailableCardMetrics.forViewport({
    required double contentWidth,
    required double contentHeight,
    required double maxHeight,
  }) {
    final anchorHero = (contentHeight * _anchorHeroShare).clamp(
      _anchorHeroMin,
      _anchorHeroMax,
    );
    final anchorSheet = contentHeight - anchorHero + LandingSheet.heroOverlap;
    final envelope = (anchorSheet - _anchorChrome).clamp(180.0, 470.0);
    final cap = maxHeight > _minHeight ? maxHeight : _minHeight;
    final height = (envelope * _heightFactor).clamp(_minHeight, cap);
    final circleSize = (height * 0.34).clamp(
      44.0 * _sizeBump,
      69.0 * _sizeBump,
    );

    return AvailableCardMetrics._(
      // Two equal cards flush with the page margins, matching the reference.
      width: (contentWidth - gap) / 2,
      height: height,
      circleSize: circleSize,
      iconSize: (circleSize * 0.55).clamp(23.0 * _sizeBump, 35.0 * _sizeBump),
      titleFontSize: 16 * _sizeBump,
      subtitleFontSize: 11.5 * _sizeBump,
    );
  }

  final double width;
  final double height;
  final double circleSize;
  final double iconSize;
  final double titleFontSize;
  final double subtitleFontSize;
}
