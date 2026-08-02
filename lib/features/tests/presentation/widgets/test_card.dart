import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_models.dart';

class TestCard extends StatelessWidget {
  const TestCard({
    super.key,
    required this.test,
    required this.onTap,
  });

  final TestModel test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  test.title,
                  style: AppTextStyles.titleMedium(context),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
          if (test.category != TestCategoryType.previousYear) ...[
            const SizedBox(height: AppSpacing.md),
            _Meta(label: 'Questions', value: '${test.questionCount}'),
            const SizedBox(height: AppSpacing.xs),
            _Meta(label: 'Marks', value: '${test.marks}'),
          ],
          if (test.category == TestCategoryType.mockTests) ...[
            const SizedBox(height: AppSpacing.xs),
            _Meta(
              label: 'Duration',
              value: '${test.durationMinutes} Minutes',
            ),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: AppTextStyles.bodyMedium(context),
    );
  }
}
