import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart' hide TestCard;
import '../../../progress/data/models/syllabus_completion.dart';
import '../../../progress/data/models/unit_performance.dart';
import '../../../progress/presentation/widgets/syllabus_completion_card.dart';
import '../../../progress/presentation/widgets/unit_performance_card.dart';
import '../../../progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import '../../../progress_cloud/repository/unit_performance_cloud_repository.dart';
import '../../../tests/data/models/test_models.dart';
import '../../../tests/presentation/screens/test_instructions_screen.dart';
import '../../../tests/presentation/widgets/test_card.dart';
import '../../../tests/presentation/widgets/tests_scroll_body.dart';
import '../../../tests/services/test_service.dart';
import '../../data/models/canonical_scope.dart';
import '../../services/syllabus_service.dart';

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
  bool _completionMutating = false;
  String? _completionMutationError;

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

  void _retryCompletion() {
    setState(() {
      _completionMutationError = null;
      _completionFuture = _loadCompletion();
    });
  }

  Future<void> _mutateCompletion(
    Future<SyllabusCompletion> Function(
      SyllabusCompletionCloudRepository,
      CanonicalScope,
    )
    action,
  ) async {
    final scope = _scope;
    if (scope == null || _completionMutating) return;

    setState(() {
      _completionMutating = true;
      _completionMutationError = null;
    });

    try {
      final repository =
          widget.syllabusCompletionRepository ??
          SyllabusCompletionCloudRepository();
      final updated = await action(repository, scope);
      if (!mounted) return;
      setState(() {
        _completionFuture = Future.value(updated);
        _completionMutating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _completionMutating = false;
        _completionMutationError = 'Unable to update completion.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = SyllabusService.instance.getCourseById(widget.courseId);
    final paper = SyllabusService.instance.getPaper(
      courseId: widget.courseId,
      paperId: widget.paperId,
    );
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
    final part = widget.partId == null
        ? null
        : SyllabusService.instance.getPart(
            courseId: widget.courseId,
            paperId: widget.paperId,
            partId: widget.partId!,
          );

    final breadcrumb = [
      course?.name,
      paper?.title,
      if (part != null) part.displayName,
      unit?.displayName,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(unit?.displayName ?? 'Tests')),
      body: FutureBuilder<List<TestModel>>(
        future: _testsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return TestsScrollBody(
              bottomInset: false,
              children: [
                _UnitHero(
                  title: unit?.displayName ?? 'Syllabus Unit',
                  breadcrumb: breadcrumb,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _buildCompletionSection(),
                const SizedBox(height: AppSpacing.xxl),
                _buildPerformanceSection(),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Tests in this Unit',
                  style: AppTextStyles.titleMedium(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Center(child: AppCircularProgress()),
              ],
            );
          }
          if (snapshot.hasError) {
            return TestsScrollBody(
              bottomInset: false,
              children: [
                _UnitHero(
                  title: unit?.displayName ?? 'Syllabus Unit',
                  breadcrumb: breadcrumb,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _buildCompletionSection(),
                const SizedBox(height: AppSpacing.xxl),
                _buildPerformanceSection(),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Tests in this Unit',
                  style: AppTextStyles.titleMedium(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                _MessageBody(
                  title: 'Unable to load tests',
                  message: 'Please check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: _retryTests,
                ),
              ],
            );
          }

          final tests = snapshot.data ?? const <TestModel>[];
          return TestsScrollBody(
            bottomInset: false,
            children: [
              _UnitHero(
                title: unit?.displayName ?? 'Syllabus Unit',
                breadcrumb: breadcrumb,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _buildCompletionSection(),
              const SizedBox(height: AppSpacing.xxl),
              _buildPerformanceSection(),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Tests in this Unit',
                style: AppTextStyles.titleMedium(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (tests.isEmpty)
                const _MessageBody(
                  title: 'No tests available',
                  message:
                      'There are no published tests in this syllabus unit yet.',
                )
              else
                for (var i = 0; i < tests.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  TestCard(
                    test: tests[i],
                    accentColor: AppColors.accentAt(i),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TestInstructionsScreen(test: tests[i]),
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

  Widget _buildCompletionSection() {
    if (_scope == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<SyllabusCompletion?>(
      future: _completionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SyllabusCompletionCard(isLoading: true);
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          final signedOut =
              error is StateError &&
              error.message.contains('no authenticated user');
          return SyllabusCompletionCard(
            errorMessage: signedOut
                ? 'Sign in to manage unit completion.'
                : 'Unable to load unit completion.',
            onRetry: signedOut ? null : _retryCompletion,
          );
        }
        return SyllabusCompletionCard(
          completion: snapshot.data,
          isMutating: _completionMutating,
          mutationErrorMessage: _completionMutationError,
          onMarkInProgress: () =>
              _mutateCompletion((repo, scope) => repo.setInProgress(scope)),
          onMarkCompleted: () =>
              _mutateCompletion((repo, scope) => repo.setCompleted(scope)),
          onReset: () =>
              _mutateCompletion((repo, scope) => repo.resetToNotStarted(scope)),
        );
      },
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
          return const UnitPerformanceCard(isLoading: true);
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          final signedOut =
              error is StateError &&
              error.message.contains('no authenticated user');
          return UnitPerformanceCard(
            errorMessage: signedOut
                ? 'Sign in to view unit performance.'
                : 'Unable to load unit performance.',
            onRetry: signedOut ? null : _retryPerformance,
          );
        }
        return UnitPerformanceCard(performance: snapshot.data);
      },
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: EmptyState(
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }
}

class _UnitHero extends StatelessWidget {
  const _UnitHero({required this.title, required this.breadcrumb});

  final String title;
  final String breadcrumb;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.lavender.withValues(alpha: 0.65),
      showBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headline(context)),
          const SizedBox(height: AppSpacing.xs),
          Text(breadcrumb, style: AppTextStyles.bodyMedium(context)),
        ],
      ),
    );
  }
}
