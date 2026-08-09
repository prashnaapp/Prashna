import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../tests/data/models/test_models.dart';

typedef AdminTestSubmit = Future<void> Function(TestModel test);

/// Create/edit form for the canonical [TestModel] metadata.
///
/// Does not expose question assignment controls.
class AdminTestForm extends StatefulWidget {
  const AdminTestForm({
    super.key,
    required this.courses,
    required this.onSubmit,
    this.initialTest,
    this.initialCourseId,
    this.onCancel,
  });

  final List<Course> courses;
  final AdminTestSubmit onSubmit;
  final TestModel? initialTest;
  final String? initialCourseId;
  final VoidCallback? onCancel;

  @override
  State<AdminTestForm> createState() => _AdminTestFormState();
}

class _AdminTestFormState extends State<AdminTestForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _questionCount;
  late final TextEditingController _marks;
  late final TextEditingController _duration;
  late final TextEditingController _negativeMarking;
  late final TextEditingController _difficulty;

  String? _courseId;
  TestCategoryType _category = TestCategoryType.chapterTests;
  bool _isPublished = false;
  bool _saving = false;
  String? _submitError;

  TestModel? get _initial => widget.initialTest;

  static const _categories = TestCategoryType.values;

  @override
  void initState() {
    super.initState();
    final initial = _initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _questionCount = TextEditingController(
      text: '${initial?.questionCount ?? 10}',
    );
    _marks = TextEditingController(text: '${initial?.marks ?? 10}');
    _duration = TextEditingController(
      text: '${initial?.durationMinutes ?? 30}',
    );
    _negativeMarking = TextEditingController(
      text: initial?.negativeMarking ?? '0',
    );
    _difficulty = TextEditingController(text: initial?.difficulty ?? 'Medium');
    _courseId =
        initial?.examId ??
        widget.initialCourseId ??
        (widget.courses.isEmpty ? null : widget.courses.first.courseId);
    _category = initial?.category ?? TestCategoryType.chapterTests;
    _isPublished = initial?.isPublished ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _questionCount.dispose();
    _marks.dispose();
    _duration.dispose();
    _negativeMarking.dispose();
    _difficulty.dispose();
    super.dispose();
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

  int? _parseInt(String value) => int.tryParse(value.trim());

  TestModel _buildTest() {
    final initial = _initial;
    return TestModel(
      id: initial?.id ?? '',
      examId: _courseId!.trim(),
      category: _category,
      title: _title.text.trim(),
      questionCount: _parseInt(_questionCount.text) ?? 0,
      marks: _parseInt(_marks.text) ?? 0,
      durationMinutes: _parseInt(_duration.text) ?? 0,
      negativeMarking: _negativeMarking.text.trim(),
      difficulty: _difficulty.text.trim(),
      questionIds: initial?.questionIds ?? const [],
      isPublished: _isPublished,
    );
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);
    if (!_formKey.currentState!.validate()) return;

    final test = _buildTest();
    setState(() => _saving = true);
    try {
      await widget.onSubmit(test);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.toString();
        _saving = false;
      });
      return;
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final editing = _initial != null;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _courseId,
            decoration: const InputDecoration(
              labelText: 'Course',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final course in widget.courses)
                DropdownMenuItem(
                  value: course.courseId,
                  child: Text('${course.title} (${course.courseId})'),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _courseId = value),
            validator: (value) =>
                value == null || value.isEmpty ? 'Course is required.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            enabled: !_saving,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Title is required.'
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TestCategoryType>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final category in _categories)
                DropdownMenuItem(
                  value: category,
                  child: Text(_categoryLabel(category)),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) {
                    if (value != null) setState(() => _category = value);
                  },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _questionCount,
            decoration: const InputDecoration(
              labelText: 'Question count',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: !_saving,
            validator: (value) {
              final parsed = _parseInt(value ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Question count must be greater than zero.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _marks,
            decoration: const InputDecoration(
              labelText: 'Total marks',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: !_saving,
            validator: (value) {
              final parsed = _parseInt(value ?? '');
              if (parsed == null || parsed < 0) {
                return 'Total marks must be zero or greater.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _duration,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: !_saving,
            validator: (value) {
              final parsed = _parseInt(value ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Duration must be greater than zero.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _negativeMarking,
            decoration: const InputDecoration(
              labelText: 'Negative marking',
              border: OutlineInputBorder(),
              helperText: 'Numeric value, e.g. 0 or 0.25',
            ),
            enabled: !_saving,
            validator: (value) {
              final trimmed = (value ?? '').trim();
              if (trimmed.isEmpty) return null;
              final parsed = num.tryParse(trimmed);
              if (parsed == null || parsed.isNaN || parsed < 0) {
                return 'Enter a valid non-negative number.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _difficulty,
            decoration: const InputDecoration(
              labelText: 'Difficulty',
              border: OutlineInputBorder(),
            ),
            enabled: !_saving,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Difficulty is required.'
                : null,
          ),
          const SizedBox(height: 16),
          if (editing)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Published'),
              subtitle: const Text('Draft tests are visible only in Admin.'),
              value: _isPublished,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _isPublished = value),
            ),
          if (_submitError != null) ...[
            const SizedBox(height: 16),
            Text(
              _submitError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                key: const ValueKey('submit-test'),
                onPressed: _saving ? null : _submit,
                child: Text(
                  _saving
                      ? 'Saving…'
                      : editing
                      ? 'Save changes'
                      : 'Create test',
                ),
              ),
              if (widget.onCancel != null)
                TextButton(
                  onPressed: _saving ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
