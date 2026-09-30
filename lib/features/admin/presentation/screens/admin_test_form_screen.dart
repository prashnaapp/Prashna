import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../tests/data/models/test_models.dart';
import '../../data/admin_test_scope.dart';
import '../../debug/admin_perf_trace.dart';
import '../../services/admin_test_service.dart';
import '../../theme/admin_colors.dart';
import '../shell/admin_dirty_scope.dart';
import '../widgets/admin_test_form.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_loading_surface.dart';
import 'admin_test_assignment_screen.dart';

class AdminTestFormScreen extends StatefulWidget {
  const AdminTestFormScreen({
    super.key,
    this.test,
    this.initialCourseId,
    this.scope,
    this.service,
  });

  final TestModel? test;
  final String? initialCourseId;
  final AdminTestScope? scope;
  final AdminTestService? service;

  @override
  State<AdminTestFormScreen> createState() => _AdminTestFormScreenState();
}

class _AdminTestFormScreenState extends State<AdminTestFormScreen> {
  late final AdminTestService _service;
  late final Future<List<Course>> _coursesFuture;
  TestModel? _test;
  bool _loadingTest = false;
  String? _testError;
  bool _changed = false;
  bool _dirty = false;
  AdminDirtyController? _dirtyController;

  bool _isDirtyChecker() => _dirty;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminTestService.instance;
    _coursesFuture = _service.loadCourses();
    if (widget.test != null) {
      _loadingTest = true;
      _loadCanonicalTest();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = AdminDirtyScope.maybeOf(context);
    if (!identical(_dirtyController, next)) {
      _dirtyController?.unbind(_isDirtyChecker);
      _dirtyController = next;
      _dirtyController?.bind(_isDirtyChecker);
    }
  }

  @override
  void dispose() {
    _dirtyController?.unbind(_isDirtyChecker);
    super.dispose();
  }

  Future<void> _save(TestModel test) async {
    await _service.updateTest(test, preserveAssignments: true);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _create(TestModel test, List<String> initialQuestionIds) async {
    await _service.createDraftWithInitialQuestions(
      test,
      initialQuestionIds: initialQuestionIds,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _openManageQuestions() async {
    final test = _test;
    if (test == null || _dirty) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AdminTestAssignmentScreen(test: test, service: _service),
      ),
    );
    if (!mounted) return;
    if (changed == true) _changed = true;
    await _loadCanonicalTest();
  }

  Future<void> _loadCanonicalTest() async {
    final id = widget.test?.id ?? _test?.id;
    if (id == null || id.trim().isEmpty) return;
    setState(() {
      _loadingTest = true;
      _testError = null;
    });
    try {
      final fresh = await AdminPerfTrace.span(
        'editTest.canonical',
        () => _service.getTest(id),
      );
      if (fresh == null) {
        throw const FormatException('Test was not found.');
      }
      if (!mounted) return;
      setState(() {
        _test = fresh;
        _loadingTest = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingTest = false;
        _testError = error.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  Future<void> _handlePopRequest() async {
    if (!_dirty) {
      if (mounted) Navigator.of(context).pop(_changed);
      return;
    }
    final controller = _dirtyController;
    final leave = controller != null
        ? await controller.confirmLeaveIfNeeded(context)
        : await _showLocalDiscardDialog();
    if (leave && mounted) Navigator.of(context).pop(_changed);
  }

  Future<bool> _showLocalDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text(
          'You have unsaved changes. If you leave this page, your changes '
          'will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard & Leave'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty && !_changed,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handlePopRequest();
      },
      child: Scaffold(
        backgroundColor: AdminColors.backgroundTop,
        appBar: AppBar(
          // Keep back / PopScope chrome; primary title lives in the form body.
          title: _dirty
              ? Text(
                  'Unsaved changes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AdminColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
          actions: [
            if (_test != null)
              IconButton(
                key: const ValueKey('test-form-manage-questions'),
                tooltip: 'Manage Questions',
                onPressed: _dirty ? null : _openManageQuestions,
                icon: const Icon(Icons.quiz_outlined),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.test != null &&
        (_loadingTest || _test == null) &&
        _testError == null) {
      return const AdminLoadingSurface(rows: 3);
    }
    if (_testError != null) {
      return AdminEmptyState(
        title: 'Unable to load Test',
        message: _testError!,
        icon: Icons.error_outline,
        action: FilledButton.tonal(
          onPressed: _loadCanonicalTest,
          child: const Text('Retry'),
        ),
      );
    }
    return FutureBuilder<List<Course>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AdminLoadingSurface(rows: 3);
        }
        if (snapshot.hasError) {
          return AdminEmptyState(
            title: 'Unable to load courses',
            message: 'Unable to load courses: ${snapshot.error}',
            icon: Icons.error_outline,
          );
        }
        final courses = snapshot.data ?? const <Course>[];
        if (courses.isEmpty) {
          return const AdminEmptyState(
            title: 'No courses available',
            message: 'No published courses are available.',
            icon: Icons.school_outlined,
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: AdminTestForm(
                key: ValueKey(_test?.id ?? 'new'),
                courses: courses,
                initialTest: _test,
                initialCourseId: widget.initialCourseId,
                scope: _test == null
                    ? widget.scope
                    : AdminTestScope.fromTest(_test!),
                service: _service,
                onSubmit: _save,
                onCreateDraft: _test == null ? _create : null,
                onManageQuestions: _test == null ? null : _openManageQuestions,
                onCancel: () => _handlePopRequest(),
                onDirtyChanged: (dirty) {
                  if (!mounted) return;
                  setState(() => _dirty = dirty);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
