import 'course.dart';
import 'user_course.dart';

/// Immutable in-memory snapshot of catalog + enrollments for the signed-in user.
///
/// [enrollments] is the single source of truth for access checks.
/// Use [enrollmentFor] for course-specific lookups — never authorize from a
/// single "current" enrollment.
class CourseContext {
  const CourseContext({
    required this.publishedCourses,
    required this.enrollments,
  });

  static const CourseContext empty = CourseContext(
    publishedCourses: [],
    enrollments: [],
  );

  final List<Course> publishedCourses;

  /// All course enrollments for the signed-in user (may include expired).
  final List<UserCourse> enrollments;

  bool get hasEnrollment => enrollments.isNotEmpty;

  /// Returns the enrollment for [courseId], if any.
  UserCourse? enrollmentFor(String courseId) {
    for (final enrollment in enrollments) {
      if (enrollment.courseId == courseId) return enrollment;
    }
    return null;
  }
}
