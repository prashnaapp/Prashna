import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';

/// Compact Chapters header — title plus a short decorative wave.
///
/// No large hero, illustration, sparkles, or notification chrome.
class ChaptersHero extends StatelessWidget {
  const ChaptersHero({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SyllabusVisual.pagePadding,
          topInset + AppSpacing.md,
          SyllabusVisual.pagePadding,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chapters',
              style: AppTextStyles.titleLarge(context).copyWith(
                color: SyllabusVisual.ink,
                fontWeight: FontWeight.w800,
                fontSize: 24,
                height: 1.15,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const SizedBox(
              width: double.infinity,
              height: 12,
              child: CustomPaint(painter: _HeaderWavePainter()),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderWavePainter extends CustomPainter {
  const _HeaderWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          SyllabusVisual.accent.withValues(alpha: 0.0),
          SyllabusVisual.accent.withValues(alpha: 0.32),
          SyllabusVisual.accent.withValues(alpha: 0.18),
          SyllabusVisual.accent.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.22,
        0,
        size.width * 0.48,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.98,
        size.width,
        size.height * 0.42,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
