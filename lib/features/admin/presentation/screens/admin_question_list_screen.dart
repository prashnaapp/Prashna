import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../admin_routes.dart';
import '../../services/admin_question_service.dart';

class AdminQuestionListScreen extends StatefulWidget {
  const AdminQuestionListScreen({super.key, this.service});

  final AdminQuestionService? service;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Questions')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            height: double.infinity,
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _courses.isEmpty) {
      return Center(child: Text(_error!));
    }
    if (_courses.isEmpty) {
      return const Center(child: Text('No published courses are available.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 600),
                child: DropdownButtonFormField<String>(
                  initialValue: _courseId,
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final course in _courses)
                      DropdownMenuItem(
                        value: course.courseId,
                        child: Text('${course.title} (${course.courseId})'),
                      ),
                  ],
                  onChanged: (value) async {
                    setState(() => _courseId = value);
                    await _loadQuestions();
                  },
                ),
              ),
              FilledButton.icon(
                onPressed: _courseId == null ? null : _openCreate,
                icon: const Icon(Icons.add),
                label: const Text('+ Create Question'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AdminRoutes.questionImport),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Import Questions'),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<QuestionPublicationStatus?>(
                  initialValue: _statusFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    for (final status in QuestionPublicationStatus.values)
                      DropdownMenuItem(value: status, child: Text(status.name)),
                  ],
                  onChanged: (value) => setState(() => _statusFilter = value),
                ),
              ),
              _filterField('Paper', (value) => _paperFilter = value),
              _filterField('Part', (value) => _partFilter = value),
              _filterField('Topic', (value) => _topicFilter = value),
              _filterField('Lesson', (value) => _lessonFilter = value),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: _loadingQuestions
              ? const Center(child: CircularProgressIndicator())
              : _visibleQuestions.isEmpty
              ? const Center(child: Text('No questions for this course.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _visibleQuestions.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final question = _visibleQuestions[index];
                    return _QuestionCard(
                      question: question,
                      onEdit: () => _openEdit(question),
                      onSetStatus: (status) => _setStatus(question, status),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterField(String label, ValueChanged<String> onChanged) {
    return SizedBox(
      width: 140,
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => setState(() => onChanged(value)),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.onEdit,
    required this.onSetStatus,
  });

  final Question question;
  final VoidCallback onEdit;
  final ValueChanged<QuestionPublicationStatus> onSetStatus;

  @override
  Widget build(BuildContext context) {
    final updated = question.updatedAt.millisecondsSinceEpoch == 0
        ? '—'
        : '${question.updatedAt.year}-${question.updatedAt.month.toString().padLeft(2, '0')}-${question.updatedAt.day.toString().padLeft(2, '0')}';
    final status =
        question.status ??
        (question.isActive
            ? QuestionPublicationStatus.published
            : QuestionPublicationStatus.archived);
    return Card(
      child: ListTile(
        title: Text(
          question.question,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${question.id} • ${question.topicId.isEmpty ? 'No topic' : question.topicId}\n'
          '${question.difficulty.name} • ${question.questionType.name} • '
          '${status.name}'
          ' • Updated $updated',
        ),
        isThreeLine: true,
        leading: Icon(
          question.isActive ? Icons.check_circle : Icons.pause_circle,
          color: question.isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: status == QuestionPublicationStatus.published
                  ? 'Archive'
                  : 'Publish',
              onPressed: () => onSetStatus(
                status == QuestionPublicationStatus.published
                    ? QuestionPublicationStatus.archived
                    : QuestionPublicationStatus.published,
              ),
              icon: Icon(
                question.isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
