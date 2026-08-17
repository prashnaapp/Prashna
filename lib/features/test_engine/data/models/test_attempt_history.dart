/// Read-model for a completed Firestore test attempt (`test_attempts/{id}`).
///
/// Values are stored results — never recalculated by the history UI.
class TestAttemptHistoryItem {
  const TestAttemptHistoryItem({
    required this.attemptId,
    required this.testId,
    required this.courseId,
    required this.mode,
    required this.status,
    required this.score,
    required this.percentage,
    required this.accuracy,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.totalQuestions,
    required this.timeSpentSeconds,
    required this.startedAt,
    required this.submittedAt,
    required this.passed,
    this.uid,
    this.testTitle,
    this.courseTitle,
    this.authority,
    this.snapshotSchemaVersion,
  });

  final String attemptId;
  final String testId;
  final String courseId;
  final String mode;
  final String status;
  final double score;
  final double percentage;
  final double accuracy;
  final int correct;
  final int wrong;
  final int skipped;
  final int totalQuestions;
  final int timeSpentSeconds;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final bool passed;

  /// Present when loaded from Firestore; used for defense-in-depth filtering.
  final String? uid;

  /// Snapshot at submit time. Absent on attempts created before M30.2.6.
  final String? testTitle;

  /// Snapshot at submit time. Absent on attempts created before M30.2.6.
  final String? courseTitle;

  /// `server_verified` or absent/`legacy_client` for older client-written docs.
  final String? authority;

  /// Null/absent = legacy attempt without frozen question/test content.
  final int? snapshotSchemaVersion;

  bool get hasImmutableSnapshot =>
      snapshotSchemaVersion != null && snapshotSchemaVersion! >= 1;

  bool get isServerVerified => authority == 'server_verified';

  bool get isLegacyClient =>
      authority == null ||
      authority == 'legacy_client' ||
      authority!.isEmpty;

  /// Prefer stored [testTitle]; fall back to [testId] for older documents.
  String get displayTestTitle {
    final title = testTitle?.trim();
    if (title != null && title.isNotEmpty) return title;
    return testId;
  }

  /// Prefer stored [courseTitle]; fall back to [courseId] for older documents.
  String get displayCourseTitle {
    final title = courseTitle?.trim();
    if (title != null && title.isNotEmpty) return title;
    return courseId;
  }
}
