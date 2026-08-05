import 'course.dart';
import 'user_course.dart';

/// Immutable in-memory snapshot of catalog + enrollment for the signed-in user.
class CourseContext {
  const CourseContext({
    required this.publishedCourses,
    required this.currentEnrollment,
    required this.activeCourse,
  });

  static const CourseContext empty = CourseContext(
    publishedCourses: [],
    currentEnrollment: null,
    activeCourse: null,
  );

  final List<Course> publishedCourses;
  final UserCourse? currentEnrollment;
  final Course? activeCourse;

  bool get hasEnrollment => currentEnrollment != null;

  bool get hasActiveCourse => activeCourse != null;
}
