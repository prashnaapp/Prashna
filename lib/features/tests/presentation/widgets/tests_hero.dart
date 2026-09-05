import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';
import '../../../syllabus/presentation/widgets/landing_sheet.dart';

/// Test Series landing hero — purple header the content sheet waves into.
///
/// The bottom edge is square: [LandingSheet]'s wave clip shapes the
/// transition, so the gradient must reach both screen edges without a corner
/// notch. The title keeps clear of [overlapClearance] so the sheet cannot
/// clip it.
class TestsHero extends StatelessWidget {
  const TestsHero({super.key, required this.height});

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
    final artWidth = (screenW * 0.36).clamp(128.0, 160.0);

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
                right: 8,
                bottom: 24,
                width: artWidth,
                height: artWidth * 0.92,
                child: const _ClipboardStopwatchArt(),
              ),
              Positioned(
                top: topInset + 34,
                left: SyllabusVisual.pagePadding,
                right: artWidth + 12,
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
                                    12)
                                .clamp(120.0, screenW),
                      ),
                      child: Text(
                        'Test Series',
                        style: AppTextStyles.headline(context).copyWith(
                          color: SyllabusVisual.headerOn,
                          fontWeight: FontWeight.w800,
                          fontSize: 30,
                          height: 1.1,
                        ),
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

class _ClipboardStopwatchArt extends StatelessWidget {
  const _ClipboardStopwatchArt();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _ClipboardStopwatchPainter());
  }
}

class _ClipboardStopwatchPainter extends CustomPainter {
  const _ClipboardStopwatchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.48, h * 0.88),
        width: w * 0.78,
        height: h * 0.22,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );

    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.12, w * 0.52, h * 0.72),
      const Radius.circular(14),
    );
    canvas.drawRRect(board, Paint()..color = const Color(0xFFB8A8FF));
    canvas.drawRRect(
      board,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final paper = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.40, h * 0.55),
      const Radius.circular(8),
    );
    canvas.drawRRect(paper, Paint()..color = Colors.white);

    final checkStroke = Paint()
      ..color = const Color(0xFF5B8CFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePaint = Paint()
      ..color = const Color(0xFFE8E4F8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = h * (0.34 + i * 0.14);
      final box = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.26, y),
          width: w * 0.07,
          height: w * 0.07,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(box, Paint()..color = const Color(0xFFEEF2FF));
      final path = Path()
        ..moveTo(w * 0.235, y)
        ..lineTo(w * 0.255, y + h * 0.02)
        ..lineTo(w * 0.285, y - h * 0.022);
      canvas.drawPath(path, checkStroke);
      canvas.drawLine(Offset(w * 0.34, y), Offset(w * 0.52, y), linePaint);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.38, h * 0.14),
          width: w * 0.22,
          height: h * 0.08,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF7B6CFF),
    );

    final clockCenter = Offset(w * 0.72, h * 0.62);
    final clockR = w * 0.18;
    canvas.drawCircle(
      clockCenter,
      clockR + 4,
      Paint()..color = const Color(0xFF6A4CFF),
    );
    canvas.drawCircle(clockCenter, clockR, Paint()..color = Colors.white);
    canvas.drawCircle(
      clockCenter,
      clockR * 0.12,
      Paint()..color = const Color(0xFF4A3AC8),
    );
    final hand = Paint()
      ..color = const Color(0xFF4A3AC8)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(clockCenter, clockCenter + Offset(0, -clockR * 0.55), hand);
    canvas.drawLine(
      clockCenter,
      clockCenter + Offset(clockR * 0.42, clockR * 0.12),
      hand,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(clockCenter.dx, clockCenter.dy - clockR - 6),
          width: 10,
          height: 8,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF6A4CFF),
    );

    final star = Paint()..color = const Color(0xFFFFE082);
    void spark(double x, double y, double s) {
      final c = Offset(w * x, h * y);
      final path = Path()
        ..moveTo(c.dx, c.dy - s)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + s, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - s, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s)
        ..close();
      canvas.drawPath(path, star);
    }

    spark(0.88, 0.28, 5);
    spark(0.78, 0.18, 3.5);
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
    final gold = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.8);
    void dot(double x, double y, double r, [Paint? p]) {
      canvas.drawCircle(Offset(size.width * x, size.height * y), r, p ?? soft);
    }

    for (final e in const [
      (0.10, 0.22, 1.2),
      (0.22, 0.40, 1.0),
      (0.38, 0.18, 1.3),
      (0.70, 0.14, 1.4),
    ]) {
      dot(e.$1, e.$2, e.$3, e.$1 > 0.65 ? gold : soft);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
