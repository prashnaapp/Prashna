import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';

/// Subtle lavender atmosphere behind Unit Detail content.
///
/// Non-interactive. Low contrast so it never fights text.
class UnitDetailBackdrop extends StatelessWidget {
  const UnitDetailBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _UnitDetailBackdropPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _UnitDetailBackdropPainter extends CustomPainter {
  const _UnitDetailBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()
      ..color = AppColors.lavender.withValues(alpha: 0.28);
    final glow = Paint()
      ..color = SyllabusVisual.accent.withValues(alpha: 0.04);

    canvas.drawCircle(
      Offset(size.width * 0.98, size.height * -0.04),
      size.width * 0.38,
      wash,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.10),
      size.width * 0.18,
      glow,
    );
    canvas.drawCircle(
      Offset(size.width * 1.06, size.height * 1.04),
      size.width * 0.42,
      wash,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.92),
      size.width * 0.14,
      glow,
    );

    final dot = Paint()
      ..color = SyllabusVisual.accent.withValues(alpha: 0.045);
    const step = 16.0;
    final maxX = size.width * 0.34;
    final minY = size.height * 0.70;
    for (var x = 18.0; x < maxX; x += step) {
      for (var y = minY; y < size.height - 28; y += step) {
        canvas.drawCircle(Offset(x, y), 1.35, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
