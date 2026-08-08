import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_attempt_history.dart';

/// Shows stored attempt fields only — does not recalculate scoring.
class TestAttemptHistoryDetailScreen extends StatelessWidget {
  const TestAttemptHistoryDetailScreen({
    super.key,
    required this.item,
  });

  final TestAttemptHistoryItem item;

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _formatScore(double score) {
    return score == score.roundToDouble()
        ? score.toStringAsFixed(0)
        : score.toStringAsFixed(2);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m <= 0) return '${s}s';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Attempt Details')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              children: [
                Text(
                  item.passed ? 'Passed' : 'Keep Practicing',
                  style: AppTextStyles.headline(context).copyWith(
                    color: item.passed ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _formatScore(item.score),
                  style: AppTextStyles.display(context).copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text('Score', style: AppTextStyles.bodyMedium(context)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(label: 'Test', value: item.displayTestTitle),
                _Row(label: 'Course', value: item.displayCourseTitle),
                _Row(label: 'Mode', value: item.mode.isEmpty ? '—' : item.mode),
                _Row(label: 'Status', value: item.status),
                _Row(
                  label: 'Completed',
                  value: _formatDate(item.submittedAt ?? item.startedAt),
                ),
                _Row(
                  label: 'Time spent',
                  value: _formatDuration(item.timeSpentSeconds),
                ),
                _Row(label: 'Percentage', value: '${item.percentage}%'),
                _Row(label: 'Accuracy', value: '${item.accuracy}%'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.55,
            children: [
              _StatCard('Correct', '${item.correct}', AppColors.success),
              _StatCard('Wrong', '${item.wrong}', AppColors.error),
              _StatCard('Skipped', '${item.skipped}', AppColors.textTertiary),
              _StatCard(
                'Accuracy',
                '${item.accuracy}%',
                AppColors.secondary,
              ),
              _StatCard(
                'Percentage',
                '${item.percentage}%',
                AppColors.primary,
              ),
              _StatCard(
                'Questions',
                '${item.totalQuestions}',
                AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.bodyMedium(context)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.titleMedium(context)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.titleLarge(context).copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.bodyMedium(context)),
        ],
      ),
    );
  }
}
