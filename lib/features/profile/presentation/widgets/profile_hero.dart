import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';
import '../../../syllabus/presentation/widgets/landing_sheet.dart';

/// Profile tab hero — purple header the content sheet waves into.
///
/// The bottom edge is square: [LandingSheet]'s wave clip shapes the
/// transition, so the gradient must reach both screen edges without a corner
/// notch. Text keeps clear of [overlapClearance] so the sheet can never clip
/// the subtitle, and scales down instead of clipping on very small phones.
class ProfileHero extends StatelessWidget {
  const ProfileHero({super.key, required this.height});

  final double height;

  /// Space at the bottom of the hero the sheet's wave can occupy.
  static const double overlapClearance = LandingSheet.heroOverlap + 8;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topInset = media.viewPadding.top > media.padding.top
        ? media.viewPadding.top
        : media.padding.top;
    final screenW = MediaQuery.sizeOf(context).width;
    final artWidth = (screenW * 0.30).clamp(108.0, 132.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: SyllabusVisual.headerGradient,
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned.fill(child: _HeroSparkles()),
              Positioned(
                right: 14,
                bottom: 26,
                width: artWidth,
                height: artWidth * 0.98,
                child: const _ProfileCardArt(),
              ),
              Positioned(
                top: topInset + 8,
                right: 16,
                child: const _NotificationBell(),
              ),
              Positioned(
                top: topInset + 34,
                left: SyllabusVisual.pagePadding,
                right: artWidth + 24,
                bottom: overlapClearance,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FittedBox(
                    alignment: Alignment.topLeft,
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            (screenW -
                                    SyllabusVisual.pagePadding -
                                    artWidth -
                                    24)
                                .clamp(120.0, screenW),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Profile',
                            style: AppTextStyles.headline(context).copyWith(
                              color: SyllabusVisual.headerOn,
                              fontWeight: FontWeight.w800,
                              fontSize: 30,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage your account and preferences.',
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: SyllabusVisual.headerOnMuted,
                              fontSize: 14.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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

/// ID card with an account glyph — same painted-illustration style as the
/// other hero widgets, so no new asset is introduced.
class _ProfileCardArt extends StatelessWidget {
  const _ProfileCardArt();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _ProfileCardPainter());
  }
}

class _ProfileCardPainter extends CustomPainter {
  const _ProfileCardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.90),
        width: w * 0.86,
        height: h * 0.20,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );

    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.10, w * 0.68, h * 0.72),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      card,
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final glyph = Paint()..color = const Color(0xFFD9D2FF);
    canvas.drawCircle(Offset(w * 0.50, h * 0.33), w * 0.10, glyph);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.50),
          width: w * 0.30,
          height: h * 0.13,
        ),
        Radius.circular(w * 0.07),
      ),
      glyph,
    );

    final line = Paint()..color = Colors.white.withValues(alpha: 0.65);
    for (var i = 0; i < 2; i++) {
      final y = h * (0.63 + i * 0.09);
      final inset = i == 0 ? 0.26 : 0.32;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * inset, y, w * (1 - inset * 2), h * 0.045),
          const Radius.circular(4),
        ),
        line,
      );
    }

    final gold = Paint()..color = const Color(0xFFFFC94D);
    final teal = Paint()..color = const Color(0xFF35C6A8);
    void spark(double x, double y, double s, Paint paint) {
      final c = Offset(w * x, h * y);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - s)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + s, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s)
          ..quadraticBezierTo(c.dx, c.dy, c.dx - s, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s)
          ..close(),
        paint,
      );
    }

    spark(0.02, 0.30, 6, gold);
    spark(0.96, 0.36, 5, teal);
    spark(0.92, 0.62, 6, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    final soft = Paint()..color = Colors.white.withValues(alpha: 0.45);
    final bright = Paint()..color = Colors.white.withValues(alpha: 0.8);

    void dot(double x, double y, double r, Paint paint) {
      canvas.drawCircle(Offset(size.width * x, size.height * y), r, paint);
    }

    for (final e in const [
      (0.10, 0.26, 1.2),
      (0.24, 0.44, 1.0),
      (0.40, 0.20, 1.4),
      (0.55, 0.60, 1.1),
    ]) {
      dot(e.$1, e.$2, e.$3, e.$3 > 1.3 ? bright : soft);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
