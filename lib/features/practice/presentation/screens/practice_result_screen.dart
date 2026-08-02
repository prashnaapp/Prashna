import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/quiz_statistics.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/result_header.dart';
import '../widgets/result_stat_tile.dart';

class PracticeResultScreen extends StatelessWidget {
  const PracticeResultScreen({
    super.key,
    required this.statistics,
  });

  final QuizStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final accuracy = statistics.accuracyPercent.toStringAsFixed(0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Practice Result')),
      body: AppResponsivePadding(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ResultHeader(),
              const SizedBox(height: AppSpacing.xxxl),
              AppCard(
                child: Column(
                  children: [
                    ResultStatTile(
                      label: 'Total Questions',
                      value: '${statistics.totalQuestions}',
                    ),
                    ResultStatTile(
                      label: 'Correct Answers',
                      value: '${statistics.correctAnswers}',
                    ),
                    ResultStatTile(
                      label: 'Wrong Answers',
                      value: '${statistics.wrongAnswers}',
                    ),
                    ResultStatTile(
                      label: 'Unanswered',
                      value: '${statistics.unansweredQuestions}',
                    ),
                    ResultStatTile(
                      label: 'Score',
                      value:
                          '${statistics.score} / ${statistics.totalQuestions}',
                    ),
                    ResultStatTile(
                      label: 'Accuracy',
                      value: '$accuracy %',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryActionButton(
                label: 'Review Answers',
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              AppOutlinedButton(
                label: 'Back to Chapters',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
