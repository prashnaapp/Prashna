/// Catalog course for Home / enrollment UI.
/// Backed by syllabus data via [CourseService].
class CourseModel {
  const CourseModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.totalMarks,
    required this.totalPapers,
    required this.isEnrolled,
    required this.isAvailable,
    required this.icon,
  });

  final String id;
  final String name;
  final String subtitle;
  final int totalMarks;
  final int totalPapers;
  final bool isEnrolled;
  final bool isAvailable;
  final String icon;
}
