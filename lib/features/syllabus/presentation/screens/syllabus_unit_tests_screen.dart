import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../progress/data/models/syllabus_completion.dart';
import '../../../progress/data/models/unit_performance.dart';
import '../../../progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import '../../../progress_cloud/repository/unit_performance_cloud_repository.dart';
import '../../../test_engine/presentation/test_engine_navigation.dart';
import '../../../tests/data/models/test_models.dart';
import '../../../tests/presentation/screens/test_instructions_screen.dart';
import '../../../tests/presentation/widgets/tests_scroll_body.dart';
import '../../../tests/services/test_service.dart';
import '../../data/models/canonical_scope.dart';
import '../../services/syllabus_service.dart';
import '../syllabus_visual.dart';
import '../widgets/syllabus_unit_visual.dart';
import '../widgets/unit_detail_backdrop.dart';
import '../widgets/unit_detail_performance_card.dart';
import '../widgets/unit_detail_surface.dart';
import '../widgets/unit_detail_test_card.dart';

/// Final syllabus-unit leaf: completion, performance, and published tests.
class SyllabusUnitTestsScreen extends StatefulWidget {
  const SyllabusUnitTestsScreen({
    super.key,
    required this.courseId,
    required this.paperId,
    required this.unitId,
    this.partId,
    this.testService,
    this.unitPerformanceRepository,
    this.syllabusCompletionRepository,
  });

  final String courseId;
  final String paperId;
  final String? partId;
  final String unitId;
  final TestService? testService;
  final UnitPerformanceCloudRepository? unitPerformanceRepository;
  final SyllabusCompletionCloudRepository? syllabusCompletionRepository;

  @override
  State<SyllabusUnitTestsScreen> createState() =>
      _SyllabusUnitTestsScreenState();
}

class _SyllabusUnitTestsScreenState extends State<SyllabusUnitTestsScreen> {
  late Future<List<TestModel>> _testsFuture;
  late Future<UnitPerformance?> _performanceFuture;
  late Future<SyllabusCompletion?> _completionFuture;
  CanonicalScope? _scope;

  @override
  void initState() {
    super.initState();
    _scope = CanonicalScope.tryFromSyllabusUnit(
      courseId: widget.courseId,
      paperId: widget.paperId,
      partId: widget.partId,
      syllabusUnitId: widget.unitId,
    );
    _testsFuture = _loadTests();
    _performanceFuture = _loadPerformance();
    _completionFuture = _loadCompletion();
  }

  Future<List<TestModel>> _loadTests() {
    final service = widget.testService ?? TestService.instance;
    return service.getTestsForSyllabusUnit(
      courseId: widget.courseId,
      paperId: widget.paperId,
      partId: widget.partId,
      syllabusUnitId: widget.unitId,
    );
  }

  Future<UnitPerformance?> _loadPerformance() async {
    final scope = _scope;
    if (scope == null) return null;
    final repository =
        widget.unitPerformanceRepository ?? UnitPerformanceCloudRepository();
    return repository.getUnitPerformance(scope.scopeKey);
  }

  Future<SyllabusCompletion?> _loadCompletion() async {
    final scope = _scope;
    if (scope == null) return null;
    final repository =
        widget.syllabusCompletionRepository ??
        SyllabusCompletionCloudRepository();
    return repository.getCompletion(scope: scope);
  }

  void _retryTests() {
    setState(() => _testsFuture = _loadTests());
  }

  void _retryPerformance() {
    setState(() => _performanceFuture = _loadPerformance());
  }

  void _openTest(TestModel test) {
    Navigator.push(
      context,
      TestEngineNavigation.catalogInstructionsRoute(
        (_) => TestInstructionsScreen(test: test),
      ),
    );
  }

  String get _unitTitle {
    final unit = widget.partId == null
        ? SyllabusService.instance.getPaperSyllabusUnit(
            courseId: widget.courseId,
            paperId: widget.paperId,
            unitId: widget.unitId,
          )
        : SyllabusService.instance.getPartSyllabusUnit(
            courseId: widget.courseId,
            paperId: widget.paperId,
            partId: widget.partId!,
            unitId: widget.unitId,
          );
    final canonical = unit?.displayName ?? 'Tests';
    final visual = SyllabusUnitVisualCatalog.resolve(
      unitId: widget.unitId,
      displayName: canonical,
      index: 0,
    );
    return visual.cardTitle ?? canonical;
  }

  String get _contextLine {
    final course = SyllabusService.instance.getCourseById(widget.courseId);
    final paper = SyllabusService.instance.getPaper(
      courseId: widget.courseId,
      paperId: widget.paperId,
    );
    return [
      course?.name,
      paper?.title,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: SyllabusVisual.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: SyllabusVisual.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        leadingWidth: canPop ? 56 : 0,
        leading: canPop ? const _UnitDetailBackButton() : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _unitTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium(context).copyWith(
                color: SyllabusVisual.ink,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                height: 1.15,
                letterSpacing: -0.2,
              ),
            ),
            if (_contextLine.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _contextLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: SyllabusVisual.accent.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: UnitDetailBackdrop()),
          FutureBuilder<List<TestModel>>(
            future: _testsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _scrollBody(
                  testsChild: const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: AppCircularProgress()),
                  ),
                );
              }
              if (snapshot.hasError) {
                return _scrollBody(
                  testsChild: _MessageCard(
                    title: 'Unable to load tests',
                    message: 'Please check your connection and try again.',
                    actionLabel: 'Retry',
                    onAction: _retryTests,
                  ),
                );
              }

              final tests = snapshot.data ?? const <TestModel>[];
              if (tests.isEmpty) {
                return _scrollBody(
                  testsChild: const _MessageCard(
                    title: 'No tests available',
                    message:
                        'There are no published tests in this syllabus unit yet.',
                  ),
                );
              }

              return _scrollBody(
                testsChild: Column(
                  children: [
                    for (var i = 0; i < tests.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      UnitDetailTestCard(
                        test: tests[i],
                        onOpen: () => _openTest(tests[i]),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _scrollBody({required Widget testsChild}) {
    return TestsScrollBody(
      bottomInset: false,
      padding: const EdgeInsets.fromLTRB(
        SyllabusVisual.pagePadding,
        AppSpacing.sm,
        SyllabusVisual.pagePadding,
        AppSpacing.xxl,
      ),
      children: [
        FutureBuilder<SyllabusCompletion?>(
          future: _completionFuture,
          builder: (_, _) => const SizedBox.shrink(),
        ),
        _buildPerformanceSection(),
        if (_scope != null) const SizedBox(height: AppSpacing.xl),
        Text(
          'Tests in this Unit',
          style: AppTextStyles.titleMedium(context).copyWith(
            color: SyllabusVisual.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        testsChild,
      ],
    );
  }

  Widget _buildPerformanceSection() {
    if (_scope == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<UnitPerformance?>(
      future: _performanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const UnitDetailPerformanceCard(isLoading: true);
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          final signedOut =
              error is StateError &&
              error.message.contains('no authenticated user');
          return UnitDetailPerformanceCard(
            errorMessage: signedOut
                ? 'Sign in to view unit performance.'
                : 'Unable to load unit performance.',
            onRetry: signedOut ? null : _retryPerformance,
          );
        }
        return UnitDetailPerformanceCard(performance: snapshot.data);
      },
    );
  }
}

class _UnitDetailBackButton extends StatelessWidget {
  const _UnitDetailBackButton();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(12));
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: SyllabusVisual.accent.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: SyllabusVisual.surface,
          shape: const RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: BackButton(
              color: SyllabusVisual.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
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
    return UnitDetailSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium(context).copyWith(
              color: SyllabusVisual.ink,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context).copyWith(
              color: SyllabusVisual.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: SyllabusVisual.accent,
                minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
