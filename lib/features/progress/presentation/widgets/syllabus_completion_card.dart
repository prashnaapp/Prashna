import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/syllabus_completion.dart';

/// Compact student-controlled syllabus-unit completion controls.
///
/// Independent of UnitPerformance and test lists.
class SyllabusCompletionCard extends StatelessWidget {
  const SyllabusCompletionCard({
    super.key,
    this.completion,
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.mutationErrorMessage,
    this.onRetry,
    this.onMarkInProgress,
    this.onMarkCompleted,
    this.onReset,
  });

  final SyllabusCompletion? completion;
  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final String? mutationErrorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onMarkInProgress;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Unit Completion', style: AppTextStyles.titleMedium(context)),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: AppCircularProgress()),
            )
          else if (errorMessage != null)
            _ErrorBody(message: errorMessage!, onRetry: onRetry)
          else
            _StatusBody(
              status: completion?.status ?? SyllabusCompletionStatus.notStarted,
              isMutating: isMutating,
              mutationErrorMessage: mutationErrorMessage,
              onMarkInProgress: onMarkInProgress,
              onMarkCompleted: onMarkCompleted,
              onReset: onReset,
            ),
        ],
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.status,
    required this.isMutating,
    this.mutationErrorMessage,
    this.onMarkInProgress,
    this.onMarkCompleted,
    this.onReset,
  });

  final SyllabusCompletionStatus status;
  final bool isMutating;
  final String? mutationErrorMessage;
  final VoidCallback? onMarkInProgress;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onReset;

  String get _label {
    switch (status) {
      case SyllabusCompletionStatus.notStarted:
        return 'Not Started';
      case SyllabusCompletionStatus.inProgress:
        return 'In Progress';
      case SyllabusCompletionStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Completion: $_label', style: AppTextStyles.bodyMedium(context)),
        const SizedBox(height: AppSpacing.md),
        if (isMutating)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: AppCircularProgress(),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (status == SyllabusCompletionStatus.notStarted)
                TextButton(
                  onPressed: onMarkInProgress,
                  child: const Text('Mark as In Progress'),
                ),
              if (status == SyllabusCompletionStatus.inProgress)
                TextButton(
                  onPressed: onMarkCompleted,
                  child: const Text('Mark as Completed'),
                ),
              if (status == SyllabusCompletionStatus.completed) ...[
                TextButton(
                  onPressed: onMarkInProgress,
                  child: const Text('Mark as In Progress'),
                ),
                TextButton(onPressed: onReset, child: const Text('Reset')),
              ],
            ],
          ),
        if (mutationErrorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(mutationErrorMessage!, style: AppTextStyles.bodyMedium(context)),
        ],
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
        Text(message, style: AppTextStyles.bodyMedium(context)),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ],
    );
  }
}
