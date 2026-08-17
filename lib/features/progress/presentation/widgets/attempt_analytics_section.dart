import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/attempt_analytics_models.dart';
import '../progress_visual.dart';
import 'analytics_stat_grid.dart';
import '../screens/progress_analytics_screen.dart';

/// Attempt analytics block — grid + “View Full Analytics”.
class AttemptAnalyticsSection extends StatelessWidget {
  const AttemptAnalyticsSection({
    super.key,
    required this.summaryFuture,
    required this.onAnalyticsClosed,
  });

  final Future<ProgressSummary> summaryFuture;
  final VoidCallback onAnalyticsClosed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Attempt Analytics', style: ProgressVisual.sectionTitle(context)),
        const SizedBox(height: 12),
        FutureBuilder<ProgressSummary>(
          future: summaryFuture,
          builder: (context, snapshot) {
            final summary = snapshot.data ?? ProgressSummary.empty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnalyticsStatGrid(summary: summary),
                const SizedBox(height: 12),
                _ViewFullAnalyticsButton(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProgressAnalyticsScreen(),
                      ),
                    );
                    onAnalyticsClosed();
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ViewFullAnalyticsButton extends StatelessWidget {
  const _ViewFullAnalyticsButton({required this.onTap});

  final VoidCallback onTap;

  static const double _height = 50;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillAll,
        child: Ink(
          height: _height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.pillAll,
            border: Border.all(
              color: ProgressVisual.accent.withValues(alpha: 0.38),
              width: 1.3,
            ),
            boxShadow: ProgressVisual.statShadow,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  'View Full Analytics',
                  style: AppTextStyles.label(context).copyWith(
                    color: ProgressVisual.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: ProgressVisual.accent.withValues(alpha: 0.7),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
