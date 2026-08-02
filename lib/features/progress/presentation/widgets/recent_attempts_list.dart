import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/attempt_analytics_models.dart';

class RecentAttemptsList extends StatelessWidget {
  const RecentAttemptsList({
    super.key,
    required this.attempts,
  });

  final List<AttemptHistory> attempts;

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) {
      return AppCard(
        showShadow: false,
        child: Text(
          'No attempts yet. Complete a test to see history.',
          style: AppTextStyles.bodyMedium(context),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < attempts.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          AppCard(
            showShadow: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        attempts[i].topicName ??
                            attempts[i].paperName ??
                            attempts[i].testId,
                        style: AppTextStyles.titleMedium(context),
                      ),
                    ),
                    Text(
                      '${attempts[i].percentage.toStringAsFixed(0)}%',
                      style: AppTextStyles.label(context).copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${attempts[i].testMode} · ${attempts[i].correct}C / ${attempts[i].wrong}W / ${attempts[i].skipped}S',
                  style: AppTextStyles.caption(context),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
