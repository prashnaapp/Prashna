import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/course.dart';
import '../model/user_course.dart';
import '../repository/course_repository.dart';
import '../repository/user_course_repository.dart';
import 'course_loader_service.dart';

/// App-facing API for course catalog + enrollment.
///
/// Activation writes to `user_courses/{uid}` then reloads [CourseLoaderService].
/// No payments, checkout, or subscription product wiring.
class CourseEnrollmentService {
  CourseEnrollmentService({
    CourseRepository? courseRepository,
    UserCourseRepository? userCourseRepository,
    CourseLoaderService? courseLoader,
  })  : _courses = courseRepository ?? CourseRepository(),
        _userCourses = userCourseRepository ?? UserCourseRepository(),
        _loader = courseLoader ?? CourseLoaderService.instance;

  static final CourseEnrollmentService instance = CourseEnrollmentService();

  final CourseRepository _courses;
  final UserCourseRepository _userCourses;
  final CourseLoaderService _loader;

  Future<List<Course>> loadPublishedCourses() =>
      _courses.loadPublishedCourses();

  Future<Course?> loadCourse(String courseId) =>
      _courses.loadCourse(courseId);

  Future<UserCourse?> loadEnrollment(String uid) =>
      _userCourses.loadEnrollment(uid);

  Future<void> createEnrollment(UserCourse enrollment) =>
      _userCourses.createEnrollment(enrollment);

  Future<void> updateEnrollment(UserCourse enrollment) =>
      _userCourses.updateEnrollment(enrollment);

  /// Creates or updates `user_courses/{uid}` as an active enrollment, then
  /// reloads [CourseLoaderService] so [CourseContext] reflects it immediately.
  ///
  /// [source] is stored as a [UserCourseSource] name (`free`, `purchase`,
  /// `admin`). [enrolledAt] is set only on first activation.
  Future<void> activateEnrollment({
    required String uid,
    required String courseId,
    required String source,
    DateTime? expiresAt,
  }) async {
    // TEMP DEBUG (Milestone 25.1) — remove after verification.
    try {
      debugPrint('activateEnrollment started');
      debugPrint('uid: $uid');
      debugPrint('courseId: $courseId');

      debugPrint('Before loadEnrollment()');
      final existing = await _userCourses.loadEnrollment(uid);
      debugPrint('After loadEnrollment()');
      debugPrint(
        'Existing enrollment found? ${existing == null ? 'NO' : 'YES'}',
      );

      final parsedSource = UserCourse.sourceFromString(source);

      final enrollment = UserCourse(
        uid: uid,
        courseId: courseId,
        enrolledAt: existing?.enrolledAt,
        status: UserCourseStatus.active,
        source: parsedSource,
        expiresAt: expiresAt,
      );

      if (existing == null) {
        debugPrint('Before createEnrollment()');
        await _userCourses.createEnrollment(enrollment);
        debugPrint('After createEnrollment()');
      } else {
        debugPrint('Before updateEnrollment()');
        await _userCourses.updateEnrollment(enrollment);
        debugPrint('After updateEnrollment()');
      }

      debugPrint('Before loader.reload()');
      await _loader.reload();
      debugPrint('After loader.reload()');

      debugPrint('activateEnrollment finished');
    } catch (error, stack) {
      debugPrint('activateEnrollment exception type: ${error.runtimeType}');
      if (error is FirebaseException) {
        debugPrint('activateEnrollment Firebase code: ${error.code}');
        debugPrint('activateEnrollment message: ${error.message}');
      } else {
        debugPrint('activateEnrollment message: $error');
      }
      debugPrint('activateEnrollment stack trace:\n$stack');
      rethrow;
    }
  }
}
