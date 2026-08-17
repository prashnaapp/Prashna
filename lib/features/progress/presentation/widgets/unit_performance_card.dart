import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/unit_performance.dart';

/// Displays server-authored canonical unit performance metrics.
///
/// Empty, loading, and error states are explicit so missing data is never
/// shown as zeroed attempts.
class UnitPerformanceCard extends StatelessWidget {
  const UnitPerformanceCard({
    super.key,
    this.performance,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final UnitPerformance? performance;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Unit Performance', style: AppTextStyles.titleMedium(context)),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: AppCircularProgress()),
            )
          else if (errorMessage != null)
            _ErrorBody(message: errorMessage!, onRetry: onRetry)
          else if (performance == null)
            Text('No attempts yet', style: AppTextStyles.bodyMedium(context))
          else
            _MetricsBody(performance: performance!),
        ],
      ),
    );
  }
}

class _MetricsBody extends StatelessWidget {
  const _MetricsBody({required this.performance});

  final UnitPerformance performance;

  @override
  Widget build(BuildContext context) {
    final percent = performance.bestPercentage.clamp(0, 100) / 100;
    final tiles = [
      _Metric('Tests Attempted', '${performance.testsAttempted}'),
      _Metric('Best Score', _formatScore(performance.bestMarks)),
      _Metric('Questions Attempted', '${performance.questionsAttempted}'),
      _Metric('Correct', '${performance.correct}'),
      _Metric('Wrong', '${performance.wrong}'),
      _Metric('Skipped', '${performance.skipped}'),
      _Metric('Accuracy', '${_formatPercent(performance.accuracy)}%'),
      _Metric(
        'Best Percentage',
        '${_formatPercent(performance.bestPercentage)}%',
      ),
      _Metric('Latest Attempt', _formatLatest(performance.latestAttemptAt)),
    ];

    return Column(
      children: [
        Row(
          children: [
            AppProgressRing(
              progress: percent,
              label: '${_formatPercent(performance.bestPercentage)}%',
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overall', style: AppTextStyles.bodyMedium(context)),
                  Text(
                    _formatScore(performance.bestMarks),
                    style: AppTextStyles.titleLarge(
                      context,
                    ).copyWith(color: AppColors.primaryStrong),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _MetricTile(metric: tiles[i])),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: i + 1 < tiles.length
                    ? _MetricTile(metric: tiles[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatPercent(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatScore(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatLatest(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(metric.value, style: AppTextStyles.titleMedium(context)),
        const SizedBox(height: AppSpacing.xs),
        Text(metric.label, style: AppTextStyles.bodyMedium(context)),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: AppTextStyles.bodyMedium(context)),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ],
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
}
