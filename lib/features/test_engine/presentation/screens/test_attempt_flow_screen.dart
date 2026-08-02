import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_engine_models.dart';
import '../controllers/test_engine_controller.dart';
import 'test_analysis_screen.dart';
import 'test_instructions_screen.dart';
import 'test_question_screen.dart';
import 'test_result_screen.dart';
import 'test_review_screen.dart';

enum _AttemptStep { instructions, questions, review, result, analysis }

/// Hosts the full attempt flow with a single shared [TestEngineController].
class TestAttemptFlowScreen extends StatefulWidget {
  const TestAttemptFlowScreen({
    super.key,
    required this.test,
    this.onCompleted,
  });

  final Test test;
  final void Function(TestResult result)? onCompleted;

  @override
  State<TestAttemptFlowScreen> createState() => _TestAttemptFlowScreenState();
}

class _TestAttemptFlowScreenState extends State<TestAttemptFlowScreen> {
  late TestEngineController _controller;
  _AttemptStep _step = _AttemptStep.instructions;

  @override
  void initState() {
    super.initState();
    _controller = TestEngineController(test: widget.test);
    if (widget.onCompleted != null) {
      _controller.service.onCompleted = widget.onCompleted;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await _controller.start();
    if (!mounted) return;
    setState(() => _step = _AttemptStep.questions);
  }

  Future<void> _submit() async {
    await _controller.submit();
    if (!mounted) return;
    setState(() => _step = _AttemptStep.result);
  }

  void _retry() {
    _controller.dispose();
    _controller = TestEngineController(test: widget.test);
    if (widget.onCompleted != null) {
      _controller.service.onCompleted = widget.onCompleted;
    }
    setState(() => _step = _AttemptStep.instructions);
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _AttemptStep.instructions ||
          _step == _AttemptStep.result,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_step == _AttemptStep.analysis) {
          setState(() => _step = _AttemptStep.result);
        } else if (_step == _AttemptStep.review) {
          setState(() => _step = _AttemptStep.questions);
        }
      },
      child: _buildStep(),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _AttemptStep.instructions:
        return TestInstructionsScreen(
          controller: _controller,
          onStart: _start,
        );
      case _AttemptStep.questions:
        return TestQuestionScreen(
          controller: _controller,
          onOpenReview: () => setState(() => _step = _AttemptStep.review),
          onSubmit: _submit,
        );
      case _AttemptStep.review:
        return TestReviewScreen(
          controller: _controller,
          onBackToQuestions: () =>
              setState(() => _step = _AttemptStep.questions),
          onJumpToQuestion: (index) {
            _controller.goTo(index);
            setState(() => _step = _AttemptStep.questions);
          },
          onSubmit: _submit,
        );
      case _AttemptStep.result:
        return TestResultScreen(
          controller: _controller,
          onViewAnalysis: () =>
              setState(() => _step = _AttemptStep.analysis),
          onRetry: _retry,
          onGoHome: _goHome,
        );
      case _AttemptStep.analysis:
        return TestAnalysisScreen(
          controller: _controller,
          onBack: () => setState(() => _step = _AttemptStep.result),
        );
    }
  }
}

/// Convenience scaffold wrapper when pushed as a route.
class TestAttemptRoute extends StatelessWidget {
  const TestAttemptRoute({
    super.key,
    required this.test,
    this.onCompleted,
  });

  final Test test;
  final void Function(TestResult result)? onCompleted;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context),
      child: ColoredBox(
        color: AppColors.background,
        child: TestAttemptFlowScreen(
          test: test,
          onCompleted: onCompleted,
        ),
      ),
    );
  }
}
