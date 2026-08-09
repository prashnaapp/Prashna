import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../services/admin_question_service.dart';
import '../widgets/admin_question_form.dart';

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

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminQuestionService.instance;
    _coursesFuture = _service.loadCourses();
  }

  Future<void> _save(Question question) async {
    if (widget.question == null) {
      await _service.createQuestion(question);
    } else {
      await _service.updateQuestion(question);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.question != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit question' : 'Create question'),
      ),
      body: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load courses: ${snapshot.error}'),
              ),
            );
          }
          final courses = snapshot.data ?? const <Course>[];
          if (courses.isEmpty) {
            return const Center(
              child: Text('No published courses are available.'),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: AdminQuestionForm(
                courses: courses,
                initialQuestion: widget.question,
                onSubmit: _save,
              ),
            ),
          );
        },
      ),
    );
  }
}
