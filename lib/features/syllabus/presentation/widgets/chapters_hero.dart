import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';

/// Chapters landing hero — curved-bottom purple header with book art.
///
/// Text sizing uses an explicit safe zone (width clear of the illustration,
/// height clear of the bottom curve/overlap) so the subtitle can never be
/// clipped; on very small devices it scales down instead of clipping.
class ChaptersHero extends StatelessWidget {
  const ChaptersHero({super.key, required this.height});

  final double height;

  static const String bookAsset = 'assets/syllabus/chapters_hero_book.png';

  /// Space the caller's overlap eats into the bottom of the hero — text must
  /// stay clear of this zone so it never sits under the content sheet.
  static const double overlapClearance = 40;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topInset = media.viewPadding.top > media.padding.top
        ? media.viewPadding.top
        : media.padding.top;
    final screenW = MediaQuery.sizeOf(context).width;
    final artWidth = (screenW * 0.30).clamp(112.0, 146.0);

    final textTop = topInset + 34.0;
    final maxTextWidth = (screenW - SyllabusVisual.pagePadding - artWidth - 16)
        .clamp(120.0, screenW);
    final maxTextHeight = (height - textTop - overlapClearance).clamp(
      40.0,
      height,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          // Bottom edge is deliberately square: the content sheet's wave
          // clip is what shapes the hero → Available transition, so the
          // gradient must reach both screen edges without a corner notch.
          decoration: const BoxDecoration(
            gradient: SyllabusVisual.headerGradient,
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned.fill(child: _HeroSparkles()),
              Positioned(
                top: topInset + 8,
                right: 16,
                child: const _NotificationBell(),
              ),
              Positioned(
                top: textTop,
                left: SyllabusVisual.pagePadding,
                right: artWidth + 16,
                child: FittedBox(
                  alignment: Alignment.topLeft,
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxTextWidth,
                      maxHeight: maxTextHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Chapters',
                          style: AppTextStyles.headline(context).copyWith(
                            color: SyllabusVisual.headerOn,
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select a course to browse the syllabus.',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: SyllabusVisual.headerOnMuted,
                            fontSize: 14.5,
                            height: 1.32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 16,
                child: Image.asset(
                  bookAsset,
                  width: artWidth,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 22,
          ),
          Positioned(
            top: 6,
            right: 7,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSparkles extends StatelessWidget {
  const _HeroSparkles();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _SparklePainter());
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final soft = Paint()..color = Colors.white.withValues(alpha: 0.55);
    final bright = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final gold = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.9);

    void dot(double x, double y, double r, [Paint? p]) {
      canvas.drawCircle(Offset(size.width * x, size.height * y), r, p ?? soft);
    }

    void sparkle(double x, double y, double r, Paint paint) {
      final c = Offset(size.width * x, size.height * y);
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(path, paint);
    }

    dot(0.08, 0.22, 1.2);
    dot(0.16, 0.38, 1.5);
    dot(0.24, 0.16, 1.1);
    dot(0.42, 0.20, 1.4);
    sparkle(0.12, 0.28, 3.2, bright);
    sparkle(0.70, 0.24, 4.0, gold);
    sparkle(0.86, 0.42, 3.4, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
