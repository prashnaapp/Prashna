import '../../../syllabus/data/models/canonical_scope.dart';

enum TestCategoryType {
  chapterTests,
  partTests,
  paperTests,
  mockTests,
  previousYear,
}

/// Catalog lifecycle. Student lists only surface [published].
enum TestPublicationStatus { draft, published, archived }

class TestCategoryModel {
  const TestCategoryModel({
    required this.type,
    required this.title,
    required this.subtitle,
  });

  final TestCategoryType type;
  final String title;
  final String subtitle;
}

class TestModel {
  const TestModel({
    required this.id,
    required this.examId,
    required this.category,
    required this.title,
    required this.questionCount,
    required this.marks,
    required this.durationMinutes,
    required this.negativeMarking,
    required this.difficulty,
    this.description = '',
    this.questionIds = const [],
    this.status = TestPublicationStatus.draft,
    this.paperId,
    this.partId,
    this.syllabusUnitId,
    this.majorStudyAreaId,
    this.contentTopicId,
    this.canonicalTopicId,
    this.lessonId,
    this.scopeShape,
    this.year,
    this.seriesId,
  });

  final String id;

  /// Course id (`group-ii`, `group-iii`). Stored as Firestore `courseId`.
  final String examId;
  final TestCategoryType category;
  final String title;
  final String description;
  final int questionCount;
  final int marks;
  final int durationMinutes;
  final String negativeMarking;
  final String difficulty;

  /// Optional ordered Firestore question IDs for fixed assignment.
  /// Empty → existing dynamic Question Bank selection.
  final List<String> questionIds;

  /// Explicit catalog lifecycle. Prefer this over [isPublished].
  final TestPublicationStatus status;

  /// Optional syllabus location (Group-III chapter/unit tests).
  ///
  /// Group-II catalog tests typically leave these null. Do not reuse as
  /// Group-II topic/lesson ids.
  final String? paperId;
  final String? partId;
  final String? syllabusUnitId;

  /// Optional canonical attributes for unambiguous [canonicalScope] resolution.
  final String? majorStudyAreaId;
  final String? contentTopicId;
  final String? canonicalTopicId;
  final String? lessonId;
  final CanonicalScopeShape? scopeShape;

  /// Optional previous-paper year. Required when [category] is previousYear.
  final int? year;

  /// Grand Test group identity (`seriesId`). Required when [category] is mockTests.
  final String? seriesId;

  /// Catalog visibility for Firestore student queries (`isPublished == true`).
  bool get isPublished => status == TestPublicationStatus.published;

  /// Whether students may start a new attempt from the catalog.
  bool get isAvailableForNewAttempts =>
      status == TestPublicationStatus.published;

  /// Derived when location fields are unambiguous; otherwise null.
  ///
  /// Legacy Group-II tests without location remain null.
  CanonicalScope? get canonicalScope => CanonicalScope.tryResolve(
    courseId: examId,
    paperId: paperId,
    partId: partId,
    syllabusUnitId: syllabusUnitId,
    majorStudyAreaId:
        majorStudyAreaId ??
        (paperId == 'group-ii-paper-i' ? syllabusUnitId : null),
    contentTopicId: contentTopicId,
    topicId:
        canonicalTopicId ??
        (examId == 'group-ii' && paperId != 'group-ii-paper-i'
            ? syllabusUnitId
            : null),
    lessonId: lessonId,
    shapeHint: scopeShape,
  );
}

class InstructionModel {
  const InstructionModel({
    required this.testName,
    required this.questionCount,
    required this.marks,
    required this.durationLabel,
    required this.negativeMarking,
    required this.difficulty,
    required this.instructions,
  });

  final String testName;
  final int questionCount;
  final int marks;
  final String durationLabel;
  final String negativeMarking;
  final String difficulty;
  final List<String> instructions;
}

class TestExamSummary {
  const TestExamSummary({
    required this.examId,
    required this.title,
    required this.maxMarks,
    required this.paperCount,
    required this.isEnabled,
  });

  final String examId;
  final String title;
  final double maxMarks;
  final int paperCount;
  final bool isEnabled;
}

/// Paper entry for Paper-wise Tests (Phase 2) and Mock Tests papers (Phase 3).
class PaperWisePaper {
  const PaperWisePaper({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

/// Mock Test list entry (Phase 3).
class MockTestEntry {
  const MockTestEntry({required this.id, required this.title});

  final String id;
  final String title;
}

/// Exam choice under Previous Papers (Phase 4).
class PreviousPaperExam {
  const PreviousPaperExam({required this.examId, required this.title});

  final String examId;
  final String title;
}

/// Year entry under a Previous Papers exam (Phase 4).
class PreviousPaperYear {
  const PreviousPaperYear({required this.year});

  final int year;

  String get id => '$year';
  String get title => '$year Previous Paper';
}
