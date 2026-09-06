/// Lifecycle of the bookmark session cache (cloud hydrate).
enum BookmarkLoadState {
  /// No successful load for the current session (or cleared).
  notLoaded,

  /// A cloud read / question resolve is in flight.
  loading,

  /// Cloud read succeeded (document may be empty).
  loaded,

  /// Last read failed; prior successful snapshot is retained when present.
  error,
}

/// Local bookmark metadata for Practice Bits & Current Affairs.
class Bookmark {
  const Bookmark({
    required this.questionId,
    required this.courseId,
    required this.courseName,
    required this.paperId,
    required this.paperName,
    required this.partId,
    required this.partName,
    required this.chapterId,
    required this.chapterName,
    required this.questionType,
    required this.questionTitle,
    required this.createdAt,
    this.majorStudyAreaId,
    this.contentTopicId,
    this.canonicalPartId,
    this.canonicalTopicId,
    this.lessonId,
  });

  final String questionId;
  final String courseId;
  final String courseName;
  final String paperId;
  final String paperName;
  final String partId;
  final String partName;
  final String chapterId;
  final String chapterName;
  final String questionType;
  final String questionTitle;
  final DateTime createdAt;
  final String? majorStudyAreaId;
  final String? contentTopicId;
  final String? canonicalPartId;
  final String? canonicalTopicId;
  final String? lessonId;
}

/// Grouped bookmarks for the Bookmarks screen.
class BookmarkGroup {
  const BookmarkGroup({
    required this.courseName,
    required this.paperName,
    required this.chapterName,
    required this.items,
  });

  final String courseName;
  final String paperName;
  final String chapterName;
  final List<Bookmark> items;
}
