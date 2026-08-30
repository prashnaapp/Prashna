import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_engine_models.dart';
import '../../services/test_service.dart';
import '../controllers/test_engine_controller.dart';
import '../test_engine_navigation.dart';
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
    this.serverAttemptId,
    this.skipInstructions = false,
    this.onCompleted,
    this.engineService,
    this.startAttempt,
  });

  final Test test;

  /// When set, submit goes through server-authoritative scoring.
  final String? serverAttemptId;

  /// When true, the catalog START TEST already created the attempt.
  final bool skipInstructions;
  final void Function(TestResult result)? onCompleted;
  final TestService? engineService;
  final Future<Map<String, dynamic>> Function({
    required String testId,
    required String startRequestId,
  })?
  startAttempt;

  @override
  TestAttemptFlowScreenState createState() => TestAttemptFlowScreenState();
}

class TestAttemptFlowScreenState extends State<TestAttemptFlowScreen> {
  late TestEngineController _controller;
  late Test _test;
  late String? _serverAttemptId;
  _AttemptStep _step = _AttemptStep.instructions;
  bool _startingAttempt = false;
  String? _startError;
  late String _startRequestId;

  bool get _requiresServerAttempt => widget.serverAttemptId != null;

  @override
  void initState() {
    super.initState();
    _test = widget.test;
    _serverAttemptId = widget.serverAttemptId;
    _startRequestId = TestService.newStartRequestId();
    _attachController(_buildController(_serverAttemptId));
    if (widget.skipInstructions && _serverAttemptId != null) {
      _step = _AttemptStep.questions;
      unawaited(_controller.start());
    }
  }

  TestEngineController _buildController(String? attemptId) {
    final controller = TestEngineController(
      test: _test,
      service: widget.engineService,
      serverAttemptId: attemptId,
    );
    if (widget.onCompleted != null) {
      controller.service.onCompleted = widget.onCompleted;
    }
    return controller;
  }

  void _attachController(TestEngineController controller) {
    _controller = controller;
    _controller.addListener(_syncResultStep);
  }

  void _replaceController(TestEngineController next) {
    _controller.removeListener(_syncResultStep);
    _controller.dispose();
    _attachController(next);
  }

  void _syncResultStep() {
    if (!mounted) return;
    if (!_controller.submitted || _controller.result == null) return;
    if (_step != _AttemptStep.questions && _step != _AttemptStep.review) {
      return;
    }
    setState(() => _step = _AttemptStep.result);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncResultStep);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_startingAttempt || _controller.started) return;
    if (_requiresServerAttempt &&
        (_serverAttemptId == null || _serverAttemptId!.isEmpty)) {
      _startingAttempt = true;
      _startError = null;
      setState(() {});
      try {
        final service = widget.engineService ?? TestService();
        final start = widget.startAttempt ?? service.startServerAttempt;
        final started = await start(
          testId: _test.id,
          startRequestId: _startRequestId,
        );
        final attemptId = started['attemptId'] as String?;
        if (attemptId == null || attemptId.isEmpty) {
          throw StateError('Server did not return an attempt id.');
        }
        // Rebuild from the new bilingual snapshot — never reuse a post-reveal
        // mutated Test from the previous attempt in this flow.
        final studentQuestions =
            (started['studentQuestions'] as List<dynamic>? ?? const [])
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
        if (studentQuestions.isNotEmpty) {
          _test = await service.createTestFromStudentSafeQuestions(
            id: _test.id,
            title: _test.title,
            courseId: _test.courseId,
            studentQuestions: studentQuestions,
            mode: _test.mode,
            duration: _test.duration,
            totalMarks: _test.totalMarks,
            negativeMarks: _test.negativeMarks,
            instructions: _test.instructions,
          );
        }
        if (!mounted) return;
        _serverAttemptId = attemptId;
        _replaceController(_buildController(_serverAttemptId));
        await _controller.start();
        if (!mounted) return;
        setState(() => _step = _AttemptStep.questions);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _startError = 'Unable to start the test. Please try again.';
        });
      } finally {
        _startingAttempt = false;
        if (mounted) setState(() {});
      }
      return;
    }

    await _controller.start();
    if (!mounted) return;
    setState(() => _step = _AttemptStep.questions);
  }

  Future<void> _submit() async {
    if (_controller.isSubmitting || _controller.submitted) return;
    final result = await _controller.submit();
    if (!mounted) return;
    if (result != null) {
      setState(() => _step = _AttemptStep.result);
    }
    _syncResultStep();
  }

  /// Result no longer exposes Retry Test. Kept for in-flow remapping tests
  /// until a later phase removes this path.
  @visibleForTesting
  Future<void> retryAttempt() => _retry();

  Future<void> _retry() async {
    _serverAttemptId = null;
    _startError = null;
    _startRequestId = TestService.newStartRequestId();
    _replaceController(_buildController(_serverAttemptId));
    setState(() => _step = _AttemptStep.instructions);
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) {
      if (route.isFirst) return true;
      final name = route.settings.name;
      return name != TestEngineNavigation.attemptRouteName &&
          name != TestEngineNavigation.catalogInstructionsRouteName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          _step == _AttemptStep.instructions || _step == _AttemptStep.result,
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
          isStarting: _startingAttempt,
          startError: _startError,
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
          onViewAnalysis: () => setState(() => _step = _AttemptStep.analysis),
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
    this.serverAttemptId,
    this.skipInstructions = false,
    this.onCompleted,
    this.engineService,
    this.startAttempt,
  });

  final Test test;
  final String? serverAttemptId;
  final bool skipInstructions;
  final void Function(TestResult result)? onCompleted;
  final TestService? engineService;
  final Future<Map<String, dynamic>> Function({
    required String testId,
    required String startRequestId,
  })?
  startAttempt;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context),
      child: ColoredBox(
        color: AppColors.background,
        child: TestAttemptFlowScreen(
          test: test,
          serverAttemptId: serverAttemptId,
          skipInstructions: skipInstructions,
          onCompleted: onCompleted,
          engineService: engineService,
          startAttempt: startAttempt,
        ),
      ),
    );
  }
}
