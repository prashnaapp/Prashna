import '../entitlement_mutation_forbidden.dart';
import '../model/course.dart';
import '../model/user_course.dart';
import '../repository/course_repository.dart';
import '../repository/user_course_repository.dart';
import 'course_loader_service.dart';

/// App-facing API for course catalog + enrollment reads.
///
/// IMMEDIATE ENTITLEMENT LOCKDOWN:
/// Student clients must not create/update enrollments (paid or free).
/// Free-course access is granted via authoritative `courses/{id}.isFree`
/// (see [SubscriptionAccessService] / Firestore `canAccessCourse`).
/// Paid entitlements require a future trusted backend writer.
class CourseEnrollmentService {
  CourseEnrollmentService({
    CourseRepository? courseRepository,
    UserCourseRepository? userCourseRepository,
    CourseLoaderService? courseLoader,
  })  : _coursesOverride = courseRepository,
        _userCoursesOverride = userCourseRepository,
        _loaderOverride = courseLoader;

  static final CourseEnrollmentService instance = CourseEnrollmentService();

  final CourseRepository? _coursesOverride;
  final UserCourseRepository? _userCoursesOverride;
  final CourseLoaderService? _loaderOverride;

  CourseRepository? _coursesCache;
  UserCourseRepository? _userCoursesCache;

  CourseRepository get _courses =>
      _coursesOverride ?? (_coursesCache ??= CourseRepository());

  UserCourseRepository get _userCourses =>
      _userCoursesOverride ?? (_userCoursesCache ??= UserCourseRepository());

  CourseLoaderService get _loader =>
      _loaderOverride ?? CourseLoaderService.instance;

  Future<List<Course>> loadPublishedCourses() =>
      _courses.loadPublishedCourses();

  Future<Course?> loadCourse(String courseId) => _courses.loadCourse(courseId);

  Future<List<UserCourse>> loadEnrollments(String uid) =>
      _userCourses.loadEnrollments(uid);

  Future<UserCourse?> loadEnrollment(String uid, String courseId) =>
      _userCourses.loadEnrollment(uid, courseId);

  /// Disabled: clients must not create enrollment documents.
  Future<void> createEnrollment(UserCourse enrollment) async {
    throw const EntitlementMutationForbidden();
  }

  /// Disabled: clients must not update enrollment documents.
  Future<void> updateEnrollment(UserCourse enrollment) async {
    throw const EntitlementMutationForbidden();
  }

  /// Disabled: clients must not activate or renew entitlements.
  ///
  /// Previously this wrote `status: active` with a client-chosen `expiresAt`
  /// and `source`, which allowed unpaid paid-course access.
  Future<void> activateEnrollment({
    required String uid,
    required String courseId,
    required String source,
    DateTime? expiresAt,
  }) async {
    throw const EntitlementMutationForbidden(
      'Client enrollment activation is disabled. '
      'Paid access requires a trusted payment backend.',
    );
  }

  /// Reloads [CourseLoaderService] after an external entitlement change.
  ///
  /// Intended for a future backend-driven refresh path; does not write.
  Future<void> reloadCourseContext() => _loader.reload();
}
