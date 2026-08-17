import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';

/// Compact Coming Soon strip — static 3D-look rocket (no animation).
class ChaptersMoreExamsBanner extends StatelessWidget {
  const ChaptersMoreExamsBanner({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: SyllabusVisual.headerGradient,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _BannerStarsPainter()),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Coming Soon',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        height: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: height * 1.15,
                    height: height,
                    child: const CustomPaint(painter: _BannerRocketPainter()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static 3D-look rocket (Home rocket language) — not animated.
class _BannerRocketPainter extends CustomPainter {
  const _BannerRocketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final origin = Offset(w * 0.48, h * 0.58);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(-0.58);

    // Fire downward from nozzle
    canvas.drawOval(
      const Rect.fromLTWH(-9, 18, 18, 28),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF176), Color(0xFFFF8A65), Color(0xFFE65100)],
        ).createShader(const Rect.fromLTWH(-9, 18, 18, 28)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-4, 22, 8, 14),
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    final smoke = Paint()..color = Colors.white.withValues(alpha: 0.28);
    canvas.drawOval(const Rect.fromLTWH(-12, 42, 11, 8), smoke);
    canvas.drawOval(const Rect.fromLTWH(-1, 48, 13, 9), smoke);
    canvas.drawOval(const Rect.fromLTWH(-9, 56, 10, 7), smoke);

    final body = Path()
      ..moveTo(0, -32)
      ..quadraticBezierTo(16, -4, 12, 18)
      ..lineTo(-12, 18)
      ..quadraticBezierTo(-16, -4, 0, -32)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFD5D8FF)],
        ).createShader(const Rect.fromLTWH(-16, -32, 32, 52)),
    );

    // Side shading for 3D depth
    canvas.drawPath(
      Path()
        ..moveTo(2, -28)
        ..quadraticBezierTo(14, -2, 10, 16)
        ..lineTo(2, 16)
        ..close(),
      Paint()..color = const Color(0xFF9EA6FF).withValues(alpha: 0.22),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-7, -24, 5, 18),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    final fin = Paint()..color = const Color(0xFF6C5CE7);
    canvas.drawPath(
      Path()
        ..moveTo(-12, 4)
        ..lineTo(-26, 24)
        ..lineTo(-8, 18)
        ..close(),
      fin,
    );
    canvas.drawPath(
      Path()
        ..moveTo(12, 4)
        ..lineTo(26, 24)
        ..lineTo(8, 18)
        ..close(),
      fin,
    );

    canvas.drawCircle(
      const Offset(0, -6),
      5.8,
      Paint()..color = const Color(0xFF4C8DFF),
    );
    canvas.drawCircle(
      const Offset(0, -6),
      2.8,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.restore();

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

    spark(0.16, 0.26, 4.2);
    spark(0.84, 0.20, 3.4);
    spark(0.78, 0.70, 2.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BannerStarsPainter extends CustomPainter {
  const _BannerStarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    void dot(double x, double y, double r) {
      canvas.drawCircle(Offset(size.width * x, size.height * y), r, paint);
    }

    dot(0.10, 0.30, 1.2);
    dot(0.26, 0.70, 1.0);
    dot(0.44, 0.24, 1.3);
    dot(0.58, 0.78, 1.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
