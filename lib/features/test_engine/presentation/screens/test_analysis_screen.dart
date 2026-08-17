import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_engine_models.dart';
import '../controllers/test_engine_controller.dart';

class TestAnalysisScreen extends StatelessWidget {
  const TestAnalysisScreen({super.key, required this.controller, this.onBack});

  final TestEngineController controller;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final analysis = controller.analysis;
    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analysis'),
          leading: onBack == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
        ),
        body: const Center(child: Text('No analysis available')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detailed Analysis'),
        leading: onBack == null
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (controller.result != null) ...[
            Center(
              child: AppProgressRing(
                progress: controller.result!.percentage / 100,
                size: 120,
                strokeWidth: 10,
                label: '${controller.result!.percentage}%',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    'Correct',
                    '${controller.result!.correct}',
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MiniStat(
                    'Wrong',
                    '${controller.result!.wrong}',
                    AppColors.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MiniStat(
                    'Skipped',
                    '${controller.result!.skipped}',
                    AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          _AreaSection(title: 'By Paper', areas: analysis.byPaper),
          _AreaSection(title: 'By Section', areas: analysis.bySection),
          _AreaSection(title: 'By Topic', areas: analysis.byTopic),
          _AreaSection(title: 'Weak Areas', areas: analysis.weakAreas),
          _AreaSection(title: 'Strong Areas', areas: analysis.strongAreas),
          const SizedBox(height: AppSpacing.md),
          Text('Question Review', style: AppTextStyles.headline(context)),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < analysis.reviews.length; i++) ...[
            _QuestionReviewCard(index: i + 1, item: analysis.reviews[i]),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showShadow: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleMedium(context).copyWith(color: color),
          ),
          Text(label, style: AppTextStyles.caption(context)),
        ],
      ),
    );
  }
}

class _AreaSection extends StatelessWidget {
  const _AreaSection({required this.title, required this.areas});

  final String title;
  final List<AreaPerformance> areas;

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleMedium(context)),
        const SizedBox(height: AppSpacing.md),
        for (final area in areas) ...[
          AppCard(
            showShadow: false,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        area.label,
                        style: AppTextStyles.bodyLarge(context),
                      ),
                    ),
                    Text(
                      '${area.correct}/${area.total} · ${area.accuracy.toStringAsFixed(0)}%',
                      style: AppTextStyles.label(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppLinearProgress(
                  value: area.total == 0 ? 0 : area.correct / area.total,
                  height: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({required this.index, required this.item});

  final int index;
  final QuestionReviewItem item;

  @override
  Widget build(BuildContext context) {
    final student = item.attempt.selectedOption;
    final color = !item.attempt.answered
        ? AppColors.textTertiary
        : item.isCorrect
        ? AppColors.success
        : AppColors.error;

    return AppCard(
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Q$index', style: AppTextStyles.label(context)),
              const Spacer(),
              Text(
                !item.attempt.answered
                    ? 'Skipped'
                    : item.isCorrect
                    ? 'Correct'
                    : 'Wrong',
                style: AppTextStyles.label(context).copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.question.text, style: AppTextStyles.bodyLarge(context)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your answer: ${student ?? '—'}',
            style: AppTextStyles.bodyMedium(context),
          ),
          Text(
            'Correct answer: ${item.question.correctOption} — ${item.question.correctAnswerText}',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.success),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.question.explanation,
            style: AppTextStyles.caption(context),
          ),
        ],
      ),
    );
  }
}
