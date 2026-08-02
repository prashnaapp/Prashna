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
