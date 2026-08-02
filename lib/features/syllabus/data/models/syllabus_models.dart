/// Syllabus hierarchy: Course → Paper → Section → Topic (Chapter).
class SyllabusCourse {
  const SyllabusCourse({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.totalMarks,
    required this.isEnrolled,
    required this.isAvailable,
    required this.icon,
    required this.papers,
  });

  final String id;
  final String name;
  final String subtitle;
  final int totalMarks;
  final bool isEnrolled;

  /// MVP catalog flag — available vs launching soon.
  final bool isAvailable;
  final String icon;
  final List<SyllabusPaper> papers;

  int get totalPapers => papers.length;
}

class SyllabusPaper {
  const SyllabusPaper({
    required this.id,
    required this.title,
    required this.sections,
  });

  final String id;
  final String title;
  final List<SyllabusSection> sections;
}

class SyllabusSection {
  const SyllabusSection({
    required this.id,
    required this.title,
    required this.topics,
  });

  final String id;
  final String title;
  final List<SyllabusTopic> topics;
}

class SyllabusTopic {
  const SyllabusTopic({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}
