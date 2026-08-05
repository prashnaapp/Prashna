import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore user progress document (`user_progress/{uid}`).
class UserProgress {
  const UserProgress({
    required this.uid,
    required this.courseId,
    required this.overall,
    required this.papers,
    required this.chapters,
    required this.lastUpdated,
    required this.appVersion,
  });

  final String uid;
  final String? courseId;
  final ProgressOverall overall;
  final Map<String, dynamic> papers;
  final Map<String, dynamic> chapters;
  final DateTime? lastUpdated;
  final String? appVersion;

  factory UserProgress.initial({
    required String uid,
    required String appVersion,
  }) {
    return UserProgress(
      uid: uid,
      courseId: null,
      overall: ProgressOverall.zero,
      papers: const {},
      chapters: const {},
      lastUpdated: null,
      appVersion: appVersion,
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
    );
  }

  /// Payload for first-time document creation.
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

  /// Full document write for [ProgressCloudRepository.update].
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

  UserProgress copyWith({
    String? uid,
    String? courseId,
    bool clearCourseId = false,
    ProgressOverall? overall,
    Map<String, dynamic>? papers,
    Map<String, dynamic>? chapters,
    DateTime? lastUpdated,
    String? appVersion,
  }) {
    return UserProgress(
      uid: uid ?? this.uid,
      courseId: clearCourseId ? null : (courseId ?? this.courseId),
      overall: overall ?? this.overall,
      papers: papers ?? this.papers,
      chapters: chapters ?? this.chapters,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      appVersion: appVersion ?? this.appVersion,
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
