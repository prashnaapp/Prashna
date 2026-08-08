import '../model/course.dart';
import '../repository/course_repository.dart';

/// Read-only published course catalog.
///
/// Uses existing [CourseRepository] — no duplicate Firestore boundary.
/// Filters unpublished courses and sorts by [Course.sortOrder] ascending.
/// No writes, payments, or enrollment logic.
class CourseCatalogService {
  CourseCatalogService({CourseRepository? courseRepository})
    : _courses = courseRepository ?? CourseRepository();

  static final CourseCatalogService instance = CourseCatalogService();

  final CourseRepository _courses;

  /// Loads published courses, sorted by [Course.sortOrder] ascending.
  ///
  /// Unpublished documents are ignored even if the repository returns them.
  Future<List<Course>> loadPublishedCourses() async {
    final courses = await _courses.loadPublishedCourses();

    final published = [
      for (final course in courses)
        if (course.isPublished) course,
    ];

    published.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return List<Course>.unmodifiable(published);
  }
}
