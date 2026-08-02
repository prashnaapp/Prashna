import '../../../question_bank/data/models/question_models.dart';
import '../../../question_bank/data/services/question_service.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../models/bookmark_models.dart';

/// Local bookmark store for Practice Bits & Current Affairs.
class BookmarkService {
  BookmarkService._();

  static final BookmarkService instance = BookmarkService._();

  final List<Bookmark> _bookmarks = [];
  final QuestionService _questions = QuestionService.instance;
  final SyllabusService _syllabus = SyllabusService.instance;

  List<Bookmark> getBookmarks() {
    final items = [..._bookmarks]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  bool isBookmarked(String questionId) {
    return _bookmarks.any((item) => item.questionId == questionId);
  }

  Future<void> toggleBookmark({
    required String questionId,
    String? courseId,
    String? paperId,
    String? partId,
    String? chapterId,
    String? questionType,
    String? questionTitle,
  }) async {
    if (isBookmarked(questionId)) {
      await removeBookmark(questionId);
      return;
    }
    await addBookmark(
      questionId: questionId,
      courseId: courseId,
      paperId: paperId,
      partId: partId,
      chapterId: chapterId,
      questionType: questionType,
      questionTitle: questionTitle,
    );
  }

  Future<void> addBookmark({
    required String questionId,
    String? courseId,
    String? paperId,
    String? partId,
    String? chapterId,
    String? questionType,
    String? questionTitle,
  }) async {
    if (isBookmarked(questionId)) return;

    final question = await _questions.getById(questionId);
    final resolvedCourseId = courseId ?? question?.courseId ?? '';
    final resolvedPaperId = paperId ?? question?.paperId ?? '';
    final resolvedPartId = partId ?? question?.sectionId ?? '';
    final resolvedChapterId = chapterId ?? question?.topicId ?? '';

    final course = _syllabus.getCourseById(resolvedCourseId);
    final paper = _syllabus.getPaper(
      courseId: resolvedCourseId,
      paperId: resolvedPaperId,
    );
    final part = _syllabus.getSection(
      courseId: resolvedCourseId,
      paperId: resolvedPaperId,
      sectionId: resolvedPartId,
    );
    final chapter = _syllabus.getTopic(
      courseId: resolvedCourseId,
      paperId: resolvedPaperId,
      sectionId: resolvedPartId,
      topicId: resolvedChapterId,
    );

    final title = questionTitle ?? question?.question ?? 'Question';
    final truncated = title.length > 90 ? '${title.substring(0, 90)}…' : title;

    _bookmarks.add(
      Bookmark(
        questionId: questionId,
        courseId: resolvedCourseId,
        courseName: course?.name ??
            (resolvedCourseId == 'current-affairs'
                ? 'Current Affairs'
                : resolvedCourseId),
        paperId: resolvedPaperId,
        paperName: paper?.title ?? resolvedPaperId,
        partId: resolvedPartId,
        partName: part?.title ?? resolvedPartId,
        chapterId: resolvedChapterId,
        chapterName: chapter?.title ?? resolvedChapterId,
        questionType: questionType ??
            question?.questionType.name ??
            QuestionType.practice.name,
        questionTitle: truncated,
        createdAt: DateTime.now(),
      ),
    );

    await _questions.setBookmarked(questionId, value: true);
  }

  Future<void> removeBookmark(String questionId) async {
    _bookmarks.removeWhere((item) => item.questionId == questionId);
    await _questions.setBookmarked(questionId, value: false);
  }

  Future<void> clearBookmarks() async {
    final ids = [for (final item in _bookmarks) item.questionId];
    _bookmarks.clear();
    for (final id in ids) {
      await _questions.setBookmarked(id, value: false);
    }
  }

  List<BookmarkGroup> getGroupedBookmarks() {
    final map = <String, List<Bookmark>>{};
    for (final item in getBookmarks()) {
      final key =
          '${item.courseName}||${item.paperName}||${item.chapterName}';
      map.putIfAbsent(key, () => []).add(item);
    }

    final groups = <BookmarkGroup>[];
    for (final entry in map.entries) {
      final parts = entry.key.split('||');
      groups.add(
        BookmarkGroup(
          courseName: parts[0],
          paperName: parts[1],
          chapterName: parts[2],
          items: entry.value,
        ),
      );
    }
    groups.sort((a, b) {
      final course = a.courseName.compareTo(b.courseName);
      if (course != 0) return course;
      final paper = a.paperName.compareTo(b.paperName);
      if (paper != 0) return paper;
      return a.chapterName.compareTo(b.chapterName);
    });
    return groups;
  }
}
