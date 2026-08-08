import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/question_models.dart';

/// Maps Firestore `questions/{questionId}` documents to [Question].
///
/// Pure functions — no Firebase dependency (unit-testable).
abstract final class QuestionCloudMapper {
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
