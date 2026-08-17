import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../test_engine/services/test_service.dart' as engine;
import '../../data/models/test_models.dart';
import '../../data/tests_dummy_data.dart';
import '../test_quiz_navigation.dart';
import '../widgets/test_instruction_card.dart';
import '../widgets/test_summary_card.dart';
import '../widgets/tests_scroll_body.dart';

/// Catalog instructions. Opening this screen does not create a server attempt.
///
/// [START TEST] creates exactly one attempt, then opens the question engine.
class TestInstructionsScreen extends StatefulWidget {
  const TestInstructionsScreen({
    super.key,
    required this.test,
    this.startAttempt,
    this.engineService,
  });

  final TestModel test;
  final StartCatalogAttempt? startAttempt;
  final engine.TestService? engineService;

  @override
  State<TestInstructionsScreen> createState() => _TestInstructionsScreenState();
}

class _TestInstructionsScreenState extends State<TestInstructionsScreen> {
  bool _starting = false;
  String? _error;
  late final String _startRequestId;

  @override
  void initState() {
    super.initState();
    _startRequestId = engine.TestService.newStartRequestId();
  }

  InstructionModel get _instructions {
    final test = widget.test;
    return InstructionModel(
      testName: test.title,
      questionCount: test.questionCount,
      marks: test.marks,
      durationLabel: '${test.durationMinutes} Minutes',
      negativeMarking: test.negativeMarking,
      difficulty: test.difficulty,
      instructions: TestsDummyData.instructions,
    );
  }

  Future<void> _onStart() async {
    if (_starting) return;
    _starting = true;
    setState(() {
      _error = null;
    });
    try {
      final started = await openTestPracticeSession(
        context,
        widget.test,
        startAttempt: widget.startAttempt,
        engineService: widget.engineService,
        startRequestId: _startRequestId,
      );
      if (!started && mounted) {
        setState(() {
          _error = 'Unable to start the test. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructions = _instructions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Test Instructions')),
      body: TestsScrollBody(
        bottomInset: false,
        children: [
          Text(instructions.testName, style: AppTextStyles.headline(context)),
          const SizedBox(height: AppSpacing.xl),
          TestSummaryCard(instructions: instructions),
          const SizedBox(height: AppSpacing.lg),
          TestInstructionCard(instructions: instructions.instructions),
          if (_starting) ...[
            const SizedBox(height: AppSpacing.lg),
            const LinearProgressIndicator(key: ValueKey('starting-indicator')),
            const SizedBox(height: AppSpacing.md),
            Text('Starting test…', style: AppTextStyles.bodyMedium(context)),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              _error!,
              key: const ValueKey('start-test-error'),
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: AppPrimaryButton(
            key: ValueKey(_error == null ? 'start-test' : 'retry-start-test'),
            label: _error == null ? 'Start Test' : 'Retry Start Test',
            isLoading: _starting,
            onPressed: _starting ? null : _onStart,
          ),
        ),
      ),
    );
  }
}
