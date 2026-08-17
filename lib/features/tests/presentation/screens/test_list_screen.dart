import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart' hide TestCard;
import '../../data/models/test_models.dart';
import '../../services/test_service.dart';
import '../widgets/test_card.dart';
import '../widgets/tests_scroll_body.dart';
import 'test_instructions_screen.dart';

class TestListScreen extends StatefulWidget {
  const TestListScreen({
    super.key,
    required this.examId,
    required this.category,
    required this.title,
    this.testService,
  });

  final String examId;
  final TestCategoryType category;
  final String title;
  final TestService? testService;

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  late Future<List<TestModel>> _testsFuture;

  @override
  void initState() {
    super.initState();
    _testsFuture = _loadTests();
  }

  TestService get _service => widget.testService ?? TestService.instance;

  Future<List<TestModel>> _loadTests() {
    return _service.getTests(examId: widget.examId, category: widget.category);
  }

  void _retry() {
    setState(() {
      _testsFuture = _loadTests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<TestModel>>(
        future: _testsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AppCircularProgress());
          }

          if (snapshot.hasError) {
            return _MessageBody(
              title: 'Unable to load tests',
              message: 'Please check your connection and try again.',
              actionLabel: 'Retry',
              onAction: _retry,
            );
          }

          final tests = snapshot.data ?? const <TestModel>[];
          if (tests.isEmpty) {
            return const _MessageBody(
              title: 'No tests available',
              message: 'There are no published tests in this category yet.',
            );
          }

          return TestsScrollBody(
            bottomInset: false,
            children: [
              for (var i = 0; i < tests.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                TestCard(
                  test: tests[i],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TestInstructionsScreen(test: tests[i]),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
