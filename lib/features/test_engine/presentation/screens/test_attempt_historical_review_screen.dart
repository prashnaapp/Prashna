import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_attempt_history_detail.dart';

/// Snapshot-backed historical question review.
///
/// Uses only frozen attempt data — never reloads live Question documents.
class TestAttemptHistoricalReviewScreen extends StatelessWidget {
  const TestAttemptHistoricalReviewScreen({
    super.key,
    required this.detail,
  });

  final TestAttemptHistoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final reviews = detail.buildQuestionReviews();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Question Review')),
      body: reviews.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  detail.summary.hasImmutableSnapshot
                      ? 'No immutable question snapshots are available for this attempt.'
                      : 'This legacy attempt does not include immutable question review.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: reviews.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                return _HistoricalReviewCard(
                  index: index + 1,
                  item: reviews[index],
                );
              },
            ),
    );
  }
}

class _HistoricalReviewCard extends StatelessWidget {
  const _HistoricalReviewCard({
    required this.index,
    required this.item,
  });

  final int index;
  final HistoricalQuestionReviewItem item;

  @override
  Widget build(BuildContext context) {
    final statusLabel = item.isSkipped
        ? 'Skipped'
        : item.isCorrect
        ? 'Correct'
        : 'Wrong';
    final statusColor = item.isSkipped
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
              Text('Q$index', style: AppTextStyles.titleMedium(context)),
              const Spacer(),
              Text(
                statusLabel,
                style: AppTextStyles.label(context).copyWith(color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.snapshot.text, style: AppTextStyles.bodyLarge(context)),
          const SizedBox(height: AppSpacing.md),
          for (final option in item.snapshot.options) ...[
            Text(
              '${option.label}. ${option.text}',
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: option.label.toUpperCase() ==
                        item.snapshot.correctOption.toUpperCase()
                    ? AppColors.success
                    : null,
                fontWeight:
                    option.label.toUpperCase() ==
                        (item.selectedOption ?? '').toUpperCase()
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your answer: ${item.selectedOption ?? '—'}',
            style: AppTextStyles.bodyMedium(context),
          ),
          Text(
            'Correct answer: ${item.snapshot.correctOption}',
            style: AppTextStyles.bodyMedium(context),
          ),
          if (item.snapshot.explanation != null &&
              item.snapshot.explanation!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.snapshot.explanation!,
              style: AppTextStyles.bodyMedium(context),
            ),
          ],
        ],
      ),
    );
  }
}
