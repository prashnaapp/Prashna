import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_models.dart';

class TestCard extends StatelessWidget {
  const TestCard({
    super.key,
    required this.test,
    required this.onTap,
    this.accentColor,
  });

  final TestModel test;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primaryStrong;
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.lg),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        AppAccentIcon(
                          icon: Icons.quiz_rounded,
                          color: accent,
                          size: 40,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            test.title,
                            style: AppTextStyles.titleMedium(context),
                          ),
                        ),
                      ],
                    ),
                    if (test.category != TestCategoryType.previousYear) ...[
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _Meta(
                            label: 'Questions',
                            value: '${test.questionCount}',
                          ),
                          _Meta(label: 'Marks', value: '${test.marks}'),
                          if (test.category == TestCategoryType.mockTests)
                            _Meta(
                              label: 'Duration',
                              value: '${test.durationMinutes} Minutes',
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppPrimaryButton(
                        label: 'Start',
                        expand: false,
                        size: AppButtonSize.medium,
                        onPressed: onTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    return Text('$label: $value', style: AppTextStyles.bodyMedium(context));
  }
}
