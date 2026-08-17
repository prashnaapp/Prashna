/// Why a course access check was allowed or denied.
enum CourseAccessReason {
  /// Course catalog marks the course as free.
  freeCourse,

  /// User has an active, non-expired entitlement for the course.
  activeEnrollment,

  /// Entitlement exists but [expiresAt] is in the past.
  expiredEntitlement,

  /// Entitlement was inactivated or revoked.
  revokedEntitlement,

  /// No free flag and no valid entitlement for this courseId.
  denied,

  /// Course context has not been loaded yet.
  contextUnavailable,
}

/// Immutable result of an access evaluation (useful for tests / future UI).
class CourseAccessDecision {
  const CourseAccessDecision({
    required this.allowed,
    required this.reason,
    required this.courseId,
  });

  final bool allowed;
  final CourseAccessReason reason;
  final String courseId;

  static CourseAccessDecision deny(
    String courseId,
    CourseAccessReason reason,
  ) {
    return CourseAccessDecision(
      allowed: false,
      reason: reason,
      courseId: courseId,
    );
  }

  static CourseAccessDecision allow(
    String courseId,
    CourseAccessReason reason,
  ) {
    return CourseAccessDecision(
      allowed: true,
      reason: reason,
      courseId: courseId,
    );
  }
}
