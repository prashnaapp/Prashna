import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../../tests/data/models/test_models.dart';
import '../../services/admin_test_service.dart';

typedef AdminTestSubmit = Future<void> Function(TestModel test);

/// Create/edit form for the canonical [TestModel] catalog definition.
class AdminTestForm extends StatefulWidget {
  const AdminTestForm({
    super.key,
    required this.courses,
    required this.onSubmit,
    this.initialTest,
    this.initialCourseId,
    this.service,
    this.onCancel,
    this.syllabusService,
  });

  final List<Course> courses;
  final AdminTestSubmit onSubmit;
  final TestModel? initialTest;
  final String? initialCourseId;
  final AdminTestService? service;
  final VoidCallback? onCancel;
  final SyllabusService? syllabusService;

  @override
  State<AdminTestForm> createState() => _AdminTestFormState();
}

class _AdminTestFormState extends State<AdminTestForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _questionCount;
  late final TextEditingController _marks;
  late final TextEditingController _duration;
  late final TextEditingController _negativeMarking;
  late final TextEditingController _difficulty;
  late final TextEditingController _questionIds;
  late final TextEditingController _filterPaper;
  late final TextEditingController _filterPart;
  late final TextEditingController _filterTopic;
  late final TextEditingController _filterLesson;
  late final TextEditingController _filterSyllabusUnit;

  String? _courseId;
  String? _paperId;
  String? _partId;
  String? _syllabusUnitId;
  TestCategoryType _category = TestCategoryType.chapterTests;
  TestPublicationStatus _status = TestPublicationStatus.draft;
  bool _saving = false;
  bool _loadingFilter = false;
  String? _submitError;
  String? _filterMessage;

  TestModel? get _initial => widget.initialTest;
  AdminTestService? _service;

  AdminTestService get _resolvedService =>
      _service ??= widget.service ?? AdminTestService.instance;

  SyllabusService get _syllabus =>
      widget.syllabusService ?? SyllabusService.instance;

  static const _categories = TestCategoryType.values;

  bool get _isSyllabusCourse =>
      _courseId == 'group-ii' || _courseId == 'group-iii';

  SyllabusPaper? get _selectedPaper {
    final courseId = _courseId;
    final paperId = _paperId;
    if (courseId == null || paperId == null) return null;
    return _syllabus.getPaper(courseId: courseId, paperId: paperId);
  }

  SyllabusPart? get _selectedPart {
    final courseId = _courseId;
    final paperId = _paperId;
    final partId = _partId;
    if (courseId == null || paperId == null || partId == null) return null;
    return _syllabus.getPart(
      courseId: courseId,
      paperId: paperId,
      partId: partId,
    );
  }

  List<SyllabusPaper> get _locationPapers {
    return _syllabus.getCourseById(_courseId ?? '')?.papers ?? const [];
  }

  List<SyllabusUnit> get _availableUnits {
    final paper = _selectedPaper;
    if (paper == null) return const [];
    if (paper.hasDirectSyllabusUnits) return paper.syllabusUnits;
    return _selectedPart?.syllabusUnits ?? const [];
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    final initial = _initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
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
    _questionIds = TextEditingController(
      text: (initial?.questionIds ?? const []).join('\n'),
    );
    _filterPaper = TextEditingController();
    _filterPart = TextEditingController();
    _filterTopic = TextEditingController();
    _filterLesson = TextEditingController();
    _filterSyllabusUnit = TextEditingController();
    _courseId =
        initial?.examId ??
        widget.initialCourseId ??
        (widget.courses.isEmpty ? null : widget.courses.first.courseId);
    _paperId = initial?.paperId;
    _partId = initial?.partId;
    _syllabusUnitId = initial?.syllabusUnitId;
    _category = initial?.category ?? TestCategoryType.chapterTests;
    _status = initial?.status ?? TestPublicationStatus.draft;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _questionCount.dispose();
    _marks.dispose();
    _duration.dispose();
    _negativeMarking.dispose();
    _difficulty.dispose();
    _questionIds.dispose();
    _filterPaper.dispose();
    _filterPart.dispose();
    _filterTopic.dispose();
    _filterLesson.dispose();
    _filterSyllabusUnit.dispose();
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

  List<String> _parseQuestionIds(String raw) {
    final ids = <String>[];
    final seen = <String>{};
    for (final part in raw.split(RegExp(r'[\n,]'))) {
      final id = part.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      ids.add(id);
    }
    return ids;
  }

  TestModel _buildTest() {
    final initial = _initial;
    final questionIds = _parseQuestionIds(_questionIds.text);
    final parsedCount = _parseInt(_questionCount.text) ?? 0;
    return TestModel(
      id: initial?.id ?? '',
      examId: _courseId!.trim(),
      category: _category,
      title: _title.text.trim(),
      description: _description.text.trim(),
      questionCount: questionIds.isNotEmpty ? questionIds.length : parsedCount,
      marks: _parseInt(_marks.text) ?? 0,
      durationMinutes: _parseInt(_duration.text) ?? 0,
      negativeMarking: _negativeMarking.text.trim(),
      difficulty: _difficulty.text.trim(),
      questionIds: questionIds,
      status: (_initial == null || _initial!.id.isEmpty)
          ? TestPublicationStatus.draft
          : _status,
      paperId: _isSyllabusCourse ? _paperId : null,
      partId: _isSyllabusCourse ? _partId : null,
      syllabusUnitId: _isSyllabusCourse ? _syllabusUnitId : null,
      // The form does not edit these. Preserve them so update() cannot
      // treat "not shown" as "explicitly cleared".
      majorStudyAreaId: initial?.majorStudyAreaId,
      contentTopicId: initial?.contentTopicId,
      canonicalTopicId: initial?.canonicalTopicId,
      lessonId: initial?.lessonId,
      scopeShape: initial?.scopeShape,
    );
  }

  Future<void> _appendFilteredQuestionIds() async {
    final courseId = _courseId;
    if (courseId == null || courseId.isEmpty) {
      setState(() => _filterMessage = 'Select a course first.');
      return;
    }
    setState(() {
      _loadingFilter = true;
      _filterMessage = null;
    });
    try {
      final ids = await _resolvedService.findQuestionIds(
        courseId: courseId,
        paperId: _optional(_filterPaper.text),
        partId: _optional(_filterPart.text),
        topicId: _optional(_filterTopic.text),
        lessonId: _optional(_filterLesson.text),
        syllabusUnitId: _optional(_filterSyllabusUnit.text),
      );
      if (!mounted) return;
      final merged = _parseQuestionIds(
        '${_questionIds.text}\n${ids.join('\n')}',
      );
      setState(() {
        _questionIds.text = merged.join('\n');
        _questionCount.text = '${merged.isEmpty ? 0 : merged.length}';
        _loadingFilter = false;
        _filterMessage = 'Appended ${ids.length} question ID(s).';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingFilter = false;
        _filterMessage = 'Could not load questions: $error';
      });
    }
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
        _submitError = error.toString().replaceFirst('FormatException: ', '');
        _saving = false;
      });
      return;
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _syllabusLocationFields() {
    final paper = _selectedPaper;
    final needsPart = paper?.hasPartSyllabusUnits == true;
    final units = _availableUnits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          '${_courseId == 'group-ii' ? 'Group-II' : 'Group-III'} '
          'syllabus location',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _locationPapers.any((p) => p.id == _paperId)
              ? _paperId
              : null,
          decoration: const InputDecoration(
            labelText: 'Paper',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final item in _locationPapers)
              DropdownMenuItem(value: item.id, child: Text(item.title)),
          ],
          onChanged: _saving
              ? null
              : (value) => setState(() {
                  _paperId = value;
                  _partId = null;
                  _syllabusUnitId = null;
                }),
        ),
        if (needsPart) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: paper!.parts.any((p) => p.id == _partId)
                ? _partId
                : null,
            decoration: const InputDecoration(
              labelText: 'Part',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final item in paper.parts)
                DropdownMenuItem(value: item.id, child: Text(item.displayName)),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() {
                    _partId = value;
                    _syllabusUnitId = null;
                  }),
            validator: (value) =>
                _paperId != null &&
                    needsPart &&
                    (value == null || value.isEmpty)
                ? 'Part is required.'
                : null,
          ),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: units.any((unit) => unit.id == _syllabusUnitId)
              ? _syllabusUnitId
              : null,
          decoration: const InputDecoration(
            labelText: 'Syllabus Unit',
            border: OutlineInputBorder(),
            helperText:
                'Final folder before Tests (e.g. Kakatiyas and Medieval Telangana).',
          ),
          items: [
            for (final unit in units)
              DropdownMenuItem(value: unit.id, child: Text(unit.displayName)),
          ],
          onChanged: _saving || units.isEmpty
              ? null
              : (value) => setState(() => _syllabusUnitId = value),
          validator: (value) =>
              _paperId != null && (value == null || value.isEmpty)
              ? 'Syllabus Unit is required.'
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = _initial != null && _initial!.id.isNotEmpty;
    final preview = _courseId == null ? null : _buildTest();
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  : (value) => setState(() {
                      _courseId = value;
                      _paperId = null;
                      _partId = null;
                      _syllabusUnitId = null;
                    }),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Course is required.' : null,
            ),
            if (_isSyllabusCourse) _syllabusLocationFields(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              enabled: !_saving,
              onChanged: (_) => setState(() {}),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Title is required.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              enabled: !_saving,
              onChanged: (_) => setState(() {}),
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
                helperText:
                    'Auto-updates when explicit question IDs are provided.',
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
              key: const ValueKey('question-ids'),
              controller: _questionIds,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Question IDs (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                helperText:
                    'One ID per line or comma-separated. Leave empty for dynamic selection.',
              ),
              enabled: !_saving,
              onChanged: (value) {
                final ids = _parseQuestionIds(value);
                if (ids.isNotEmpty) {
                  _questionCount.text = '${ids.length}';
                }
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Filter-based question selection',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _filterPaper,
                    decoration: const InputDecoration(
                      labelText: 'Paper ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _filterPart,
                    decoration: const InputDecoration(
                      labelText: 'Part ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _filterTopic,
                    decoration: const InputDecoration(
                      labelText: 'Topic ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _filterLesson,
                    decoration: const InputDecoration(
                      labelText: 'Lesson ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _filterSyllabusUnit,
                    decoration: const InputDecoration(
                      labelText: 'Syllabus Unit ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _saving || _loadingFilter
                      ? null
                      : _appendFilteredQuestionIds,
                  child: Text(
                    _loadingFilter
                        ? 'Loading…'
                        : 'Append matching question IDs',
                  ),
                ),
              ],
            ),
            if (_filterMessage != null) ...[
              const SizedBox(height: 8),
              Text(_filterMessage!),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _marks,
              decoration: const InputDecoration(
                labelText: 'Total marks',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              enabled: !_saving,
              onChanged: (_) => setState(() {}),
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
              onChanged: (_) => setState(() {}),
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
              onChanged: (_) => setState(() {}),
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
            if (editing) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<TestPublicationStatus>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final status in TestPublicationStatus.values)
                    DropdownMenuItem(value: status, child: Text(status.name)),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _status = value);
                      },
              ),
            ],
            if (preview != null) ...[
              const SizedBox(height: 20),
              Card(
                key: const ValueKey('test-preview'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preview.title.isEmpty ? 'Untitled test' : preview.title,
                      ),
                      if (preview.description.isNotEmpty)
                        Text(preview.description),
                      Text(
                        '${preview.questionCount} questions • ${preview.marks} marks • '
                        '${preview.durationMinutes} min • negative ${preview.negativeMarking}',
                      ),
                      Text(
                        preview.questionIds.isEmpty
                            ? 'Question selection: dynamic'
                            : 'Question selection: ${preview.questionIds.length} explicit IDs',
                      ),
                      if (preview.syllabusUnitId != null)
                        Text(
                          'Location: ${preview.paperId ?? '—'}'
                          '${preview.partId == null ? '' : ' / ${preview.partId}'}'
                          ' / ${preview.syllabusUnitId}',
                        ),
                      Text('Status: ${preview.status.name}'),
                    ],
                  ),
                ),
              ),
            ],
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
                        : 'Create draft',
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
      ),
    );
  }
}
