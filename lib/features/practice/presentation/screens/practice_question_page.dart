import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../controllers/quiz_controller.dart';
import '../widgets/correct_answer_card.dart';
import '../widgets/explanation_card.dart';
import '../widgets/option_tile.dart';
import '../widgets/question_card.dart';
import '../widgets/question_progress.dart';
import '../widgets/quiz_footer.dart';
import '../widgets/quiz_stats.dart';
import '../widgets/quiz_timer.dart';

class PracticeQuestionPage extends StatelessWidget {
  const PracticeQuestionPage({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.onNext,
    required this.onFinish,
  });

  final QuizController controller;
  final VoidCallback onSubmit;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final question = controller.currentQuestion;
    final submitted = controller.submitted;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QuestionProgress(
                  current: controller.currentNumber,
                  total: controller.statistics.totalQuestions,
                ),
                const SizedBox(height: AppSpacing.lg),
                QuizTimer(secondsRemaining: controller.secondsRemaining),
                const SizedBox(height: AppSpacing.md),
                QuizStats(statistics: controller.statistics),
                const SizedBox(height: AppSpacing.xxl),
                QuestionCard(prompt: question.question),
                const SizedBox(height: AppSpacing.lg),
                for (var i = 0; i < question.options.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  OptionTile(
                    label: question.options[i].label,
                    optionText: question.options[i].text,
                    selected:
                        controller.selectedLabel == question.options[i].label,
                    onTap: submitted
                        ? null
                        : () => controller.selectOption(
                              question.options[i].label,
                            ),
                  ),
                ],
                if (submitted) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  CorrectAnswerCard(answerText: question.correctAnswerText),
                  const SizedBox(height: AppSpacing.lg),
                  ExplanationCard(explanation: question.explanation),
                ],
                const SizedBox(height: AppSpacing.xxxl),
                QuizFooter(
                  submitted: submitted,
                  isLastQuestion: controller.isLastQuestion,
                  canSubmit: controller.selectedLabel != null,
                  onSubmit: onSubmit,
                  onNext: onNext,
                  onFinish: onFinish,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
