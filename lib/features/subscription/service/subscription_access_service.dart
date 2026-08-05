import '../../course_enrollment/model/course.dart';
import '../../course_enrollment/model/course_context.dart';
import '../../course_enrollment/model/user_course.dart';
import '../../course_enrollment/service/course_loader_service.dart';
import '../model/course_access_decision.dart';

/// Read-only subscription / course access checks.
///
/// Uses [CourseLoaderService.current] only — no Firestore, no payments.
class SubscriptionAccessService {
  SubscriptionAccessService({
    CourseLoaderService? courseLoader,
    DateTime Function()? now,
  })  : _courseLoader = courseLoader ?? CourseLoaderService.instance,
        _now = now ?? DateTime.now;

  static final SubscriptionAccessService instance = SubscriptionAccessService();

  final CourseLoaderService _courseLoader;
  final DateTime Function() _now;

  CourseContext? get _context => _courseLoader.current;

  /// True when the user has a valid active enrollment for [courseId].
  ///
  /// Does not grant access solely because a course is free — use
  /// [canAccessCourse] for the full gate.
  Future<bool> hasCourseAccess(String courseId) async {
    return _hasValidEnrollmentFor(courseId);
  }

  /// True when [currentEnrollment] is active and not expired.
  ///
  /// Reflects "has an active subscription/enrollment" in Phase A terms
  /// (enrollment document), not a separate payments product.
  Future<bool> hasActiveSubscription() async {
    final enrollment = _context?.currentEnrollment;
    if (enrollment == null) return false;
    return _isEnrollmentActive(enrollment);
  }

  /// True when [courseId] is marked free in the loaded catalog / active course.
  Future<bool> isFreeCourse(String courseId) async {
    final course = _findCourse(courseId);
    return course?.isFree ?? false;
  }

  /// Full access gate: free course OR valid enrollment for [courseId].
  Future<bool> canAccessCourse(String courseId) async {
    final decision = await evaluateCourseAccess(courseId);
    return decision.allowed;
  }

  /// Detailed decision for tests and future paywall UI.
  Future<CourseAccessDecision> evaluateCourseAccess(String courseId) async {
    if (_context == null) {
      return CourseAccessDecision.deny(
        courseId,
        CourseAccessReason.contextUnavailable,
      );
    }

    if (await isFreeCourse(courseId)) {
      return CourseAccessDecision.allow(
        courseId,
        CourseAccessReason.freeCourse,
      );
    }

    if (_hasValidEnrollmentFor(courseId)) {
      return CourseAccessDecision.allow(
        courseId,
        CourseAccessReason.activeEnrollment,
      );
    }

    return CourseAccessDecision.deny(
      courseId,
      CourseAccessReason.denied,
    );
  }

  bool _hasValidEnrollmentFor(String courseId) {
    final enrollment = _context?.currentEnrollment;
    if (enrollment == null) return false;
    if (enrollment.courseId != courseId) return false;
    return _isEnrollmentActive(enrollment);
  }

  bool _isEnrollmentActive(UserCourse enrollment) {
    if (enrollment.status != UserCourseStatus.active) return false;
    final expiresAt = enrollment.expiresAt;
    if (expiresAt == null) return true;
    return expiresAt.isAfter(_now());
  }

  Course? _findCourse(String courseId) {
    final context = _context;
    if (context == null) return null;

    for (final course in context.publishedCourses) {
      if (course.courseId == courseId) return course;
    }

    final active = context.activeCourse;
    if (active != null && active.courseId == courseId) return active;

    return null;
  }
}
