import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../question_bank/data/models/question_models.dart';

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
  late final TextEditingController _paper;
  late final TextEditingController _section;
  late final TextEditingController _topic;
  late final TextEditingController _explanation;
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

  String? _courseId;
  String _correctOption = 'A';
  QuestionDifficulty _difficulty = QuestionDifficulty.medium;
  QuestionType _questionType = QuestionType.practice;
  bool _isActive = true;
  bool _saving = false;
  String? _submitError;

  Question? get _initial => widget.initialQuestion;

  @override
  void initState() {
    super.initState();
    final initial = _initial;
    _question = TextEditingController(text: initial?.question ?? '');
    _paper = TextEditingController(text: initial?.paperId ?? '');
    _section = TextEditingController(text: initial?.sectionId ?? '');
    _topic = TextEditingController(text: initial?.topicId ?? '');
    _explanation = TextEditingController(text: initial?.explanation ?? '');
    _hint = TextEditingController(text: initial?.hint ?? '');
    _aiExplanation =
        TextEditingController(text: initial?.aiExplanation ?? '');
    _language = TextEditingController(text: initial?.language ?? 'en');
    _marks = TextEditingController(text: _number(initial?.marks ?? 1));
    _negativeMarks =
        TextEditingController(text: _number(initial?.negativeMarks ?? 0));
    _estimatedSeconds = TextEditingController(
      text: '${initial?.estimatedTime.inSeconds ?? 60}',
    );
    _year = TextEditingController(text: initial?.year?.toString() ?? '');
    _examName = TextEditingController(text: initial?.examName ?? '');
    _tags = TextEditingController(text: initial?.tags.join(', ') ?? '');
    _options = [
      for (final option in initial?.options ?? const ['', '', '', ''])
        TextEditingController(text: option),
    ];
    _courseId = initial?.courseId;
    _correctOption = initial?.correctOption ?? 'A';
    _difficulty = initial?.difficulty ?? QuestionDifficulty.medium;
    _questionType = initial?.questionType ?? QuestionType.practice;
    _isActive = initial?.isActive ?? true;
  }

  @override
  void dispose() {
    _question.dispose();
    _paper.dispose();
    _section.dispose();
    _topic.dispose();
    _explanation.dispose();
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

  String? _positiveNumber(String? value, String label, {bool allowZero = false}) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || !parsed.isFinite || (!allowZero && parsed <= 0) ||
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
      sectionId: _section.text.trim(),
      topicId: _topic.text.trim(),
      question: _question.text.trim(),
      options: [
        for (final option in _options) option.text.trim(),
      ],
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

  void _addOption() {
    if (_options.length >= 5) return;
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_options.length <= 2) return;
    final removed = _options.removeAt(index);
    removed.dispose();
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
            onChanged: _saving ? null : (value) => setState(() => _courseId = value),
          ),
          _field(_question, 'Question *', maxLines: 4, validator: (v) => _required(v, 'Question text')),
          _field(_paper, 'Paper ID'),
          _field(_section, 'Section ID'),
          _field(_topic, 'Topic ID'),
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
                    validator: (v) => _required(v, 'Option ${String.fromCharCode(65 + i)}'),
                  ),
                ),
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
            onChanged: _saving ? null : (value) => setState(() => _correctOption = value!),
          ),
          _field(_explanation, 'Explanation', maxLines: 3),
          _field(_hint, 'Hint', maxLines: 2),
          _field(_aiExplanation, 'AI explanation', maxLines: 3),
          Row(
            children: [
              Expanded(child: _enumField<QuestionDifficulty>(
                label: 'Difficulty',
                value: _difficulty,
                values: QuestionDifficulty.values,
                onChanged: (value) => setState(() => _difficulty = value!),
              )),
              const SizedBox(width: 12),
              Expanded(child: _enumField<QuestionType>(
                label: 'Question type',
                value: _questionType,
                values: QuestionType.values,
                onChanged: (value) => setState(() => _questionType = value!),
              )),
            ],
          ),
          Row(
            children: [
              Expanded(child: _field(_language, 'Language *', validator: (v) => _required(v, 'Language'))),
              const SizedBox(width: 12),
              Expanded(child: _field(_marks, 'Marks *', validator: (v) => _positiveNumber(v, 'Marks'))),
              const SizedBox(width: 12),
              Expanded(child: _field(_negativeMarks, 'Negative marks', validator: (v) => _positiveNumber(v, 'Negative marks', allowZero: true))),
            ],
          ),
          Row(
            children: [
              Expanded(child: _field(_estimatedSeconds, 'Estimated seconds *', validator: (v) {
                final parsed = int.tryParse(v?.trim() ?? '');
                return parsed == null || parsed <= 0 ? 'Use a positive whole number.' : null;
              })),
              const SizedBox(width: 12),
              Expanded(child: _field(_year, 'Year', keyboardType: TextInputType.number)),
            ],
          ),
          _field(_examName, 'Exam name'),
          _field(_tags, 'Tags (comma separated)'),
          if (_initial != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: _saving ? null : (value) => setState(() => _isActive = value),
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
                onPressed: _saving ? null : widget.onCancel ?? () => Navigator.of(context).pop(),
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
                    : Text(_initial == null ? 'Create question' : 'Save changes'),
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
}
