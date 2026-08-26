import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/question_models.dart';

/// Maps Firestore `questions/{questionId}` documents to [Question].
///
/// Pure functions — no Firebase dependency (unit-testable).
abstract final class QuestionCloudMapper {
  static const _optionLabels = ['A', 'B', 'C', 'D', 'E'];

  /// Returns null when required identity/content fields are missing.
  static Question? fromFirestore(String docId, Map<String, dynamic> data) {
    final rawId = data['id'] as String?;
    final id = (rawId != null && rawId.isNotEmpty) ? rawId : docId;
    if (id.isEmpty) return null;

    final courseId = data['courseId'] as String?;
    if (courseId == null || courseId.isEmpty) return null;

    final content = _readContent(data['content']);
    final questionText = (data['question'] as String?) ?? content?.en.question;
    if (questionText == null || questionText.isEmpty) return null;

    final options = _readStringList(data['options']);
    final resolvedOptions = options.isNotEmpty
        ? options
        : content?.en.options.map((option) => option.text).toList() ?? const [];
    if (resolvedOptions.isEmpty) return null;

    final correctOption = data['correctOption'] as String?;
    if (correctOption == null || correctOption.isEmpty) return null;

    final difficulty = parseDifficulty(data['difficulty'] as String?);
    final questionType = parseQuestionType(data['questionType'] as String?);
    if (difficulty == null || questionType == null) return null;

    final createdAt =
        readTimestamp(data['createdAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt = readTimestamp(data['updatedAt']) ?? createdAt;

    final estimatedSeconds = asInt(data['estimatedTimeSeconds']) ?? 60;

    final paperId = (data['paperId'] as String?) ?? '';
    final sectionId = (data['sectionId'] as String?) ?? '';
    final topicId = (data['topicId'] as String?) ?? '';

    return Question(
      id: id,
      courseId: courseId,
      paperId: paperId,
      sectionId: sectionId,
      topicId: topicId,
      question: questionText,
      options: resolvedOptions,
      correctOption: correctOption,
      explanation:
          (data['explanation'] as String?) ?? content?.en.explanation ?? '',
      difficulty: difficulty,
      questionType: questionType,
      language: (data['language'] as String?) ?? 'en',
      marks: asDouble(data['marks']) ?? 1,
      negativeMarks: asDouble(data['negativeMarks']) ?? 0,
      tags: _readStringList(data['tags']),
      estimatedTime: Duration(seconds: estimatedSeconds),
      year: asInt(data['year']),
      examName: data['examName'] as String?,
      hint: data['hint'] as String?,
      aiExplanation: data['aiExplanation'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: data['isActive'] == true,
      content: content,
      syllabus: _readSyllabus(
        data,
        courseId: courseId,
        paperId: paperId,
        legacySectionId: sectionId,
        legacyTopicId: topicId,
      ),
      status: parsePublicationStatus(data['status'] as String?),
      itemFormat: parseItemFormat(data['itemFormat'] as String?),
    );
  }

  /// Validates a question before an admin write.
  ///
  /// The read mapper intentionally fails soft for legacy documents. Writes
  /// must be strict so malformed content never enters the question bank.
  static List<String> validateForWrite(
    Question question, {
    String? documentId,
  }) {
    final errors = <String>[];
    final id = question.id.trim();
    final expectedId = documentId?.trim();

    if (id.isEmpty && (expectedId == null || expectedId.isEmpty)) {
      errors.add('Question ID is required.');
    }
    if (expectedId != null &&
        expectedId.isNotEmpty &&
        id.isNotEmpty &&
        id != expectedId) {
      errors.add('Question ID must match the Firestore document ID.');
    }
    if (question.courseId.trim().isEmpty) {
      errors.add('Course is required.');
    }
    final questionText = question.question.trim().isNotEmpty
        ? question.question.trim()
        : question.content?.en.question.trim() ?? '';
    final options = question.options.isNotEmpty
        ? question.options
        : question.content?.en.options.map((option) => option.text).toList() ??
              const <String>[];

    if (questionText.isEmpty) {
      errors.add('Question text is required.');
    }
    if (options.length < 2 || options.length > 5) {
      errors.add('Provide between 2 and 5 answer options.');
    }
    if (options.any((option) => option.trim().isEmpty)) {
      errors.add('Answer options cannot be empty.');
    }
    final correctOption = question.correctOption.trim().toUpperCase();
    if (!_optionLabels.contains(correctOption) ||
        _optionLabels.indexOf(correctOption) >= options.length) {
      errors.add('Correct option must match one of the provided options.');
    }
    if (question.language.trim().isEmpty) {
      errors.add('Language is required.');
    }
    if (!_isFiniteNonNegative(question.marks) || question.marks <= 0) {
      errors.add('Marks must be greater than zero.');
    }
    if (!_isFiniteNonNegative(question.negativeMarks)) {
      errors.add('Negative marks must be zero or greater.');
    }
    if (question.estimatedTime.inSeconds <= 0) {
      errors.add('Estimated time must be greater than zero.');
    }
    final content = question.content;
    if (content?.te != null) {
      final teHasOptions = content!.te!.options.any(
        (option) => option.text.trim().isNotEmpty,
      );
      final requireMatchingOptions =
          question.resolvedItemFormat != QuestionItemFormat.statementMcq ||
          teHasOptions;
      if (requireMatchingOptions &&
          content.en.options.length != content.te!.options.length) {
        errors.add('English and Telugu option counts must match.');
      }
    }
    errors.addAll(_validateItemFormat(question));
    return errors;
  }

  /// Maps a canonical question to the existing Firestore schema.
  ///
  /// [documentId] is used by create/update boundaries to make the document
  /// ID authoritative and prevent `data.id` drift.
  ///
  /// When [forUpdate] is true, known optional syllabus fields that are empty
  /// in the current model are written as [FieldValue.delete] so Firestore
  /// `update()` removes stale values. Create continues to omit empty optional
  /// fields instead of emitting delete sentinels.
  static Map<String, dynamic> toFirestore(
    Question question, {
    bool includeCreatedAt = false,
    String? documentId,
    bool forUpdate = false,
  }) {
    final errors = validateForWrite(question, documentId: documentId);
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }

    final id = documentId?.trim().isNotEmpty == true
        ? documentId!.trim()
        : question.id.trim();
    final content = question.content;
    final questionText = question.question.trim().isNotEmpty
        ? question.question.trim()
        : content?.en.question.trim() ?? '';
    final options = question.options.isNotEmpty
        ? question.options
        : content?.en.options.map((option) => option.text).toList() ??
              const <String>[];
    final data = <String, dynamic>{
      'id': id,
      'courseId': question.courseId.trim(),
      'question': questionText,
      'options': [for (final option in options) option.trim()],
      'correctOption': question.correctOption.trim().toUpperCase(),
      'explanation': question.explanation.trim().isNotEmpty
          ? question.explanation.trim()
          : content?.en.explanation.trim() ?? '',
      'difficulty': question.difficulty.name,
      'questionType': _questionTypeFirestoreValue(question.questionType),
      'language': question.language.trim(),
      'marks': question.marks,
      'negativeMarks': question.negativeMarks,
      'tags': [
        for (final tag in question.tags)
          if (tag.trim().isNotEmpty) tag.trim(),
      ],
      'estimatedTimeSeconds': question.estimatedTime.inSeconds,
      'year': question.year,
      'examName': question.examName?.trim(),
      'hint': question.hint?.trim(),
      'aiExplanation': question.aiExplanation?.trim(),
      'isActive': question.isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final itemFormatValue = _itemFormatFirestoreValue(question.itemFormat);
    if (itemFormatValue != null) {
      data['itemFormat'] = itemFormatValue;
    }
    if (forUpdate) {
      _writeOptionalSyllabusField(
        data,
        'paperId',
        _firstNonEmpty(question.syllabus?.paperId, question.paperId),
        clearNested: true,
      );
      _writeOptionalSyllabusField(
        data,
        'sectionId',
        _firstNonEmpty(question.syllabus?.legacySectionId, question.sectionId),
        clearNested: true,
      );
      _writeOptionalSyllabusField(
        data,
        'topicId',
        _firstNonEmpty(question.syllabus?.topicId, question.topicId),
        clearNested: true,
      );
      _writeOptionalSyllabusField(
        data,
        'majorStudyAreaId',
        question.syllabus?.majorStudyAreaId,
        clearNested: true,
      );
      _writeOptionalSyllabusField(
        data,
        'contentTopicId',
        question.syllabus?.contentTopicId,
        clearNested: true,
      );
      _writeOptionalSyllabusField(
        data,
        'partId',
        question.syllabus?.partId,
        clearNested: true,
      );
      _writeOptionalSyllabusField(
        data,
        'lessonId',
        question.syllabus?.lessonId,
        clearNested: true,
      );
      _writeOptionalSyllabusField(
        data,
        'syllabusUnitId',
        question.syllabus?.syllabusUnitId,
        clearNested: true,
      );
    } else {
      data['paperId'] = question.paperId.trim();
      data['sectionId'] = question.sectionId.trim();
      data['topicId'] = question.topicId.trim();
      _addCanonicalAttribution(data, question.syllabus);
    }
    if (question.status != null) {
      data['status'] = question.status!.name;
      data['isActive'] = question.status == QuestionPublicationStatus.published;
    }
    if (content != null) {
      data['content'] = _contentToFirestore(
        content,
        omitEmptyTeluguOptions:
            question.resolvedItemFormat == QuestionItemFormat.statementMcq,
      );
    }
    if (includeCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    return data;
  }

  static Map<String, dynamic> toDeactivateMap({required bool isActive}) {
    return {'isActive': isActive, 'updatedAt': FieldValue.serverTimestamp()};
  }

  static Map<String, dynamic> toStatusMap(QuestionPublicationStatus status) {
    return {
      'status': status.name,
      'isActive': status == QuestionPublicationStatus.published,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static QuestionContent? _readContent(dynamic raw) {
    if (raw is! Map) return null;
    final en = _readLocalizedContent(raw['en']);
    if (en == null) return null;
    return QuestionContent(en: en, te: _readLocalizedContent(raw['te']));
  }

  static QuestionLocalizedContent? _readLocalizedContent(dynamic raw) {
    if (raw is! Map) return null;
    final question = raw['question'] as String?;
    if (question == null) return null;
    return QuestionLocalizedContent(
      question: question,
      options: [
        for (final option in _readStringList(raw['options']))
          QuestionOption(text: option),
      ],
      explanation: raw['explanation'] as String? ?? '',
      statements: _readStatements(raw['statements']),
    );
  }

  static QuestionSyllabusAttribution _readSyllabus(
    Map<String, dynamic> data, {
    required String courseId,
    required String paperId,
    required String legacySectionId,
    required String legacyTopicId,
  }) {
    final nested = data['syllabus'] is Map
        ? Map<String, dynamic>.from(data['syllabus'] as Map)
        : const <String, dynamic>{};
    String? read(String key) {
      final value = nested[key] ?? data[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    final majorStudyAreaId = read('majorStudyAreaId');
    final contentTopicId = read('contentTopicId');
    final partId = read('partId');
    final lessonId = read('lessonId');
    final syllabusUnitId = read('syllabusUnitId');
    final hasCanonicalAttribution =
        majorStudyAreaId != null ||
        contentTopicId != null ||
        partId != null ||
        lessonId != null ||
        syllabusUnitId != null;

    return QuestionSyllabusAttribution(
      courseId: courseId,
      paperId: paperId,
      majorStudyAreaId: majorStudyAreaId,
      contentTopicId: contentTopicId,
      partId: partId,
      topicId: hasCanonicalAttribution ? read('topicId') : null,
      lessonId: lessonId,
      syllabusUnitId: syllabusUnitId,
      legacySectionId: hasCanonicalAttribution ? null : legacySectionId,
      legacyTopicId: hasCanonicalAttribution ? null : legacyTopicId,
    );
  }

  static Map<String, dynamic> _contentToFirestore(
    QuestionContent content, {
    bool omitEmptyTeluguOptions = false,
  }) {
    Map<String, dynamic> localized(
      QuestionLocalizedContent value, {
      bool omitEmptyOptions = false,
    }) {
      final statements = [
        for (final statement in value.statements)
          if (statement.trim().isNotEmpty) statement.trim(),
      ];
      final options = [
        for (final option in value.options) option.text.trim(),
      ];
      final hasOptionText = options.any((option) => option.isNotEmpty);
      return {
        'question': value.question.trim(),
        if (!(omitEmptyOptions && !hasOptionText)) 'options': options,
        'explanation': value.explanation.trim(),
        if (statements.isNotEmpty) 'statements': statements,
      };
    }

    return {
      'en': localized(content.en),
      if (content.te != null)
        'te': localized(
          content.te!,
          omitEmptyOptions: omitEmptyTeluguOptions,
        ),
    };
  }

  static void _addCanonicalAttribution(
    Map<String, dynamic> data,
    QuestionSyllabusAttribution? syllabus,
  ) {
    if (syllabus == null) return;
    void add(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        data[key] = value.trim();
      }
    }

    add('majorStudyAreaId', syllabus.majorStudyAreaId);
    add('contentTopicId', syllabus.contentTopicId);
    add('partId', syllabus.partId);
    add('topicId', syllabus.topicId);
    add('lessonId', syllabus.lessonId);
    add('syllabusUnitId', syllabus.syllabusUnitId);
  }

  static void _writeOptionalSyllabusField(
    Map<String, dynamic> data,
    String key,
    String? value, {
    bool clearNested = false,
  }) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      data[key] = trimmed;
    } else {
      data[key] = FieldValue.delete();
    }
    if (clearNested) {
      data['syllabus.$key'] = FieldValue.delete();
    }
  }

  static String? _firstNonEmpty(String? primary, String? fallback) {
    final first = primary?.trim();
    if (first != null && first.isNotEmpty) return first;
    final second = fallback?.trim();
    if (second != null && second.isNotEmpty) return second;
    return null;
  }

  static bool _isFiniteNonNegative(double value) {
    return value.isFinite && value >= 0;
  }

  static String _questionTypeFirestoreValue(QuestionType type) {
    switch (type) {
      case QuestionType.practice:
        return 'practice';
      case QuestionType.previousYear:
        return 'previousYear';
      case QuestionType.mock:
        return 'mock';
    }
  }

  static QuestionDifficulty? parseDifficulty(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'easy':
        return QuestionDifficulty.easy;
      case 'medium':
        return QuestionDifficulty.medium;
      case 'hard':
        return QuestionDifficulty.hard;
      default:
        return null;
    }
  }

  static List<String> _validateItemFormat(Question question) {
    final errors = <String>[];
    final format = question.resolvedItemFormat;
    final content = question.content;
    final enStatements = content?.en.statements ?? const <String>[];
    final teStatements = content?.te?.statements;

    if (format == QuestionItemFormat.statementMcq) {
      if (enStatements.isEmpty) {
        errors.add('Statement-based questions require at least one statement.');
      }
      if (enStatements.any((statement) => statement.trim().isEmpty)) {
        errors.add('Statements cannot be empty.');
      }
      if (teStatements != null) {
        if (teStatements.length != enStatements.length) {
          errors.add('English and Telugu statement counts must match.');
        }
        if (teStatements.any((statement) => statement.trim().isEmpty)) {
          errors.add('Telugu statements cannot be empty.');
        }
      }
    } else if (enStatements.isNotEmpty ||
        (teStatements != null && teStatements.isNotEmpty)) {
      if (teStatements != null &&
          teStatements.length != enStatements.length) {
        errors.add('English and Telugu statement counts must match.');
      }
    }
    return errors;
  }

  static String? _itemFormatFirestoreValue(QuestionItemFormat? format) {
    switch (format) {
      case QuestionItemFormat.standardMcq:
        return 'standard_mcq';
      case QuestionItemFormat.statementMcq:
        return 'statement_mcq';
      case null:
        return null;
    }
  }

  static QuestionItemFormat? parseItemFormat(String? raw) {
    switch (raw?.trim()) {
      case 'standard_mcq':
        return QuestionItemFormat.standardMcq;
      case 'statement_mcq':
        return QuestionItemFormat.statementMcq;
      default:
        return null;
    }
  }

  static List<String> _readStatements(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item != null && item.toString().trim().isNotEmpty)
          item.toString().trim(),
    ];
  }

  static QuestionType? parseQuestionType(String? raw) {
    switch (raw?.trim()) {
      case 'practice':
        return QuestionType.practice;
      case 'previousYear':
      case 'previous_year':
      case 'previous-year':
        return QuestionType.previousYear;
      case 'mock':
        return QuestionType.mock;
      default:
        return null;
    }
  }

  static QuestionPublicationStatus? parsePublicationStatus(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'draft':
        return QuestionPublicationStatus.draft;
      case 'published':
        return QuestionPublicationStatus.published;
      case 'archived':
        return QuestionPublicationStatus.archived;
      default:
        return null;
    }
  }

  static int? asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return [for (final item in value) item.toString()];
  }
}
