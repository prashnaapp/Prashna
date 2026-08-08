import 'package:flutter/foundation.dart';

import '../../authentication/services/auth_service.dart';
import '../model/course.dart';
import '../model/course_context.dart';
import '../model/user_course.dart';
import '../repository/course_repository.dart';
import '../repository/user_course_repository.dart';
import 'course_catalog_service.dart';

/// Read-only startup loader for published courses + user enrollments.
///
/// Published catalog comes from [CourseCatalogService].
/// Enrollments come from `user_courses/{uid}/courses/*`.
/// Caches an immutable [CourseContext] in memory. Never writes enrollments
/// (legacy migration may write via [UserCourseRepository] during load).
class CourseLoaderService {
  CourseLoaderService({
    CourseCatalogService? catalogService,
    CourseRepository? courseRepository,
    UserCourseRepository? userCourseRepository,
  })  : _catalogOverride = catalogService,
        _courseRepositoryOverride = courseRepository,
        _userCoursesOverride = userCourseRepository;

  static final CourseLoaderService instance = CourseLoaderService();

  final CourseCatalogService? _catalogOverride;
  final CourseRepository? _courseRepositoryOverride;
  final UserCourseRepository? _userCoursesOverride;

  CourseCatalogService? _catalogCache;
  UserCourseRepository? _userCoursesCache;

  CourseCatalogService get _catalog =>
      _catalogCache ??= _catalogOverride ??
          CourseCatalogService(courseRepository: _courseRepositoryOverride);

  UserCourseRepository get _userCourses =>
      _userCoursesCache ??=
          _userCoursesOverride ?? UserCourseRepository();

  CourseContext? _current;
  Future<CourseContext>? _inFlight;

  /// Last successfully loaded context, if any.
  CourseContext? get current => _current;

  /// Loads published courses and the signed-in user's enrollments.
  ///
  /// On any failure, caches and returns [CourseContext.empty] — never throws.
  Future<CourseContext> load() {
    return _inFlight ??= _loadInternal().whenComplete(() {
      _inFlight = null;
    });
  }

  /// Forces a fresh load so [current] reflects the latest Firestore state.
  ///
  /// Drops any in-flight [load] coalesce — used after enrollment activation.
  Future<CourseContext> reload() {
    _inFlight = null;
    return load();
  }

  Future<CourseContext> _loadInternal() async {
    try {
      final uid = AuthService.instance.currentUser?.uid;

      final published = await _catalog.loadPublishedCourses();

      List<UserCourse> enrollments = const [];
      if (uid != null && uid.isNotEmpty) {
        enrollments = await _userCourses.loadEnrollments(uid);
      }

      final context = CourseContext(
        publishedCourses: List<Course>.unmodifiable(published),
        enrollments: List<UserCourse>.unmodifiable(enrollments),
      );
      _current = context;
      return context;
    } catch (error, stack) {
      debugPrint('CourseLoaderService.load failed: $error\n$stack');
      _current = CourseContext.empty;
      return CourseContext.empty;
    }
  }

  /// Clears the in-memory cache (e.g. after sign-out in a later milestone).
  void clear() {
    _current = null;
    _inFlight = null;
  }

  /// Test-only: inject a [CourseContext] without hitting Firestore.
  @visibleForTesting
  void debugSetCurrent(CourseContext? context) {
    _current = context;
  }
}
