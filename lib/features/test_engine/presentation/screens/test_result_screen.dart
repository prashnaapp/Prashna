import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../controllers/test_engine_controller.dart';

class TestResultScreen extends StatelessWidget {
  const TestResultScreen({
    super.key,
    required this.controller,
    required this.onViewAnalysis,
    required this.onRetry,
    required this.onGoHome,
  });

  final TestEngineController controller;
  final VoidCallback onViewAnalysis;
  final VoidCallback onRetry;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final result = controller.result;
    if (result == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final scoreLabel = result.score == result.score.roundToDouble()
        ? result.score.toStringAsFixed(0)
        : result.score.toStringAsFixed(2);
    final totalMarks = controller.test.totalMarks;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Result'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.lavender,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    result.passed
                        ? Icons.emoji_events_rounded
                        : Icons.school_rounded,
                    color: AppColors.primaryStrong,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'TEST COMPLETED!',
                  style: AppTextStyles.label(context).copyWith(
                    color: AppColors.primaryStrong,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  result.passed ? 'Passed' : 'Keep Practicing',
                  style: AppTextStyles.headline(context).copyWith(
                    color: result.passed
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$scoreLabel / $totalMarks',
                  style: AppTextStyles.display(
                    context,
                  ).copyWith(color: AppColors.primaryStrong),
                ),
                Text(
                  '${result.percentage}%',
                  style: AppTextStyles.titleLarge(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatCard('Correct', '${result.correct}', AppColors.success),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard('Wrong', '${result.wrong}', AppColors.error),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  'Skipped',
                  '${result.skipped}',
                  AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  'Accuracy',
                  '${result.accuracy}%',
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  'Time Taken',
                  _formatDuration(result.timeTaken),
                  AppColors.accentTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppPrimaryButton(
            label: 'Review Answers',
            onPressed: onViewAnalysis,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(label: 'Retry Test', onPressed: onRetry),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onGoHome, child: const Text('Back to Unit')),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
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
      showShadow: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.titleMedium(context).copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption(context)),
        ],
      ),
    );
  }
}
