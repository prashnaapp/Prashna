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

    final questionText = data['question'] as String?;
    if (questionText == null || questionText.isEmpty) return null;

    final options = _readStringList(data['options']);
    if (options.isEmpty) return null;

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

    return Question(
      id: id,
      courseId: courseId,
      paperId: (data['paperId'] as String?) ?? '',
      sectionId: (data['sectionId'] as String?) ?? '',
      topicId: (data['topicId'] as String?) ?? '',
      question: questionText,
      options: options,
      correctOption: correctOption,
      explanation: (data['explanation'] as String?) ?? '',
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
    if (question.question.trim().isEmpty) {
      errors.add('Question text is required.');
    }
    if (question.options.length < 2 || question.options.length > 5) {
      errors.add('Provide between 2 and 5 answer options.');
    }
    if (question.options.any((option) => option.trim().isEmpty)) {
      errors.add('Answer options cannot be empty.');
    }
    final correctOption = question.correctOption.trim().toUpperCase();
    if (!_optionLabels.contains(correctOption) ||
        _optionLabels.indexOf(correctOption) >= question.options.length) {
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
    return errors;
  }

  /// Maps a canonical question to the existing Firestore schema.
  ///
  /// [documentId] is used by create/update boundaries to make the document
  /// ID authoritative and prevent `data.id` drift.
  static Map<String, dynamic> toFirestore(
    Question question, {
    bool includeCreatedAt = false,
    String? documentId,
  }) {
    final errors = validateForWrite(question, documentId: documentId);
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }

    final id = documentId?.trim().isNotEmpty == true
        ? documentId!.trim()
        : question.id.trim();
    final data = <String, dynamic>{
      'id': id,
      'courseId': question.courseId.trim(),
      'paperId': question.paperId.trim(),
      'sectionId': question.sectionId.trim(),
      'topicId': question.topicId.trim(),
      'question': question.question.trim(),
      'options': [
        for (final option in question.options) option.trim(),
      ],
      'correctOption': question.correctOption.trim().toUpperCase(),
      'explanation': question.explanation.trim(),
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
    if (includeCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    return data;
  }

  static Map<String, dynamic> toDeactivateMap({required bool isActive}) {
    return {
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
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
    return [
      for (final item in value) item.toString(),
    ];
  }
}
