import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../tests/data/models/test_models.dart';
import '../../services/admin_test_service.dart';
import '../widgets/admin_test_form.dart';

class AdminTestFormScreen extends StatefulWidget {
  const AdminTestFormScreen({
    super.key,
    this.test,
    this.initialCourseId,
    this.service,
  });

  final TestModel? test;
  final String? initialCourseId;
  final AdminTestService? service;

  @override
  State<AdminTestFormScreen> createState() => _AdminTestFormScreenState();
}

class _AdminTestFormScreenState extends State<AdminTestFormScreen> {
  late final AdminTestService _service;
  late final Future<List<Course>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminTestService.instance;
    _coursesFuture = _service.loadCourses();
  }

  Future<void> _save(TestModel test) async {
    if (widget.test == null) {
      await _service.createTest(test);
    } else {
      await _service.updateTest(
        TestModel(
          id: widget.test!.id,
          examId: test.examId,
          category: test.category,
          title: test.title,
          questionCount: test.questionCount,
          marks: test.marks,
          durationMinutes: test.durationMinutes,
          negativeMarking: test.negativeMarking,
          difficulty: test.difficulty,
          questionIds: widget.test!.questionIds,
          isPublished: test.isPublished,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.test != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit test' : 'Create test')),
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
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: AdminTestForm(
                  courses: courses,
                  initialTest: widget.test,
                  initialCourseId: widget.initialCourseId,
                  onSubmit: _save,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
