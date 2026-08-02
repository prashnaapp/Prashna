import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../controllers/test_engine_controller.dart';
import '../widgets/attempt_summary_grid.dart';
import '../widgets/question_palette.dart';

class TestReviewScreen extends StatelessWidget {
  const TestReviewScreen({
    super.key,
    required this.controller,
    required this.onBackToQuestions,
    required this.onJumpToQuestion,
    required this.onSubmit,
  });

  final TestEngineController controller;
  final VoidCallback onBackToQuestions;
  final ValueChanged<int> onJumpToQuestion;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Review'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackToQuestions,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Attempt Summary', style: AppTextStyles.headline(context)),
              const SizedBox(height: AppSpacing.lg),
              AttemptSummaryGrid(counts: controller.statusCounts),
              const SizedBox(height: AppSpacing.xl),
              const QuestionStatusLegend(),
              const SizedBox(height: AppSpacing.lg),
              QuestionPalette(
                attempts: controller.attempts,
                currentIndex: controller.currentIndex,
                onSelect: onJumpToQuestion,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppPrimaryButton(
                label: 'Submit Test',
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Submit Test?'),
                      content: const Text(
                        'Submit your answers for evaluation.',
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
                  if (ok == true && context.mounted) await onSubmit();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppSecondaryButton(
                label: 'Back to Questions',
                onPressed: onBackToQuestions,
              ),
            ],
          ),
        );
      },
    );
  }
}
