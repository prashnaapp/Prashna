import '../../../syllabus/data/models/canonical_scope.dart';

enum QuestionDifficulty { easy, medium, hard }

enum QuestionType { practice, previousYear, mock }

enum QuestionPublicationStatus { draft, published, archived }

/// One language variant of a question's student-facing content.
class QuestionLocalizedContent {
  const QuestionLocalizedContent({
    required this.question,
    required this.options,
    required this.explanation,
  });

  final String question;
  final List<QuestionOption> options;
  final String explanation;
}

/// Bilingual content for one question record.
///
/// `en.options[i]` and `te.options[i]` are translations of the same option.
class QuestionContent {
  const QuestionContent({required this.en, this.te});

  final QuestionLocalizedContent en;
  final QuestionLocalizedContent? te;
}

class QuestionOption {
  const QuestionOption({required this.text});

  final String text;
}

/// Canonical syllabus attribution, with legacy fields retained explicitly.
class QuestionSyllabusAttribution {
  const QuestionSyllabusAttribution({
    required this.courseId,
    required this.paperId,
    this.majorStudyAreaId,
    this.contentTopicId,
    this.partId,
    this.topicId,
    this.lessonId,
    this.syllabusUnitId,
    this.legacySectionId,
    this.legacyTopicId,
  });

  final String courseId;
  final String paperId;
  final String? majorStudyAreaId;
  final String? contentTopicId;
  final String? partId;
  final String? topicId;
  final String? lessonId;

  /// Group-III final folder before Tests (Paper → [Part →] Syllabus Unit).
  ///
  /// Optional so Group-II documents remain unchanged.
  final String? syllabusUnitId;

  /// Compatibility-only attribution from legacy documents.
  final String? legacySectionId;
  final String? legacyTopicId;

  bool get isPaperI => majorStudyAreaId != null || contentTopicId != null;

  bool get isPartBased => partId != null || lessonId != null;

  bool get isGroupIiiUnitBased => syllabusUnitId != null;

  /// Normalized analytical identity when attribution is unambiguous.
  ///
  /// Returns null for legacy-only or ambiguous records. Never invents
  /// identity from `legacySectionId` / `legacyTopicId`.
  CanonicalScope? get canonicalScope => CanonicalScope.tryResolve(
    courseId: courseId,
    paperId: paperId,
    partId: partId,
    syllabusUnitId: syllabusUnitId,
    majorStudyAreaId: majorStudyAreaId,
    contentTopicId: contentTopicId,
    topicId: topicId,
    lessonId: lessonId,
    legacySectionId: legacySectionId,
    legacyTopicId: legacyTopicId,
  );
}

/// Canonical question entity — single source of truth for the app.
class Question {
  const Question({
    required this.id,
    required this.courseId,
    required this.paperId,
    this.sectionId = '',
    this.topicId = '',
    this.question = '',
    this.options = const [],
    required this.correctOption,
    this.explanation = '',
    required this.difficulty,
    required this.questionType,
    this.language = 'en',
    required this.marks,
    required this.negativeMarks,
    required this.tags,
    required this.estimatedTime,
    required this.createdAt,
    required this.updatedAt,
    this.content,
    this.syllabus,
    this.status,
    this.year,
    this.examName,
    this.hint,
    this.aiExplanation,
    this.isActive = true,
  });

  final String id;
  final String courseId;
  final String paperId;
  final String sectionId;
  final String topicId;
  final String question;
  final List<String> options;
  final String correctOption;
  final String explanation;
  final QuestionDifficulty difficulty;
  final QuestionType questionType;
  final String language;
  final double marks;
  final double negativeMarks;
  final int? year;
  final String? examName;
  final List<String> tags;
  final Duration estimatedTime;
  final String? hint;
  final String? aiExplanation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final QuestionContent? content;
  final QuestionSyllabusAttribution? syllabus;
  final QuestionPublicationStatus? status;

  bool get isPublished =>
      status == QuestionPublicationStatus.published ||
      (status == null && isActive);

  String? get majorStudyAreaId => syllabus?.majorStudyAreaId;
  String? get contentTopicId => syllabus?.contentTopicId;
  String? get partId => syllabus?.partId;
  String? get lessonId => syllabus?.lessonId;
  String? get syllabusUnitId => syllabus?.syllabusUnitId;

  /// Derived when [syllabus] attribution is unambiguous; otherwise null.
  CanonicalScope? get canonicalScope => syllabus?.canonicalScope;

  String get correctAnswerText {
    const labels = ['A', 'B', 'C', 'D', 'E'];
    final index = labels.indexOf(correctOption);
    if (index >= 0 && index < options.length) return options[index];
    return correctOption;
  }
}

/// Filter criteria for repository / service queries.
class QuestionFilter {
  const QuestionFilter({
    this.courseId,
    this.paperId,
    this.sectionId,
    this.topicId,
    this.partId,
    this.lessonId,
    this.syllabusUnitId,
    this.majorStudyAreaId,
    this.contentTopicId,
    this.difficulty,
    this.questionType,
    this.language,
    this.year,
    this.bookmarked,
    this.attempted,
    this.activeOnly = true,
  });

  final String? courseId;
  final String? paperId;
  final String? sectionId;
  final String? topicId;
  final String? partId;
  final String? lessonId;
  final String? syllabusUnitId;
  final String? majorStudyAreaId;
  final String? contentTopicId;
  final QuestionDifficulty? difficulty;
  final QuestionType? questionType;
  final String? language;
  final int? year;
  final bool? bookmarked;
  final bool? attempted;
  final bool activeOnly;

  QuestionFilter copyWith({
    String? courseId,
    String? paperId,
    String? sectionId,
    String? topicId,
    String? partId,
    String? lessonId,
    String? syllabusUnitId,
    String? majorStudyAreaId,
    String? contentTopicId,
    QuestionDifficulty? difficulty,
    QuestionType? questionType,
    String? language,
    int? year,
    bool? bookmarked,
    bool? attempted,
    bool? activeOnly,
  }) {
    return QuestionFilter(
      courseId: courseId ?? this.courseId,
      paperId: paperId ?? this.paperId,
      sectionId: sectionId ?? this.sectionId,
      topicId: topicId ?? this.topicId,
      partId: partId ?? this.partId,
      lessonId: lessonId ?? this.lessonId,
      syllabusUnitId: syllabusUnitId ?? this.syllabusUnitId,
      majorStudyAreaId: majorStudyAreaId ?? this.majorStudyAreaId,
      contentTopicId: contentTopicId ?? this.contentTopicId,
      difficulty: difficulty ?? this.difficulty,
      questionType: questionType ?? this.questionType,
      language: language ?? this.language,
      year: year ?? this.year,
      bookmarked: bookmarked ?? this.bookmarked,
      attempted: attempted ?? this.attempted,
      activeOnly: activeOnly ?? this.activeOnly,
    );
  }
}

enum QuestionSort { newest, oldest, difficultyAsc, difficultyDesc, yearDesc }
