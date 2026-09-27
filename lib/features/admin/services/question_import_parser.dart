import 'dart:convert';

import '../data/models/question_import_models.dart';

/// Parses the single supported bulk-import JSON format.
///
/// Expected shape:
/// ```json
/// {
///   "questions": [
///     {
///       "id": "optional-stable-id",
///       "courseId": "group-ii",
///       "paperId": "group-ii-paper-i",
///       "majorStudyAreaId": "...",
///       "contentTopicId": "...",
///       "question": { "en": "...", "te": "..." },
///       "options": [
///         { "en": "...", "te": "..." },
///         { "en": "...", "te": "..." },
///         { "en": "...", "te": "..." },
///         { "en": "...", "te": "..." }
///       ],
///       "correctOption": "A",
///       "explanation": { "en": "...", "te": "..." }
///     }
///   ]
/// }
/// ```
abstract final class QuestionImportParser {
  static List<QuestionImportRecord> parseJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException(
        'Import JSON must be an object with a "questions" array.',
      );
    }
    final questionsRaw = decoded['questions'];
    if (questionsRaw is! List) {
      throw const FormatException(
        'Import JSON must contain a "questions" array.',
      );
    }
    return [
      for (var i = 0; i < questionsRaw.length; i++)
        _parseRecord(questionsRaw[i], i),
    ];
  }

  static QuestionImportRecord _parseRecord(Object? raw, int index) {
    if (raw is! Map) {
      throw FormatException('Record ${index + 1} must be an object.');
    }
    final map = Map<String, dynamic>.from(raw);
    return QuestionImportRecord(
      id: _optionalString(map['id']),
      courseId: _optionalText(map['courseId'], 'courseId', index),
      paperId: _optionalText(map['paperId'], 'paperId', index),
      majorStudyAreaId: _optionalString(map['majorStudyAreaId']),
      contentTopicId: _optionalString(map['contentTopicId']),
      partId: _optionalString(map['partId']),
      topicId: _optionalString(map['topicId']),
      lessonId: _optionalString(map['lessonId']),
      syllabusUnitId: _optionalString(map['syllabusUnitId']),
      question: _localized(map['question'], 'question', index),
      options: _options(map['options'], index),
      correctOption: _string(map['correctOption'], 'correctOption', index),
      explanation: _localized(map['explanation'], 'explanation', index),
      itemFormat: _optionalString(map['itemFormat']),
      statements: _statements(map['statements'], index),
      testId: _optionalString(map['testId']),
      contentArea: _optionalString(map['contentArea']),
      testSeriesCategory: _optionalString(map['testSeriesCategory']),
      seriesId: _optionalString(map['seriesId']),
      year: _optionalYear(map['year'], index),
    );
  }

  static QuestionImportLocalizedText _localized(
    Object? raw,
    String field,
    int index,
  ) {
    if (raw is! Map) {
      throw FormatException('Record ${index + 1}\n$field\nMust be an object.');
    }
    final map = Map<String, dynamic>.from(raw);
    return QuestionImportLocalizedText(
      en: _string(map['en'], '$field.en', index),
      te: _string(map['te'], '$field.te', index),
    );
  }

  static List<QuestionImportOption> _options(Object? raw, int index) {
    if (raw is! List) {
      throw FormatException('Record ${index + 1}\noptions\nMust be an array.');
    }
    return [for (var i = 0; i < raw.length; i++) _option(raw[i], i, index)];
  }

  static QuestionImportOption _option(Object? raw, int optionIndex, int index) {
    if (raw is! Map) {
      throw FormatException(
        'Record ${index + 1}\noptions[$optionIndex]\nMust be an object.',
      );
    }
    final map = Map<String, dynamic>.from(raw);
    return QuestionImportOption(
      en: _string(map['en'], 'options[$optionIndex].en', index),
      te: _optionalText(map['te'], 'options[$optionIndex].te', index),
    );
  }

  static List<QuestionImportLocalizedText> _statements(Object? raw, int index) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw FormatException(
        'Record ${index + 1}\nstatements\nMust be an array.',
      );
    }
    return [
      for (var i = 0; i < raw.length; i++)
        _localized(raw[i], 'statements[$i]', index),
    ];
  }

  static String _string(Object? raw, String field, int index) {
    if (raw is! String) {
      throw FormatException('Record ${index + 1}\n$field\nMust be a string.');
    }
    return raw;
  }

  static String? _optionalString(Object? raw) {
    if (raw == null) return null;
    if (raw is! String) return null;
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  static String _optionalText(Object? raw, String field, int index) {
    if (raw == null) return '';
    if (raw is! String) {
      throw FormatException('Record ${index + 1}\n$field\nMust be a string.');
    }
    return raw;
  }

  static int? _optionalYear(Object? raw, int index) {
    if (raw == null) return null;
    if (raw is! int) {
      throw FormatException('Record ${index + 1}\nyear\nMust be an integer.');
    }
    return raw;
  }
}
