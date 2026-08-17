import 'package:flutter/material.dart';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HomeSectionTitle('Continue Learning'),
            const SizedBox(height: 12),
            const Text(
              'Pick a course and begin your first session.',
              style: TextStyle(
                fontSize: 14,
                color: HomeVisual.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            HomeCtaButton(label: 'Start Learning →', onPressed: onContinue),
          ],
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final showArt = width >= 340;

    return HomeSurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeSectionTitle('Continue Learning'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(_pill(data.courseName)),
              _MetaPill(_pill(data.paperLabel)),
              _MetaPill(_pill(data.partLabel)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.chapterLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: HomeVisual.ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: HomeLinearProgress(value: data.progressPercent / 100),
              ),
              const SizedBox(width: 10),
              Text(
                '${data.progressPercent.round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: HomeVisual.ctaDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: showArt ? 7 : 10,
                child: HomeCtaButton(
                  label: 'Continue Now →',
                  onPressed: onContinue,
                ),
              ),
              if (showArt) ...[
                const SizedBox(width: 4),
                const Expanded(
                  flex: 3,
                  child: IgnorePointer(
                    child: Image(
                      image: AssetImage(_studentAsset),
                      height: 104,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
