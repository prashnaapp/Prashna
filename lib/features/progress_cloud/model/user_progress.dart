import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore progress snapshot.
///
/// Legacy parent path: `user_progress/{uid}` (read-only after cutover).
/// Per-course path: `user_progress/{uid}/courses/{courseId}`.
class UserProgress {
  const UserProgress({
    required this.uid,
    required this.courseId,
    required this.overall,
    required this.papers,
    required this.chapters,
    required this.lastUpdated,
    required this.appVersion,
    this.schemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final String uid;
  final String? courseId;
  final ProgressOverall overall;
  final Map<String, dynamic> papers;
  final Map<String, dynamic> chapters;
  final DateTime? lastUpdated;
  final String? appVersion;
  final int? schemaVersion;

  factory UserProgress.initial({
    required String uid,
    required String appVersion,
    String? courseId,
  }) {
    return UserProgress(
      uid: uid,
      courseId: courseId,
      overall: ProgressOverall.zero,
      papers: const {},
      chapters: const {},
      lastUpdated: null,
      appVersion: appVersion,
      schemaVersion: currentSchemaVersion,
    );
  }

  factory UserProgress.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    final overallRaw = data['overall'];
    final papersRaw = data['papers'];
    final chaptersRaw = data['chapters'];

    return UserProgress(
      uid: (data['uid'] as String?) ?? uid,
      courseId: data['courseId'] as String?,
      overall: overallRaw is Map
          ? ProgressOverall.fromMap(Map<String, dynamic>.from(overallRaw))
          : ProgressOverall.zero,
      papers: papersRaw is Map
          ? Map<String, dynamic>.from(papersRaw)
          : const {},
      chapters: chaptersRaw is Map
          ? Map<String, dynamic>.from(chaptersRaw)
          : const {},
      lastUpdated: _readTimestamp(data['lastUpdated']),
      appVersion: data['appVersion'] as String?,
      schemaVersion: (data['schemaVersion'] as num?)?.toInt(),
    );
  }

  /// Parses a per-course document at `user_progress/{uid}/courses/{courseId}`.
  ///
  /// Throws [FormatException] when path/body ownership fields disagree or
  /// required maps are malformed.
  factory UserProgress.fromCourseFirestore({
    required String uid,
    required String courseId,
    required Map<String, dynamic> data,
  }) {
    final bodyUid = data['uid'];
    final bodyCourseId = data['courseId'];
    if (bodyUid is String && bodyUid != uid) {
      throw FormatException(
        'Course progress uid mismatch: path=$uid body=$bodyUid',
      );
    }
    if (bodyCourseId is String && bodyCourseId != courseId) {
      throw FormatException(
        'Course progress courseId mismatch: path=$courseId body=$bodyCourseId',
      );
    }

    final overallRaw = data['overall'];
    final papersRaw = data['papers'];
    final chaptersRaw = data['chapters'];
    if (overallRaw != null && overallRaw is! Map) {
      throw const FormatException('Course progress overall must be a map');
    }
    if (papersRaw != null && papersRaw is! Map) {
      throw const FormatException('Course progress papers must be a map');
    }
    if (chaptersRaw != null && chaptersRaw is! Map) {
      throw const FormatException('Course progress chapters must be a map');
    }

    return UserProgress(
      uid: uid,
      courseId: courseId,
      overall: overallRaw is Map
          ? ProgressOverall.fromMap(Map<String, dynamic>.from(overallRaw))
          : ProgressOverall.zero,
      papers: papersRaw is Map
          ? Map<String, dynamic>.from(papersRaw)
          : const {},
      chapters: chaptersRaw is Map
          ? Map<String, dynamic>.from(chaptersRaw)
          : const {},
      lastUpdated: _readTimestamp(data['lastUpdated']),
      appVersion: data['appVersion'] as String?,
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ??
          currentSchemaVersion,
    );
  }

  /// Payload for first-time legacy parent creation.
  Map<String, dynamic> toCreateMap({required String appVersion}) {
    return {
      'uid': uid,
      'courseId': courseId,
      'overall': ProgressOverall.zero.toMap(),
      'papers': <String, dynamic>{},
      'chapters': <String, dynamic>{},
      'lastUpdated': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
    };
  }

  /// Full legacy parent document write for [ProgressCloudRepository.update].
  Map<String, dynamic> toUpdateMap({required String appVersion}) {
    return {
      'uid': uid,
      'courseId': courseId,
      'overall': overall.toMap(),
      'papers': papers,
      'chapters': chapters,
      'lastUpdated': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
    };
  }

  /// Payload for first-time per-course document creation.
  Map<String, dynamic> toCourseCreateMap({required String appVersion}) {
    final resolvedCourseId = courseId;
    if (resolvedCourseId == null || resolvedCourseId.isEmpty) {
      throw StateError('Course progress create requires a non-empty courseId');
    }
    return {
      'uid': uid,
      'courseId': resolvedCourseId,
      'overall': ProgressOverall.zero.toMap(),
      'papers': <String, dynamic>{},
      'chapters': <String, dynamic>{},
      'lastUpdated': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
      'schemaVersion': currentSchemaVersion,
    };
  }

  /// Full per-course document write (single course only).
  Map<String, dynamic> toCourseUpdateMap({required String appVersion}) {
    final resolvedCourseId = courseId;
    if (resolvedCourseId == null || resolvedCourseId.isEmpty) {
      throw StateError('Course progress update requires a non-empty courseId');
    }
    return {
      'uid': uid,
      'courseId': resolvedCourseId,
      'overall': overall.toMap(),
      'papers': papers,
      'chapters': chapters,
      'lastUpdated': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
      'schemaVersion': schemaVersion ?? currentSchemaVersion,
    };
  }

  UserProgress copyWith({
    String? uid,
    String? courseId,
    bool clearCourseId = false,
    ProgressOverall? overall,
    Map<String, dynamic>? papers,
    Map<String, dynamic>? chapters,
    DateTime? lastUpdated,
    String? appVersion,
    int? schemaVersion,
  }) {
    return UserProgress(
      uid: uid ?? this.uid,
      courseId: clearCourseId ? null : (courseId ?? this.courseId),
      overall: overall ?? this.overall,
      papers: papers ?? this.papers,
      chapters: chapters ?? this.chapters,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      appVersion: appVersion ?? this.appVersion,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class ProgressOverall {
  const ProgressOverall({
    required this.completion,
    required this.accuracy,
    required this.chaptersCompleted,
    required this.totalChapters,
    required this.questionsAttempted,
    required this.questionsCorrect,
  });

  static const ProgressOverall zero = ProgressOverall(
    completion: 0,
    accuracy: 0,
    chaptersCompleted: 0,
    totalChapters: 0,
    questionsAttempted: 0,
    questionsCorrect: 0,
  );

  final num completion;
  final num accuracy;
  final int chaptersCompleted;
  final int totalChapters;
  final int questionsAttempted;
  final int questionsCorrect;

  factory ProgressOverall.fromMap(Map<String, dynamic> data) {
    return ProgressOverall(
      completion: (data['completion'] as num?) ?? 0,
      accuracy: (data['accuracy'] as num?) ?? 0,
      chaptersCompleted: (data['chaptersCompleted'] as num?)?.toInt() ?? 0,
      totalChapters: (data['totalChapters'] as num?)?.toInt() ?? 0,
      questionsAttempted: (data['questionsAttempted'] as num?)?.toInt() ?? 0,
      questionsCorrect: (data['questionsCorrect'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completion': completion,
      'accuracy': accuracy,
      'chaptersCompleted': chaptersCompleted,
      'totalChapters': totalChapters,
      'questionsAttempted': questionsAttempted,
      'questionsCorrect': questionsCorrect,
    };
  }
}
