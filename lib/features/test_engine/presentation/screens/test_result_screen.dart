import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';
import '../controllers/test_engine_controller.dart';
import '../test_engine_presentation.dart';

class TestResultScreen extends StatelessWidget {
  const TestResultScreen({
    super.key,
    required this.controller,
    required this.onViewAnalysis,
    required this.onGoHome,
  });

  final TestEngineController controller;
  final VoidCallback onViewAnalysis;
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: SyllabusVisual.page,
      appBar: AppBar(
        backgroundColor: SyllabusVisual.page,
        foregroundColor: SyllabusVisual.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          'Result',
          style: AppTextStyles.titleMedium(context).copyWith(
            color: SyllabusVisual.ink,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          SyllabusVisual.pagePadding,
          AppSpacing.sm,
          SyllabusVisual.pagePadding,
          bottomInset + AppSpacing.xxl,
        ),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: SyllabusVisual.surface,
              borderRadius: BorderRadius.circular(SyllabusVisual.cardRadius),
              boxShadow: SyllabusVisual.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              child: Column(
                children: [
                  _CompletionMark(passed: result.passed),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'TEST COMPLETED!',
                    style: AppTextStyles.label(context).copyWith(
                      color: AppColors.primaryStrong,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    result.passed ? 'Passed' : 'Keep Practicing',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headline(context).copyWith(
                      color: result.passed
                          ? AppColors.success
                          : AppColors.accentWarm,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '$scoreLabel / $totalMarks',
                    style: AppTextStyles.display(
                      context,
                    ).copyWith(color: SyllabusVisual.ink),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${result.percentage}%',
                    style: AppTextStyles.titleLarge(context).copyWith(
                      color: SyllabusVisual.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Correct',
                  value: '${result.correct}',
                  color: AppColors.success,
                  icon: Icons.check_rounded,
                  tint: AppColors.successSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Wrong',
                  value: '${result.wrong}',
                  color: AppColors.error,
                  icon: Icons.close_rounded,
                  tint: AppColors.errorSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Skipped',
                  value: '${result.skipped}',
                  color: AppColors.textTertiary,
                  icon: Icons.remove_rounded,
                  tint: AppColors.surfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Accuracy',
                  value: '${result.accuracy}%',
                  color: AppColors.primaryStrong,
                  icon: Icons.gps_fixed_rounded,
                  tint: AppColors.lavender,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Time Taken',
                  value: TestEnginePresentation.timeTakenLabel(
                    result.timeTaken,
                  ),
                  color: AppColors.accentTeal,
                  icon: Icons.schedule_rounded,
                  tint: SyllabusVisual.tileTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppPrimaryButton(
            label: 'Review Answers',
            icon: Icons.arrow_forward_rounded,
            onPressed: onViewAnalysis,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onGoHome,
            style: TextButton.styleFrom(foregroundColor: SyllabusVisual.muted),
            child: const Text('Back to Unit'),
          ),
        ],
      ),
    );
  }
}

class _CompletionMark extends StatelessWidget {
  const _CompletionMark({required this.passed});

  final bool passed;

  @override
  Widget build(BuildContext context) {
    final sparkle = AppColors.primary.withValues(alpha: 0.55);
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 2,
            right: 10,
            child: Icon(Icons.star_rounded, size: 11, color: sparkle),
          ),
          Positioned(
            top: 18,
            left: 6,
            child: Icon(
              Icons.star_rounded,
              size: 8,
              color: AppColors.primaryLight,
            ),
          ),
          Positioned(
            bottom: 10,
            right: 4,
            child: Icon(
              Icons.auto_awesome,
              size: 12,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(
              passed ? Icons.emoji_events_rounded : Icons.school_rounded,
              color: AppColors.primaryStrong,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SyllabusVisual.surface,
        borderRadius: BorderRadius.circular(SyllabusVisual.cardRadius),
        boxShadow: SyllabusVisual.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTextStyles.titleMedium(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: SyllabusVisual.muted),
            ),
          ],
        ),
      ),
    );
  }
}
