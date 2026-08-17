import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';

/// Soft tip strip under the Test Series hero.
///
/// Height is fixed to [layoutHeight] so parent layout math stays exact and
/// content never overflows (fixes BOTTOM OVERFLOWED).
class TestsTipBanner extends StatelessWidget {
  const TestsTipBanner({super.key});

  static const double layoutHeight = 52;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: layoutHeight,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SyllabusVisual.tileLavender,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: SyllabusVisual.accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice Smart. Score Higher.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium(context).copyWith(
                        color: SyllabusVisual.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Choose a test series to begin your preparation.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: SyllabusVisual.muted,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
