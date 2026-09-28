import '../../syllabus/data/models/syllabus_models.dart';
import '../../syllabus/services/syllabus_service.dart';
import 'admin_test_hierarchy.dart';

/// Syllabus location selected while browsing Chapter Questions.
///
/// IDs match the persisted Chapter attribution already used by import and
/// the question form. This is not a Test Series bank.
class AdminChapterQuestionContext {
  const AdminChapterQuestionContext({
    this.courseId,
    this.paperId,
    this.majorStudyAreaId,
    this.contentTopicId,
    this.partId,
    this.topicId,
    this.lessonId,
    this.syllabusUnitId,
  });

  final String? courseId;
  final String? paperId;
  final String? majorStudyAreaId;
  final String? contentTopicId;
  final String? partId;
  final String? topicId;
  final String? lessonId;
  final String? syllabusUnitId;

  AdminChapterQuestionContext copyWith({
    String? courseId,
    String? paperId,
    String? majorStudyAreaId,
    String? contentTopicId,
    String? partId,
    String? topicId,
    String? lessonId,
    String? syllabusUnitId,
    bool clearPaper = false,
    bool clearArea = false,
    bool clearContentTopic = false,
    bool clearPart = false,
    bool clearTopic = false,
    bool clearLesson = false,
    bool clearUnit = false,
  }) {
    return AdminChapterQuestionContext(
      courseId: courseId ?? this.courseId,
      paperId: clearPaper ? null : (paperId ?? this.paperId),
      majorStudyAreaId: clearArea
          ? null
          : (majorStudyAreaId ?? this.majorStudyAreaId),
      contentTopicId: clearContentTopic
          ? null
          : (contentTopicId ?? this.contentTopicId),
      partId: clearPart ? null : (partId ?? this.partId),
      topicId: clearTopic ? null : (topicId ?? this.topicId),
      lessonId: clearLesson ? null : (lessonId ?? this.lessonId),
      syllabusUnitId: clearUnit
          ? null
          : (syllabusUnitId ?? this.syllabusUnitId),
    );
  }

  /// True when the selected node is the persisted terminal for this branch.
  bool isTerminal(SyllabusService syllabus) {
    final course = courseId;
    final paperId = this.paperId;
    if (course == null || paperId == null) return false;
    final paper = syllabus.getPaper(courseId: course, paperId: paperId);
    if (paper == null) return false;

    if (course == 'group-iii') {
      return _present(syllabusUnitId);
    }
    if (paper.hasCanonicalPaperIContent) {
      return _present(contentTopicId);
    }
    // Topic is the Chapter terminal. Legacy lessonId is not a folder.
    return _present(topicId) && _topic(paper) != null;
  }

  String pathLabel(SyllabusService syllabus) {
    final parts = <String>[];
    final course = courseId == null ? null : syllabus.getCourseById(courseId!);
    if (courseId != null) parts.add(course?.name ?? courseId!);
    final paper = (courseId == null || paperId == null)
        ? null
        : syllabus.getPaper(courseId: courseId!, paperId: paperId!);
    if (paper != null) parts.add(AdminTestHierarchy.paperLabel(paper));
    if (paper != null && _present(majorStudyAreaId)) {
      final area = paper.majorStudyAreas
          .where((item) => item.id == majorStudyAreaId)
          .firstOrNull;
      parts.add(area?.displayName ?? majorStudyAreaId!);
    }
    if (paper != null &&
        _present(contentTopicId) &&
        _present(majorStudyAreaId)) {
      final area = paper.majorStudyAreas
          .where((item) => item.id == majorStudyAreaId)
          .firstOrNull;
      final topic = area?.contentTopics
          .where((item) => item.id == contentTopicId)
          .firstOrNull;
      final topicName = topic?.displayName ?? contentTopicId!;
      final areaName = area?.displayName;
      final sameWrapper =
          areaName != null &&
          normalizeChapterFolderName(areaName) ==
              normalizeChapterFolderName(topicName);
      if (!sameWrapper) parts.add(topicName);
    }
    if (paper != null && _present(partId)) {
      final part = paper.parts.where((item) => item.id == partId).firstOrNull;
      parts.add(part?.displayName ?? partId!);
    }
    final topic = paper == null ? null : _topic(paper);
    if (topic != null) parts.add(topic.resolvedDisplayName);
    if (topic != null && _present(lessonId)) {
      final lesson = topic.lessons
          .where((item) => item.id == lessonId)
          .firstOrNull;
      parts.add(lesson?.displayName ?? lessonId!);
    }
    if (paper != null && _present(syllabusUnitId)) {
      final units = paper.hasDirectSyllabusUnits
          ? paper.syllabusUnits
          : paper.parts
                .where((part) => part.id == partId)
                .expand((part) => part.syllabusUnits);
      final unit = units.where((item) => item.id == syllabusUnitId).firstOrNull;
      parts.add(unit?.displayName ?? syllabusUnitId!);
    }
    return parts.join('  ›  ');
  }

  SyllabusTopic? _topic(SyllabusPaper paper) {
    if (!_present(partId) || !_present(topicId)) return null;
    for (final part in paper.parts) {
      if (part.id != partId) continue;
      for (final topic in part.topics) {
        if (topic.id == topicId) return topic;
      }
    }
    return null;
  }

  static bool _present(String? value) =>
      value != null && value.trim().isNotEmpty;
}

/// Folder labels compared when a Paper I content topic is only a duplicate
/// wrapper for its major study area.
String normalizeChapterFolderName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// The content topic to open directly when it is the area's only child and
/// the names match. Distinct topics stay on their own screen.
SyllabusContentTopic? paperISameNameContentTopic(SyllabusMajorStudyArea area) {
  if (area.contentTopics.length != 1) return null;
  final topic = area.contentTopics.single;
  if (normalizeChapterFolderName(topic.displayName) !=
      normalizeChapterFolderName(area.displayName)) {
    return null;
  }
  return topic;
}
