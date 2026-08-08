import 'package:cloud_firestore/cloud_firestore.dart';

/// Enrollment status for [UserCourse].
enum UserCourseStatus { active, inactive }

/// How the user obtained access to the course.
enum UserCourseSource { free, purchase, admin }

/// Firestore enrollment document (`user_courses/{uid}/courses/{courseId}`).
///
/// Legacy flat documents lived at `user_courses/{uid}` and are migrated into
/// the subcollection without deleting the parent.
class UserCourse {
  const UserCourse({
    required this.uid,
    required this.courseId,
    required this.enrolledAt,
    required this.status,
    required this.source,
    required this.expiresAt,
    this.updatedAt,
  });

  final String uid;
  final String courseId;
  final DateTime? enrolledAt;
  final UserCourseStatus status;
  final UserCourseSource source;
  final DateTime? expiresAt;
  final DateTime? updatedAt;

  factory UserCourse.fromFirestore(
    String uid,
    Map<String, dynamic> data, {
    String? courseIdFallback,
  }) {
    return UserCourse(
      uid: (data['uid'] as String?) ?? uid,
      courseId: (data['courseId'] as String?) ?? courseIdFallback ?? '',
      enrolledAt: _readTimestamp(data['enrolledAt']),
      status: _parseStatus(data['status'] as String?),
      source: _parseSource(data['source'] as String?),
      expiresAt: _readTimestamp(data['expiresAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
    );
  }

  /// First activation write — [enrolledAt] and [updatedAt] are server timestamps.
  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'courseId': courseId,
      'enrolledAt': FieldValue.serverTimestamp(),
      'status': status.name,
      'source': source.name,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Update write — preserves [enrolledAt] when already set; always refreshes
  /// [updatedAt].
  Map<String, dynamic> toUpdateMap() {
    return {
      'uid': uid,
      'courseId': courseId,
      'enrolledAt': enrolledAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(enrolledAt!),
      'status': status.name,
      'source': source.name,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Payload used when copying a legacy parent doc into the subcollection.
  Map<String, dynamic> toLegacyMigrationMap() {
    return {
      'uid': uid,
      'courseId': courseId,
      'enrolledAt': enrolledAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(enrolledAt!),
      'status': status.name,
      'source': source.name,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  static UserCourseStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'inactive':
        return UserCourseStatus.inactive;
      case 'active':
      default:
        return UserCourseStatus.active;
    }
  }

  static UserCourseSource _parseSource(String? raw) {
    switch (raw) {
      case 'purchase':
        return UserCourseSource.purchase;
      case 'admin':
        return UserCourseSource.admin;
      case 'free':
      default:
        return UserCourseSource.free;
    }
  }

  /// Parses activation [source] strings for [CourseEnrollmentService].
  static UserCourseSource sourceFromString(String source) {
    return _parseSource(source.trim().toLowerCase());
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
