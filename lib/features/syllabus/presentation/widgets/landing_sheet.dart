import 'package:flutter/material.dart';

import '../syllabus_visual.dart';

/// The light content sheet that a landing hero flows into.
///
/// Its top edge is a smooth wave rather than a plain rounded corner, so the
/// purple hero and the content below read as one continuous designed section.
/// Shared by the Chapters and Test Series landings so both tabs transition
/// identically.
///
/// Place it in a [Stack] under the hero, offset by [heroOverlap]:
///
/// ```dart
/// Positioned(
///   top: heroHeight - LandingSheet.heroOverlap,
///   left: 0,
///   right: 0,
///   bottom: bottomInset,
///   child: LandingSheet(child: ...),
/// )
/// ```
class LandingSheet extends StatelessWidget {
  const LandingSheet({
    super.key,
    required this.child,
    this.expand = false,
    this.padding,
  });

  /// How far the sheet's top edge rides up into the hero. The wave is shaped
  /// to stay within this band, so it always sits on the hero gradient.
  static const double heroOverlap = 36;

  /// Clearance the sheet's own padding puts between the wave's lowest point
  /// and the first line of content, so content never sits on the hero.
  static const double topPad = _WaveTopClipper.troughDepth + 18;

  final Widget child;

  /// When true, the sheet fills its parent's height so a [Column] with a
  /// [Spacer] can absorb leftover space instead of overflowing.
  final bool expand;

  /// Override the default inset. A scrolling child should pass
  /// [EdgeInsets.zero] and apply [topPad] itself, so its content scrolls up to
  /// the wave and is clipped by it instead of vanishing at a padding edge.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _WaveTopClipper(),
      child: Container(
        width: double.infinity,
        height: expand ? double.infinity : null,
        color: SyllabusVisual.page,
        padding:
            padding ??
            const EdgeInsets.fromLTRB(
              SyllabusVisual.pagePadding,
              topPad,
              SyllabusVisual.pagePadding,
              0,
            ),
        child: child,
      ),
    );
  }
}

/// Shapes the sheet's top edge into a smooth, wide wave: a long rise into a
/// broad crest left of centre, then a gentle fall into a shallow trough on the
/// right, with both ends rounded into the screen edges.
class _WaveTopClipper extends CustomClipper<Path> {
  const _WaveTopClipper();

  /// Depth where the wave leaves the left screen edge.
  static const double leftInset = 22;

  /// Lowest point of the wave — content must clear this.
  static const double troughDepth = 24;

  /// Crest height: how far the sheet climbs into the hero at its highest.
  static const double crestDepth = 2;

  /// Corner rounding where the wave meets the screen edges.
  static const double endRadius = 12;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    // Every join below is tangent-continuous — each curve leaves and arrives
    // horizontally — so the wave reads as one smooth sine-like sweep with no
    // kink at the crest, the trough, or the corners.
    return Path()
      ..moveTo(0, leftInset + endRadius)
      ..quadraticBezierTo(0, leftInset, endRadius, leftInset)
      ..cubicTo(w * 0.10, leftInset, w * 0.24, crestDepth, w * 0.42, crestDepth)
      ..cubicTo(
        w * 0.60,
        crestDepth,
        w * 0.74,
        troughDepth,
        w * 0.88,
        troughDepth,
      )
      ..lineTo(w - endRadius, troughDepth)
      ..quadraticBezierTo(w, troughDepth, w, troughDepth + endRadius)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
