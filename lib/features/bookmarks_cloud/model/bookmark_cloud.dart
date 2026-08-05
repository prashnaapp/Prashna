import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore bookmarks document (`user_bookmarks/{uid}`).
class BookmarkCloud {
  const BookmarkCloud({
    required this.uid,
    required this.courseId,
    required this.questionIds,
    required this.updatedAt,
    required this.appVersion,
  });

  final String uid;
  final String? courseId;
  final List<String> questionIds;
  final DateTime? updatedAt;
  final String? appVersion;

  factory BookmarkCloud.initial({
    required String uid,
    required String appVersion,
  }) {
    return BookmarkCloud(
      uid: uid,
      courseId: null,
      questionIds: const [],
      updatedAt: null,
      appVersion: appVersion,
    );
  }

  factory BookmarkCloud.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    final idsRaw = data['questionIds'];
    return BookmarkCloud(
      uid: (data['uid'] as String?) ?? uid,
      courseId: data['courseId'] as String?,
      questionIds: idsRaw is List
          ? [
              for (final id in idsRaw)
                if (id is String) id,
            ]
          : const [],
      updatedAt: _readTimestamp(data['updatedAt']),
      appVersion: data['appVersion'] as String?,
    );
  }

  /// Payload for first-time document creation.
  Map<String, dynamic> toCreateMap({required String appVersion}) {
    return {
      'uid': uid,
      'courseId': courseId,
      'questionIds': <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
    };
  }

  /// Full document write for [BookmarkCloudRepository.update].
  Map<String, dynamic> toUpdateMap({required String appVersion}) {
    return {
      'uid': uid,
      'courseId': courseId,
      'questionIds': questionIds,
      'updatedAt': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
    };
  }

  BookmarkCloud copyWith({
    String? uid,
    String? courseId,
    bool clearCourseId = false,
    List<String>? questionIds,
    DateTime? updatedAt,
    String? appVersion,
  }) {
    return BookmarkCloud(
      uid: uid ?? this.uid,
      courseId: clearCourseId ? null : (courseId ?? this.courseId),
      questionIds: questionIds ?? this.questionIds,
      updatedAt: updatedAt ?? this.updatedAt,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
