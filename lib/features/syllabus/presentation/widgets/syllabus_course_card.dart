import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';

/// Distinct white course card on lavender page — clear elevation + boundary.
class SyllabusCourseCard extends StatelessWidget {
  const SyllabusCourseCard({
    super.key,
    required this.title,
    required this.icon,
    required this.height,
    this.subtitle,
    this.locked = false,
    this.accent = SyllabusVisual.accent,
    this.circleSize = 56,
    this.iconSize = 30,
    this.titleFontSize = 15,
    this.subtitleFontSize = 11,
    this.centerContent = false,
    this.titleColor,
    this.boundaryTint,
    this.elevatedShadow = false,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final double height;
  final String? subtitle;
  final bool locked;
  final Color accent;
  final double circleSize;
  final double iconSize;
  final double titleFontSize;
  final double subtitleFontSize;

  /// When true, icon + title + subtitle are centered as a block in the
  /// vertical middle of the card instead of icon-top/text-bottom.
  final bool centerContent;

  /// Optional override for the title color (defaults to the theme ink).
  final Color? titleColor;

  /// Optional dark-purple tint for the card's border + shadow, so the
  /// boundary reads clearly regardless of the per-card icon accent.
  final Color? boundaryTint;

  /// When true (with [boundaryTint] set), uses a more noticeable, ambient
  /// purple-tinted elevation that softly wraps all four sides of the card
  /// instead of the default bottom-weighted shadow.
  final bool elevatedShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = locked
        ? SyllabusVisual.accent.withValues(alpha: 0.45)
        : accent;
    final ink = locked
        ? SyllabusVisual.ink.withValues(alpha: 0.45)
        : (titleColor ?? SyllabusVisual.ink);
    final boundary = boundaryTint;
    final circleFill = locked
        ? const Color(0xFFE8E4F2)
        : color.withValues(alpha: 0.14);
    final waveColor = locked
        ? const Color(0xFFEDE8F8).withValues(alpha: 0.9)
        : color.withValues(alpha: 0.18);
    final waveHeight = (height * 0.12).clamp(12.0, 20.0);
    final topPad = (height * 0.06).clamp(4.0, 10.0);
    final safeCircle = circleSize.clamp(
      24.0,
      (height * 0.46).clamp(24.0, 96.0),
    );
    final safeIcon = iconSize.clamp(16.0, safeCircle * 0.58);
    const radius = 18.0;

    final card = Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: locked ? const Color(0xFFF7F6FB) : Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: locked
                  ? SyllabusVisual.accent.withValues(alpha: 0.04)
                  : (boundary ?? SyllabusVisual.accent).withValues(
                      // With the ambient elevation doing the work, the rim
                      // stays whisper-light so it never reads as an outline.
                      alpha: boundary == null
                          ? 0.07
                          : (elevatedShadow ? 0.07 : 0.18),
                    ),
            ),
            boxShadow: locked
                ? SyllabusVisual.lockedCardShadow
                : (boundary == null
                      ? SyllabusVisual.clickableCardShadow
                      : (elevatedShadow
                            ? [
                                // Ambient halo — wide and diffuse so it wraps
                                // all four sides without ever reading as an
                                // outline or a solid block behind the card.
                                BoxShadow(
                                  color: boundary.withValues(alpha: 0.15),
                                  blurRadius: 26,
                                  spreadRadius: 2,
                                ),
                                // Grounding lift under the card.
                                BoxShadow(
                                  color: boundary.withValues(alpha: 0.22),
                                  blurRadius: 30,
                                  offset: const Offset(0, 14),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: boundary.withValues(alpha: 0.20),
                                  blurRadius: 18,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 7),
                                ),
                                BoxShadow(
                                  color: boundary.withValues(alpha: 0.10),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ])),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: waveHeight,
                  child: CustomPaint(
                    painter: _CardWavePainter(color: waveColor),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    centerContent ? 12 : 8,
                    centerContent ? 10 : topPad,
                    centerContent ? 12 : 8,
                    centerContent ? 10 : 4,
                  ),
                  child: Column(
                    mainAxisAlignment: centerContent
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: safeCircle,
                        height: safeCircle,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: circleFill,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              locked ? Icons.lock_rounded : icon,
                              color: color,
                              size: safeIcon,
                            ),
                          ),
                        ),
                      ),
                      if (centerContent)
                        SizedBox(height: (height * 0.08).clamp(14.0, 22.0))
                      else
                        const Spacer(flex: 1),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium(context).copyWith(
                          color: ink,
                          fontWeight: centerContent
                              ? FontWeight.w900
                              : FontWeight.w800,
                          fontSize: titleFontSize,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: centerContent ? 8 : 2),
                      Text(
                        subtitle ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          color: locked
                              ? SyllabusVisual.accent.withValues(alpha: 0.45)
                              : SyllabusVisual.muted,
                          fontWeight: locked
                              ? FontWeight.w600
                              : FontWeight.w700,
                          fontSize: subtitleFontSize,
                        ),
                      ),
                      if (!centerContent)
                        SizedBox(height: (waveHeight * 0.22).clamp(2.0, 6.0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!locked) return card;
    return IgnorePointer(child: Opacity(opacity: 0.72, child: card));
  }
}

class _CardWavePainter extends CustomPainter {
  const _CardWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.08,
        size.width * 0.5,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.88,
        size.width,
        size.height * 0.4,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CardWavePainter oldDelegate) =>
      oldDelegate.color != color;
}
