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
            toolbarHeight: 52,
            titleSpacing: AppSpacing.sm,
            title: Text(
              controller.test.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium(context),
            ),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Question ${controller.questionNumber} / ${controller.test.totalQuestions}',
                          style: AppTextStyles.label(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (controller.bookmarksEnabled)
                          IconButton(
                            tooltip: 'Bookmark',
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: const Size(40, 40),
                              padding: const EdgeInsets.all(AppSpacing.xs),
                            ),
                            onPressed: controller.toggleBookmark,
                            icon: Icon(
                              attempt.bookmarked
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: AppSizes.iconLg,
                              color: attempt.bookmarked
                                  ? AppColors.accentWarm
                                  : AppColors.textTertiary,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Mark for review',
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(40, 40),
                            padding: const EdgeInsets.all(AppSpacing.xs),
                          ),
                          onPressed: controller.toggleMarkForReview,
                          icon: Icon(
                            attempt.markedForReview
                                ? Icons.flag
                                : Icons.flag_outlined,
                            size: AppSizes.iconLg,
                            color: attempt.markedForReview
                                ? AppColors.primaryStrong
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppLinearProgress(
                      value:
                          controller.questionNumber /
                          controller.test.totalQuestions,
                      height: 4,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _CompactExamAction(
                          key: const ValueKey('open-review'),
                          icon: Icons.outlined_flag,
                          label: 'Review',
                          onPressed: controller.isSubmitting
                              ? null
                              : onOpenReview,
                        ),
                        _CompactExamAction(
                          key: const ValueKey('open-palette'),
                          icon: Icons.grid_view_rounded,
                          label: 'Palette',
                          onPressed: controller.isSubmitting
                              ? null
                              : () => _showPalette(context),
                        ),
                        const Spacer(),
                        _CompactExamAction(
                          key: const ValueKey('go-next'),
                          icon: Icons.arrow_forward,
                          label: 'Next',
                          onPressed: controller.isSubmitting || controller.isLast
                              ? null
                              : controller.goNext,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.massive,
                  ),
                  children: [
                    Text(
                      question.text,
                      style: AppTextStyles.titleMedium(context).copyWith(
                        height: 1.4,
                      ),
                    ),
                    if (question.teluguText != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        question.teluguText!,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          height: 1.45,
                        ),
                      ),
                    ],
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
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: attempt.selectedOption == null
                            ? null
                            : controller.clearResponse,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                        child: const Text('Clear Response'),
                      ),
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.divider),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        SubmissionStatusPanel(
                          controller: controller,
                          onRetry: onSubmit,
                        ),
                        if (controller.submissionPhase ==
                                TestSubmissionPhase.submitting ||
                            controller.submissionPhase ==
                                TestSubmissionPhase.submissionFailed)
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
                              child: OutlinedButton(
                                key: const ValueKey('submit-attempt'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(
                                    AppSizes.buttonLarge,
                                  ),
                                ),
                                onPressed:
                                    controller.isSubmitting ||
                                        controller.submissionPhase ==
                                            TestSubmissionPhase.submissionFailed
                                    ? null
                                    : () async {
                                        final ok = await _confirmSubmit(
                                          context,
                                        );
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

class _CompactExamAction extends StatelessWidget {
  const _CompactExamAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.textSecondary,
      ),
      icon: Icon(icon, size: AppSizes.iconSm),
      label: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
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
    return Column(
      key: const ValueKey('statement-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statements',
          style: AppTextStyles.caption(context).copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < english.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatementIndexBadge(index: i + 1),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      english[i],
                      key: ValueKey('statement-en-${i + 1}'),
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    if (i < telugu.length && telugu[i].trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        telugu[i],
                        key: ValueKey('statement-te-${i + 1}'),
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatementIndexBadge extends StatelessWidget {
  const _StatementIndexBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.xxl,
      height: AppSpacing.xxl,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        index.toString().padLeft(2, '0'),
        style: AppTextStyles.caption(context).copyWith(
          color: AppColors.primaryStrong,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
