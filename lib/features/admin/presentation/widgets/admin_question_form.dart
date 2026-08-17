import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';

typedef AdminQuestionSubmit = Future<void> Function(Question question);

/// Create/edit form for the canonical Question entity.
class AdminQuestionForm extends StatefulWidget {
  const AdminQuestionForm({
    super.key,
    required this.courses,
    required this.onSubmit,
    this.initialQuestion,
    this.onCancel,
  });

  final List<Course> courses;
  final AdminQuestionSubmit onSubmit;
  final Question? initialQuestion;
  final VoidCallback? onCancel;

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

  String? _courseId;
  String _correctOption = 'A';
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

  Question? get _initial => widget.initialQuestion;
  bool get _isGroupIii => _courseId == 'group-iii';

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
    super.dispose();
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
      content: _canonicalMode
          ? QuestionContent(
              en: QuestionLocalizedContent(
                question: _question.text.trim(),
                options: [
                  for (final option in _options)
                    QuestionOption(text: option.text.trim()),
                ],
                explanation: _explanation.text.trim(),
              ),
              te: QuestionLocalizedContent(
                question: _teluguQuestion.text.trim(),
                options: [
                  for (final option in _teluguOptions)
                    QuestionOption(text: option.text.trim()),
                ],
                explanation: _teluguExplanation.text.trim(),
              ),
            )
          : null,
      syllabus: _canonicalMode ? _canonicalAttribution() : null,
      status: _canonicalMode ? _status : _initial?.status,
    );

    setState(() {
      _saving = true;
      _submitError = null;
    });
    try {
      await widget.onSubmit(question);
      if (mounted) Navigator.of(context).pop(true);
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
        Text(
          'Group-III syllabus location',
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
          onChanged: (value) => setState(() {
            _paper.text = value ?? '';
            _partId = null;
            _syllabusUnitId = null;
          }),
        ),
        if (needsPart)
          _canonicalDropdown(
            label: 'Part *',
            value: _partId,
            items: [
              for (final item in paper!.parts)
                DropdownMenuItem(
                  value: item.id,
                  child: Text(item.displayName),
                ),
            ],
            validator: (value) => _required(value, 'Part'),
            onChanged: (value) => setState(() {
              _partId = value;
              _syllabusUnitId = null;
            }),
          ),
        _canonicalDropdown(
          label: 'Syllabus Unit *',
          value: _syllabusUnitId,
          items: [
            for (final unit in units)
              DropdownMenuItem(
                value: unit.id,
                child: Text(unit.displayName),
              ),
          ],
          validator: (value) => _required(value, 'Syllabus Unit'),
          onChanged: units.isEmpty
              ? null
              : (value) => setState(() => _syllabusUnitId = value),
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
        Text(
          'Canonical syllabus attribution',
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
          onChanged: (value) => setState(() {
            _paper.text = value ?? '';
            _majorStudyAreaId = null;
            _contentTopicId = null;
            _partId = null;
            _canonicalTopicId = null;
            _lessonId = null;
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
            onChanged: (value) => setState(() {
              _majorStudyAreaId = value;
              _contentTopicId = null;
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
            onChanged: (value) => setState(() => _contentTopicId = value),
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
            onChanged: (value) => setState(() {
              _partId = value;
              _canonicalTopicId = null;
              _lessonId = null;
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
            onChanged: (value) => setState(() => _canonicalTopicId = value),
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
            onChanged: (value) => setState(() => _lessonId = value),
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
        initialValue: validValue,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
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
    setState(() {
      _options.add(TextEditingController());
      _teluguOptions.add(TextEditingController());
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const ValueKey('submit-question'),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_initial == null ? 'Create question' : 'Save changes'),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _courseId,
            decoration: const InputDecoration(labelText: 'Course *'),
            items: [
              for (final course in widget.courses)
                DropdownMenuItem(
                  value: course.courseId,
                  child: Text('${course.title} (${course.courseId})'),
                ),
            ],
            validator: (value) =>
                value == null || value.isEmpty ? 'Course is required.' : null,
            onChanged: _saving
                ? null
                : (value) => setState(() {
                      _courseId = value;
                      if (_canonicalMode) {
                        _clearSyllabusSelection(resetPaperDefault: true);
                      }
                    }),
          ),
          if (_canonicalMode) _canonicalFields(context),
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
          if (!_canonicalMode) ...[
            _field(_paper, 'Paper ID'),
            _field(_section, 'Section ID'),
            _field(_topic, 'Topic ID'),
          ],
          const SizedBox(height: 8),
          Text('Options *', style: Theme.of(context).textTheme.titleMedium),
          for (var i = 0; i < _options.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    _options[i],
                    'Option ${String.fromCharCode(65 + i)}',
                    validator: (v) =>
                        _required(v, 'Option ${String.fromCharCode(65 + i)}'),
                  ),
                ),
                if (_canonicalMode) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _teluguOptions[i],
                      'Telugu ${String.fromCharCode(65 + i)}',
                      validator: (v) => _required(
                        v,
                        'Telugu option ${String.fromCharCode(65 + i)}',
                      ),
                    ),
                  ),
                ],
                if (_options.length > 2)
                  IconButton(
                    tooltip: 'Remove option',
                    onPressed: _saving ? null : () => _removeOption(i),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
              ],
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _saving || _options.length >= 5 ? null : _addOption,
              icon: const Icon(Icons.add),
              label: const Text('Add option'),
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: _correctOption,
            decoration: const InputDecoration(labelText: 'Correct option *'),
            items: [
              for (var i = 0; i < _options.length; i++)
                DropdownMenuItem(
                  value: String.fromCharCode(65 + i),
                  child: Text(String.fromCharCode(65 + i)),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _correctOption = value!),
          ),
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
          Row(
            children: [
              Expanded(
                child: _enumField<QuestionDifficulty>(
                  label: 'Difficulty',
                  value: _difficulty,
                  values: QuestionDifficulty.values,
                  onChanged: (value) => setState(() => _difficulty = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _enumField<QuestionType>(
                  label: 'Question type',
                  value: _questionType,
                  values: QuestionType.values,
                  onChanged: (value) => setState(() => _questionType = value!),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  _language,
                  'Language *',
                  validator: (v) => _required(v, 'Language'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _marks,
                  'Marks *',
                  validator: (v) => _positiveNumber(v, 'Marks'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _negativeMarks,
                  'Negative marks',
                  validator: (v) =>
                      _positiveNumber(v, 'Negative marks', allowZero: true),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  _estimatedSeconds,
                  'Estimated seconds *',
                  validator: (v) {
                    final parsed = int.tryParse(v?.trim() ?? '');
                    return parsed == null || parsed <= 0
                        ? 'Use a positive whole number.'
                        : null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _year,
                  'Year',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          _field(_examName, 'Exam name'),
          _field(_tags, 'Tags (comma separated)'),
          if (_canonicalMode)
            _enumField<QuestionPublicationStatus>(
              label: 'Status',
              value: _status,
              values: QuestionPublicationStatus.values,
              onChanged: (value) => setState(
                () => _status = value ?? QuestionPublicationStatus.draft,
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
                  : (value) => setState(() => _isActive = value),
            ),
          if (_submitError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _submitError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving
                    ? null
                    : widget.onCancel ?? () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _initial == null ? 'Create question' : 'Save changes',
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: _canonicalMode ? (_) => setState(() {}) : null,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _enumField<T extends Enum>({
    required String label,
    required T value,
    required List<T> values,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in values)
          DropdownMenuItem(value: item, child: Text(item.name)),
      ],
      onChanged: _saving ? null : onChanged,
    );
  }

  Widget _preview(BuildContext context) {
    const letters = ['A', 'B', 'C', 'D'];
    return Card(
      key: const ValueKey('admin-question-preview'),
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            for (var i = 0; i < _options.length && i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${letters[i]}. ${_options[i].text}\n'
                  '   ${_teluguOptions[i].text}',
                ),
              ),
            Text('Correct answer: $_correctOption'),
            Text('English explanation: ${_explanation.text}'),
            Text('Telugu explanation: ${_teluguExplanation.text}'),
          ],
        ),
      ),
    );
  }
}
