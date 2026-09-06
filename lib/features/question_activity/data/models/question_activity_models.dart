// Shared question-activity vocabulary for Revision Center / Bookmarks.
//
// Content modules (Chapters, Test Series, Current Affairs, …) stay independent.
// They report activity through QuestionActivityReporter using these models.
//
// Global revision identity is always QuestionActivityContext.questionId.
// Encounter/source fields are optional metadata and must not create duplicate
// revision identities.

/// Product module that presented the question (not syllabus hierarchy).
enum QuestionActivitySourceModule {
  /// Syllabus / Chapters catalog and related chapter question flows.
  chapters,

  /// Exam catalog: paper-wise, grand, old grand, previous papers.
  testSeries,

  /// Local practice Test Engine sessions (non-catalog).
  practice,

  /// Revision Center practice builders / revision flows.
  revision,

  /// Current Affairs weekly/monthly sets.
  currentAffairs,

  /// Reachable but unclassified student path.
  other,

  /// Legacy records or callers that did not supply a module.
  unknown,
}

/// Finer encounter subtype. Prefer existing product identifiers.
///
/// All values are optional at report time; unknown is valid for legacy data.
enum QuestionActivitySourceType {
  /// Syllabus unit / chapterTests under Chapters.
  chapterTests,

  /// Paper-wise partTests (and folded chapterTests under Test Series).
  partTests,

  /// Catalog paperTests (rare / legacy category).
  paperTests,

  /// Grand Test papers (`mockTests` with approved series).
  grandTest,

  /// Old Grand Tests container papers.
  oldGrandTest,

  /// Previous-year catalog tests.
  previousPaper,

  /// Topic / Practice Bits style practice (TestMode.practice).
  topicPractice,

  /// Weak-topic / revision practice builders.
  revisionPractice,

  /// Current Affairs weekly set.
  currentAffairsWeekly,

  /// Current Affairs monthly set.
  currentAffairsMonthly,

  /// Revision Center / bookmarks question viewer (no scored attempt).
  questionViewer,

  /// Not supplied or not classifiable.
  unknown,
}

/// Kind of student activity being reported.
enum QuestionActivityType {
  wrongAnswer,
  bookmarkAdded,
  bookmarkRemoved,
}

/// Whether the activity reached (or will reach) server revision authority.
enum QuestionActivityAuthority {
  /// Catalog submit → Cloud Function → `user_revision` (authoritative).
  serverVerified,

  /// Local session Progress / reporter only; does not write `user_revision`.
  localSession,

  /// Bookmark cloud path (`user_bookmarks`) — independent of revision.
  bookmarkCloud,

  /// Non-catalog answer verified by `reportQuestionActivity` callable
  /// (question option check). Distinct from catalog grading-snapshot trust.
  serverVerifiedQuestionOption,
}

/// Outcome of attempting durable revision persistence for one wrong answer.
enum QuestionActivityPersistState {
  /// Session encounter recorded only.
  localRecorded,

  /// Server confirmed revision side effects (or idempotent duplicate).
  serverPersisted,

  /// Server call failed; local encounter may still exist.
  serverFailed,

  /// Intentionally not dispatched (e.g. catalog / blocked module).
  notDispatched,
}

/// Result for one wrong-answer persist attempt.
class QuestionActivityPersistResult {
  const QuestionActivityPersistResult({
    required this.questionId,
    required this.activityEventId,
    required this.state,
    this.duplicate = false,
    this.error,
  });

  final String questionId;
  final String activityEventId;
  final QuestionActivityPersistState state;
  final bool duplicate;
  final Object? error;

  bool get isServerAuthoritative =>
      state == QuestionActivityPersistState.serverPersisted;
}

/// Encounter context for one question activity event.
///
/// Required: [questionId]. Everything else is optional and forward-compatible.
/// Do not invent historical source for legacy ID-only records.
class QuestionActivityContext {
  const QuestionActivityContext({
    required this.questionId,
    this.courseId,
    this.sourceModule = QuestionActivitySourceModule.unknown,
    this.sourceType = QuestionActivitySourceType.unknown,
    this.testId,
    this.testTitle,
    this.paperId,
    this.sectionId,
    this.partId,
    this.topicId,
    this.lessonId,
    this.majorStudyAreaId,
    this.contentTopicId,
    this.syllabusUnitId,
    this.seriesId,
    this.year,
    this.currentAffairsSetId,
    this.encounterId,
    this.recordedAt,
  });

  /// Global question identity (`questions/{questionId}`).
  final String questionId;

  final String? courseId;
  final QuestionActivitySourceModule sourceModule;
  final QuestionActivitySourceType sourceType;

  final String? testId;
  final String? testTitle;
  final String? paperId;

  /// Legacy section id (Group-III style).
  final String? sectionId;

  /// Canonical part id when distinct from [sectionId].
  final String? partId;
  final String? topicId;
  final String? lessonId;
  final String? majorStudyAreaId;
  final String? contentTopicId;
  final String? syllabusUnitId;
  final String? seriesId;
  final int? year;
  final String? currentAffairsSetId;

  /// Opaque per-attempt / per-encounter id when available.
  final String? encounterId;
  final DateTime? recordedAt;

  QuestionActivityContext copyWith({
    String? questionId,
    String? courseId,
    QuestionActivitySourceModule? sourceModule,
    QuestionActivitySourceType? sourceType,
    String? testId,
    String? testTitle,
    String? paperId,
    String? sectionId,
    String? partId,
    String? topicId,
    String? lessonId,
    String? majorStudyAreaId,
    String? contentTopicId,
    String? syllabusUnitId,
    String? seriesId,
    int? year,
    String? currentAffairsSetId,
    String? encounterId,
    DateTime? recordedAt,
  }) {
    return QuestionActivityContext(
      questionId: questionId ?? this.questionId,
      courseId: courseId ?? this.courseId,
      sourceModule: sourceModule ?? this.sourceModule,
      sourceType: sourceType ?? this.sourceType,
      testId: testId ?? this.testId,
      testTitle: testTitle ?? this.testTitle,
      paperId: paperId ?? this.paperId,
      sectionId: sectionId ?? this.sectionId,
      partId: partId ?? this.partId,
      topicId: topicId ?? this.topicId,
      lessonId: lessonId ?? this.lessonId,
      majorStudyAreaId: majorStudyAreaId ?? this.majorStudyAreaId,
      contentTopicId: contentTopicId ?? this.contentTopicId,
      syllabusUnitId: syllabusUnitId ?? this.syllabusUnitId,
      seriesId: seriesId ?? this.seriesId,
      year: year ?? this.year,
      currentAffairsSetId: currentAffairsSetId ?? this.currentAffairsSetId,
      encounterId: encounterId ?? this.encounterId,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  /// Minimal legacy-safe context (ID only).
  factory QuestionActivityContext.legacyQuestionId(String questionId) {
    return QuestionActivityContext(questionId: questionId.trim());
  }
}

/// One reported activity event. Identity for revision lists is always [context.questionId].
class QuestionActivityEvent {
  const QuestionActivityEvent({
    required this.type,
    required this.context,
    required this.authority,
    this.isCorrect,
  });

  final QuestionActivityType type;
  final QuestionActivityContext context;
  final QuestionActivityAuthority authority;

  /// When known for answer activities; null for bookmarks.
  final bool? isCorrect;

  String get questionId => context.questionId;
}
