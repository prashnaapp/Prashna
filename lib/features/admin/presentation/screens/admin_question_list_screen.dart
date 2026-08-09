import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../admin_routes.dart';
import '../../services/admin_question_service.dart';

class AdminQuestionListScreen extends StatefulWidget {
  const AdminQuestionListScreen({
    super.key,
    this.service,
  });

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
    await Navigator.of(context).pushNamed(
      AdminRoutes.questionEdit,
      arguments: question,
    );
    if (mounted) await _loadQuestions();
  }

  Future<void> _setActive(Question question, bool active) async {
    if (!active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deactivate question?'),
          content: const Text(
            'This may affect published tests that reference this question. '
            'The question will remain stored and can be reactivated later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      if (active) {
        await _service.reactivateQuestion(question.id);
      } else {
        await _service.deactivateQuestion(question.id);
      }
      if (mounted) await _loadQuestions();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update question: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questions'),
      ),
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
                constraints: const BoxConstraints(
                  minWidth: 200,
                  maxWidth: 600,
                ),
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
              : _questions.isEmpty
                  ? const Center(child: Text('No questions for this course.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _questions.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final question = _questions[index];
                        return _QuestionCard(
                          question: question,
                          onEdit: () => _openEdit(question),
                          onSetActive: (value) => _setActive(question, value),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.onEdit,
    required this.onSetActive,
  });

  final Question question;
  final VoidCallback onEdit;
  final ValueChanged<bool> onSetActive;

  @override
  Widget build(BuildContext context) {
    final updated = question.updatedAt.millisecondsSinceEpoch == 0
        ? '—'
        : '${question.updatedAt.year}-${question.updatedAt.month.toString().padLeft(2, '0')}-${question.updatedAt.day.toString().padLeft(2, '0')}';
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
          '${question.language} • ${question.isActive ? 'Active' : 'Inactive'}'
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
              tooltip: question.isActive ? 'Deactivate' : 'Reactivate',
              onPressed: () => onSetActive(!question.isActive),
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
