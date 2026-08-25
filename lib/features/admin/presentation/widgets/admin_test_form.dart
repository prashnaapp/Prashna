import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../../tests/data/models/test_models.dart';
import '../../data/admin_test_scope.dart';
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
    this.scope,
    this.service,
    this.onCancel,
    this.syllabusService,
  });

  final List<Course> courses;
  final AdminTestSubmit onSubmit;
  final TestModel? initialTest;
  final String? initialCourseId;
  final AdminTestScope? scope;
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
  late final TextEditingController _year;
  late final TextEditingController _seriesId;

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

  static const _categories = [
    TestCategoryType.chapterTests,
    TestCategoryType.partTests,
    TestCategoryType.mockTests,
    TestCategoryType.previousYear,
  ];

  bool get _locked => widget.scope != null;

  bool get _isLockedChapter =>
      _locked &&
      _category == TestCategoryType.chapterTests &&
      _syllabusUnitId != null &&
      _syllabusUnitId!.isNotEmpty;

  bool get _isSyllabusCourse {
    final course = _syllabus.getCourseById(_courseId ?? '');
    return course != null && course.papers.isNotEmpty;
  }

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
    _year = TextEditingController(
      text: initial?.year == null
          ? (widget.scope?.year == null ? '' : '${widget.scope!.year}')
          : '${initial!.year}',
    );
    _seriesId = TextEditingController(
      text: initial?.seriesId ?? widget.scope?.seriesId ?? '',
    );
    _courseId =
        initial?.examId ??
        widget.scope?.courseId ??
        widget.initialCourseId ??
        (widget.courses.isEmpty ? null : widget.courses.first.courseId);
    _paperId = initial?.paperId ?? widget.scope?.paperId;
    _partId = initial?.partId ?? widget.scope?.partId;
    _syllabusUnitId = initial?.syllabusUnitId ?? widget.scope?.syllabusUnitId;
    _category =
        initial?.category ??
        widget.scope?.category ??
        TestCategoryType.chapterTests;
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
    _year.dispose();
    _seriesId.dispose();
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
        return 'Grand Tests';
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
    final isPaperWise = _category == TestCategoryType.partTests;
    final isGrand = _category == TestCategoryType.mockTests;
    final isPrevious = _category == TestCategoryType.previousYear;
    final keepChapterLocation =
        _category == TestCategoryType.chapterTests ||
        _category == TestCategoryType.paperTests;
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
      partId: _isSyllabusCourse && (isPaperWise || keepChapterLocation)
          ? _partId
          : null,
      syllabusUnitId: _isSyllabusCourse && keepChapterLocation
          ? _syllabusUnitId
          : null,
      year: isPrevious ? _parseInt(_year.text) : null,
      seriesId: isGrand ? _optional(_seriesId.text) : null,
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
    if (_isLockedChapter) {
      await _appendChapterQuestionIds();
      return;
    }
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
      _mergeQuestionIds(ids, emptyMessage: 'No matching questions found.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingFilter = false;
        _filterMessage = 'Could not load questions: $error';
      });
    }
  }

  Future<void> _appendChapterQuestionIds() async {
    final courseId = _courseId;
    final paperId = _paperId;
    final unitId = _syllabusUnitId;
    if (courseId == null || paperId == null || unitId == null) {
      setState(() => _filterMessage = 'Chapter location is missing.');
      return;
    }
    setState(() {
      _loadingFilter = true;
      _filterMessage = null;
    });
    try {
      final ids = await _resolvedService.findQuestionIdsForChapterTest(
        courseId: courseId,
        paperId: paperId,
        partId: _partId,
        syllabusUnitId: unitId,
      );
      if (!mounted) return;
      _mergeQuestionIds(
        ids,
        emptyMessage: 'No published questions in this Chapter/Topic yet.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingFilter = false;
        _filterMessage = 'Could not load questions: $error';
      });
    }
  }

  void _mergeQuestionIds(List<String> ids, {required String emptyMessage}) {
    if (ids.isEmpty) {
      setState(() {
        _loadingFilter = false;
        _filterMessage = emptyMessage;
      });
      return;
    }
    final merged = _parseQuestionIds('${_questionIds.text}\n${ids.join('\n')}');
    setState(() {
      _questionIds.text = merged.join('\n');
      _questionCount.text = '${merged.isEmpty ? 0 : merged.length}';
      _loadingFilter = false;
      _filterMessage = 'Appended ${ids.length} question ID(s).';
    });
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

  Widget _lockedContextCard() {
    final courseTitle = () {
      for (final course in widget.courses) {
        if (course.courseId == _courseId) return course.title;
      }
      return _courseId ?? '';
    }();
    final unitName = () {
      for (final unit in _availableUnits) {
        if (unit.id == _syllabusUnitId) return unit.displayName;
      }
      return _syllabusUnitId;
    }();
    final lines = <String>[
      'Category: ${_categoryLabel(_category)}',
      if (_courseId != null) 'Course: $courseTitle',
      if (_paperId != null) 'Paper: ${_selectedPaper?.title ?? _paperId}',
      if (_partId != null) 'Part: ${_selectedPart?.displayName ?? _partId}',
      if (_syllabusUnitId != null) 'Chapter / Topic: $unitName',
      if (_seriesId.text.trim().isNotEmpty)
        'Grand Test: ${_seriesId.text.trim()}',
      if (_year.text.trim().isNotEmpty)
        'Examination year: ${_year.text.trim()}',
    ];
    if (_isLockedChapter) {
      lines.add(
        '$courseTitle → ${_selectedPaper?.title ?? _paperId}'
        '${_selectedPart == null ? '' : ' → ${_selectedPart!.displayName}'}'
        ' → $unitName',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Placement',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final line in lines) Text(line),
          ],
        ),
      ),
    );
  }

  Widget _categoryMetadataFields() {
    if (!_isSyllabusCourse) return const SizedBox.shrink();
    return switch (_category) {
      TestCategoryType.partTests => _paperWiseFields(),
      TestCategoryType.mockTests => _grandTestFields(),
      TestCategoryType.previousYear => _previousPaperFields(),
      TestCategoryType.chapterTests ||
      TestCategoryType.paperTests => _chapterLocationFields(),
    };
  }

  Widget _paperDropdown({required bool requiredField}) {
    return DropdownButtonFormField<String>(
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
      validator: (value) => requiredField && (value == null || value.isEmpty)
          ? 'Paper is required.'
          : null,
    );
  }

  Widget _partDropdown({required bool requiredField}) {
    final paper = _selectedPaper;
    final needsPart = paper?.hasCanonicalParts == true;
    if (!needsPart) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DropdownButtonFormField<String>(
        initialValue: paper!.parts.any((p) => p.id == _partId) ? _partId : null,
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
            requiredField &&
                _paperId != null &&
                (value == null || value.isEmpty)
            ? 'Part is required.'
            : null,
      ),
    );
  }

  Widget _paperWiseFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'Paper-wise Tests',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _paperDropdown(requiredField: true),
        _partDropdown(requiredField: true),
      ],
    );
  }

  Widget _grandTestFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text('Grand Tests', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: _seriesId,
          decoration: const InputDecoration(
            labelText: 'Grand Test',
            hintText: 'Grand Test 1',
            border: OutlineInputBorder(),
            helperText: 'Group identity shared by every paper in this set.',
          ),
          enabled: !_saving,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Grand Test group is required.'
              : null,
        ),
        const SizedBox(height: 16),
        _paperDropdown(requiredField: true),
      ],
    );
  }

  Widget _previousPaperFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text('Previous Papers', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: _year,
          decoration: const InputDecoration(
            labelText: 'Year',
            hintText: '2016',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          enabled: !_saving,
          validator: (value) {
            final year = _parseInt(value ?? '');
            if (year == null || year < 1900 || year > 2100) {
              return 'A valid exam year is required.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _paperDropdown(requiredField: true),
      ],
    );
  }

  Widget _chapterLocationFields() {
    final units = _availableUnits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          '${_syllabus.getCourseById(_courseId ?? '')?.name ?? _courseId} '
          'syllabus location',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _paperDropdown(requiredField: false),
        _partDropdown(requiredField: true),
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
            if (_locked)
              _lockedContextCard()
            else ...[
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
                validator: (value) => value == null || value.isEmpty
                    ? 'Course is required.'
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
                        if (value != null) {
                          setState(() {
                            _category = value;
                            if (value != TestCategoryType.partTests &&
                                value != TestCategoryType.chapterTests &&
                                value != TestCategoryType.paperTests) {
                              _partId = null;
                            }
                            if (value != TestCategoryType.chapterTests &&
                                value != TestCategoryType.paperTests) {
                              _syllabusUnitId = null;
                            }
                          });
                        }
                      },
              ),
              _categoryMetadataFields(),
            ],
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
              decoration: InputDecoration(
                labelText: 'Question IDs (optional)',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                helperText: _isLockedChapter
                    ? 'Only questions from this Chapter/Topic are accepted. '
                          'One ID per line or comma-separated.'
                    : 'One ID per line or comma-separated. Leave empty for dynamic selection.',
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
            if (_isLockedChapter) ...[
              Text(
                'Questions for this Chapter/Topic only',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _saving || _loadingFilter
                    ? null
                    : _appendChapterQuestionIds,
                child: Text(
                  _loadingFilter
                      ? 'Loading…'
                      : 'Append questions from this Chapter/Topic',
                ),
              ),
            ] else ...[
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
            ],
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
