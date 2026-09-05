import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';
import '../../../syllabus/presentation/widgets/landing_sheet.dart';

/// Progress tab hero — purple header the content sheet waves into.
///
/// The bottom edge is square: [LandingSheet]'s wave clip shapes the
/// transition, so the gradient must reach both screen edges without a corner
/// notch. Text keeps clear of [overlapClearance] so the sheet can never clip
/// the subtitle, and scales down instead of clipping on very small phones.
class ProgressHero extends StatelessWidget {
  const ProgressHero({super.key, required this.height});

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
    final artWidth = (screenW * 0.37).clamp(132.0, 162.0);

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
                right: 6,
                bottom: 16,
                width: artWidth,
                height: artWidth * 0.94,
                child: const _ProgressBoardArt(),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Progress',
                            style: AppTextStyles.headline(context).copyWith(
                              color: SyllabusVisual.headerOn,
                              fontWeight: FontWeight.w800,
                              fontSize: 30,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Track your syllabus progress.',
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

/// Checklist clipboard with a pencil — same painted-illustration style as the
/// Chapters and Test Series heroes, so no new asset is introduced.
class _ProgressBoardArt extends StatelessWidget {
  const _ProgressBoardArt();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _ProgressBoardPainter());
  }
}

class _ProgressBoardPainter extends CustomPainter {
  const _ProgressBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft cloud the board sits on.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.46, h * 0.90),
        width: w * 0.84,
        height: h * 0.20,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );

    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.14, w * 0.54, h * 0.72),
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

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.24, w * 0.42, h * 0.55),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.white,
    );

    final checkStroke = Paint()
      ..color = const Color(0xFF6A4CFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePaint = Paint()
      ..color = const Color(0xFFE8E4F8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final y = h * (0.36 + i * 0.14);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * 0.30, y),
            width: w * 0.08,
            height: w * 0.08,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFEEEAFF),
      );
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.272, y)
          ..lineTo(w * 0.294, y + h * 0.020)
          ..lineTo(w * 0.328, y - h * 0.024),
        checkStroke,
      );
      canvas.drawLine(Offset(w * 0.38, y), Offset(w * 0.58, y), linePaint);
    }

    // Clip at the top of the board.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.43, h * 0.16),
          width: w * 0.22,
          height: h * 0.08,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF7B6CFF),
    );

    _paintPencil(canvas, size);

    final gold = Paint()..color = const Color(0xFFFFE082);
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

    spark(0.06, 0.60, 5.5, teal);
    spark(0.90, 0.56, 5, gold);
    spark(0.82, 0.22, 3.5, gold);
  }

  /// Pencil resting against the right edge of the board, tip pointing down.
  void _paintPencil(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyW = w * 0.13;
    final bodyH = h * 0.52;

    canvas.save();
    canvas.translate(w * 0.74, h * 0.30);
    canvas.rotate(0.22 * math.pi / 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, bodyW, bodyH * 0.18),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF8E7BFF),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, bodyH * 0.18, bodyW, bodyH * 0.62),
      Paint()..color = const Color(0xFFF5A623),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, bodyH * 0.80)
        ..lineTo(bodyW, bodyH * 0.80)
        ..lineTo(bodyW / 2, bodyH)
        ..close(),
      Paint()..color = const Color(0xFFFFE0B2),
    );
    canvas.drawPath(
      Path()
        ..moveTo(bodyW * 0.30, bodyH * 0.94)
        ..lineTo(bodyW * 0.70, bodyH * 0.94)
        ..lineTo(bodyW / 2, bodyH)
        ..close(),
      Paint()..color = const Color(0xFF3F3560),
    );

    canvas.restore();
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

    void dot(double x, double y, double r, Paint paint) {
      canvas.drawCircle(Offset(size.width * x, size.height * y), r, paint);
    }

    for (final e in const [
      (0.09, 0.24, 1.2),
      (0.20, 0.40, 1.0),
      (0.34, 0.18, 1.3),
      (0.62, 0.16, 1.4),
    ]) {
      dot(e.$1, e.$2, e.$3, e.$1 > 0.55 ? gold : soft);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
