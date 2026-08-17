import '../../course_enrollment/model/course.dart';
import '../../course_enrollment/model/course_context.dart';
import '../../course_enrollment/model/user_course.dart';
import '../../course_enrollment/service/course_loader_service.dart';
import '../model/course_access_decision.dart';
import '../model/course_entitlement.dart';

/// Authoritative course-access / entitlement checks.
///
/// Single source of truth for: "Does this signed-in user currently have access
/// to course X?"
///
/// Rules:
/// - Free catalog courses (`courses.isFree`) are accessible without entitlement.
/// - Paid courses require an active [CourseEntitlement] for the exact courseId.
/// - Payment / transaction records are never consulted here.
///
/// Uses [CourseLoaderService.current] only — no Firestore writes, no payments.
class SubscriptionAccessService {
  SubscriptionAccessService({
    CourseLoaderService? courseLoader,
    DateTime Function()? now,
  }) : _courseLoader = courseLoader ?? CourseLoaderService.instance,
       _now = now ?? DateTime.now;

  static final SubscriptionAccessService instance = SubscriptionAccessService();

  final CourseLoaderService _courseLoader;
  final DateTime Function() _now;

  CourseContext? get _context => _courseLoader.current;

  /// Authoritative course access gate (free course OR active entitlement).
  ///
  /// Prefer this (or [canAccessCourse]) from Question Bank, Test Series,
  /// Home, and other paid features. Do not reimplement access locally.
  Future<bool> hasCourseAccess(String courseId) => canAccessCourse(courseId);

  /// Alias of [hasCourseAccess] — kept for existing call sites.
  Future<bool> canAccessCourse(String courseId) async {
    final decision = await evaluateCourseAccess(courseId);
    return decision.allowed;
  }

  /// True when an active entitlement exists for [courseId] (excludes free).
  Future<bool> hasActiveEntitlement(String courseId) async {
    final entitlement = entitlementFor(courseId);
    return entitlement?.grantsAccess ?? false;
  }

  /// True when the user has any active entitlement for any course.
  Future<bool> hasActiveSubscription() async {
    final enrollments = _context?.enrollments;
    if (enrollments == null || enrollments.isEmpty) return false;
    for (final enrollment in enrollments) {
      if (_entitlementFrom(enrollment).grantsAccess) return true;
    }
    return false;
  }

  /// True when [courseId] is marked free in the loaded published catalog.
  Future<bool> isFreeCourse(String courseId) async {
    final course = _findCourse(courseId);
    return course?.isFree ?? false;
  }

  /// Effective entitlement for [courseId], if an enrollment document exists.
  CourseEntitlement? entitlementFor(String courseId) {
    final enrollment = _context?.enrollmentFor(courseId);
    if (enrollment == null) return null;
    return _entitlementFrom(enrollment);
  }

  /// All entitlements currently loaded for the signed-in user.
  ///
  /// Suitable for future admin / profile visibility (status, start, expiry,
  /// source). Does not query other users.
  List<CourseEntitlement> listEntitlements() {
    final enrollments = _context?.enrollments;
    if (enrollments == null || enrollments.isEmpty) return const [];
    return [
      for (final enrollment in enrollments) _entitlementFrom(enrollment),
    ];
  }

  /// Detailed decision for tests, guards, and paywall UI.
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

    final entitlement = entitlementFor(courseId);
    if (entitlement != null && entitlement.grantsAccess) {
      return CourseAccessDecision.allow(
        courseId,
        CourseAccessReason.activeEnrollment,
      );
    }

    if (entitlement != null) {
      switch (entitlement.status) {
        case CourseEntitlementStatus.expired:
          return CourseAccessDecision.deny(
            courseId,
            CourseAccessReason.expiredEntitlement,
          );
        case CourseEntitlementStatus.revoked:
          return CourseAccessDecision.deny(
            courseId,
            CourseAccessReason.revokedEntitlement,
          );
        case CourseEntitlementStatus.active:
          break;
      }
    }

    return CourseAccessDecision.deny(courseId, CourseAccessReason.denied);
  }

  CourseEntitlement _entitlementFrom(UserCourse enrollment) {
    return CourseEntitlement.fromUserCourse(enrollment, now: _now);
  }

  Course? _findCourse(String courseId) {
    final context = _context;
    if (context == null) return null;

    for (final course in context.publishedCourses) {
      if (course.courseId == courseId) return course;
    }

    return null;
  }
}

/// Preferred name for the authoritative course-access service.
///
/// Same implementation as [SubscriptionAccessService] — use either name;
/// do not invent a second access-check path.
typedef CourseAccessService = SubscriptionAccessService;
