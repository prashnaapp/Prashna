import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../services/admin_question_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../shell/admin_dirty_scope.dart';
import '../widgets/admin_question_form.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_loading_surface.dart';

class AdminQuestionFormScreen extends StatefulWidget {
  const AdminQuestionFormScreen({
    super.key,
    this.question,
    this.service,
  });

  final Question? question;
  final AdminQuestionService? service;

  @override
  State<AdminQuestionFormScreen> createState() =>
      _AdminQuestionFormScreenState();
}

class _AdminQuestionFormScreenState extends State<AdminQuestionFormScreen> {
  late final AdminQuestionService _service;
  late final Future<List<Course>> _coursesFuture;
  bool _dirty = false;
  AdminDirtyController? _dirtyController;

  bool _isDirtyChecker() => _dirty;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminQuestionService.instance;
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

  Future<void> _save(Question question) async {
    if (widget.question == null) {
      await _service.createQuestion(question);
    } else {
      await _service.updateQuestion(question);
    }
  }

  Future<void> _handlePopRequest() async {
    if (!_dirty) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    final controller = _dirtyController;
    final leave = controller != null
        ? await controller.confirmLeaveIfNeeded(context)
        : await _showLocalDiscardDialog();
    if (leave && mounted) Navigator.of(context).pop(false);
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
                message: '${snapshot.error}',
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
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AdminSpacing.contentMaxWidth,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: AdminQuestionForm(
                    courses: courses,
                    initialQuestion: widget.question,
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
