import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../controllers/test_engine_controller.dart';
import '../widgets/attempt_option_tile.dart';
import '../widgets/attempt_timer_badge.dart';
import '../widgets/question_palette.dart';
import '../widgets/submission_status_panel.dart';
import '../../data/models/test_engine_models.dart';

class TestQuestionScreen extends StatelessWidget {
  const TestQuestionScreen({
    super.key,
    required this.controller,
    required this.onOpenReview,
    required this.onSubmit,
  });

  final TestEngineController controller;
  final VoidCallback onOpenReview;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final question = controller.currentQuestion;
        final attempt = controller.currentAttempt;
        final urgent = controller.remaining.inMinutes < 2;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(controller.test.title),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Center(
                  child: AttemptTimerBadge(
                    label: controller.formatRemaining(),
                    urgent: urgent,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Row(
                      children: [
                        Text(
                          'Question ${controller.questionNumber} / ${controller.test.totalQuestions}',
                          style: AppTextStyles.label(context),
                        ),
                        const Spacer(),
                        if (controller.bookmarksEnabled)
                          IconButton(
                            tooltip: 'Bookmark',
                            onPressed: controller.toggleBookmark,
                            icon: Icon(
                              attempt.bookmarked
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: attempt.bookmarked
                                  ? AppColors.accentWarm
                                  : AppColors.textSecondary,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Mark for review',
                          onPressed: controller.toggleMarkForReview,
                          icon: Icon(
                            attempt.markedForReview
                                ? Icons.flag
                                : Icons.flag_outlined,
                            color: attempt.markedForReview
                                ? AppColors.primaryStrong
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppLinearProgress(
                      value:
                          controller.questionNumber /
                          controller.test.totalQuestions,
                      height: 6,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      showShadow: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.text,
                            style: AppTextStyles.bodyLarge(
                              context,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (question.teluguText != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              question.teluguText!,
                              style: AppTextStyles.bodyMedium(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (question.hasNumberedStatements) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _StatementBlock(question: question),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    for (final option in question.options) ...[
                      AttemptOptionTile(
                        key: ValueKey('attempt-option-${option.label}'),
                        label: option.label,
                        optionText: question.hasNumberedStatements
                            ? option.text
                            : option.teluguText == null
                            ? option.text
                            : '${option.text}\n${option.teluguText}',
                        selected: attempt.selectedOption == option.label,
                        onTap: () => controller.selectOption(option.label),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: attempt.selectedOption == null
                            ? null
                            : controller.clearResponse,
                        child: const Text('Clear Response'),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      SubmissionStatusPanel(
                        controller: controller,
                        onRetry: onSubmit,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: AppSecondaryButton(
                              label: 'Previous',
                              onPressed: controller.isFirst
                                  ? null
                                  : controller.goPrevious,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppPrimaryButton(
                              label: controller.isLast ? 'Review' : 'Next',
                              onPressed: controller.isLast
                                  ? onOpenReview
                                  : controller.goNext,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showPalette(context),
                              icon: const Icon(Icons.grid_view_rounded),
                              label: const Text('Palette'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: OutlinedButton(
                              key: const ValueKey('submit-attempt'),
                              onPressed:
                                  controller.isSubmitting ||
                                      controller.submissionPhase ==
                                          TestSubmissionPhase.submissionFailed
                                  ? null
                                  : () async {
                                      final ok = await _confirmSubmit(context);
                                      if (ok && context.mounted) {
                                        await onSubmit();
                                      }
                                    },
                              child: const Text('Submit'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmSubmit(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Test?'),
        content: const Text(
          'You will not be able to change answers after submitting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showPalette(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question Palette',
                    style: AppTextStyles.headline(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const QuestionStatusLegend(),
                  const SizedBox(height: AppSpacing.lg),
                  QuestionPalette(
                    attempts: controller.attempts,
                    currentIndex: controller.currentIndex,
                    onSelect: (index) {
                      controller.goTo(index);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatementBlock extends StatelessWidget {
  const _StatementBlock({required this.question});

  final TestQuestion question;

  @override
  Widget build(BuildContext context) {
    final english = question.englishStatements;
    final telugu = question.teluguStatements;
    return AppCard(
      key: const ValueKey('statement-section'),
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statements', style: AppTextStyles.label(context)),
          for (var i = 0; i < english.length; i++) ...[
            const SizedBox(height: AppSpacing.md),
            Text('${i + 1}.', style: AppTextStyles.label(context)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              english[i],
              key: ValueKey('statement-en-${i + 1}'),
              style: AppTextStyles.bodyLarge(context),
            ),
            if (i < telugu.length && telugu[i].trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                telugu[i],
                key: ValueKey('statement-te-${i + 1}'),
                style: AppTextStyles.bodyMedium(context),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
