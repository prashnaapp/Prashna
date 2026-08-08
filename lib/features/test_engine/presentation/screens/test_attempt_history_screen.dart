import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_attempt_history.dart';
import '../../repository/test_attempt_cloud_repository.dart';
import 'test_attempt_history_detail_screen.dart';

/// Lists the signed-in user's completed Firestore test attempts.
class TestAttemptHistoryScreen extends StatefulWidget {
  const TestAttemptHistoryScreen({
    super.key,
    this.repository,
  });

  final TestAttemptCloudRepository? repository;

  @override
  State<TestAttemptHistoryScreen> createState() =>
      _TestAttemptHistoryScreenState();
}

class _TestAttemptHistoryScreenState extends State<TestAttemptHistoryScreen> {
  late final TestAttemptCloudRepository _repository;
  late Future<List<TestAttemptHistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TestAttemptCloudRepository();
    _future = _repository.getMyCompletedAttempts();
  }

  void _retry() {
    setState(() {
      _future = _repository.getMyCompletedAttempts();
    });
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _formatScore(double score) {
    return score == score.roundToDouble()
        ? score.toStringAsFixed(0)
        : score.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Test History')),
      body: FutureBuilder<List<TestAttemptHistoryItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AppCircularProgress());
          }

          if (snapshot.hasError) {
            return _MessageBody(
              title: 'Unable to load history',
              message: 'Please check your connection and try again.',
              actionLabel: 'Retry',
              onAction: _retry,
            );
          }

          final items = snapshot.data ?? const <TestAttemptHistoryItem>[];
          if (items.isEmpty) {
            return const _MessageBody(
              title: 'No attempts yet',
              message: 'Completed tests will appear here after you submit them.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = items[index];
              final completedAt = item.submittedAt ?? item.startedAt;
              return AppCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TestAttemptHistoryDetailScreen(item: item),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.displayTestTitle,
                            style: AppTextStyles.titleMedium(context),
                          ),
                        ),
                        Text(
                          item.passed ? 'Passed' : 'Not passed',
                          style: AppTextStyles.label(context).copyWith(
                            color: item.passed
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.displayCourseTitle,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Score ${_formatScore(item.score)} · '
                      '${item.percentage}% · '
                      'Accuracy ${item.accuracy}%',
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatDate(completedAt),
                      style: AppTextStyles.bodyMedium(context),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
