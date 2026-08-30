import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';
import '../../../syllabus/presentation/widgets/syllabus_header_band.dart';
import '../../../syllabus/presentation/widgets/syllabus_paper_progress_banner.dart';
import '../../../syllabus/presentation/widgets/syllabus_selector_pill.dart';
import '../../../syllabus/presentation/widgets/syllabus_wave_footer.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../../test_engine/presentation/test_engine_navigation.dart';
import '../../data/models/test_models.dart';
import '../../data/test_series_browser_groups.dart';
import '../../services/test_service.dart';
import '../widgets/test_series_row_card.dart';
import 'test_instructions_screen.dart';

/// Chapters-style Test Series browser: pills on top, cards underneath.
class TestSeriesBrowserScreen extends StatefulWidget {
  const TestSeriesBrowserScreen({
    super.key,
    required this.examId,
    required this.mode,
    this.title,
    this.testService,
    this.syllabusService,
  });

  final String examId;

  /// Header label. Defaults to the category name for [mode].
  final String? title;
  final TestSeriesBrowserMode mode;
  final TestService? testService;
  final SyllabusService? syllabusService;

  @override
  State<TestSeriesBrowserScreen> createState() =>
      _TestSeriesBrowserScreenState();
}

class _TestSeriesBrowserScreenState extends State<TestSeriesBrowserScreen> {
  late final String _examId;
  String? _selectedTabId;
  late Future<List<TestModel>> _testsFuture;

  TestService get _testService => widget.testService ?? TestService.instance;

  SyllabusService get _syllabus =>
      widget.syllabusService ?? SyllabusService.instance;

  @override
  void initState() {
    super.initState();
    _examId = widget.examId;
    _testsFuture = _loadTests();
  }

  TestCategoryType get _category {
    return switch (widget.mode) {
      TestSeriesBrowserMode.paperWise => TestCategoryType.partTests,
      TestSeriesBrowserMode.grandTests => TestCategoryType.mockTests,
      TestSeriesBrowserMode.previousPapers => TestCategoryType.previousYear,
    };
  }

  Future<List<TestModel>> _loadTests() async {
    final published = await _testService.getTests(
      examId: _examId,
      category: _category,
    );
    return published;
  }

  void _retry() {
    setState(() => _testsFuture = _loadTests());
  }

  SyllabusCourse? get _course => _syllabus.getCourseById(_examId);

  List<SyllabusPaper> get _papers => _course?.papers ?? const [];

  String get _title =>
      widget.title ??
      switch (widget.mode) {
        TestSeriesBrowserMode.paperWise => 'Paper-wise Tests',
        TestSeriesBrowserMode.grandTests => 'Grand Tests',
        TestSeriesBrowserMode.previousPapers => 'Previous Papers',
      };

  List<TestSeriesTab> _tabsFor(List<TestModel> tests) {
    return switch (widget.mode) {
      TestSeriesBrowserMode.paperWise => TestSeriesBrowserGroups.paperWise(
        papers: _papers,
        tests: tests,
      ),
      TestSeriesBrowserMode.grandTests => TestSeriesBrowserGroups.grandTests(
        tests,
      ),
      TestSeriesBrowserMode.previousPapers =>
        TestSeriesBrowserGroups.previousPapers(tests),
    };
  }

  TestSeriesTab? _selectedTab(List<TestSeriesTab> tabs) {
    if (tabs.isEmpty) return null;
    for (final tab in tabs) {
      if (tab.id == _selectedTabId) return tab;
    }
    return tabs.first;
  }

  void _openTest(TestModel test) {
    Navigator.push(
      context,
      TestEngineNavigation.catalogInstructionsRoute(
        (_) => TestInstructionsScreen(test: test),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyllabusVisual.page,
      body: Column(
        children: [
          SyllabusHeaderBand(
            child: _BrowserHeader(
              title: _title,
              onBack: () => Navigator.maybePop(context),
            ),
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

                final tests = snapshot.data ?? const <TestModel>[];
                final tabs = _tabsFor(tests);
                final selected = _selectedTab(tabs);
                final cards = selected?.tests ?? const <TestModel>[];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    SyllabusVisual.pagePadding,
                    8,
                    SyllabusVisual.pagePadding,
                    24,
                  ),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (tabs.isNotEmpty) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < tabs.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              SyllabusSelectorPill(
                                label: tabs[i].label,
                                selected: tabs[i].id == selected?.id,
                                onTap: () {
                                  if (_selectedTabId == tabs[i].id) return;
                                  setState(() => _selectedTabId = tabs[i].id);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (cards.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: _MessageBody(
                          title: 'No tests available',
                          message:
                              'There are no published tests in this category yet.',
                        ),
                      )
                    else
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        TestSeriesRowCard(
                          title: cards[i].title,
                          questionCount: cards[i].questionCount,
                          marks: cards[i].marks,
                          progress: 0,
                          onTap: () => _openTest(cards[i]),
                        ),
                      ],
                    if (selected != null && cards.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      SyllabusPaperProgressBanner(
                        paperTitle: selected.label,
                        progress: 0,
                      ),
                    ],
                    const SizedBox(height: 8),
                    const SyllabusWaveFooter(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowserHeader extends StatelessWidget {
  const _BrowserHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: SyllabusVisual.headerOn,
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleLarge(context).copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: SyllabusVisual.headerOn,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _HeaderBell(),
        ],
      ),
    );
  }
}

class _HeaderBell extends StatelessWidget {
  const _HeaderBell();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 22,
          ),
          Positioned(
            top: 6,
            right: 7,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
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
