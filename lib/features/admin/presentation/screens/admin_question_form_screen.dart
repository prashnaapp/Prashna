import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../../tests/data/models/test_models.dart';
import '../../data/admin_chapter_question_context.dart';
import '../../data/admin_question_scope.dart';
import '../../services/admin_question_service.dart';
import '../../services/admin_question_test_assignment.dart';
import '../../services/admin_test_series_question_create.dart';
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
    this.scope,
    this.chapterContext,
    this.assignment,
  });

  final Question? question;
  final AdminQuestionService? service;

  /// Locked Test Series bank. Chapter create leaves this null.
  final AdminQuestionScope? scope;

  /// Locked Chapter syllabus location from the Chapter Questions browser.
  final AdminChapterQuestionContext? chapterContext;
  final AdminQuestionTestAssignment? assignment;

  @override
  State<AdminQuestionFormScreen> createState() =>
      _AdminQuestionFormScreenState();
}

class _AdminQuestionFormScreenState extends State<AdminQuestionFormScreen> {
  late final AdminQuestionService _service;
  late final AdminQuestionTestAssignment _assignment;
  late final Future<({List<Course> courses, List<TestModel> tests})>
  _loadFuture;
  bool _dirty = false;
  String? _assignTestId;
  AdminDirtyController? _dirtyController;

  bool get _lockedBank {
    if (widget.scope?.isQuestionBank == true && widget.question == null) {
      return true;
    }
    return false;
  }

  AdminQuestionScope? get _formScope {
    final explicit = widget.scope;
    if (explicit != null && explicit.isQuestionBank) return explicit;
    final question = widget.question;
    if (question == null) return null;
    return AdminQuestionScope.fromQuestion(
      contentArea: question.contentArea,
      courseId: question.courseId,
      testSeriesCategory: question.testSeriesCategory,
      paperId: question.paperId,
      seriesId: question.seriesId,
      year: question.year,
    );
  }

  bool _isDirtyChecker() => _dirty;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminQuestionService.instance;
    _assignment = widget.assignment ?? AdminQuestionTestAssignment();
    _loadFuture = _load();
  }

  Future<({List<Course> courses, List<TestModel> tests})> _load() async {
    if (_lockedBank) {
      final tests = await _assignment.loadCompatibleTests(widget.scope!);
      return (courses: const <Course>[], tests: tests);
    }
    final courses = await _service.loadCourses();
    return (courses: courses, tests: const <TestModel>[]);
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
    if (_lockedBank) {
      await createTestSeriesQuestion(
        questions: _service,
        assignment: _assignment,
        scope: widget.scope!,
        question: question,
        assignToTestId: _assignTestId,
      );
      return;
    }
    if (widget.question == null) {
      await _service.createQuestion(question);
    } else {
      await _service.updateQuestion(question, scope: _formScope);
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
        body: FutureBuilder<({List<Course> courses, List<TestModel> tests})>(
          future: _loadFuture,
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
            final courses = snapshot.data?.courses ?? const <Course>[];
            final tests = snapshot.data?.tests ?? const <TestModel>[];
            if (!_lockedBank &&
                widget.chapterContext == null &&
                courses.isEmpty) {
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
                    lockedScope: _formScope,
                    chapterContext: widget.question == null
                        ? widget.chapterContext
                        : null,
                    compatibleTests: _lockedBank ? tests : const [],
                    onAssignTestChanged: _lockedBank
                        ? (testId) => _assignTestId = testId
                        : null,
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
