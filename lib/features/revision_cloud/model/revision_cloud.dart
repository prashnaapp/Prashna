import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore revision document (`user_revision/{uid}`).
class RevisionCloud {
  const RevisionCloud({
    required this.uid,
    required this.courseId,
    required this.wrongQuestions,
    required this.weakQuestions,
    required this.frequentlyWrongQuestions,
    required this.updatedAt,
    required this.appVersion,
  });

  final String uid;
  final String? courseId;
  final List<String> wrongQuestions;
  final List<String> weakQuestions;
  final List<String> frequentlyWrongQuestions;
  final DateTime? updatedAt;
  final String? appVersion;

  factory RevisionCloud.initial({
    required String uid,
    required String appVersion,
  }) {
    return RevisionCloud(
      uid: uid,
      courseId: null,
      wrongQuestions: const [],
      weakQuestions: const [],
      frequentlyWrongQuestions: const [],
      updatedAt: null,
      appVersion: appVersion,
    );
  }

  factory RevisionCloud.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return RevisionCloud(
      uid: (data['uid'] as String?) ?? uid,
      courseId: data['courseId'] as String?,
      wrongQuestions: _readStringList(data['wrongQuestions']),
      weakQuestions: _readStringList(data['weakQuestions']),
      frequentlyWrongQuestions:
          _readStringList(data['frequentlyWrongQuestions']),
      updatedAt: _readTimestamp(data['updatedAt']),
      appVersion: data['appVersion'] as String?,
    );
  }

  /// Payload for first-time document creation.
  Map<String, dynamic> toCreateMap({required String appVersion}) {
    return {
      'uid': uid,
      'courseId': courseId,
      'wrongQuestions': <String>[],
      'weakQuestions': <String>[],
      'frequentlyWrongQuestions': <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
    };
  }

  /// Full document write for [RevisionCloudRepository.update].
  Map<String, dynamic> toUpdateMap({required String appVersion}) {
    return {
      'uid': uid,
      'courseId': courseId,
      'wrongQuestions': wrongQuestions,
      'weakQuestions': weakQuestions,
      'frequentlyWrongQuestions': frequentlyWrongQuestions,
      'updatedAt': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
    };
  }

  RevisionCloud copyWith({
    String? uid,
    String? courseId,
    bool clearCourseId = false,
    List<String>? wrongQuestions,
    List<String>? weakQuestions,
    List<String>? frequentlyWrongQuestions,
    DateTime? updatedAt,
    String? appVersion,
  }) {
    return RevisionCloud(
      uid: uid ?? this.uid,
      courseId: clearCourseId ? null : (courseId ?? this.courseId),
      wrongQuestions: wrongQuestions ?? this.wrongQuestions,
      weakQuestions: weakQuestions ?? this.weakQuestions,
      frequentlyWrongQuestions:
          frequentlyWrongQuestions ?? this.frequentlyWrongQuestions,
      updatedAt: updatedAt ?? this.updatedAt,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String) item,
    ];
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
