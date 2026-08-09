import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../authentication/services/user_session_state_coordinator.dart';
import '../../../bookmarks_cloud/model/bookmark_cloud.dart';
import '../../../bookmarks_cloud/service/bookmark_cloud_service.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../../question_bank/data/services/question_service.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../models/bookmark_models.dart';

/// Local bookmark store for Practice Bits & Current Affairs.
///
/// Local list remains the source of truth. Cloud sync is asynchronous and best-effort.
class BookmarkService {
  BookmarkService._({
    QuestionService? questionService,
    SyllabusService? syllabusService,
    BookmarkCloudService? cloudService,
    Future<void> Function(BookmarkCloud snapshot)? cloudSync,
    UserSessionStateCoordinator? sessionCoordinator,
  }) : _questions = questionService ?? QuestionService.instance,
       _syllabus = syllabusService ?? SyllabusService.instance,
       _cloudOverride = cloudService,
       _cloudSyncOverride = cloudSync,
       _sessions = sessionCoordinator ?? UserSessionStateCoordinator.instance;

  static final BookmarkService instance = BookmarkService._()
    .._registerSessionReset();

  final List<Bookmark> _bookmarks = [];
  final QuestionService _questions;
  final SyllabusService _syllabus;
  final UserSessionStateCoordinator _sessions;
  final BookmarkCloudService? _cloudOverride;
  final Future<void> Function(BookmarkCloud snapshot)? _cloudSyncOverride;
  BookmarkCloudService? _cloudCache;

  BookmarkCloudService get _cloud =>
      _cloudCache ??= _cloudOverride ?? BookmarkCloudService.instance;

  @visibleForTesting
  BookmarkService.debug({
    required QuestionService questionService,
    SyllabusService? syllabusService,
    Future<void> Function(BookmarkCloud snapshot)? cloudSync,
    UserSessionStateCoordinator? sessionCoordinator,
  }) : this._(
         questionService: questionService,
         syllabusService: syllabusService,
         cloudSync: cloudSync,
         sessionCoordinator: sessionCoordinator,
       );

  /// Coalesces rapid sync requests so only the latest snapshot is written.
  int _cloudSyncGeneration = 0;

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
    final session = _sessions.capture();
    if (isBookmarked(questionId)) return;

    final question = await _questions.getById(questionId);
    if (!_sessions.isCurrent(session)) return;

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

    if (!_sessions.isCurrent(session)) return;
    _bookmarks.add(
      Bookmark(
        questionId: questionId,
        courseId: resolvedCourseId,
        courseName:
            course?.name ??
            (resolvedCourseId == 'current-affairs'
                ? 'Current Affairs'
                : resolvedCourseId),
        paperId: resolvedPaperId,
        paperName: paper?.title ?? resolvedPaperId,
        partId: resolvedPartId,
        partName: part?.title ?? resolvedPartId,
        chapterId: resolvedChapterId,
        chapterName: chapter?.title ?? resolvedChapterId,
        questionType:
            questionType ??
            question?.questionType.name ??
            QuestionType.practice.name,
        questionTitle: truncated,
        createdAt: DateTime.now(),
      ),
    );

    await _questions.setBookmarked(questionId, value: true);
    if (_sessions.isCurrent(session)) {
      _scheduleCloudSync(session: session);
    }
  }

  Future<void> removeBookmark(String questionId) async {
    final session = _sessions.capture();
    _bookmarks.removeWhere((item) => item.questionId == questionId);
    await _questions.setBookmarked(questionId, value: false);
    if (_sessions.isCurrent(session)) {
      _scheduleCloudSync(session: session);
    }
  }

  Future<void> clearBookmarks() async {
    final session = _sessions.capture();
    final ids = [for (final item in _bookmarks) item.questionId];
    _bookmarks.clear();
    for (final id in ids) {
      await _questions.setBookmarked(id, value: false);
      if (!_sessions.isCurrent(session)) return;
    }
    if (_sessions.isCurrent(session)) {
      _scheduleCloudSync(session: session);
    }
  }

  List<BookmarkGroup> getGroupedBookmarks() {
    final map = <String, List<Bookmark>>{};
    for (final item in getBookmarks()) {
      final key = '${item.courseName}||${item.paperName}||${item.chapterName}';
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

  /// Clears only local bookmark state for the previous authenticated session.
  /// Cloud bookmark documents are not deleted or modified.
  void clear() {
    _bookmarks.clear();
    _cloudSyncGeneration++;
  }

  @visibleForTesting
  void debugSetBookmarks(Iterable<Bookmark> bookmarks) {
    _bookmarks
      ..clear()
      ..addAll(bookmarks);
  }

  void _registerSessionReset() {
    UserSessionStateCoordinator.instance.register(clear);
  }

  // ---------------------------------------------------------------------------
  // Cloud sync (best-effort mirror of local bookmarks)
  // ---------------------------------------------------------------------------

  /// Schedules an async Firestore sync. Rapid calls are coalesced so only the
  /// latest local snapshot is written.
  void _scheduleCloudSync({required UserSessionIdentity session}) {
    // TEMP DEBUG (Milestone 19.1)
    debugPrint('BookmarkService._scheduleCloudSync() called');
    debugPrint('Bookmark count: ${_bookmarks.length}');

    if (!_sessions.isCurrent(session)) return;
    final uid = session.uid;
    // TEMP DEBUG (Milestone 19.1)
    debugPrint('Current Firebase UID: ${uid ?? 'NULL'}');

    if (uid == null || uid.isEmpty) {
      // TEMP DEBUG (Milestone 19.1)
      debugPrint('_scheduleCloudSync returns early: YES (UID null/empty)');
      return;
    }

    // TEMP DEBUG (Milestone 19.1)
    debugPrint('_scheduleCloudSync returns early: NO');

    final generation = ++_cloudSyncGeneration;
    unawaited(_runCloudSync(session: session, generation: generation));
  }

  Future<void> _runCloudSync({
    required UserSessionIdentity session,
    required int generation,
  }) async {
    // Brief delay collapses rapid add/remove/clear into one write.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (generation != _cloudSyncGeneration) return;
    if (!_sessions.isCurrent(session)) return;

    try {
      final snapshot = _buildCloudSnapshot(uid: session.uid!);
      if (generation != _cloudSyncGeneration || !_sessions.isCurrent(session)) {
        return;
      }
      if (_cloudSyncOverride != null) {
        await _cloudSyncOverride(snapshot);
      } else {
        await _cloud.syncSnapshot(snapshot);
      }
    } catch (error, stack) {
      // Never crash — local bookmarks already committed.
      debugPrint('BookmarkService cloud sync failed: $error\n$stack');
    }
  }

  BookmarkCloud _buildCloudSnapshot({required String uid}) {
    final questionIds = [for (final item in _bookmarks) item.questionId];
    final courseId = _bookmarks.isEmpty
        ? null
        : (_bookmarks.last.courseId.isEmpty ? null : _bookmarks.last.courseId);

    return BookmarkCloud(
      uid: uid,
      courseId: courseId,
      questionIds: questionIds,
      updatedAt: null,
      appVersion: null,
    );
  }
}
