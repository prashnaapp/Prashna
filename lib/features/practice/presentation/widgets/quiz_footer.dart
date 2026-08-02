import 'package:flutter/material.dart';

import '../widgets/primary_action_button.dart';

class QuizFooter extends StatelessWidget {
  const QuizFooter({
    super.key,
    required this.submitted,
    required this.isLastQuestion,
    this.onSubmit,
    this.onNext,
    this.onFinish,
    this.canSubmit = false,
  });

  final bool submitted;
  final bool isLastQuestion;
  final bool canSubmit;
  final VoidCallback? onSubmit;
  final VoidCallback? onNext;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    if (!submitted) {
      return PrimaryActionButton(
        label: 'Submit',
        onPressed: canSubmit ? onSubmit : null,
      );
    }

    return PrimaryActionButton(
      label: isLastQuestion ? 'Finish Practice' : 'Next Question',
      onPressed: isLastQuestion ? onFinish : onNext,
    );
  }
}
