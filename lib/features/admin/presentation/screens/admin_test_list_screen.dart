import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../tests/data/models/test_models.dart';
import '../../admin_routes.dart';
import '../../services/admin_test_service.dart';

class AdminTestListScreen extends StatefulWidget {
  const AdminTestListScreen({super.key, this.service});

  final AdminTestService? service;

  @override
  State<AdminTestListScreen> createState() => _AdminTestListScreenState();
}

class _AdminTestListScreenState extends State<AdminTestListScreen> {
  late final AdminTestService _service;
  List<Course> _courses = const [];
  List<TestModel> _tests = const [];
  String? _courseId;
  String? _error;
  bool _loadingCourses = true;
  bool _loadingTests = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminTestService.instance;
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
      if (_courseId != null) await _loadTests();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingCourses = false;
        _error = 'Unable to load courses: $error';
      });
    }
  }

  Future<void> _loadTests() async {
    final courseId = _courseId;
    if (courseId == null || courseId.isEmpty) return;
    setState(() {
      _loadingTests = true;
      _error = null;
    });
    try {
      final tests = await _service.loadTests(courseId);
      if (!mounted) return;
      setState(() {
        _tests = tests;
        _loadingTests = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingTests = false;
        _error = 'Unable to load tests: $error';
      });
    }
  }

  Future<void> _openCreate() async {
    await Navigator.of(
      context,
    ).pushNamed(AdminRoutes.testCreate, arguments: _courseId);
    if (mounted) await _loadTests();
  }

  Future<void> _openEdit(TestModel test) async {
    await Navigator.of(
      context,
    ).pushNamed(AdminRoutes.testEdit, arguments: test);
    if (mounted) await _loadTests();
  }

  Future<void> _setPublished(TestModel test, bool published) async {
    if (published) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Publish test?'),
          content: const Text(
            'Students with course access will be able to see this test '
            'in the Test Series catalog.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Publish'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      if (published) {
        await _service.publishTest(test.id);
      } else {
        await _service.unpublishTest(test.id);
      }
      if (mounted) await _loadTests();
    } catch (error) {
      if (!mounted) return;
      final message = error is FormatException
          ? error.message
          : 'Could not update test. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _categoryLabel(TestCategoryType type) {
    switch (type) {
      case TestCategoryType.chapterTests:
        return 'Chapter Tests';
      case TestCategoryType.partTests:
        return 'Paper-wise Tests';
      case TestCategoryType.paperTests:
        return 'Paper Tests';
      case TestCategoryType.mockTests:
        return 'Mock Tests';
      case TestCategoryType.previousYear:
        return 'Previous Papers';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tests')),
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
                    await _loadTests();
                  },
                ),
              ),
              FilledButton.icon(
                onPressed: _courseId == null ? null : _openCreate,
                icon: const Icon(Icons.add),
                label: const Text('+ Create Test'),
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
          child: _loadingTests
              ? const Center(child: CircularProgressIndicator())
              : _tests.isEmpty
              ? const Center(child: Text('No tests for this course.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _tests.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final test = _tests[index];
                    return _TestCard(
                      test: test,
                      categoryLabel: _categoryLabel(test.category),
                      onEdit: () => _openEdit(test),
                      onSetPublished: (value) => _setPublished(test, value),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.test,
    required this.categoryLabel,
    required this.onEdit,
    required this.onSetPublished,
  });

  final TestModel test;
  final String categoryLabel;
  final VoidCallback onEdit;
  final ValueChanged<bool> onSetPublished;

  @override
  Widget build(BuildContext context) {
    final status = test.isPublished ? 'Published' : 'Draft';
    return Card(
      child: ListTile(
        title: Text(test.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${test.id} • $categoryLabel\n'
          '${test.questionCount} questions • ${test.marks} marks • '
          '${test.durationMinutes} min • ${test.difficulty} • $status',
        ),
        isThreeLine: true,
        leading: Icon(
          test.isPublished ? Icons.publish : Icons.edit_note,
          color: test.isPublished
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
              tooltip: test.isPublished ? 'Unpublish' : 'Publish',
              onPressed: () => onSetPublished(!test.isPublished),
              icon: Icon(
                test.isPublished
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
