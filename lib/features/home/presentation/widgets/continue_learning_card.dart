import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/home_models.dart';
import '../home_visual.dart';
import 'home_decorations.dart';

class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final ContinueLearningModel data;
  final VoidCallback onContinue;

  static const _studentAsset = 'assets/home/student_reading.png';

  static String _pill(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), '-').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (!data.hasHistory) {
      return HomeSurfaceCard(
        featured: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HomeSectionTitle('Continue Learning'),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Pick a course and begin your first session.',
              style: TextStyle(
                fontSize: 14,
                color: HomeVisual.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            HomeCtaButton(
              label: 'Start Learning →',
              onPressed: onContinue,
              height: AppSizes.buttonMedium,
            ),
          ],
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final showArt = width >= 360;

    return HomeSurfaceCard(
      featured: true,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeSectionTitle('Continue Learning'),
          const SizedBox(height: AppSpacing.sm),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _MetaPill(_pill(data.courseName)),
                      _MetaPill(_pill(data.paperLabel)),
                      _MetaPill(_pill(data.partLabel)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    data.chapterLabel,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: HomeVisual.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: EdgeInsets.only(right: showArt ? 78 : 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: HomeLinearProgress(
                            value: data.progressPercent / 100,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${data.progressPercent.round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: HomeVisual.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: EdgeInsets.only(right: showArt ? 78 : 0),
                    child: HomeCtaButton(
                      label: 'Continue Now →',
                      onPressed: onContinue,
                      height: AppSizes.buttonMedium,
                    ),
                  ),
                ],
              ),
              if (showArt)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 86,
                      height: 86,
                      child: Image(
                        image: AssetImage(_studentAsset),
                        width: 86,
                        height: 86,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: HomeVisual.pillFill,
        borderRadius: BorderRadius.circular(HomeVisual.pillRadius),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: HomeVisual.muted,
        ),
      ),
    );
  }
}
