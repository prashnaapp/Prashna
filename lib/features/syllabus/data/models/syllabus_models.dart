/// Legacy syllabus hierarchy retained for existing consumers:
/// Course → Paper → Section → Topic.
///
/// Canonical fields on [SyllabusPaper], [SyllabusPart], [SyllabusTopic], and
/// [SyllabusLesson] represent the approved hierarchy without reinterpreting
/// legacy `sectionId` or `topicId` values.
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
    this.sections = const [],
    this.majorStudyAreas = const [],
    this.parts = const [],
    this.syllabusUnits = const [],
  });

  final String id;
  final String title;

  /// Legacy Section tree used by existing syllabus UI and adapters.
  final List<SyllabusSection> sections;

  /// Canonical Paper I tree.
  final List<SyllabusMajorStudyArea> majorStudyAreas;

  /// Canonical Papers II–IV tree.
  final List<SyllabusPart> parts;

  /// Paper-I final folders (Paper → Syllabus Unit → Tests).
  ///
  /// Used by Group-II Paper-I and Group-III Paper-I. Papers with Parts keep
  /// this empty and store units on [SyllabusPart.syllabusUnits].
  final List<SyllabusUnit> syllabusUnits;

  bool get hasCanonicalPaperIContent => majorStudyAreas.isNotEmpty;
  bool get hasCanonicalParts => parts.isNotEmpty;
  bool get hasDirectSyllabusUnits => syllabusUnits.isNotEmpty;
  bool get hasPartSyllabusUnits =>
      parts.any((part) => part.syllabusUnits.isNotEmpty);
}

/// Canonical Paper I node: Paper → Major Study Area → Content Topic.
class SyllabusMajorStudyArea {
  const SyllabusMajorStudyArea({
    required this.id,
    required this.officialName,
    required this.displayName,
    required this.contentTopics,
  });

  final String id;
  final String officialName;
  final String displayName;
  final List<SyllabusContentTopic> contentTopics;
}

/// Canonical Paper I content node.
class SyllabusContentTopic {
  const SyllabusContentTopic({
    required this.id,
    required this.officialName,
    required this.displayName,
  });

  final String id;
  final String officialName;
  final String displayName;
}

/// Canonical Papers II–IV node. This replaces Section only in the canonical
/// tree; legacy [SyllabusSection] remains available for existing consumers.
class SyllabusPart {
  const SyllabusPart({
    required this.id,
    required this.officialName,
    required this.displayName,
    this.topics = const [],
    this.syllabusUnits = const [],
  });

  final String id;
  final String officialName;
  final String displayName;

  /// Group-II canonical Topic → Lesson tree.
  final List<SyllabusTopic> topics;

  /// Student-facing folders (Part → Syllabus Unit → Tests).
  ///
  /// Group-II: copied from official Topics (Topic → Lesson retained).
  /// Group-III: official numbered units (no Topic/Lesson children).
  final List<SyllabusUnit> syllabusUnits;
}

/// Final student-facing syllabus folder before Tests.
///
/// There is no Lesson / Topic child under this node.
class SyllabusUnit {
  const SyllabusUnit({
    required this.id,
    required this.officialName,
    required this.displayName,
  });

  final String id;
  final String officialName;
  final String displayName;
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
    this.officialName,
    this.displayName,
    this.lessons = const [],
  });

  final String id;
  final String title;
  final String? officialName;
  final String? displayName;
  final List<SyllabusLesson> lessons;

  String get resolvedOfficialName => officialName ?? title;
  String get resolvedDisplayName => displayName ?? title;
}

/// Canonical lowest syllabus/content unit before Questions.
class SyllabusLesson {
  const SyllabusLesson({
    required this.id,
    required this.officialName,
    required this.displayName,
    required this.sourceType,
  });

  final String id;
  final String officialName;
  final String displayName;
  final String sourceType;
}
