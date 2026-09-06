/// Hub destinations on Revision Center home.
enum RevisionHubType {
  wrongQuestions,
  weakTopics,
  bookmarked,
  frequentlyIncorrect,
}

class RevisionHubItem {
  const RevisionHubItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.count,
    this.hasError = false,
  });

  final RevisionHubType type;
  final String title;
  final String subtitle;
  final int count;

  /// When true, [count] must not be shown as Empty — load failed.
  final bool hasError;
}

/// Grouped Question Bank items for Wrong / Frequently Incorrect lists.
class RevisionQuestionItem {
  const RevisionQuestionItem({
    required this.questionId,
    required this.title,
    required this.courseId,
    required this.courseName,
    required this.paperId,
    required this.paperName,
    required this.chapterId,
    required this.chapterName,
    this.wrongCount,
    this.majorStudyAreaId,
    this.contentTopicId,
    this.canonicalPartId,
    this.canonicalTopicId,
    this.lessonId,
  });

  final String questionId;
  final String title;
  final String courseId;
  final String courseName;
  final String paperId;
  final String paperName;
  final String chapterId;
  final String chapterName;
  final int? wrongCount;
  final String? majorStudyAreaId;
  final String? contentTopicId;
  final String? canonicalPartId;
  final String? canonicalTopicId;
  final String? lessonId;
}

class RevisionQuestionGroup {
  const RevisionQuestionGroup({
    required this.courseName,
    required this.paperName,
    required this.chapterName,
    required this.items,
  });

  final String courseName;
  final String paperName;
  final String chapterName;
  final List<RevisionQuestionItem> items;
}

class RevisionWeakTopicGroup {
  const RevisionWeakTopicGroup({required this.paperName, required this.topics});

  final String paperName;
  final List<WeakTopicRevision> topics;
}

/// Weak topic row for revision UI (backed by ProgressService WeakTopic).
class WeakTopicRevision {
  const WeakTopicRevision({
    required this.topicId,
    required this.topicName,
    required this.paperId,
    required this.paperName,
    required this.accuracy,
    required this.attempts,
    required this.courseId,
  });

  final String topicId;
  final String topicName;
  final String paperId;
  final String paperName;
  final double accuracy;
  final int attempts;
  final String courseId;
}

/// Legacy collection type kept for session recording / quiz builder.
enum RevisionCollectionType {
  wrongQuestions,
  bookmarked,
  weakTopics,
  frequentlyIncorrect,
}

class RevisionCollection {
  const RevisionCollection({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.questionIds,
  });

  final RevisionCollectionType type;
  final String title;
  final String subtitle;
  final List<String> questionIds;

  int get count => questionIds.length;
  bool get isEmpty => questionIds.isEmpty;
  bool get isNotEmpty => questionIds.isNotEmpty;
}
