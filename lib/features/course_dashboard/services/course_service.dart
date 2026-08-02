import '../../syllabus/data/models/syllabus_models.dart';
import '../../syllabus/services/syllabus_service.dart';
import '../models/course_model.dart';

/// Course catalog API for Home. Delegates to [SyllabusService].
class CourseService {
  CourseService._();

  static final CourseService instance = CourseService._();

  List<CourseModel> getAllCourses() {
    return SyllabusService.instance
        .getAllCourses()
        .map(_map)
        .toList(growable: false);
  }

  CourseModel? getCourseById(String id) {
    final course = SyllabusService.instance.getCourseById(id);
    return course == null ? null : _map(course);
  }

  List<CourseModel> getEnrolledCourses() {
    return SyllabusService.instance
        .getEnrolledCourses()
        .map(_map)
        .toList(growable: false);
  }

  List<CourseModel> getAvailableCourses() {
    return SyllabusService.instance
        .getAvailableCourses()
        .map(_map)
        .toList(growable: false);
  }

  List<CourseModel> getLaunchingSoonCourses() {
    return SyllabusService.instance
        .getLaunchingSoonCourses()
        .map(_map)
        .toList(growable: false);
  }

  CourseModel _map(SyllabusCourse course) {
    return CourseModel(
      id: course.id,
      name: course.name,
      subtitle: course.subtitle,
      totalMarks: course.totalMarks,
      totalPapers: course.totalPapers,
      isEnrolled: course.isEnrolled,
      isAvailable: course.isAvailable,
      icon: course.icon,
    );
  }
}
