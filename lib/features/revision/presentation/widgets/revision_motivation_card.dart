import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// Decorative motivational strip under Revision Center hub cards.
class RevisionMotivationCard extends StatelessWidget {
  const RevisionMotivationCard({super.key});

  static const BorderRadius _radius = AppRadius.lgAll;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: AppShadows.soft,
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFE8F2FF),
            AppColors.lavender.withValues(alpha: 0.55),
            AppColors.surface,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: Stack(
          children: [
            Positioned(
              right: -8,
              bottom: -6,
              child: CustomPaint(
                size: const Size(92, 72),
                painter: const _MotivationScenePainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxxl,
                AppSpacing.xl,
              ),
              child: Row(
                children: [
                  Container(
                    width: AppSpacing.massive,
                    height: AppSpacing.massive,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Small steps.\nStronger results.',
                          style: AppTextStyles.titleMedium(context).copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "Keep revising. You've got this.",
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
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

class _MotivationScenePainter extends CustomPainter {
  const _MotivationScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mountain = Paint()..color = AppColors.accent.withValues(alpha: 0.12);
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.28, h * 0.42)
      ..lineTo(w * 0.48, h * 0.68)
      ..lineTo(w * 0.72, h * 0.28)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, mountain);

    final flagPole = Paint()
      ..color = AppColors.primaryStrong.withValues(alpha: 0.35)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.72, h * 0.28),
      Offset(w * 0.72, h * 0.12),
      flagPole,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.72, h * 0.12)
        ..lineTo(w * 0.86, h * 0.16)
        ..lineTo(w * 0.72, h * 0.20)
        ..close(),
      Paint()..color = AppColors.primaryStrong.withValues(alpha: 0.40),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
