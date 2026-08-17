import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/attempt_analytics_models.dart';
import '../progress_visual.dart';

/// Compact three-column statistic tiles.
///
/// Values, formatting, and accent colours are unchanged — presentation only.
class AnalyticsStatGrid extends StatelessWidget {
  const AnalyticsStatGrid({super.key, required this.summary});

  final ProgressSummary summary;

  static const int _columns = 3;
  static const double _gap = 10;

  /// Fixed so all six tiles are exactly equal, regardless of value length.
  static const double _tileHeight = 70;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Stat(
        'Tests',
        '${summary.totalTests}',
        AppColors.primary,
        Icons.description_rounded,
      ),
      _Stat(
        'Questions',
        '${summary.totalQuestions}',
        AppColors.accent,
        Icons.help_rounded,
      ),
      _Stat(
        'Avg Score',
        summary.averageScore.toStringAsFixed(1),
        AppColors.secondary,
        Icons.track_changes_rounded,
      ),
      _Stat(
        'Accuracy',
        '${summary.averageAccuracy.toStringAsFixed(1)}%',
        AppColors.success,
        Icons.show_chart_rounded,
      ),
      _Stat(
        'Avg Time',
        _formatDuration(summary.averageTime),
        AppColors.accentWarm,
        Icons.schedule_rounded,
      ),
      _Stat(
        'Streak',
        '${summary.currentStreak}d',
        AppColors.warning,
        Icons.local_fire_department_rounded,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tiles.length; i += _columns) ...[
          if (i > 0) const SizedBox(height: _gap),
          Row(
            children: [
              for (var c = 0; c < _columns; c++) ...[
                if (c > 0) const SizedBox(width: _gap),
                Expanded(
                  child: i + c < tiles.length
                      ? _StatTile(stat: tiles[i + c])
                      : const SizedBox(height: _tileHeight),
                ),
              ],
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
    return Container(
      height: AnalyticsStatGrid._tileHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ProgressVisual.statRadius),
        border: ProgressVisual.cardBorder,
        boxShadow: ProgressVisual.statShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Long values (e.g. "100.0%") scale down rather than overflow on
          // narrow phones, keeping all three columns identical.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(stat.icon, size: 15, color: stat.color),
                ),
                const SizedBox(width: 7),
                Text(
                  stat.value,
                  style: AppTextStyles.titleLarge(context).copyWith(
                    color: stat.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stat.label,
              maxLines: 1,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: ProgressVisual.muted,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.color, this.icon);
  final String label;
  final String value;
  final Color color;
  final IconData icon;
}
