import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../practice/presentation/widgets/primary_action_button.dart';
import '../../data/models/test_models.dart';
import '../../services/test_service.dart';
import '../test_quiz_navigation.dart';
import '../widgets/test_instruction_card.dart';
import '../widgets/test_summary_card.dart';
import '../widgets/tests_scroll_body.dart';

class TestInstructionsScreen extends StatelessWidget {
  const TestInstructionsScreen({
    super.key,
    required this.test,
  });

  final TestModel test;

  @override
  Widget build(BuildContext context) {
    final instructions = TestService.instance.getInstructions(test);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Test Instructions')),
      body: TestsScrollBody(
        bottomInset: false,
        children: [
          Text(
            instructions.testName,
            style: AppTextStyles.headline(context),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TestSummaryCard(instructions: instructions),
          const SizedBox(height: AppSpacing.lg),
          TestInstructionCard(
            instructions: instructions.instructions,
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryActionButton(
            label: 'Start Test',
            onPressed: () => openTestPracticeSession(context, test),
          ),
        ],
      ),
    );
  }
}
