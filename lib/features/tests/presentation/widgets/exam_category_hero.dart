import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';
import '../../../syllabus/presentation/widgets/landing_sheet.dart';

/// Compact purple hero for Test Series → Group-II / Group-III.
///
/// Bottom edge is square: [LandingSheet] shapes the wave into the cards.
/// Text stays clear of [overlapClearance] so the subtitle is never clipped.
class ExamCategoryHero extends StatelessWidget {
  const ExamCategoryHero({
    super.key,
    required this.title,
    required this.height,
    required this.onBack,
  });

  final String title;
  final double height;
  final VoidCallback onBack;

  static const double overlapClearance = LandingSheet.heroOverlap + 8;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topInset = media.viewPadding.top > media.padding.top
        ? media.viewPadding.top
        : media.padding.top;
    final screenW = MediaQuery.sizeOf(context).width;
    final artWidth = (screenW * 0.34).clamp(118.0, 148.0);

    final textTop = topInset + 48.0;
    final maxTextWidth = (screenW - SyllabusVisual.pagePadding - artWidth - 12)
        .clamp(120.0, screenW);

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
                top: topInset + 4,
                left: 4,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      tooltip: 'Back',
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    const _NotificationBell(),
                  ],
                ),
              ),
              Positioned(
                top: textTop,
                left: SyllabusVisual.pagePadding,
                right: artWidth + 8,
                bottom: overlapClearance,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FittedBox(
                    alignment: Alignment.topLeft,
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxTextWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.headline(context).copyWith(
                              color: SyllabusVisual.headerOn,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Choose a category to begin.',
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
              ),
              Positioned(
                right: 6,
                bottom: 26,
                width: artWidth,
                height: artWidth * 0.92,
                child: const _ClipboardArt(),
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

class _ClipboardArt extends StatelessWidget {
  const _ClipboardArt();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _ClipboardPainter());
  }
}

class _ClipboardPainter extends CustomPainter {
  const _ClipboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.48, h * 0.90),
        width: w * 0.72,
        height: h * 0.18,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );

    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.10, w * 0.50, h * 0.72),
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
      Rect.fromLTWH(w * 0.22, h * 0.22, w * 0.38, h * 0.52),
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
      final y = h * (0.34 + i * 0.13);
      final box = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.30, y),
          width: w * 0.07,
          height: w * 0.07,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(box, Paint()..color = const Color(0xFFEEF2FF));
      final path = Path()
        ..moveTo(w * 0.275, y)
        ..lineTo(w * 0.295, y + h * 0.02)
        ..lineTo(w * 0.325, y - h * 0.022);
      canvas.drawPath(path, checkStroke);
      canvas.drawLine(Offset(w * 0.38, y), Offset(w * 0.54, y), linePaint);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.41, h * 0.12),
          width: w * 0.20,
          height: h * 0.08,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF7B6CFF),
    );

    // Pen resting on the board — matches the category-screen reference.
    final pen = Paint()
      ..color = const Color(0xFF4A3AC8)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.62, h * 0.22),
      Offset(w * 0.86, h * 0.62),
      pen,
    );
    canvas.drawCircle(
      Offset(w * 0.86, h * 0.62),
      4.5,
      Paint()..color = const Color(0xFFFFB74D),
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

    spark(0.88, 0.22, 5);
    spark(0.78, 0.12, 3.5);
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
    final soft = Paint()..color = Colors.white.withValues(alpha: 0.55);
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

    dot(0.10, 0.28, 1.2);
    dot(0.22, 0.18, 1.1);
    dot(0.38, 0.22, 1.4);
    sparkle(0.16, 0.34, 3.0, soft);
    sparkle(0.72, 0.20, 3.6, gold);
    sparkle(0.90, 0.38, 3.2, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
