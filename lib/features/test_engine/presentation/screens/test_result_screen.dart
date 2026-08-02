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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                Text(
                  result.passed ? 'Passed' : 'Keep Practicing',
                  style: AppTextStyles.headline(context).copyWith(
                    color: result.passed ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  result.score.toStringAsFixed(
                    result.score == result.score.roundToDouble() ? 0 : 2,
                  ),
                  style: AppTextStyles.display(context).copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text('Score', style: AppTextStyles.bodyMedium(context)),
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
              _StatCard('Correct', '${result.correct}', AppColors.success),
              _StatCard('Wrong', '${result.wrong}', AppColors.error),
              _StatCard('Skipped', '${result.skipped}', AppColors.textTertiary),
              _StatCard(
                'Accuracy',
                '${result.accuracy}%',
                AppColors.secondary,
              ),
              _StatCard(
                'Percentage',
                '${result.percentage}%',
                AppColors.primary,
              ),
              _StatCard(
                'Time Taken',
                _formatDuration(result.timeTaken),
                AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppPrimaryButton(
            label: 'View Analysis',
            onPressed: onViewAnalysis,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: 'Retry Test',
            onPressed: onRetry,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onGoHome,
            child: const Text('Go Home'),
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.headline(context).copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.bodyMedium(context)),
        ],
      ),
    );
  }
}
