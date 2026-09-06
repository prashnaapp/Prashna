import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// Premium Revision Center hero — eyebrow, editorial headline, soft study art.
///
/// Illustration is painted (no new asset) to match the existing Progress /
/// Chapters hero craftsmanship.
class RevisionCenterHero extends StatelessWidget {
  const RevisionCenterHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRACTICE • REVIEW • IMPROVE',
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.primaryStrong.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Practice what\nneeds your\nattention',
                style: AppTextStyles.display(context).copyWith(
                  fontSize: 32,
                  height: 1.12,
                  letterSpacing: -0.6,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const SizedBox(
          width: 112,
          height: 118,
          child: _RevisionHeroArt(),
        ),
      ],
    );
  }
}

class _RevisionHeroArt extends StatelessWidget {
  const _RevisionHeroArt();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _RevisionBooksPainter());
  }
}

class _RevisionBooksPainter extends CustomPainter {
  const _RevisionBooksPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft atmospheric blob behind the books.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.54, h * 0.58),
        width: w * 0.98,
        height: h * 0.78,
      ),
      Paint()..color = AppColors.lavender.withValues(alpha: 0.85),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.62, h * 0.42),
        width: w * 0.52,
        height: h * 0.42,
      ),
      Paint()..color = AppColors.primaryLight.withValues(alpha: 0.28),
    );

    // Bottom book.
    final bottom = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.58, w * 0.72, h * 0.22),
      const Radius.circular(10),
    );
    canvas.drawRRect(bottom, Paint()..color = const Color(0xFF9BB6FF));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, h * 0.58, w * 0.10, h * 0.22),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF7A96E8),
    );

    // Top book.
    final top = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.38, w * 0.66, h * 0.20),
      const Radius.circular(10),
    );
    canvas.drawRRect(top, Paint()..color = const Color(0xFFB8C8FF));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.38, w * 0.10, h * 0.20),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF8FA4F0),
    );

    // Sprout / plant.
    final stem = Paint()
      ..color = const Color(0xFF2BB8A8)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.48, h * 0.40),
      Offset(w * 0.48, h * 0.22),
      stem,
    );
    final leaf = Paint()..color = const Color(0xFF35C6A8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.40, h * 0.26),
        width: w * 0.16,
        height: h * 0.10,
      ),
      leaf,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.58, h * 0.24),
        width: w * 0.14,
        height: h * 0.09,
      ),
      leaf,
    );

    // Soft sparkles.
    final spark = Paint()..color = AppColors.primaryStrong.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(w * 0.86, h * 0.28), 2.2, spark);
    canvas.drawCircle(Offset(w * 0.18, h * 0.30), 1.6, spark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
