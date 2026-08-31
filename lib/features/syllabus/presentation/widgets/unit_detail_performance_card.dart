import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../progress/data/models/unit_performance.dart';
import '../syllabus_visual.dart';
import 'unit_detail_surface.dart';

/// Compact Unit Detail performance panel.
///
/// Display-only. Values come from the existing [UnitPerformance] document.
class UnitDetailPerformanceCard extends StatelessWidget {
  const UnitDetailPerformanceCard({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: AppTextStyles.titleMedium(context).copyWith(
            color: SyllabusVisual.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        UnitDetailSurface(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: _body(context),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: AppCircularProgress()),
      );
    }
    if (errorMessage != null) {
      return _ErrorBody(message: errorMessage!, onRetry: onRetry);
    }
    if (performance == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: Text(
            'No attempts yet',
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: SyllabusVisual.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return _MetricsBody(performance: performance!);
  }
}

class _MetricsBody extends StatelessWidget {
  const _MetricsBody({required this.performance});

  final UnitPerformance performance;

  @override
  Widget build(BuildContext context) {
    final percent = (performance.bestPercentage.clamp(0, 100) / 100)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _PrimaryMetric(
                value: '${_formatPercent(performance.bestPercentage)}%',
                label: 'Best %',
                align: CrossAxisAlignment.start,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.divider.withValues(alpha: 0.9),
            ),
            Expanded(
              child: _PrimaryMetric(
                value: '${_formatPercent(performance.accuracy)}%',
                label: 'Accuracy',
                align: CrossAxisAlignment.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: AppRadius.pillAll,
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: AppColors.lavender,
            color: SyllabusVisual.accent,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _SecondaryMetric(
                label: 'Best Score',
                value: _formatScore(performance.bestMarks),
                icon: Icons.emoji_events_rounded,
                wellColor: SyllabusVisual.tileLavender,
                iconColor: SyllabusVisual.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SecondaryMetric(
                label: 'Tests',
                value: '${performance.testsAttempted}',
                icon: Icons.assignment_rounded,
                wellColor: SyllabusVisual.tileBlue,
                iconColor: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SecondaryMetric(
                label: 'Questions',
                value: '${performance.questionsAttempted}',
                icon: Icons.help_outline_rounded,
                wellColor: SyllabusVisual.tileLavender,
                iconColor: SyllabusVisual.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(
          height: 1,
          thickness: 1,
          color: AppColors.divider.withValues(alpha: 0.85),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SecondaryMetric(
                label: 'Correct',
                value: '${performance.correct}',
                icon: Icons.check_rounded,
                wellColor: AppColors.successSurface,
                iconColor: AppColors.success,
                valueColor: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SecondaryMetric(
                label: 'Wrong',
                value: '${performance.wrong}',
                icon: Icons.close_rounded,
                wellColor: AppColors.errorSurface,
                iconColor: AppColors.error,
                valueColor: AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SecondaryMetric(
                label: 'Skipped',
                value: '${performance.skipped}',
                icon: Icons.remove_rounded,
                wellColor: AppColors.surfaceVariant,
                iconColor: SyllabusVisual.muted,
                valueColor: SyllabusVisual.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryMetric extends StatelessWidget {
  const _PrimaryMetric({
    required this.value,
    required this.label,
    required this.align,
  });

  final String value;
  final String label;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleMedium(context).copyWith(
            color: SyllabusVisual.accent,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            color: SyllabusVisual.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SecondaryMetric extends StatelessWidget {
  const _SecondaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.wellColor,
    required this.iconColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color wellColor;
  final Color iconColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: wellColor,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, size: 15, color: iconColor),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: SyllabusVisual.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label(context).copyWith(
                  color: valueColor ?? SyllabusVisual.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
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
        Text(
          message,
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: SyllabusVisual.muted,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: SyllabusVisual.accent,
              padding: EdgeInsets.zero,
              minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry'),
          ),
        ],
      ],
    );
  }
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
