import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../tests/data/models/test_models.dart';
import '../../data/admin_test_scope.dart';
import '../../services/admin_test_service.dart';
import '../../theme/admin_colors.dart';
import '../shell/admin_dirty_scope.dart';
import '../widgets/admin_test_form.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_loading_surface.dart';

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
  bool _dirty = false;
  AdminDirtyController? _dirtyController;

  bool _isDirtyChecker() => _dirty;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminTestService.instance;
    _coursesFuture = _service.loadCourses();
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
    if (widget.test == null) {
      await _service.createTest(test);
    } else {
      await _service.updateTest(test);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handlePopRequest() async {
    if (!_dirty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final controller = _dirtyController;
    final leave = controller != null
        ? await controller.confirmLeaveIfNeeded(context)
        : await _showLocalDiscardDialog();
    if (leave && mounted) Navigator.of(context).pop();
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
      canPop: !_dirty,
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
        ),
        body: FutureBuilder<List<Course>>(
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
                    courses: courses,
                    initialTest: widget.test,
                    initialCourseId: widget.initialCourseId,
                    scope: widget.scope,
                    service: _service,
                    onSubmit: _save,
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
        ),
      ),
    );
  }
}
