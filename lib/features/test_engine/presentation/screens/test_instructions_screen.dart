import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_engine_models.dart';
import '../controllers/test_engine_controller.dart';

class TestInstructionsScreen extends StatelessWidget {
  const TestInstructionsScreen({
    super.key,
    required this.controller,
    required this.onStart,
  });

  final TestEngineController controller;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final test = controller.test;
    final minutes = test.duration.inMinutes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(test.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Instructions', style: AppTextStyles.headline(context)),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            showShadow: false,
            child: Column(
              children: [
                _MetaRow(label: 'Questions', value: '${test.totalQuestions}'),
                const Divider(height: AppSpacing.xxl),
                _MetaRow(label: 'Total Marks', value: '${test.totalMarks}'),
                const Divider(height: AppSpacing.xxl),
                _MetaRow(label: 'Duration', value: '$minutes min'),
                const Divider(height: AppSpacing.xxl),
                _MetaRow(
                  label: 'Negative Marks',
                  value: test.negativeMarks == 0
                      ? 'None'
                      : '-${test.negativeMarks}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < test.instructions.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    test.instructions[i],
                    style: AppTextStyles.bodyMedium(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.xxl),
          AppPrimaryButton(
            label: 'Start Test',
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMedium(context)),
        ),
        Text(
          value,
          style: AppTextStyles.label(context).copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

String testModeLabel(TestMode mode) {
  switch (mode) {
    case TestMode.practice:
      return 'Practice';
    case TestMode.topic:
      return 'Topic Test';
    case TestMode.section:
      return 'Section Test';
    case TestMode.paper:
      return 'Paper Test';
    case TestMode.mock:
      return 'Mock Test';
    case TestMode.previousYear:
      return 'Previous Year';
    case TestMode.grand:
      return 'Grand Test';
  }
}
