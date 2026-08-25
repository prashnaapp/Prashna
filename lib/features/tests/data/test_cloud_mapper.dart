import 'package:cloud_firestore/cloud_firestore.dart';

import '../../syllabus/data/models/canonical_scope.dart';
import 'models/test_models.dart';

/// Maps Firestore `tests/{testId}` documents to catalog [TestModel].
///
/// Pure functions — no Firebase dependency (unit-testable).
abstract final class TestCloudMapper {
  /// Returns null when required fields are missing or the test is not published.
  ///
  /// Student catalog path — drafts and archived tests are never surfaced.
  static TestModel? fromFirestore(String docId, Map<String, dynamic> data) {
    final mapped = _mapDocument(docId, data);
    if (mapped == null ||
        mapped.status != TestPublicationStatus.published ||
        data['isPublished'] != true) {
      return null;
    }
    return mapped;
  }

  /// Admin read path — includes draft, published, and archived tests.
  static TestModel? fromFirestoreAdmin(
    String docId,
    Map<String, dynamic> data,
  ) {
    return _mapDocument(docId, data);
  }

  static TestModel? _mapDocument(String docId, Map<String, dynamic> data) {
    final rawCourseId = data['courseId'];
    if (rawCourseId is! String || rawCourseId.isEmpty) return null;
    final courseId = rawCourseId;

    final rawCategory = data['category'];
    final category = parseCategory(rawCategory is String ? rawCategory : null);
    if (category == null) return null;

    final rawId = data['id'] as String?;
    final id = (rawId != null && rawId.isNotEmpty) ? rawId : docId;

    final title = data['title'] as String? ?? '';
    final description = data['description'] as String? ?? '';

    return TestModel(
      id: id,
      examId: courseId,
      category: category,
      title: title,
      description: description,
      questionCount: asInt(data['questionCount']) ?? 0,
      marks: asInt(data['totalMarks']) ?? 0,
      durationMinutes: asInt(data['durationMinutes']) ?? 0,
      negativeMarking: formatNegativeMarking(data['negativeMarks']),
      difficulty: _difficulty(data['difficulty']),
      questionIds: parseQuestionIds(data['questionIds']),
      status: parsePublicationStatus(
        data['status'] as String?,
        isPublished: data['isPublished'] == true,
      ),
      paperId: readOptionalString(data['paperId']),
      partId: readOptionalString(data['partId']),
      syllabusUnitId: readOptionalString(data['syllabusUnitId']),
      majorStudyAreaId: readOptionalString(data['majorStudyAreaId']),
      contentTopicId: readOptionalString(data['contentTopicId']),
      canonicalTopicId: readOptionalString(data['canonicalTopicId']),
      lessonId: readOptionalString(data['lessonId']),
      scopeShape: parseScopeShape(data['scopeShape'] as String?),
      year: asInt(data['year']),
      seriesId: readOptionalString(data['seriesId']),
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
    if (test.questionIds.isNotEmpty &&
        test.questionIds.length != test.questionCount) {
      errors.add('Question count must match assigned question IDs.');
    }
    errors.addAll(_validateCategoryMetadata(test));
    return errors;
  }

  static List<String> _validateCategoryMetadata(TestModel test) {
    final errors = <String>[];
    final paperId = test.paperId?.trim();
    final seriesId = test.seriesId?.trim();
    switch (test.category) {
      case TestCategoryType.partTests:
        if (paperId == null || paperId.isEmpty) {
          errors.add('Paper is required for Paper-wise Tests.');
        }
      case TestCategoryType.mockTests:
        if (seriesId == null || seriesId.isEmpty) {
          errors.add('Grand Test group is required.');
        }
        if (paperId == null || paperId.isEmpty) {
          errors.add('Paper is required for Grand Tests.');
        }
      case TestCategoryType.previousYear:
        final year = test.year;
        if (year == null || year < 1900 || year > 2100) {
          errors.add('A valid exam year is required.');
        }
        if (paperId == null || paperId.isEmpty) {
          errors.add('Paper is required for Previous Papers.');
        }
      case TestCategoryType.chapterTests:
      case TestCategoryType.paperTests:
        break;
    }
    return errors;
  }

  /// Validates the canonical persisted metadata before publication.
  ///
  /// Unlike create validation, publication always requires the model to carry
  /// a non-empty ID because the document already exists.
  static List<String> validateForPublication(
    TestModel test, {
    required String documentId,
  }) {
    final errors = validateForWrite(test, documentId: documentId);
    if (documentId.trim().isEmpty && !errors.contains('Test ID is required.')) {
      errors.insert(0, 'Test ID is required.');
    }
    if (test.id.trim().isEmpty && !errors.contains('Test ID is required.')) {
      errors.insert(0, 'Test ID is required.');
    }
    if (test.status == TestPublicationStatus.archived) {
      errors.add('Archived tests cannot be published.');
    }
    return errors;
  }

  /// Maps a canonical test to the existing Firestore schema.
  ///
  /// When [forUpdate] is true, known optional syllabus fields that are empty
  /// in the current model are written as [FieldValue.delete] so Firestore
  /// `update()` removes stale values. Create continues to omit empty optional
  /// fields instead of emitting delete sentinels.
  static Map<String, dynamic> toFirestore(
    TestModel test, {
    String? documentId,
    bool forUpdate = false,
  }) {
    final errors = validateForWrite(test, documentId: documentId);
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }

    final id = documentId?.trim().isNotEmpty == true
        ? documentId!.trim()
        : test.id.trim();
    final negative = parseNegativeMarkingValue(test.negativeMarking)!;

    final data = <String, dynamic>{
      'id': id,
      'courseId': test.examId.trim(),
      'title': test.title.trim(),
      'description': test.description.trim(),
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
      'status': test.status.name,
      // Keep boolean for student security-rule queries.
      'isPublished': test.isPublished,
    };

    void writeOptional(String key, String? value) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        data[key] = trimmed;
      } else if (forUpdate) {
        data[key] = FieldValue.delete();
      }
    }

    writeOptional('paperId', test.paperId);
    writeOptional('partId', test.partId);
    writeOptional('syllabusUnitId', test.syllabusUnitId);
    writeOptional('majorStudyAreaId', test.majorStudyAreaId);
    writeOptional('contentTopicId', test.contentTopicId);
    writeOptional('canonicalTopicId', test.canonicalTopicId);
    writeOptional('lessonId', test.lessonId);
    writeOptional('seriesId', test.seriesId);
    if (test.year != null) {
      data['year'] = test.year;
    } else if (forUpdate) {
      data['year'] = FieldValue.delete();
    }
    if (test.scopeShape != null) {
      data['scopeShape'] = test.scopeShape!.name;
    } else if (forUpdate) {
      data['scopeShape'] = FieldValue.delete();
    }
    // scopeKey is derived — not persisted to production documents.
    return data;
  }

  static String? readOptionalString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static CanonicalScopeShape? parseScopeShape(String? raw) {
    switch (raw?.trim()) {
      case 'groupIiPaperI':
        return CanonicalScopeShape.groupIiPaperI;
      case 'groupIiPartUnit':
        return CanonicalScopeShape.groupIiPartUnit;
      case 'groupIiiPaperUnit':
        return CanonicalScopeShape.groupIiiPaperUnit;
      case 'groupIiiPartUnit':
        return CanonicalScopeShape.groupIiiPartUnit;
      default:
        return null;
    }
  }

  static Map<String, dynamic> toPublishMap({required bool isPublished}) {
    return {
      'isPublished': isPublished,
      'status': isPublished
          ? TestPublicationStatus.published.name
          : TestPublicationStatus.draft.name,
    };
  }

  static Map<String, dynamic> toStatusMap(TestPublicationStatus status) {
    return {
      'status': status.name,
      'isPublished': status == TestPublicationStatus.published,
    };
  }

  static bool hasConsistentPublishedState(Map<String, dynamic> data) {
    return data['status'] == TestPublicationStatus.published.name &&
        data['isPublished'] == true;
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
    if (parsed == null || !parsed.isFinite || parsed < 0) return null;
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

  static TestPublicationStatus parsePublicationStatus(
    String? raw, {
    required bool isPublished,
  }) {
    switch (raw?.trim().toLowerCase()) {
      case 'draft':
        return TestPublicationStatus.draft;
      case 'published':
        return TestPublicationStatus.published;
      case 'archived':
        return TestPublicationStatus.archived;
      default:
        return isPublished
            ? TestPublicationStatus.published
            : TestPublicationStatus.draft;
    }
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
