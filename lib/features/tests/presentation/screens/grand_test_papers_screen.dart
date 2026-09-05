import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../../test_engine/presentation/test_engine_navigation.dart';
import '../../data/models/test_models.dart';
import '../../data/test_series_browser_groups.dart';
import '../../services/test_service.dart';
import '../widgets/test_series_row_card.dart';
import '../widgets/tests_plain_header.dart';
import 'test_instructions_screen.dart';

/// Papers in one Grand Test series. Each paper card is a published TestModel.
class GrandTestPapersScreen extends StatefulWidget {
  const GrandTestPapersScreen({
    super.key,
    required this.examId,
    required this.seriesId,
    this.testService,
    this.syllabusService,
  });

  final String examId;
  final String seriesId;
  final TestService? testService;
  final SyllabusService? syllabusService;

  @override
  State<GrandTestPapersScreen> createState() => _GrandTestPapersScreenState();
}

class _GrandTestPapersScreenState extends State<GrandTestPapersScreen> {
  late Future<List<TestModel>> _testsFuture;

  TestService get _testService => widget.testService ?? TestService.instance;

  SyllabusService get _syllabus =>
      widget.syllabusService ?? SyllabusService.instance;

  @override
  void initState() {
    super.initState();
    _testsFuture = _loadTests();
  }

  Future<List<TestModel>> _loadTests() {
    return _testService.getTests(
      examId: widget.examId,
      category: TestCategoryType.mockTests,
    );
  }

  void _retry() {
    setState(() => _testsFuture = _loadTests());
  }

  void _openTest(BuildContext context, TestModel test) {
    Navigator.push(
      context,
      TestEngineNavigation.catalogInstructionsRoute(
        (_) => TestInstructionsScreen(test: test),
      ),
    );
  }

  String _paperTitle(TestModel test) {
    final paperId = test.paperId;
    if (paperId == null || paperId.isEmpty) return test.title;
    final paper = _syllabus.getPaper(courseId: widget.examId, paperId: paperId);
    if (paper == null) return test.title;
    return paper.title;
  }

  List<TestModel> _papersForSeries(List<TestModel> published) {
    final papers = _syllabus.getCourseById(widget.examId)?.papers ?? const [];
    final seriesTests = [
      for (final test in published)
        if (test.seriesId?.trim() == widget.seriesId) test,
    ];
    return TestSeriesBrowserGroups.papersForSeries(
      papers: papers,
      seriesTests: seriesTests,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyllabusVisual.page,
      body: Column(
        children: [
          TestsPlainHeader(
            title: widget.seriesId,
            onBack: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: FutureBuilder<List<TestModel>>(
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

                final tests = _papersForSeries(
                  snapshot.data ?? const <TestModel>[],
                );
                if (tests.isEmpty) {
                  return const _MessageBody(
                    title: 'There are no published papers in this Grand Test yet.',
                    message: '',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    SyllabusVisual.pagePadding,
                    8,
                    SyllabusVisual.pagePadding,
                    24,
                  ),
                  itemCount: tests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final test = tests[index];
                    return TestSeriesRowCard(
                      title: _paperTitle(test),
                      questionCount: test.questionCount,
                      marks: test.marks,
                      showProgress: false,
                      showStart: true,
                      onTap: () => _openTest(context, test),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium(context),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(context),
              ),
            ],
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
