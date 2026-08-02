import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/attempt_analytics_models.dart';
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
        Text(
          'Attempt Analytics',
          style: AppTextStyles.titleLarge(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<ProgressSummary>(
          future: summaryFuture,
          builder: (context, snapshot) {
            final summary = snapshot.data ?? ProgressSummary.empty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnalyticsStatGrid(summary: summary),
                const SizedBox(height: AppSpacing.lg),
                AppSecondaryButton(
                  label: 'View Full Analytics',
                  onPressed: () async {
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
