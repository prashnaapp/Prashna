import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import 'admin_ui/admin_form_section.dart';
import 'admin_ui/admin_status_badge.dart';
import 'admin_ui/admin_surface.dart';

typedef AdminQuestionSubmit = Future<void> Function(Question question);

/// Create/edit form for the canonical Question entity.
class AdminQuestionForm extends StatefulWidget {
  const AdminQuestionForm({
    super.key,
    required this.courses,
    required this.onSubmit,
    this.initialQuestion,
    this.onCancel,
    this.onDirtyChanged,
  });

  final List<Course> courses;
  final AdminQuestionSubmit onSubmit;
  final Question? initialQuestion;
  final VoidCallback? onCancel;
  final ValueChanged<bool>? onDirtyChanged;

  @override
  State<AdminQuestionForm> createState() => _AdminQuestionFormState();
}

class _AdminQuestionFormState extends State<AdminQuestionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _question;
  late final TextEditingController _teluguQuestion;
  late final TextEditingController _paper;
  late final TextEditingController _section;
  late final TextEditingController _topic;
  late final TextEditingController _explanation;
  late final TextEditingController _teluguExplanation;
  late final TextEditingController _hint;
  late final TextEditingController _aiExplanation;
  late final TextEditingController _language;
  late final TextEditingController _marks;
  late final TextEditingController _negativeMarks;
  late final TextEditingController _estimatedSeconds;
  late final TextEditingController _year;
  late final TextEditingController _examName;
  late final TextEditingController _tags;
  late List<TextEditingController> _options;
  late List<TextEditingController> _teluguOptions;
  late List<_StatementControllers> _statements;

  String? _courseId;
  String _correctOption = 'A';
  QuestionItemFormat _itemFormat = QuestionItemFormat.standardMcq;
  QuestionDifficulty _difficulty = QuestionDifficulty.medium;
  QuestionType _questionType = QuestionType.practice;
  bool _isActive = true;
  bool _canonicalMode = true;
  String? _majorStudyAreaId;
  String? _contentTopicId;
  String? _partId;
  String? _canonicalTopicId;
  String? _lessonId;
  String? _syllabusUnitId;
  QuestionPublicationStatus _status = QuestionPublicationStatus.draft;
  bool _saving = false;
  String? _submitError;
  bool _trackDirty = false;
  bool _isDirty = false;

  Question? get _initial => widget.initialQuestion;
  bool get _isGroupIii => _courseId == 'group-iii';
  bool get _isStatementFormat =>
      _canonicalMode && _itemFormat == QuestionItemFormat.statementMcq;

  @override
  void initState() {
    super.initState();
    final initial = _initial;
    _question = TextEditingController(
      text: (initial?.question.isNotEmpty == true)
          ? initial!.question
          : initial?.content?.en.question ?? '',
    );
    _teluguQuestion = TextEditingController(
      text: initial?.content?.te?.question ?? '',
    );
    _paper = TextEditingController(text: initial?.paperId ?? '');
    _section = TextEditingController(text: initial?.sectionId ?? '');
    _topic = TextEditingController(text: initial?.topicId ?? '');
    _explanation = TextEditingController(
      text: (initial?.explanation.isNotEmpty == true)
          ? initial!.explanation
          : initial?.content?.en.explanation ?? '',
    );
    _teluguExplanation = TextEditingController(
      text: initial?.content?.te?.explanation ?? '',
    );
    _hint = TextEditingController(text: initial?.hint ?? '');
    _aiExplanation = TextEditingController(text: initial?.aiExplanation ?? '');
    _language = TextEditingController(text: initial?.language ?? 'en');
    _marks = TextEditingController(text: _number(initial?.marks ?? 1));
    _negativeMarks = TextEditingController(
      text: _number(initial?.negativeMarks ?? 0),
    );
    _estimatedSeconds = TextEditingController(
      text: '${initial?.estimatedTime.inSeconds ?? 60}',
    );
    _year = TextEditingController(text: initial?.year?.toString() ?? '');
    _examName = TextEditingController(text: initial?.examName ?? '');
    _tags = TextEditingController(text: initial?.tags.join(', ') ?? '');
    final seedOptions = () {
      if (initial != null && initial.options.isNotEmpty) {
        return initial.options;
      }
      final fromContent = initial?.content?.en.options
          .map((option) => option.text)
          .toList(growable: false);
      if (fromContent != null && fromContent.isNotEmpty) {
        return fromContent;
      }
      return const ['', '', '', ''];
    }();
    _options = [
      for (final option in seedOptions) TextEditingController(text: option),
    ];
    final seedTelugu = () {
      final fromContent = initial?.content?.te?.options
          .map((option) => option.text)
          .toList(growable: false);
      if (fromContent != null && fromContent.isNotEmpty) {
        return fromContent;
      }
      return const <String>[];
    }();
    _teluguOptions = [
      for (final option in seedTelugu) TextEditingController(text: option),
    ];
    while (_teluguOptions.length < _options.length) {
      _teluguOptions.add(TextEditingController());
    }
    _itemFormat = initial?.resolvedItemFormat ?? QuestionItemFormat.standardMcq;
    _statements = _seedStatements(initial);
    _courseId = initial?.courseId;
    _canonicalMode = initial == null || initial.content != null;
    if (_canonicalMode &&
        _paper.text.isEmpty &&
        (_courseId == null || _courseId == 'group-ii')) {
      _paper.text = 'group-ii-paper-i';
    }
    _majorStudyAreaId = initial?.majorStudyAreaId;
    _contentTopicId = initial?.contentTopicId;
    _partId = initial?.partId;
    _canonicalTopicId = initial?.syllabus?.topicId;
    _lessonId = initial?.lessonId;
    _syllabusUnitId = initial?.syllabusUnitId;
    _correctOption = initial?.correctOption ?? 'A';
    _difficulty = initial?.difficulty ?? QuestionDifficulty.medium;
    _questionType = initial?.questionType ?? QuestionType.practice;
    _isActive = initial?.isActive ?? true;
    _status = initial?.status ?? QuestionPublicationStatus.draft;
    if (_itemFormat == QuestionItemFormat.statementMcq) {
      _ensureFourEnglishOptions();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _attachDirtyListeners();
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

  void _watchController(TextEditingController controller) {
    controller.addListener(_markDirty);
  }

  void _onUserEdit(VoidCallback apply) {
    _markDirty();
    apply();
  }

  void _attachDirtyListeners() {
    final controllers = <TextEditingController>[
      _question,
      _teluguQuestion,
      _paper,
      _section,
      _topic,
      _explanation,
      _teluguExplanation,
      _hint,
      _aiExplanation,
      _language,
      _marks,
      _negativeMarks,
      _estimatedSeconds,
      _year,
      _examName,
      _tags,
      ..._options,
      ..._teluguOptions,
      for (final statement in _statements) ...[
        statement.english,
        statement.telugu,
      ],
    ];
    for (final controller in controllers) {
      _watchController(controller);
    }
  }

  @override
  void dispose() {
    _question.dispose();
    _teluguQuestion.dispose();
    _paper.dispose();
    _section.dispose();
    _topic.dispose();
    _explanation.dispose();
    _teluguExplanation.dispose();
    _hint.dispose();
    _aiExplanation.dispose();
    _language.dispose();
    _marks.dispose();
    _negativeMarks.dispose();
    _estimatedSeconds.dispose();
    _year.dispose();
    _examName.dispose();
    _tags.dispose();
    for (final option in _options) {
      option.dispose();
    }
    for (final option in _teluguOptions) {
      option.dispose();
    }
    for (final statement in _statements) {
      statement.dispose();
    }
    super.dispose();
  }

  List<_StatementControllers> _seedStatements(Question? initial) {
    final english = initial?.content?.en.statements ?? const <String>[];
    final telugu = initial?.content?.te?.statements ?? const <String>[];
    final count = english.length > telugu.length
        ? english.length
        : telugu.length;
    if (count == 0) {
      if (initial?.resolvedItemFormat == QuestionItemFormat.statementMcq) {
        return [_StatementControllers(), _StatementControllers()];
      }
      return <_StatementControllers>[];
    }
    return [
      for (var i = 0; i < count; i++)
        _StatementControllers(
          english: i < english.length ? english[i] : '',
          telugu: i < telugu.length ? telugu[i] : '',
        ),
    ];
  }

  void _onItemFormatChanged(QuestionItemFormat? format) {
    if (format == null) return;
    _onUserEdit(() {
      setState(() {
        _itemFormat = format;
        if (format == QuestionItemFormat.statementMcq) {
          _ensureFourEnglishOptions();
          if (_statements.isEmpty) {
            final first = _StatementControllers();
            final second = _StatementControllers();
            if (_trackDirty) {
              _watchController(first.english);
              _watchController(first.telugu);
              _watchController(second.english);
              _watchController(second.telugu);
            }
            _statements.add(first);
            _statements.add(second);
          }
        }
      });
    });
  }

  void _ensureFourEnglishOptions() {
    while (_options.length < 4) {
      final en = TextEditingController();
      final te = TextEditingController();
      if (_trackDirty) {
        _watchController(en);
        _watchController(te);
      }
      _options.add(en);
      _teluguOptions.add(te);
    }
    while (_options.length > 4) {
      _options.removeLast().dispose();
      if (_teluguOptions.isNotEmpty) {
        _teluguOptions.removeLast().dispose();
      }
    }
    while (_teluguOptions.length < _options.length) {
      final te = TextEditingController();
      if (_trackDirty) _watchController(te);
      _teluguOptions.add(te);
    }
    const labels = ['A', 'B', 'C', 'D'];
    if (!labels.contains(_correctOption)) {
      _correctOption = labels.last;
    }
  }

  void _addStatement() {
    final statement = _StatementControllers();
    if (_trackDirty) {
      _watchController(statement.english);
      _watchController(statement.telugu);
    }
    _onUserEdit(() => setState(() => _statements.add(statement)));
  }

  void _removeStatement(int index) {
    if (_statements.length <= 1) return;
    final removed = _statements.removeAt(index);
    removed.dispose();
    _onUserEdit(() => setState(() {}));
  }

  static String _number(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  String? _positiveNumber(
    String? value,
    String label, {
    bool allowZero = false,
  }) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null ||
        !parsed.isFinite ||
        (!allowZero && parsed <= 0) ||
        (allowZero && parsed < 0)) {
      return '$label must be a valid ${allowZero ? 'non-negative' : 'positive'} number.';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_courseId == null || _courseId!.isEmpty) {
      setState(() => _submitError = 'Course is required.');
      return;
    }

    final marks = double.parse(_marks.text.trim());
    final negativeMarks = double.parse(_negativeMarks.text.trim());
    final seconds = int.parse(_estimatedSeconds.text.trim());
    final year = int.tryParse(_year.text.trim());
    final question = Question(
      id: _initial?.id ?? '',
      courseId: _courseId!,
      paperId: _paper.text.trim(),
      sectionId: _canonicalMode ? '' : _section.text.trim(),
      topicId: _canonicalMode ? '' : _topic.text.trim(),
      question: _question.text.trim(),
      options: [for (final option in _options) option.text.trim()],
      correctOption: _correctOption,
      explanation: _explanation.text.trim(),
      difficulty: _difficulty,
      questionType: _questionType,
      language: _language.text.trim(),
      marks: marks,
      negativeMarks: negativeMarks,
      tags: [
        for (final tag in _tags.text.split(','))
          if (tag.trim().isNotEmpty) tag.trim(),
      ],
      estimatedTime: Duration(seconds: seconds),
      year: year,
      examName: _examName.text.trim().isEmpty ? null : _examName.text.trim(),
      hint: _hint.text.trim().isEmpty ? null : _hint.text.trim(),
      aiExplanation: _aiExplanation.text.trim().isEmpty
          ? null
          : _aiExplanation.text.trim(),
      createdAt: _initial?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: _isActive,
      itemFormat: _canonicalMode ? _itemFormat : _initial?.itemFormat,
      content: _canonicalMode
          ? QuestionContent(
              en: QuestionLocalizedContent(
                question: _question.text.trim(),
                options: [
                  for (final option in _options)
                    QuestionOption(text: option.text.trim()),
                ],
                explanation: _explanation.text.trim(),
                statements: _isStatementFormat
                    ? [
                        for (final statement in _statements)
                          statement.english.text.trim(),
                      ]
                    : const [],
              ),
              te: QuestionLocalizedContent(
                question: _teluguQuestion.text.trim(),
                options: _isStatementFormat
                    ? const []
                    : [
                        for (final option in _teluguOptions)
                          QuestionOption(text: option.text.trim()),
                      ],
                explanation: _teluguExplanation.text.trim(),
                statements: _isStatementFormat
                    ? [
                        for (final statement in _statements)
                          statement.telugu.text.trim(),
                      ]
                    : const [],
              ),
            )
          : null,
      syllabus: _canonicalMode ? _canonicalAttribution() : _initial?.syllabus,
      status: _canonicalMode ? _status : _initial?.status,
    );

    setState(() {
      _saving = true;
      _submitError = null;
    });
    try {
      await widget.onSubmit(question);
      if (mounted) {
        _clearDirty();
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = error.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  QuestionSyllabusAttribution _canonicalAttribution() {
    if (_isGroupIii) {
      return QuestionSyllabusAttribution(
        courseId: _courseId!,
        paperId: _paper.text.trim(),
        partId: _partId,
        syllabusUnitId: _syllabusUnitId,
      );
    }
    return QuestionSyllabusAttribution(
      courseId: _courseId!,
      paperId: _paper.text.trim(),
      majorStudyAreaId: _majorStudyAreaId,
      contentTopicId: _contentTopicId,
      partId: _partId,
      topicId: _canonicalTopicId,
      lessonId: _lessonId,
    );
  }

  SyllabusPaper? get _selectedPaper {
    return SyllabusService.instance.getPaper(
      courseId: _courseId ?? '',
      paperId: _paper.text.trim(),
    );
  }

  List<SyllabusUnit> get _groupIiiUnits {
    final paper = _selectedPaper;
    if (paper == null) return const [];
    if (paper.hasDirectSyllabusUnits) return paper.syllabusUnits;
    if (_partId == null) return const [];
    for (final part in paper.parts) {
      if (part.id == _partId) return part.syllabusUnits;
    }
    return const [];
  }

  void _clearSyllabusSelection({required bool resetPaperDefault}) {
    _paper.clear();
    _majorStudyAreaId = null;
    _contentTopicId = null;
    _partId = null;
    _canonicalTopicId = null;
    _lessonId = null;
    _syllabusUnitId = null;
    if (resetPaperDefault && (_courseId == null || _courseId == 'group-ii')) {
      _paper.text = 'group-ii-paper-i';
    }
  }

  Widget _canonicalFields(BuildContext context) {
    if (_isGroupIii) return _groupIiiCanonicalFields(context);
    return _groupIiCanonicalFields(context);
  }

  Widget _groupIiiCanonicalFields(BuildContext context) {
    final paper = _selectedPaper;
    final needsPart = paper?.hasPartSyllabusUnits == true;
    final units = _groupIiiUnits;
    return Column(
      key: const ValueKey('group-iii-question-syllabus'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _canonicalDropdown(
          label: 'Paper *',
          value: _paper.text.isEmpty ? null : _paper.text,
          items: [
            for (final item
                in SyllabusService.instance
                        .getCourseById('group-iii')
                        ?.papers ??
                    const <SyllabusPaper>[])
              DropdownMenuItem(value: item.id, child: Text(item.title)),
          ],
          validator: (value) => _required(value, 'Paper'),
          onChanged: (value) => _onUserEdit(() {
            setState(() {
              _paper.text = value ?? '';
              _partId = null;
              _syllabusUnitId = null;
            });
          }),
        ),
        if (needsPart)
          _canonicalDropdown(
            label: 'Part *',
            value: _partId,
            items: [
              for (final item in paper!.parts)
                DropdownMenuItem(value: item.id, child: Text(item.displayName)),
            ],
            validator: (value) => _required(value, 'Part'),
            onChanged: (value) => _onUserEdit(() {
              setState(() {
                _partId = value;
                _syllabusUnitId = null;
              });
            }),
          ),
        _canonicalDropdown(
          label: 'Syllabus Unit *',
          value: _syllabusUnitId,
          items: [
            for (final unit in units)
              DropdownMenuItem(value: unit.id, child: Text(unit.displayName)),
          ],
          validator: (value) => _required(value, 'Syllabus Unit'),
          onChanged: units.isEmpty
              ? null
              : (value) => _onUserEdit(
                  () => setState(() => _syllabusUnitId = value),
                ),
        ),
      ],
    );
  }

  Widget _groupIiCanonicalFields(BuildContext context) {
    final paper = _selectedPaper;
    final paperI = paper?.majorStudyAreas.isNotEmpty == true;
    return Column(
      key: const ValueKey('group-ii-question-syllabus'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _canonicalDropdown(
          label: 'Paper *',
          value: _paper.text.isEmpty ? null : _paper.text,
          items: [
            for (final item
                in SyllabusService.instance
                        .getCourseById(_courseId ?? '')
                        ?.papers ??
                    const <SyllabusPaper>[])
              DropdownMenuItem(value: item.id, child: Text(item.title)),
          ],
          validator: (value) => _required(value, 'Paper'),
          onChanged: (value) => _onUserEdit(() {
            setState(() {
              _paper.text = value ?? '';
              _majorStudyAreaId = null;
              _contentTopicId = null;
              _partId = null;
              _canonicalTopicId = null;
              _lessonId = null;
            });
          }),
        ),
        if (paperI) ...[
          _canonicalDropdown(
            label: 'Major Study Area *',
            value: _majorStudyAreaId,
            items: [
              for (final item in paper!.majorStudyAreas)
                DropdownMenuItem(value: item.id, child: Text(item.displayName)),
            ],
            validator: (value) => _required(value, 'Major Study Area'),
            onChanged: (value) => _onUserEdit(() {
              setState(() {
                _majorStudyAreaId = value;
                _contentTopicId = null;
              });
            }),
          ),
          _canonicalDropdown(
            label: 'Content Topic *',
            value: _contentTopicId,
            items: [
              for (final area in paper.majorStudyAreas)
                if (area.id == _majorStudyAreaId)
                  for (final item in area.contentTopics)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(item.displayName),
                    ),
            ],
            validator: (value) => _required(value, 'Content Topic'),
            onChanged: (value) =>
                _onUserEdit(() => setState(() => _contentTopicId = value)),
          ),
        ] else if (paper != null) ...[
          _canonicalDropdown(
            label: 'Part *',
            value: _partId,
            items: [
              for (final item in paper.parts)
                DropdownMenuItem(value: item.id, child: Text(item.displayName)),
            ],
            validator: (value) => _required(value, 'Part'),
            onChanged: (value) => _onUserEdit(() {
              setState(() {
                _partId = value;
                _canonicalTopicId = null;
                _lessonId = null;
              });
            }),
          ),
          _canonicalDropdown(
            label: 'Topic *',
            value: _canonicalTopicId,
            items: [
              for (final part in paper.parts)
                if (part.id == _partId)
                  for (final item in part.topics)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(item.resolvedDisplayName),
                    ),
            ],
            validator: (value) => _required(value, 'Topic'),
            onChanged: (value) =>
                _onUserEdit(() => setState(() => _canonicalTopicId = value)),
          ),
          _canonicalDropdown(
            label: 'Lesson',
            value: _lessonId,
            items: [
              for (final part in paper.parts)
                if (part.id == _partId)
                  for (final topic in part.topics)
                    if (topic.id == _canonicalTopicId)
                      for (final item in topic.lessons)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text(item.displayName),
                        ),
            ],
            onChanged: (value) =>
                _onUserEdit(() => setState(() => _lessonId = value)),
          ),
        ],
      ],
    );
  }

  Widget _canonicalDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
    String? Function(String?)? validator,
  }) {
    final validValue = items.any((item) => item.value == value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey('question-syllabus-$label'),
        initialValue: validValue,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: [
          for (final item in items)
            DropdownMenuItem<String>(
              value: item.value,
              enabled: item.enabled,
              child: item.child is Text
                  ? Text(
                      (item.child as Text).data ?? '',
                      overflow: TextOverflow.ellipsis,
                    )
                  : item.child,
            ),
        ],
        validator: validator,
        onChanged: _saving ? null : onChanged,
      ),
    );
  }

  void _addOption() {
    if (_options.length >= 5) return;
    final en = TextEditingController();
    final te = TextEditingController();
    if (_trackDirty) {
      _watchController(en);
      _watchController(te);
    }
    _onUserEdit(() {
      setState(() {
        _options.add(en);
        _teluguOptions.add(te);
      });
    });
  }

  void _removeOption(int index) {
    if (_options.length <= 2) return;
    final removed = _options.removeAt(index);
    final removedTelugu = _teluguOptions.removeAt(index);
    removed.dispose();
    removedTelugu.dispose();
    final labels = ['A', 'B', 'C', 'D', 'E'];
    if (labels.indexOf(_correctOption) >= _options.length) {
      _correctOption = labels[_options.length - 1];
    }
    _onUserEdit(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final editing = _initial != null;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _editorHeader(context, editing: editing),
        const SizedBox(height: AdminSpacing.lg),
        AdminFormSection(
          key: const ValueKey('section-classification'),
          title: 'Classification & Syllabus',
          subtitle:
              'Place this question in the locked course hierarchy. Child '
              'fields update from the selections above.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: const ValueKey('question-course'),
                initialValue: _courseId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Course *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final course in widget.courses)
                    DropdownMenuItem(
                      value: course.courseId,
                      child: Text(
                        '${course.title} (${course.courseId})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                validator: (value) => value == null || value.isEmpty
                    ? 'Course is required.'
                    : null,
                onChanged: _saving
                    ? null
                    : (value) => _onUserEdit(() {
                        setState(() {
                          _courseId = value;
                          if (_canonicalMode) {
                            _clearSyllabusSelection(resetPaperDefault: true);
                          }
                        });
                      }),
              ),
              if (_canonicalMode) _canonicalFields(context),
              if (!_canonicalMode) ...[
                _field(_paper, 'Paper ID'),
                _field(_section, 'Section ID'),
                _field(_topic, 'Topic ID'),
              ],
            ],
          ),
        ),
        AdminFormSection(
          key: const ValueKey('section-content'),
          title: 'Question Content',
          subtitle: _canonicalMode
              ? 'Author the bilingual stem students will see in practice.'
              : 'Legacy question text for this record.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_canonicalMode)
                _field(
                  _question,
                  'English question *',
                  maxLines: 4,
                  validator: (v) => _required(v, 'English question'),
                )
              else
                _field(
                  _question,
                  'Question *',
                  maxLines: 4,
                  validator: (v) => _required(v, 'Question text'),
                ),
              if (_canonicalMode)
                _field(
                  _teluguQuestion,
                  'Telugu question *',
                  maxLines: 4,
                  validator: (v) => _required(v, 'Telugu question'),
                ),
              if (_isStatementFormat) ..._statementEditors(context),
            ],
          ),
        ),
        AdminFormSection(
          key: const ValueKey('section-answer'),
          title: 'Answer Configuration',
          subtitle:
              'Configure format, options, and the single correct choice.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_canonicalMode) _formatSelector(),
              const SizedBox(height: AdminSpacing.sm),
              Text(
                'Options *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (var i = 0; i < _options.length; i++) _optionRow(i),
              if (!_isStatementFormat)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _saving || _options.length >= 5
                        ? null
                        : _addOption,
                    icon: const Icon(Icons.add),
                    label: const Text('Add option'),
                  ),
                ),
              const SizedBox(height: AdminSpacing.sm),
              DropdownButtonFormField<String>(
                key: const ValueKey('correct-option'),
                initialValue: _correctOption,
                decoration: const InputDecoration(
                  labelText: 'Correct option *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var i = 0; i < _options.length; i++)
                    DropdownMenuItem(
                      value: String.fromCharCode(65 + i),
                      child: Text(String.fromCharCode(65 + i)),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => _onUserEdit(
                        () => setState(() => _correctOption = value!),
                      ),
              ),
              const SizedBox(height: AdminSpacing.md),
              _enumField<QuestionType>(
                key: const ValueKey('question-type'),
                label: 'Question type',
                value: _questionType,
                values: QuestionType.values,
                onChanged: (value) => setState(() => _questionType = value!),
              ),
            ],
          ),
        ),
        AdminFormSection(
          key: const ValueKey('section-explanation'),
          title: 'Explanation & Learning Content',
          subtitle:
              'Supporting content shown after answering. Hint and AI '
              'explanation remain optional.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(
                _explanation,
                _canonicalMode ? 'English explanation *' : 'Explanation',
                maxLines: 3,
                validator: _canonicalMode
                    ? (v) => _required(v, 'English explanation')
                    : null,
              ),
              if (_canonicalMode)
                _field(
                  _teluguExplanation,
                  'Telugu explanation *',
                  maxLines: 3,
                  validator: (v) => _required(v, 'Telugu explanation'),
                ),
              _field(_hint, 'Hint', maxLines: 2),
              _field(_aiExplanation, 'AI explanation', maxLines: 3),
            ],
          ),
        ),
        AdminFormSection(
          key: const ValueKey('section-metadata'),
          title: 'Exam & Question Metadata',
          subtitle: 'Scoring, timing, and catalog metadata for this item.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 640;
                  final difficulty = _enumField<QuestionDifficulty>(
                    key: const ValueKey('question-difficulty'),
                    label: 'Difficulty',
                    value: _difficulty,
                    values: QuestionDifficulty.values,
                    onChanged: (value) =>
                        setState(() => _difficulty = value!),
                  );
                  final language = _field(
                    _language,
                    'Language *',
                    validator: (v) => _required(v, 'Language'),
                  );
                  final marks = _field(
                    _marks,
                    'Marks *',
                    validator: (v) => _positiveNumber(v, 'Marks'),
                  );
                  final negative = _field(
                    _negativeMarks,
                    'Negative marks',
                    validator: (v) => _positiveNumber(
                      v,
                      'Negative marks',
                      allowZero: true,
                    ),
                  );
                  final seconds = _field(
                    _estimatedSeconds,
                    'Estimated seconds *',
                    validator: (v) {
                      final parsed = int.tryParse(v?.trim() ?? '');
                      return parsed == null || parsed <= 0
                          ? 'Use a positive whole number.'
                          : null;
                    },
                  );
                  final year = _field(
                    _year,
                    'Year',
                    keyboardType: TextInputType.number,
                  );
                  if (!wide) {
                    return Column(
                      children: [
                        difficulty,
                        language,
                        marks,
                        negative,
                        seconds,
                        year,
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: difficulty),
                          const SizedBox(width: AdminSpacing.md),
                          Expanded(child: language),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: marks),
                          const SizedBox(width: AdminSpacing.md),
                          Expanded(child: negative),
                          const SizedBox(width: AdminSpacing.md),
                          Expanded(child: seconds),
                          const SizedBox(width: AdminSpacing.md),
                          Expanded(child: year),
                        ],
                      ),
                    ],
                  );
                },
              ),
              _field(_examName, 'Exam name'),
              _field(_tags, 'Tags (comma separated)'),
            ],
          ),
        ),
        if (_canonicalMode)
          AdminFormSection(
            key: const ValueKey('section-publication'),
            title: 'Publication',
            subtitle: _publicationHelp(_status),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _enumField<QuestionPublicationStatus>(
                  key: const ValueKey('question-status'),
                  label: 'Status',
                  value: _status,
                  values: QuestionPublicationStatus.values,
                  onChanged: (value) => setState(
                    () =>
                        _status = value ?? QuestionPublicationStatus.draft,
                  ),
                ),
                const SizedBox(height: AdminSpacing.md),
                Wrap(
                  spacing: AdminSpacing.sm,
                  runSpacing: AdminSpacing.sm,
                  children: [
                    for (final status in QuestionPublicationStatus.values)
                      FilterChip(
                        selected: _status == status,
                        label: Text(AdminStatusBadge.labelFor(status)),
                        onSelected: _saving
                            ? null
                            : (selected) {
                                if (!selected || _status == status) return;
                                _markDirty();
                                setState(() => _status = status);
                              },
                      ),
                  ],
                ),
              ],
            ),
          ),
        if (_canonicalMode) _preview(context),
        if (_initial != null && !_canonicalMode)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            value: _isActive,
            onChanged: _saving
                ? null
                : (value) => _onUserEdit(
                    () => setState(() => _isActive = value),
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
                editing ? 'Edit Question' : 'Create Question',
                key: ValueKey(
                  editing ? 'question-form-edit-title' : 'question-form-create-title',
                ),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AdminSpacing.xs),
              Text(
                editing
                    ? 'Update content, classification, and publication status.'
                    : 'Author a new exam question for the Admin question bank.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (_canonicalMode)
          AdminStatusBadge.question(
            _status,
            key: const ValueKey('question-form-status-badge'),
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
                key: const ValueKey('submit-question'),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(editing ? 'Save changes' : 'Create question'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _publicationHelp(QuestionPublicationStatus status) {
    switch (status) {
      case QuestionPublicationStatus.draft:
        return 'Draft — not visible to students.';
      case QuestionPublicationStatus.published:
        return 'Published — available according to existing student visibility rules.';
      case QuestionPublicationStatus.archived:
        return 'Archived — removed from active student content without permanent deletion.';
    }
  }

  Widget _formatSelector() {
    return DropdownButtonFormField<QuestionItemFormat>(
      key: const ValueKey('question-format'),
      initialValue: _itemFormat,
      decoration: const InputDecoration(
        labelText: 'Question format *',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: QuestionItemFormat.standardMcq,
          child: Text('Standard MCQ'),
        ),
        DropdownMenuItem(
          value: QuestionItemFormat.statementMcq,
          child: Text('Statement Based'),
        ),
      ],
      onChanged: _saving ? null : _onItemFormatChanged,
    );
  }

  List<Widget> _statementEditors(BuildContext context) {
    return [
      const SizedBox(height: AdminSpacing.md),
      Text(
        'Statements *',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      for (var i = 0; i < _statements.length; i++) _statementRow(context, i),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const ValueKey('add-statement'),
          onPressed: _saving ? null : _addStatement,
          icon: const Icon(Icons.add),
          label: const Text('Add Statement'),
        ),
      ),
    ];
  }

  Widget _statementRow(BuildContext context, int index) {
    final number = index + 1;
    return Padding(
      key: ValueKey('statement-row-$number'),
      padding: const EdgeInsets.only(top: AdminSpacing.md),
      child: AdminSurface(
        padding: const EdgeInsets.fromLTRB(
          AdminSpacing.md,
          AdminSpacing.sm,
          AdminSpacing.md,
          AdminSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Statement $number',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (_statements.length > 1)
                  TextButton(
                    key: ValueKey('remove-statement-$number'),
                    onPressed: _saving ? null : () => _removeStatement(index),
                    child: const Text('Remove'),
                  ),
              ],
            ),
            _field(
              _statements[index].english,
              'English',
              key: ValueKey('statement-en-$number'),
              maxLines: 3,
              validator: (v) => _required(v, 'Statement $number English'),
            ),
            _field(
              _statements[index].telugu,
              'Telugu',
              key: ValueKey('statement-te-$number'),
              maxLines: 3,
              validator: (v) => _required(v, 'Statement $number Telugu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionRow(int index) {
    final letter = String.fromCharCode(65 + index);
    final selected = _correctOption == letter;
    return Padding(
      padding: const EdgeInsets.only(top: AdminSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? AdminColors.successSoft.withValues(alpha: 0.55)
              : AdminColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AdminColors.success.withValues(alpha: 0.35)
                : AdminColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AdminSpacing.md,
            AdminSpacing.sm,
            AdminSpacing.sm,
            AdminSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: InkWell(
                  onTap: _saving
                      ? null
                      : () => _onUserEdit(
                          () => setState(() => _correctOption = letter),
                        ),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AdminColors.success
                          : AdminColors.surfaceElevated,
                      border: Border.all(
                        color: selected
                            ? AdminColors.success
                            : AdminColors.border,
                      ),
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : AdminColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AdminSpacing.md),
              Expanded(
                child: _field(
                  _options[index],
                  'Option $letter',
                  key: ValueKey('option-en-$letter'),
                  validator: (v) => _required(v, 'Option $letter'),
                ),
              ),
              if (_canonicalMode && !_isStatementFormat) ...[
                const SizedBox(width: AdminSpacing.md),
                Expanded(
                  child: _field(
                    _teluguOptions[index],
                    'Telugu $letter',
                    key: ValueKey('option-te-$letter'),
                    validator: (v) => _required(v, 'Telugu option $letter'),
                  ),
                ),
              ],
              if (!_isStatementFormat && _options.length > 2)
                IconButton(
                  tooltip: 'Remove option',
                  onPressed: _saving ? null : () => _removeOption(index),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    Key? key,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AdminSpacing.md),
      child: TextFormField(
        key: key,
        controller: controller,
        enabled: !_saving,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: _canonicalMode ? (_) => setState(() {}) : null,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  Widget _enumField<T extends Enum>({
    Key? key,
    required String label,
    required T value,
    required List<T> values,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AdminSpacing.md),
      child: DropdownButtonFormField<T>(
        key: key,
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final item in values)
            DropdownMenuItem(value: item, child: Text(item.name)),
        ],
        onChanged: _saving
            ? null
            : (next) {
                _markDirty();
                onChanged(next);
              },
      ),
    );
  }

  Widget _preview(BuildContext context) {
    const letters = ['A', 'B', 'C', 'D'];
    return AdminFormSection(
      key: const ValueKey('admin-question-preview'),
      title: 'Student preview',
      subtitle: 'Live preview of bilingual content as currently entered.',
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _question.text.trim().isEmpty
                ? 'English question'
                : _question.text,
          ),
          Text(
            _teluguQuestion.text.trim().isEmpty
                ? 'Telugu question'
                : _teluguQuestion.text,
          ),
          if (_isStatementFormat) ...[
            const SizedBox(height: AdminSpacing.sm),
            for (var i = 0; i < _statements.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${i + 1}. ${_statements[i].english.text}\n'
                  '   ${_statements[i].telugu.text}',
                ),
              ),
          ],
          const SizedBox(height: AdminSpacing.sm),
          for (var i = 0; i < _options.length && i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _isStatementFormat
                    ? '${letters[i]}. ${_options[i].text}'
                    : '${letters[i]}. ${_options[i].text}\n'
                          '   ${_teluguOptions[i].text}',
              ),
            ),
          Text('Correct answer: $_correctOption'),
          Text('English explanation: ${_explanation.text}'),
          Text('Telugu explanation: ${_teluguExplanation.text}'),
        ],
      ),
    );
  }
}

class _StatementControllers {
  _StatementControllers({String english = '', String telugu = ''})
    : english = TextEditingController(text: english),
      telugu = TextEditingController(text: telugu);

  final TextEditingController english;
  final TextEditingController telugu;

  void dispose() {
    english.dispose();
    telugu.dispose();
  }
}
