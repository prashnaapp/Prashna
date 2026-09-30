import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../../tests/data/grand_test_series.dart';
import '../../../tests/data/models/test_models.dart';
import '../../data/admin_test_scope.dart';
import '../../services/admin_test_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import 'admin_ui/admin_form_section.dart';
import 'admin_ui/admin_question_row.dart';
import 'admin_ui/admin_status_badge.dart';
import 'admin_ui/admin_surface.dart';

typedef AdminTestSubmit = Future<void> Function(TestModel test);

typedef AdminTestCreate =
    Future<void> Function(TestModel test, List<String> initialQuestionIds);

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
    this.onCreateDraft,
    this.onManageQuestions,
    this.onCancel,
    this.syllabusService,
    this.onDirtyChanged,
  });

  final List<Course> courses;
  final AdminTestSubmit onSubmit;
  final TestModel? initialTest;
  final String? initialCourseId;
  final AdminTestScope? scope;
  final AdminTestService? service;

  /// Create-only. Receives metadata plus optional initial Question IDs.
  /// Membership is not written onto [TestModel.questionIds] by this form.
  final AdminTestCreate? onCreateDraft;
  final VoidCallback? onManageQuestions;
  final VoidCallback? onCancel;
  final SyllabusService? syllabusService;
  final ValueChanged<bool>? onDirtyChanged;

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
  late final TextEditingController _year;
  late final TextEditingController _initialQuestionIds;
  String? _seriesId;

  String? _courseId;
  String? _paperId;
  String? _partId;
  String? _syllabusUnitId;
  TestCategoryType _category = TestCategoryType.chapterTests;
  TestPublicationStatus _status = TestPublicationStatus.draft;
  bool _saving = false;
  bool _draftPersisted = false;
  bool _loadingAvailable = false;
  String? _submitError;
  String? _availableMessage;
  List<Question> _availableQuestions = const [];
  final Set<String> _selectedQuestionIds = <String>{};
  bool _trackDirty = false;
  bool _isDirty = false;

  TestModel? get _initial => widget.initialTest;

  SyllabusService get _syllabus =>
      widget.syllabusService ?? SyllabusService.instance;

  static const _categories = [
    TestCategoryType.chapterTests,
    TestCategoryType.partTests,
    TestCategoryType.mockTests,
    TestCategoryType.previousYear,
  ];

  bool get _locked => widget.scope != null;

  bool get _isEditing => _initial != null && _initial!.id.isNotEmpty;

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
    _initialQuestionIds = TextEditingController();
    _year = TextEditingController(
      text: initial?.year == null
          ? (widget.scope?.year == null ? '' : '${widget.scope!.year}')
          : '${initial!.year}',
    );
    _seriesId = _optionalString(initial?.seriesId ?? widget.scope?.seriesId);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final controller in [
        _title,
        _description,
        _questionCount,
        _marks,
        _duration,
        _negativeMarking,
        _year,
        _initialQuestionIds,
      ]) {
        controller.addListener(_markDirty);
      }
      _trackDirty = true;
    });
  }

  void _markDirty() {
    if (!_trackDirty || _isDirty) return;
    _isDirty = true;
    widget.onDirtyChanged?.call(true);
  }

  void _clearDirty() {
    if (!_isDirty) return;
    _isDirty = false;
    widget.onDirtyChanged?.call(false);
  }

  void _onUserEdit(VoidCallback apply) {
    _markDirty();
    apply();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _questionCount.dispose();
    _marks.dispose();
    _duration.dispose();
    _negativeMarking.dispose();
    _year.dispose();
    _initialQuestionIds.dispose();
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

  TestModel _buildTest() {
    final initial = _initial;
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
      questionCount: parsedCount,
      marks: _parseInt(_marks.text) ?? 0,
      durationMinutes: _parseInt(_duration.text) ?? 0,
      negativeMarking: _negativeMarking.text.trim(),
      // Keep the legacy schema value without exposing Difficulty in the form.
      difficulty: _initial?.difficulty ?? 'Medium',
      questionIds: initial?.questionIds ?? const [],
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
      seriesId: isGrand ? _seriesId : null,
      // The form does not edit these. Preserve them so update() cannot
      // treat "not shown" as "explicitly cleared".
      majorStudyAreaId: initial?.majorStudyAreaId,
      contentTopicId: initial?.contentTopicId,
      canonicalTopicId: initial?.canonicalTopicId,
      lessonId: initial?.lessonId,
      scopeShape: initial?.scopeShape,
    );
  }

  String? _optionalString(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  List<String> _selectedInitialIds() {
    return AdminTestService.dedupeQuestionIds([
      _initialQuestionIds.text,
      ..._selectedQuestionIds,
    ]);
  }

  Future<void> _loadAvailableQuestions() async {
    final service = widget.service;
    if (service == null) {
      setState(() {
        _availableMessage = 'Compatible Questions are not available.';
      });
      return;
    }
    setState(() {
      _loadingAvailable = true;
      _availableMessage = null;
    });
    try {
      final page = await service.loadAvailableInitialQuestionPage(_buildTest());
      if (!mounted) return;
      setState(() {
        _availableQuestions = page.questions;
        _selectedQuestionIds.removeWhere(
          (id) => !page.questions.any((question) => question.id == id),
        );
        _loadingAvailable = false;
        _availableMessage = page.questions.isEmpty
            ? 'No unassigned compatible Questions.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingAvailable = false;
        _availableMessage = 'Could not load compatible Questions: $error';
      });
    }
  }

  Future<void> _submit() async {
    if (_draftPersisted) return;
    setState(() => _submitError = null);
    if (!_formKey.currentState!.validate()) return;

    final test = _buildTest();
    setState(() => _saving = true);
    try {
      if (_isEditing || widget.onCreateDraft == null) {
        await widget.onSubmit(test);
      } else {
        var ids = _selectedInitialIds();
        final service = widget.service;
        if (service != null && ids.isNotEmpty) {
          ids = await service.normalizeInitialQuestionIds(test, ids);
        }
        await widget.onCreateDraft!(test, ids);
      }
      if (mounted) _clearDirty();
    } on InitialQuestionAssignmentException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.toString();
        _draftPersisted = true;
        _saving = false;
      });
      _clearDirty();
      return;
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
      if (_seriesId != null) 'Grand Test: $_seriesId',
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
    return AdminFormSection(
      title: 'Placement',
      subtitle: 'Scope is locked from the hierarchy browser.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines) ...[
            Text(
              line,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AdminColors.textSecondary,
              ),
            ),
            const SizedBox(height: AdminSpacing.xs),
          ],
        ],
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
      key: const ValueKey('test-paper'),
      initialValue: _locationPapers.any((p) => p.id == _paperId)
          ? _paperId
          : null,
      isExpanded: true,
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
          : (value) => _onUserEdit(() {
              setState(() {
                _paperId = value;
                _partId = null;
                _syllabusUnitId = null;
              });
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
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Part',
          border: OutlineInputBorder(),
        ),
        items: [
          for (final item in paper.parts)
            DropdownMenuItem(
              value: item.id,
              child: Text(item.displayName, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _saving
            ? null
            : (value) => _onUserEdit(() {
                setState(() {
                  _partId = value;
                  _syllabusUnitId = null;
                });
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
        Text('Paper-wise Tests', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _paperDropdown(requiredField: true),
      ],
    );
  }

  Widget _grandTestFields() {
    final options = GrandTestSeries.selectorValues(existing: _seriesId);
    final selected = options.contains(_seriesId) ? _seriesId : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text('Grand Tests', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const ValueKey('grand-test-series'),
          initialValue: selected,
          decoration: const InputDecoration(
            labelText: 'Grand Test',
            border: OutlineInputBorder(),
            helperText: 'Group identity shared by every paper in this set.',
          ),
          items: [
            for (final id in options)
              DropdownMenuItem<String>(value: id, child: Text(id)),
          ],
          onChanged: _saving || _locked
              ? null
              : (value) => _onUserEdit(() => setState(() => _seriesId = value)),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Grand Test group is required.'
              : null,
        ),
        const SizedBox(height: 16),
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
          key: const ValueKey('test-year'),
          controller: _year,
          decoration: const InputDecoration(
            labelText: 'Year',
            hintText: '2016',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          enabled: !_saving && !_locked,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            final year = _parseInt(value ?? '');
            if (year == null || year < 1900 || year > 2100) {
              return 'A valid exam year is required.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
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
              : (value) =>
                    _onUserEdit(() => setState(() => _syllabusUnitId = value)),
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
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _editorHeader(context, editing: editing),
        const SizedBox(height: AdminSpacing.lg),
        if (_locked)
          _lockedContextCard()
        else
          AdminFormSection(
            key: const ValueKey('section-classification'),
            title: 'Test Classification & Scope',
            subtitle:
                'Choose the course, category, and scope that place this test '
                'in the catalog.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  key: const ValueKey('test-course'),
                  initialValue: _courseId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final course in widget.courses)
                      DropdownMenuItem(
                        value: course.courseId,
                        child: Text(
                          course.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => _onUserEdit(() {
                          setState(() {
                            _courseId = value;
                            _paperId = null;
                            _partId = null;
                            _syllabusUnitId = null;
                            _seriesId = null;
                            _year.clear();
                          });
                        }),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Course is required.'
                      : null,
                ),
                const SizedBox(height: AdminSpacing.lg),
                DropdownButtonFormField<TestCategoryType>(
                  key: const ValueKey('test-category'),
                  initialValue: _category,
                  isExpanded: true,
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
                          if (value == null) return;
                          _onUserEdit(() {
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
                          });
                        },
                ),
                _categoryMetadataFields(),
              ],
            ),
          ),
        AdminFormSection(
          key: const ValueKey('section-details'),
          title: 'Test Details',
          subtitle: 'Title and description for Admin and catalog.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: AdminSpacing.lg),
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
            ],
          ),
        ),
        AdminFormSection(
          key: const ValueKey('section-exam-config'),
          title: 'Exam Configuration',
          subtitle:
              'Question count, marks, duration, and negative marking for the '
              'test engine.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 640;
              final fields = [
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
              ];
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      if (i > 0) const SizedBox(height: AdminSpacing.lg),
                      fields[i],
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: AdminSpacing.lg),
                      Expanded(child: fields[1]),
                    ],
                  ),
                  const SizedBox(height: AdminSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: fields[2]),
                      const SizedBox(width: AdminSpacing.lg),
                      Expanded(child: fields[3]),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        if (!editing) _initialQuestionsSection(),
        if (editing) _assignedQuestionsSummary(),
        if (editing)
          AdminFormSection(
            key: const ValueKey('section-publication'),
            title: 'Publication',
            subtitle: _publicationHelp(_status),
            child: DropdownButtonFormField<TestPublicationStatus>(
              key: const ValueKey('test-status'),
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final status in TestPublicationStatus.values)
                  DropdownMenuItem(
                    value: status,
                    child: Text(_statusLabel(status)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      _onUserEdit(() => setState(() => _status = value));
                    },
            ),
          ),
        if (preview != null)
          AdminFormSection(
            key: const ValueKey('test-preview'),
            title: 'Preview',
            subtitle: 'Live summary of the catalog payload before save.',
            compact: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.title.isEmpty ? 'Untitled test' : preview.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (preview.description.isNotEmpty) ...[
                  const SizedBox(height: AdminSpacing.xs),
                  Text(preview.description),
                ],
                const SizedBox(height: AdminSpacing.sm),
                Text(
                  '${preview.questionCount} planned questions • ${preview.marks} marks • '
                  '${preview.durationMinutes} min • negative ${preview.negativeMarking}',
                ),
                Text(
                  editing
                      ? 'Assigned Questions: ${preview.questionIds.length}'
                      : '${_selectedInitialIds().length} currently selected',
                ),
                if (preview.syllabusUnitId != null)
                  Text(
                    'Location: ${preview.paperId ?? '—'}'
                    '${preview.partId == null ? '' : ' / ${preview.partId}'}'
                    ' / ${preview.syllabusUnitId}',
                  ),
                Text('Status: ${_statusLabel(preview.status)}'),
              ],
            ),
          ),
        if (_submitError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AdminSpacing.md),
            child: AdminSurface(
              padding: const EdgeInsets.all(AdminSpacing.md),
              child: Text(
                _submitError!,
                style: const TextStyle(color: AdminColors.danger),
              ),
            ),
          ),
        const SizedBox(height: AdminSpacing.xxxl),
      ],
    );

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded =
              constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
          final scroll = SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AdminSpacing.pagePadding,
              AdminSpacing.pagePadding,
              AdminSpacing.pagePadding,
              AdminSpacing.lg,
            ),
            child: body,
          );
          if (!bounded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AdminSpacing.pagePadding,
                AdminSpacing.pagePadding,
                AdminSpacing.pagePadding,
                AdminSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  body,
                  _actionBar(editing: editing),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: scroll),
              _actionBar(editing: editing),
            ],
          );
        },
      ),
    );
  }

  Widget _assignedQuestionsSummary() {
    final count = _initial?.questionIds.length ?? 0;
    return AdminFormSection(
      key: const ValueKey('section-assigned-questions'),
      title: 'Assigned Questions',
      subtitle: 'Change membership from Manage Questions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assigned Questions: $count'),
          if (widget.onManageQuestions != null) ...[
            const SizedBox(height: AdminSpacing.sm),
            TextButton(
              key: const ValueKey('edit-manage-questions'),
              onPressed: _saving ? null : widget.onManageQuestions,
              child: const Text('Manage Questions'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _initialQuestionsSection() {
    final selected = _selectedInitialIds().length;
    return AdminFormSection(
      key: const ValueKey('section-initial-questions'),
      title: 'Initial Questions (Optional)',
      subtitle:
          'Seed this draft from the compatible Question Bank, or leave it empty. '
          'Later changes stay in Manage Questions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const ValueKey('initial-question-ids'),
            controller: _initialQuestionIds,
            maxLines: 4,
            enabled: !_saving && !_draftPersisted,
            decoration: const InputDecoration(
              labelText: 'Manual Question IDs',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              helperText: 'Optional. One ID per line or comma-separated.',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AdminSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              key: const ValueKey('load-available-questions'),
              onPressed: _saving || _loadingAvailable || _draftPersisted
                  ? null
                  : _loadAvailableQuestions,
              child: Text(
                _loadingAvailable ? 'Loading…' : 'Load available Questions',
              ),
            ),
          ),
          if (_availableMessage != null) ...[
            const SizedBox(height: AdminSpacing.sm),
            Text(_availableMessage!),
          ],
          if (_availableQuestions.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.md),
            for (final question in _availableQuestions)
              Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  key: ValueKey('initial-question-${question.id}'),
                  value: _selectedQuestionIds.contains(question.id),
                  contentPadding: EdgeInsets.zero,
                  title: Text(AdminQuestionRow.previewText(question)),
                  subtitle: Text(question.id),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: _saving || _draftPersisted
                      ? null
                      : (value) => _onUserEdit(() {
                          setState(() {
                            if (value == true) {
                              _selectedQuestionIds.add(question.id);
                            } else {
                              _selectedQuestionIds.remove(question.id);
                            }
                          });
                        }),
                ),
              ),
          ],
          const SizedBox(height: AdminSpacing.sm),
          Text(
            '$selected currently selected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AdminColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorHeader(BuildContext context, {required bool editing}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editing ? 'Edit Test' : 'Create Test',
                key: ValueKey(
                  editing ? 'test-form-edit-title' : 'test-form-create-title',
                ),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AdminSpacing.xs),
              Text(
                editing
                    ? 'Update classification, exam config, and status. '
                          'Question membership stays in Manage Questions.'
                    : 'Define a new catalog test for the selected Admin scope.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AdminColors.textSecondary,
                ),
              ),
              if (_isDirty) ...[
                const SizedBox(height: AdminSpacing.sm),
                Text(
                  'Unsaved changes',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AdminColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (editing)
          AdminStatusBadge.test(
            _status,
            key: const ValueKey('test-form-status-badge'),
          ),
      ],
    );
  }

  Widget _actionBar({required bool editing}) {
    return Material(
      elevation: 6,
      color: AdminColors.surfaceElevated,
      shadowColor: AdminColors.textPrimary.withValues(alpha: 0.08),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AdminSpacing.pagePadding,
            AdminSpacing.md,
            AdminSpacing.pagePadding,
            AdminSpacing.md,
          ),
          child: Row(
            children: [
              TextButton(
                onPressed: _saving
                    ? null
                    : widget.onCancel ?? () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('submit-test'),
                onPressed: _saving || _draftPersisted ? null : _submit,
                child: Text(
                  _saving
                      ? 'Saving…'
                      : editing
                      ? 'Save changes'
                      : 'Create draft',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(TestPublicationStatus status) {
    switch (status) {
      case TestPublicationStatus.draft:
        return 'Draft';
      case TestPublicationStatus.published:
        return 'Published';
      case TestPublicationStatus.archived:
        return 'Archived';
    }
  }

  static String _publicationHelp(TestPublicationStatus status) {
    switch (status) {
      case TestPublicationStatus.draft:
        return 'Draft — not visible to students in the catalog.';
      case TestPublicationStatus.published:
        return 'Published — available to students with course access.';
      case TestPublicationStatus.archived:
        return 'Archived — removed from active catalog without permanent deletion.';
    }
  }
}
