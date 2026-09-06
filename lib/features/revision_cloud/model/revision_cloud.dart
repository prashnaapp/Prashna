import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore revision document (`user_revision/{uid}`).
///
/// Catalog revision is server-authored. [mistakeCounts] is written by Cloud
/// Functions and required for Frequently Incorrect; client sync must not drop it.
class RevisionCloud {
  const RevisionCloud({
    required this.uid,
    required this.courseId,
    required this.wrongQuestions,
    required this.weakQuestions,
    required this.frequentlyWrongQuestions,
    required this.mistakeCounts,
    required this.updatedAt,
    required this.appVersion,
    this.authority,
  });

  final String uid;
  final String? courseId;
  final List<String> wrongQuestions;
  final List<String> weakQuestions;
  final List<String> frequentlyWrongQuestions;

  /// Per-question wrong tallies from server (`mistakeCounts` map).
  final Map<String, int> mistakeCounts;

  final DateTime? updatedAt;
  final String? appVersion;

  /// Server write marker when present (e.g. `server_verified`).
  final String? authority;

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
      mistakeCounts: const {},
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
      frequentlyWrongQuestions: _readStringList(
        data['frequentlyWrongQuestions'],
      ),
      mistakeCounts: _readIntMap(data['mistakeCounts']),
      updatedAt: _readTimestamp(data['updatedAt']),
      appVersion: data['appVersion'] as String?,
      authority: data['authority'] as String?,
    );
  }

  /// Empty but loaded revision for a signed-in user with no cloud document.
  factory RevisionCloud.emptyForUser(String uid) {
    return RevisionCloud(
      uid: uid,
      courseId: null,
      wrongQuestions: const [],
      weakQuestions: const [],
      frequentlyWrongQuestions: const [],
      mistakeCounts: const {},
      updatedAt: null,
      appVersion: null,
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
      'mistakeCounts': <String, int>{},
      'updatedAt': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
    };
  }

  /// Full document write for [RevisionCloudRepository.update].
  ///
  /// Includes [mistakeCounts] so a client write cannot wipe server tallies.
  Map<String, dynamic> toUpdateMap({required String appVersion}) {
    return {
      'uid': uid,
      'courseId': courseId,
      'wrongQuestions': wrongQuestions,
      'weakQuestions': weakQuestions,
      'frequentlyWrongQuestions': frequentlyWrongQuestions,
      'mistakeCounts': mistakeCounts,
      'updatedAt': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
      if (authority != null) 'authority': authority,
    };
  }

  RevisionCloud copyWith({
    String? uid,
    String? courseId,
    bool clearCourseId = false,
    List<String>? wrongQuestions,
    List<String>? weakQuestions,
    List<String>? frequentlyWrongQuestions,
    Map<String, int>? mistakeCounts,
    DateTime? updatedAt,
    String? appVersion,
    String? authority,
    bool clearAuthority = false,
  }) {
    return RevisionCloud(
      uid: uid ?? this.uid,
      courseId: clearCourseId ? null : (courseId ?? this.courseId),
      wrongQuestions: wrongQuestions ?? this.wrongQuestions,
      weakQuestions: weakQuestions ?? this.weakQuestions,
      frequentlyWrongQuestions:
          frequentlyWrongQuestions ?? this.frequentlyWrongQuestions,
      mistakeCounts: mistakeCounts ?? this.mistakeCounts,
      updatedAt: updatedAt ?? this.updatedAt,
      appVersion: appVersion ?? this.appVersion,
      authority: clearAuthority ? null : (authority ?? this.authority),
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String) item,
    ];
  }

  static Map<String, int> _readIntMap(dynamic value) {
    if (value is! Map) return const {};
    final out = <String, int>{};
    value.forEach((key, raw) {
      if (key is! String) return;
      if (raw is int) {
        out[key] = raw;
      } else if (raw is num) {
        out[key] = raw.toInt();
      }
    });
    return Map.unmodifiable(out);
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
