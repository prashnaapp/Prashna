import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class WeakTopicsSection extends StatelessWidget {
  const WeakTopicsSection({
    super.key,
    required this.topics,
  });

  final List<String> topics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'Weak Topics'),
        const SizedBox(height: AppSpacing.lg),
        if (topics.isEmpty)
          AppCard(
            child: Text(
              'Complete a few tests to identify weak areas.',
              style: AppTextStyles.bodyMedium(context),
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final topic in topics)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.divider.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Text(
                    topic,
                    style: AppTextStyles.label(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
