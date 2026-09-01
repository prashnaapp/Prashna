import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';
import '../../../test_engine/services/test_service.dart' as engine;
import '../../data/models/test_models.dart';
import '../../data/tests_dummy_data.dart';
import '../test_instructions_presentation.dart';
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
      durationLabel: TestInstructionsPresentation.durationLabel(
        test.durationMinutes,
      ),
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
    final contextLabel = TestInstructionsPresentation.contextLabel(widget.test);

    return Scaffold(
      backgroundColor: SyllabusVisual.page,
      appBar: AppBar(
        backgroundColor: SyllabusVisual.page,
        foregroundColor: SyllabusVisual.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Test Instructions',
          style: AppTextStyles.titleMedium(context).copyWith(
            color: SyllabusVisual.ink,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: TestsScrollBody(
        bottomInset: false,
        padding: const EdgeInsets.fromLTRB(
          SyllabusVisual.pagePadding,
          4,
          SyllabusVisual.pagePadding,
          AppSpacing.md,
        ),
        children: [
          Text(
            instructions.testName,
            style: AppTextStyles.titleLarge(context).copyWith(
              color: SyllabusVisual.ink,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.2,
            ),
          ),
          if (contextLabel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SyllabusVisual.tileLavender,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    contextLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: SyllabusVisual.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TestSummaryCard(instructions: instructions),
          const SizedBox(height: 16),
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
      bottomNavigationBar: ColoredBox(
        color: SyllabusVisual.page,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SyllabusVisual.pagePadding,
              8,
              SyllabusVisual.pagePadding,
              16,
            ),
            child: AppPrimaryButton(
              key: ValueKey(_error == null ? 'start-test' : 'retry-start-test'),
              label: _error == null ? 'Start Test' : 'Retry Start Test',
              icon: Icons.play_arrow_rounded,
              isLoading: _starting,
              onPressed: _starting ? null : _onStart,
            ),
          ),
        ),
      ),
    );
  }
}
