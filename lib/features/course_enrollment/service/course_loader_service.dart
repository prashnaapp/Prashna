import 'package:flutter/foundation.dart';

import '../../authentication/services/auth_service.dart';
import '../model/course.dart';
import '../model/course_context.dart';
import '../model/user_course.dart';
import '../repository/course_repository.dart';
import '../repository/user_course_repository.dart';
import 'course_catalog_service.dart';

/// Read-only startup loader for published courses + current enrollment.
///
/// Published catalog comes from [CourseCatalogService].
/// Caches an immutable [CourseContext] in memory. Never writes to Firestore.
class CourseLoaderService {
  CourseLoaderService({
    CourseCatalogService? catalogService,
    CourseRepository? courseRepository,
    UserCourseRepository? userCourseRepository,
  })  : _catalog = catalogService ??
            CourseCatalogService(courseRepository: courseRepository),
        _courses = courseRepository ?? CourseRepository(),
        _userCourses = userCourseRepository ?? UserCourseRepository();

  static final CourseLoaderService instance = CourseLoaderService();

  final CourseCatalogService _catalog;
  final CourseRepository _courses;
  final UserCourseRepository _userCourses;

  CourseContext? _current;
  Future<CourseContext>? _inFlight;

  /// Last successfully loaded context, if any.
  CourseContext? get current => _current;

  /// Loads published courses and the signed-in user's enrollment (read-only).
  ///
  /// On any failure, caches and returns [CourseContext.empty] — never throws.
  Future<CourseContext> load() {
    return _inFlight ??= _loadInternal().whenComplete(() {
      _inFlight = null;
    });
  }

  Future<CourseContext> _loadInternal() async {
    try {
      final uid = AuthService.instance.currentUser?.uid;

      final published = await _catalog.loadPublishedCourses();

      UserCourse? enrollment;
      if (uid != null && uid.isNotEmpty) {
        enrollment = await _userCourses.loadEnrollment(uid);
      }

      final activeCourse = await _resolveActiveCourse(
        published: published,
        enrollment: enrollment,
      );

      final context = CourseContext(
        publishedCourses: List<Course>.unmodifiable(published),
        currentEnrollment: enrollment,
        activeCourse: activeCourse,
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
  }

  Future<Course?> _resolveActiveCourse({
    required List<Course> published,
    required UserCourse? enrollment,
  }) async {
    if (enrollment == null) return null;
    if (enrollment.status != UserCourseStatus.active) return null;
    if (enrollment.courseId.isEmpty) return null;

    for (final course in published) {
      if (course.courseId == enrollment.courseId) return course;
    }

    // Enrollment may point at a course not in the published list.
    try {
      return await _courses.loadCourse(enrollment.courseId);
    } catch (error, stack) {
      debugPrint(
        'CourseLoaderService active course lookup failed: $error\n$stack',
      );
      return null;
    }
  }
}
