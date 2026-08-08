import 'models/test_models.dart';

/// Maps Firestore `tests/{testId}` documents to catalog [TestModel].
///
/// Pure functions — no Firebase dependency (unit-testable).
abstract final class TestCloudMapper {
  /// Returns null when required fields are missing or [isPublished] is not true.
  static TestModel? fromFirestore(String docId, Map<String, dynamic> data) {
    if (data['isPublished'] != true) return null;

    final courseId = data['courseId'] as String?;
    if (courseId == null || courseId.isEmpty) return null;

    final category = parseCategory(data['category'] as String?);
    if (category == null) return null;

    final rawId = data['id'] as String?;
    final id = (rawId != null && rawId.isNotEmpty) ? rawId : docId;

    final title = data['title'] as String? ?? '';

    return TestModel(
      id: id,
      examId: courseId,
      category: category,
      title: title,
      questionCount: asInt(data['questionCount']) ?? 0,
      marks: asInt(data['totalMarks']) ?? 0,
      durationMinutes: asInt(data['durationMinutes']) ?? 0,
      negativeMarking: formatNegativeMarking(data['negativeMarks']),
      difficulty: _difficulty(data['difficulty']),
      questionIds: parseQuestionIds(data['questionIds']),
    );
  }

  /// Firestore `questionIds` → ordered non-empty string IDs.
  /// Missing/null/malformed → empty list (dynamic selection).
  static List<String> parseQuestionIds(dynamic value) {
    if (value == null) return const [];
    if (value is! List) return const [];
    final ids = <String>[];
    for (final entry in value) {
      if (entry is! String) continue;
      final trimmed = entry.trim();
      if (trimmed.isEmpty) continue;
      ids.add(trimmed);
    }
    return List<String>.unmodifiable(ids);
  }

  /// Firestore `category` string → [TestCategoryType].
  static TestCategoryType? parseCategory(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'chapter':
      case 'chaptertests':
      case 'chapter_tests':
      case 'chapter-tests':
        return TestCategoryType.chapterTests;
      case 'part':
      case 'parttests':
      case 'part_tests':
      case 'paper-wise':
      case 'paperwise':
        return TestCategoryType.partTests;
      case 'paper':
      case 'papertests':
      case 'paper_tests':
        return TestCategoryType.paperTests;
      case 'mock':
      case 'mocktests':
      case 'mock_tests':
        return TestCategoryType.mockTests;
      case 'previousyear':
      case 'previous_year':
      case 'previous-year':
      case 'previous':
        return TestCategoryType.previousYear;
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

  /// Catalog [TestModel.negativeMarking] is a display string; engine parses digits.
  static String formatNegativeMarking(dynamic value) {
    if (value == null) return '0';
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? '0' : trimmed;
    }
    if (value is num) {
      final asDouble = value.toDouble();
      if (asDouble == asDouble.roundToDouble()) {
        return asDouble.toInt().toString();
      }
      return asDouble.toString();
    }
    return '0';
  }

  static String _difficulty(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return 'Medium';
  }
}
