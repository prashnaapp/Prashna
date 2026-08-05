import '../model/course.dart';
import '../model/user_course.dart';
import '../repository/course_repository.dart';
import '../repository/user_course_repository.dart';

/// App-facing API for course catalog + enrollment.
///
/// Phase A: infrastructure only — delegates to repositories.
/// Not wired to Auth, Progress, UI, payments, or subscriptions.
class CourseEnrollmentService {
  CourseEnrollmentService({
    CourseRepository? courseRepository,
    UserCourseRepository? userCourseRepository,
  })  : _courses = courseRepository ?? CourseRepository(),
        _userCourses = userCourseRepository ?? UserCourseRepository();

  static final CourseEnrollmentService instance = CourseEnrollmentService();

  final CourseRepository _courses;
  final UserCourseRepository _userCourses;

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
}
