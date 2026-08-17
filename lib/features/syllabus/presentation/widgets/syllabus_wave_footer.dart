import 'package:flutter/material.dart';

import '../syllabus_visual.dart';

class SyllabusWaveFooter extends StatelessWidget {
  const SyllabusWaveFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: CustomPaint(painter: _WavePainter()),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final back = Paint()..color = SyllabusVisual.wave.withValues(alpha: 0.95);
    final mid = Paint()..color = SyllabusVisual.accent.withValues(alpha: 0.10);
    final front = Paint()
      ..color = const Color(0xFFE56BA0).withValues(alpha: 0.08);

    canvas.drawPath(_wave(size, 0.48, 0.12, 0.40, 0.78, 0.30), back);
    canvas.drawPath(_wave(size, 0.58, 0.22, 0.50, 0.86, 0.38), mid);
    canvas.drawPath(_wave(size, 0.66, 0.34, 0.58, 0.90, 0.46), front);
  }

  Path _wave(
    Size size,
    double startY,
    double c1Y,
    double midY,
    double c2Y,
    double endY,
  ) {
    return Path()
      ..moveTo(0, size.height * startY)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * c1Y,
        size.width * 0.5,
        size.height * midY,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * c2Y,
        size.width,
        size.height * endY,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
