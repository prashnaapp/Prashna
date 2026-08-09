import 'models/test_models.dart';

/// Maps Firestore `tests/{testId}` documents to catalog [TestModel].
///
/// Pure functions — no Firebase dependency (unit-testable).
abstract final class TestCloudMapper {
  /// Returns null when required fields are missing or [isPublished] is not true.
  ///
  /// Student catalog path — drafts are never surfaced.
  static TestModel? fromFirestore(String docId, Map<String, dynamic> data) {
    if (data['isPublished'] != true) return null;
    return _mapDocument(docId, data, isPublished: true);
  }

  /// Admin read path — includes published and draft tests.
  static TestModel? fromFirestoreAdmin(
    String docId,
    Map<String, dynamic> data,
  ) {
    return _mapDocument(docId, data, isPublished: data['isPublished'] == true);
  }

  static TestModel? _mapDocument(
    String docId,
    Map<String, dynamic> data, {
    required bool isPublished,
  }) {
    final rawCourseId = data['courseId'];
    if (rawCourseId is! String || rawCourseId.isEmpty) return null;
    final courseId = rawCourseId;

    final rawCategory = data['category'];
    final category = parseCategory(rawCategory is String ? rawCategory : null);
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
      isPublished: isPublished,
    );
  }

  /// Validates test metadata before an admin write.
  static List<String> validateForWrite(TestModel test, {String? documentId}) {
    final errors = <String>[];
    final id = test.id.trim();
    final expectedId = documentId?.trim();

    if (id.isEmpty && (expectedId == null || expectedId.isEmpty)) {
      errors.add('Test ID is required.');
    }
    if (expectedId != null &&
        expectedId.isNotEmpty &&
        id.isNotEmpty &&
        id != expectedId) {
      errors.add('Test ID must match the Firestore document ID.');
    }
    if (test.examId.trim().isEmpty) {
      errors.add('Course is required.');
    }
    if (test.title.trim().isEmpty) {
      errors.add('Title is required.');
    }
    if (categoryToFirestore(test.category) == null) {
      errors.add('Category is not supported.');
    }
    if (test.questionCount <= 0) {
      errors.add('Question count must be greater than zero.');
    }
    if (test.marks < 0) {
      errors.add('Total marks must be zero or greater.');
    }
    if (test.durationMinutes <= 0) {
      errors.add('Duration must be greater than zero.');
    }
    final negative = parseNegativeMarkingValue(test.negativeMarking);
    if (negative == null) {
      errors.add('Negative marking must be a valid non-negative number.');
    }
    if (test.difficulty.trim().isEmpty) {
      errors.add('Difficulty is required.');
    }
    return errors;
  }

  /// Maps a canonical test to the existing Firestore schema.
  static Map<String, dynamic> toFirestore(
    TestModel test, {
    String? documentId,
  }) {
    final errors = validateForWrite(test, documentId: documentId);
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }

    final id = documentId?.trim().isNotEmpty == true
        ? documentId!.trim()
        : test.id.trim();
    final negative = parseNegativeMarkingValue(test.negativeMarking)!;

    return {
      'id': id,
      'courseId': test.examId.trim(),
      'title': test.title.trim(),
      'category': categoryToFirestore(test.category)!,
      'questionCount': test.questionCount,
      'totalMarks': test.marks,
      'durationMinutes': test.durationMinutes,
      'negativeMarks': negative,
      'difficulty': test.difficulty.trim(),
      'questionIds': [
        for (final questionId in test.questionIds)
          if (questionId.trim().isNotEmpty) questionId.trim(),
      ],
      'isPublished': test.isPublished,
    };
  }

  static Map<String, dynamic> toPublishMap({required bool isPublished}) {
    return {'isPublished': isPublished};
  }

  /// Canonical Firestore category string for writes.
  static String? categoryToFirestore(TestCategoryType category) {
    switch (category) {
      case TestCategoryType.chapterTests:
        return 'chapter';
      case TestCategoryType.partTests:
        return 'part';
      case TestCategoryType.paperTests:
        return 'paper';
      case TestCategoryType.mockTests:
        return 'mock';
      case TestCategoryType.previousYear:
        return 'previousyear';
    }
  }

  /// Parses [TestModel.negativeMarking] into a non-negative number for writes.
  static num? parseNegativeMarkingValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    final parsed = num.tryParse(trimmed);
    if (parsed == null || parsed.isNaN || parsed < 0) return null;
    return parsed;
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
