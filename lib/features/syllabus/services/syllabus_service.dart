import '../data/models/syllabus_models.dart';
import '../data/syllabus_dummy_data.dart';

/// Syllabus API. UI must never read [SyllabusDummyData] directly.
class SyllabusService {
  SyllabusService._();

  static final SyllabusService instance = SyllabusService._();

  List<SyllabusCourse> getAllCourses() =>
      List.unmodifiable(SyllabusDummyData.all);

  /// MVP available exams (Group-II, Group-III).
  List<SyllabusCourse> getAvailableCourses() => List.unmodifiable(
        SyllabusDummyData.all.where((course) => course.isAvailable),
      );

  /// MVP launching-soon exams (Police SI, Constable).
  List<SyllabusCourse> getLaunchingSoonCourses() => List.unmodifiable(
        SyllabusDummyData.all.where((course) => !course.isAvailable),
      );

  List<SyllabusCourse> getEnrolledCourses() => List.unmodifiable(
        SyllabusDummyData.all.where((course) => course.isEnrolled),
      );

  SyllabusCourse? getCourseById(String id) {
    for (final course in SyllabusDummyData.all) {
      if (course.id == id) return course;
    }
    return null;
  }

  SyllabusPaper? getPaper({
    required String courseId,
    required String paperId,
  }) {
    final course = getCourseById(courseId);
    if (course == null) return null;
    for (final paper in course.papers) {
      if (paper.id == paperId) return paper;
    }
    return null;
  }

  SyllabusSection? getSection({
    required String courseId,
    required String paperId,
    required String sectionId,
  }) {
    final paper = getPaper(courseId: courseId, paperId: paperId);
    if (paper == null) return null;
    for (final section in paper.sections) {
      if (section.id == sectionId) return section;
    }
    return null;
  }

  SyllabusTopic? getTopic({
    required String courseId,
    required String paperId,
    required String sectionId,
    required String topicId,
  }) {
    final section = getSection(
      courseId: courseId,
      paperId: paperId,
      sectionId: sectionId,
    );
    if (section == null) return null;
    for (final topic in section.topics) {
      if (topic.id == topicId) return topic;
    }
    return null;
  }
}
