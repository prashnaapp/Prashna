import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/attempt_analytics_models.dart';

/// Content-height analytics tiles (no fixed aspect-ratio empty cells).
class AnalyticsStatGrid extends StatelessWidget {
  const AnalyticsStatGrid({
    super.key,
    required this.summary,
  });

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Stat('Tests', '${summary.totalTests}', AppColors.primary),
      _Stat('Questions', '${summary.totalQuestions}', AppColors.accent),
      _Stat(
        'Avg Score',
        summary.averageScore.toStringAsFixed(1),
        AppColors.secondary,
      ),
      _Stat(
        'Accuracy',
        '${summary.averageAccuracy.toStringAsFixed(1)}%',
        AppColors.success,
      ),
      _Stat(
        'Avg Time',
        _formatDuration(summary.averageTime),
        AppColors.accentWarm,
      ),
      _Stat(
        'Streak',
        '${summary.currentStreak}d',
        AppColors.warning,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _StatTile(stat: tiles[i])),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: i + 1 < tiles.length
                    ? _StatTile(stat: tiles[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m <= 0) return '${s}s';
    return '${m}m';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.value,
            style: AppTextStyles.headline(context).copyWith(color: stat.color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(stat.label, style: AppTextStyles.bodyMedium(context)),
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}
