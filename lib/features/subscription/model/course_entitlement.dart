import '../../course_enrollment/model/user_course.dart';

/// Effective entitlement lifecycle used for access decisions and admin views.
///
/// Stored Firestore enrollment status remains [UserCourseStatus] (`active` /
/// `inactive` / `revoked`). Expiry is evaluated from [expiresAt] at read time
/// and surfaces here as [expired] without rewriting the document.
enum CourseEntitlementStatus { active, expired, revoked }

/// Authoritative course access entitlement for one `(uid, courseId)`.
///
/// Backed by Firestore `user_courses/{uid}/courses/{courseId}` ([UserCourse]).
/// Payment/transaction records are NOT entitlements and must never be used as
/// the application access check.
class CourseEntitlement {
  const CourseEntitlement({
    required this.uid,
    required this.courseId,
    required this.status,
    required this.startedAt,
    required this.source,
    this.expiresAt,
    this.updatedAt,
  });

  final String uid;
  final String courseId;
  final CourseEntitlementStatus status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final UserCourseSource source;
  final DateTime? updatedAt;

  /// True when this entitlement currently grants paid/granted course access.
  bool get grantsAccess => status == CourseEntitlementStatus.active;

  /// Maps a stored [UserCourse] into the effective entitlement view.
  factory CourseEntitlement.fromUserCourse(
    UserCourse enrollment, {
    DateTime Function()? now,
  }) {
    final clock = now ?? DateTime.now;
    return CourseEntitlement(
      uid: enrollment.uid,
      courseId: enrollment.courseId,
      status: resolveStatus(enrollment, now: clock),
      startedAt: enrollment.enrolledAt,
      expiresAt: enrollment.expiresAt,
      source: enrollment.source,
      updatedAt: enrollment.updatedAt,
    );
  }

  /// Effective status: revoked/inactive → revoked; past expiresAt → expired.
  static CourseEntitlementStatus resolveStatus(
    UserCourse enrollment, {
    required DateTime Function() now,
  }) {
    switch (enrollment.status) {
      case UserCourseStatus.inactive:
      case UserCourseStatus.revoked:
        return CourseEntitlementStatus.revoked;
      case UserCourseStatus.active:
        final expiresAt = enrollment.expiresAt;
        if (expiresAt != null && !expiresAt.isAfter(now())) {
          return CourseEntitlementStatus.expired;
        }
        return CourseEntitlementStatus.active;
    }
  }
}
