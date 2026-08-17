import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_engine_models.dart';
import '../controllers/test_engine_controller.dart';

/// Student-facing submit/retry status. Never shows internal exceptions.
class SubmissionStatusPanel extends StatelessWidget {
  const SubmissionStatusPanel({
    super.key,
    required this.controller,
    required this.onRetry,
  });

  final TestEngineController controller;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    switch (controller.submissionPhase) {
      case TestSubmissionPhase.submitting:
        return const Column(
          key: ValueKey('submitting-indicator'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Submitting your answers…'),
          ],
        );
      case TestSubmissionPhase.submissionFailed:
        return Column(
          key: const ValueKey('submission-error'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              controller.submissionError ??
                  'Unable to submit your test. Your answers are saved. Please try again.',
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              key: const ValueKey('retry-submission'),
              label: 'Retry Submission',
              onPressed: () {
                onRetry();
              },
            ),
          ],
        );
      case TestSubmissionPhase.idle:
      case TestSubmissionPhase.submitted:
        return const SizedBox.shrink();
    }
  }
}
