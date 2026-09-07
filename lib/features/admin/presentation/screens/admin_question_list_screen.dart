import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../admin_routes.dart';
import '../../services/admin_question_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_loading_surface.dart';
import '../widgets/admin_ui/admin_page_header.dart';
import '../widgets/admin_ui/admin_question_row.dart';
import '../widgets/admin_ui/admin_surface.dart';

class AdminQuestionListScreen extends StatefulWidget {
  const AdminQuestionListScreen({
    super.key,
    this.service,
    this.embeddedInShell = false,
  });

  final AdminQuestionService? service;
  final bool embeddedInShell;

  @override
  State<AdminQuestionListScreen> createState() =>
      _AdminQuestionListScreenState();
}

class _AdminQuestionListScreenState extends State<AdminQuestionListScreen> {
  late final AdminQuestionService _service;
  List<Course> _courses = const [];
  List<Question> _questions = const [];
  String? _courseId;
  QuestionPublicationStatus? _statusFilter;
  String _search = '';
  String _paperFilter = '';
  String _partFilter = '';
  String _topicFilter = '';
  String _lessonFilter = '';
  String? _error;
  bool _loadingCourses = true;
  bool _loadingQuestions = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminQuestionService.instance;
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await _service.loadCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _courseId = courses.isEmpty ? null : courses.first.courseId;
        _loadingCourses = false;
      });
      if (_courseId != null) await _loadQuestions();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingCourses = false;
        _error = 'Unable to load courses: $error';
      });
    }
  }

  Future<void> _loadQuestions() async {
    final courseId = _courseId;
    if (courseId == null || courseId.isEmpty) return;
    setState(() {
      _loadingQuestions = true;
      _error = null;
    });
    try {
      final questions = await _service.loadQuestions(courseId);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loadingQuestions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingQuestions = false;
        _error = 'Unable to load questions: $error';
      });
    }
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).pushNamed(AdminRoutes.questionCreate);
    if (mounted) await _loadQuestions();
  }

  Future<void> _openEdit(Question question) async {
    await Navigator.of(
      context,
    ).pushNamed(AdminRoutes.questionEdit, arguments: question);
    if (mounted) await _loadQuestions();
  }

  Future<void> _requestLifecycleStatus(
    Question question,
    QuestionPublicationStatus status,
  ) async {
    if (status == QuestionPublicationStatus.archived) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Archive Question?'),
            content: const Text(
              'This question will be removed from Student Practice and new Tests.\n'
              'Existing historical records will not be deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Archive'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
    }
    await _setStatus(question, status);
  }

  Future<void> _setStatus(
    Question question,
    QuestionPublicationStatus status,
  ) async {
    try {
      await _service.setStatus(question.id, status);
      if (mounted) await _loadQuestions();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update status: $error')),
      );
    }
  }

  bool get _hasActiveFilters {
    return _search.trim().isNotEmpty ||
        _statusFilter != null ||
        _paperFilter.trim().isNotEmpty ||
        _partFilter.trim().isNotEmpty ||
        _topicFilter.trim().isNotEmpty ||
        _lessonFilter.trim().isNotEmpty;
  }

  List<Question> get _visibleQuestions {
    final query = _search.trim().toLowerCase();
    return _questions
        .where((question) {
          final status =
              question.status ??
              (question.isActive
                  ? QuestionPublicationStatus.published
                  : QuestionPublicationStatus.archived);
          if (_statusFilter != null && status != _statusFilter) return false;
          if (!_contains(question.paperId, _paperFilter) ||
              !_contains(question.partId, _partFilter) ||
              !_contains(question.syllabus?.topicId, _topicFilter) ||
              !_contains(question.lessonId, _lessonFilter)) {
            return false;
          }
          if (query.isEmpty) return true;
          return question.question.toLowerCase().contains(query) ||
              question.id.toLowerCase().contains(query) ||
              question.paperId.toLowerCase().contains(query) ||
              (question.partId ?? '').toLowerCase().contains(query) ||
              (question.contentTopicId ?? '').toLowerCase().contains(query) ||
              (question.lessonId ?? '').toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  bool _contains(String? value, String filter) {
    final normalized = filter.trim().toLowerCase();
    return normalized.isEmpty ||
        (value ?? '').toLowerCase().contains(normalized);
  }

  List<Widget> get _headerActions => [
    FilledButton.icon(
      key: const ValueKey('question-list-create'),
      onPressed: _courseId == null ? null : _openCreate,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('+ Create Question'),
    ),
    OutlinedButton.icon(
      key: const ValueKey('question-list-import'),
      onPressed: () =>
          Navigator.of(context).pushNamed(AdminRoutes.questionImport),
      icon: const Icon(Icons.upload_file_outlined, size: 18),
      label: const Text('Import Questions'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final contentW = maxW < AdminSpacing.contentMaxWidth
            ? maxW
            : AdminSpacing.contentMaxWidth;

        return SizedBox(
          width: maxW,
          height: maxH,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentW,
              height: maxH,
              child: _buildBody(context),
            ),
          ),
        );
      },
    );

    if (widget.embeddedInShell) return body;

    return Scaffold(
      backgroundColor: AdminColors.backgroundTop,
      appBar: AppBar(title: const Text('Question Bank')),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loadingCourses) {
      return const AdminLoadingSurface();
    }
    if (_error != null && _courses.isEmpty) {
      return AdminEmptyState(
        title: 'Unable to load courses',
        message: _error!,
        icon: Icons.error_outline,
        action: FilledButton.tonal(
          onPressed: () {
            setState(() {
              _loadingCourses = true;
              _error = null;
            });
            _loadCourses();
          },
          child: const Text('Retry'),
        ),
      );
    }
    if (_courses.isEmpty) {
      return const AdminEmptyState(
        title: 'No courses available',
        message: 'No published courses are available for question management.',
        icon: Icons.school_outlined,
      );
    }

    final visible = _visibleQuestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AdminSpacing.pagePadding,
            AdminSpacing.pagePadding,
            AdminSpacing.pagePadding,
            AdminSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminPageHeader(
                title: 'Question Bank',
                subtitle:
                    'Manage, review, publish, archive, and organize your exam questions.',
                actions: _headerActions,
              ),
              _FilterWorkspace(
                courses: _courses,
                courseId: _courseId,
                statusFilter: _statusFilter,
                onCourseChanged: (value) async {
                  setState(() => _courseId = value);
                  await _loadQuestions();
                },
                onSearchChanged: (value) => setState(() => _search = value),
                onStatusChanged: (value) =>
                    setState(() => _statusFilter = value),
                onPaperChanged: (value) =>
                    setState(() => _paperFilter = value),
                onPartChanged: (value) => setState(() => _partFilter = value),
                onTopicChanged: (value) =>
                    setState(() => _topicFilter = value),
                onLessonChanged: (value) =>
                    setState(() => _lessonFilter = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: AdminSpacing.md),
                AdminSurface(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminSpacing.lg,
                    vertical: AdminSpacing.md,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AdminColors.danger,
                      ),
                      const SizedBox(width: AdminSpacing.md),
                      Expanded(
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AdminColors.danger),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadQuestions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _loadingQuestions
              ? const AdminLoadingSurface(rows: 3)
              : visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AdminSpacing.pagePadding,
                    0,
                    AdminSpacing.pagePadding,
                    AdminSpacing.pagePadding,
                  ),
                  child: _buildEmptyState(),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AdminSpacing.pagePadding,
                    AdminSpacing.sm,
                    AdminSpacing.pagePadding,
                    AdminSpacing.pagePadding,
                  ),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AdminSpacing.md),
                  itemBuilder: (context, index) {
                    final question = visible[index];
                    return AdminQuestionRow(
                      question: question,
                      onEdit: () => _openEdit(question),
                      onRequestStatus: (status) =>
                          _requestLifecycleStatus(question, status),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    if (_questions.isEmpty) {
      return AdminEmptyState(
        title: 'No questions yet',
        message:
            'Create your first question for this course, or import a bilingual JSON batch.',
        icon: Icons.quiz_outlined,
        action: FilledButton.icon(
          onPressed: _courseId == null ? null : _openCreate,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('+ Create Question'),
        ),
      );
    }
    return AdminEmptyState(
      title: 'No questions found',
      message: _hasActiveFilters
          ? 'Try adjusting your filters or create a new question.'
          : 'No questions match the current view.',
      icon: Icons.filter_alt_outlined,
      action: FilledButton.icon(
        onPressed: _courseId == null ? null : _openCreate,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('+ Create Question'),
      ),
    );
  }
}

class _FilterWorkspace extends StatelessWidget {
  const _FilterWorkspace({
    required this.courses,
    required this.courseId,
    required this.statusFilter,
    required this.onCourseChanged,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onPaperChanged,
    required this.onPartChanged,
    required this.onTopicChanged,
    required this.onLessonChanged,
  });

  final List<Course> courses;
  final String? courseId;
  final QuestionPublicationStatus? statusFilter;
  final ValueChanged<String?> onCourseChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<QuestionPublicationStatus?> onStatusChanged;
  final ValueChanged<String> onPaperChanged;
  final ValueChanged<String> onPartChanged;
  final ValueChanged<String> onTopicChanged;
  final ValueChanged<String> onLessonChanged;

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.all(AdminSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('question-list-search'),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Search',
              hintText: 'Search questions by text, ID, or syllabus…',
              prefixIcon: Icon(Icons.search, size: 20),
              border: OutlineInputBorder(),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: AdminSpacing.sm),
          Wrap(
            spacing: AdminSpacing.sm,
            runSpacing: AdminSpacing.sm,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('question-list-course'),
                  initialValue: courseId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Course',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final course in courses)
                      DropdownMenuItem(
                        value: course.courseId,
                        child: Text(
                          '${course.title} (${course.courseId})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: onCourseChanged,
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<QuestionPublicationStatus?>(
                  key: const ValueKey('question-list-status'),
                  initialValue: statusFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    for (final status in QuestionPublicationStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              _FilterField(
                key: const ValueKey('question-list-paper'),
                label: 'Paper',
                onChanged: onPaperChanged,
              ),
              _FilterField(
                key: const ValueKey('question-list-part'),
                label: 'Part',
                onChanged: onPartChanged,
              ),
              _FilterField(
                key: const ValueKey('question-list-topic'),
                label: 'Topic',
                onChanged: onTopicChanged,
              ),
              _FilterField(
                key: const ValueKey('question-list-lesson'),
                label: 'Lesson',
                onChanged: onLessonChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _statusLabel(QuestionPublicationStatus status) {
    switch (status) {
      case QuestionPublicationStatus.draft:
        return 'Draft';
      case QuestionPublicationStatus.published:
        return 'Published';
      case QuestionPublicationStatus.archived:
        return 'Archived';
    }
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    super.key,
    required this.label,
    required this.onChanged,
  });

  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: TextField(
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
