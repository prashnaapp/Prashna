import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../authentication/services/user_session_state_coordinator.dart';
import '../../../bookmarks_cloud/model/bookmark_cloud.dart';
import '../../../bookmarks_cloud/service/bookmark_cloud_service.dart';
import '../../../question_activity/data/models/question_activity_models.dart';
import '../../../question_activity/data/question_activity_context_factory.dart';
import '../../../question_activity/services/bookmark_eligibility.dart';
import '../../../question_activity/services/question_activity_reporter.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../../question_bank/data/services/question_service.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../models/bookmark_models.dart';

/// Session bookmark store keyed by global questionId.
///
/// After hydrate, the in-memory session cache is the UI source of truth.
/// Mutation cloud sync remains asynchronous and best-effort. Catalog hydrate
/// reads `user_bookmarks/{uid}` once per session unless refreshed.
class BookmarkService {
  BookmarkService._({
    QuestionService? questionService,
    SyllabusService? syllabusService,
    BookmarkCloudService? cloudService,
    Future<BookmarkCloud?> Function(String uid)? cloudLoader,
    Future<void> Function(BookmarkCloud snapshot)? cloudSync,
    UserSessionStateCoordinator? sessionCoordinator,
  }) : _questions = questionService ?? QuestionService.instance,
       _syllabus = syllabusService ?? SyllabusService.instance,
       _cloudOverride = cloudService,
       _cloudLoaderOverride = cloudLoader,
       _cloudSyncOverride = cloudSync,
       _sessions = sessionCoordinator ?? UserSessionStateCoordinator.instance;

  static final BookmarkService instance = BookmarkService._()
    .._registerSessionReset();

  final List<Bookmark> _bookmarks = [];
  final QuestionService _questions;
  final SyllabusService _syllabus;
  final UserSessionStateCoordinator _sessions;
  final BookmarkCloudService? _cloudOverride;
  final Future<BookmarkCloud?> Function(String uid)? _cloudLoaderOverride;
  final Future<void> Function(BookmarkCloud snapshot)? _cloudSyncOverride;
  BookmarkCloudService? _cloudCache;

  BookmarkLoadState _loadState = BookmarkLoadState.notLoaded;
  Object? _loadError;
  Future<BookmarkLoadState>? _loadInFlight;
  int _loadGeneration = 0;

  BookmarkCloudService get _cloud =>
      _cloudCache ??= _cloudOverride ?? BookmarkCloudService.instance;

  @visibleForTesting
  BookmarkService.debug({
    required QuestionService questionService,
    SyllabusService? syllabusService,
    BookmarkCloudService? cloudService,
    Future<BookmarkCloud?> Function(String uid)? cloudLoader,
    Future<void> Function(BookmarkCloud snapshot)? cloudSync,
    UserSessionStateCoordinator? sessionCoordinator,
  }) : this._(
         questionService: questionService,
         syllabusService: syllabusService,
         cloudService: cloudService,
         cloudLoader: cloudLoader,
         cloudSync: cloudSync,
         sessionCoordinator: sessionCoordinator,
       );

  /// Coalesces rapid sync requests so only the latest snapshot is written.
  int _cloudSyncGeneration = 0;

  BookmarkLoadState get bookmarkLoadState => _loadState;

  Object? get bookmarkLoadError => _loadError;

  /// Current session bookmarks (newest first). Same as [getBookmarks].
  List<Bookmark> get currentBookmarks => getBookmarks();

  Future<BookmarkCloud?> Function(String uid) get _loadCloud {
    final override = _cloudLoaderOverride;
    if (override != null) return override;
    return _cloud.load;
  }

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
    String? majorStudyAreaId,
    String? contentTopicId,
    String? canonicalPartId,
    String? canonicalTopicId,
    String? lessonId,
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
      majorStudyAreaId: majorStudyAreaId,
      contentTopicId: contentTopicId,
      canonicalPartId: canonicalPartId,
      canonicalTopicId: canonicalTopicId,
      lessonId: lessonId,
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
    String? majorStudyAreaId,
    String? contentTopicId,
    String? canonicalPartId,
    String? canonicalTopicId,
    String? lessonId,
    String? questionType,
    String? questionTitle,
  }) async {
    final session = _sessions.capture();
    if (isBookmarked(questionId)) return;

    final question = await _questions.getById(questionId);
    if (!_sessions.isCurrent(session)) return;

    // H2.8F-4B: never persist unresolved or blocked-source IDs.
    if (question == null || !BookmarkEligibility.forQuestion(question)) {
      return;
    }

    final resolvedCourseId = courseId ?? question.courseId;
    final resolvedPaperId = paperId ?? question.paperId;
    final resolvedPartId = partId ?? question.sectionId;
    final resolvedChapterId = chapterId ?? question.topicId;
    final canonicalAreaId = majorStudyAreaId ?? question.majorStudyAreaId;
    final canonicalContentId = contentTopicId ?? question.contentTopicId;
    final canonicalPart = canonicalPartId ?? question.partId;
    final canonicalTopic = canonicalTopicId ?? question.syllabus?.topicId;
    final canonicalLesson = lessonId ?? question.lessonId;

    final course = _syllabus.getCourseById(resolvedCourseId);
    final paper = _syllabus.getPaper(
      courseId: resolvedCourseId,
      paperId: resolvedPaperId,
    );
    final legacyPart = _syllabus.getSection(
      courseId: resolvedCourseId,
      paperId: resolvedPaperId,
      sectionId: resolvedPartId,
    );
    final legacyChapter = _syllabus.getTopic(
      courseId: resolvedCourseId,
      paperId: resolvedPaperId,
      sectionId: resolvedPartId,
      topicId: resolvedChapterId,
    );
    final area = canonicalAreaId == null
        ? null
        : _syllabus.getMajorStudyArea(
            courseId: resolvedCourseId,
            paperId: resolvedPaperId,
            majorStudyAreaId: canonicalAreaId,
          );
    final content = canonicalAreaId == null || canonicalContentId == null
        ? null
        : _syllabus.getContentTopic(
            courseId: resolvedCourseId,
            paperId: resolvedPaperId,
            majorStudyAreaId: canonicalAreaId,
            contentTopicId: canonicalContentId,
          );
    final canonicalPartModel = canonicalPart == null
        ? null
        : _syllabus.getPart(
            courseId: resolvedCourseId,
            paperId: resolvedPaperId,
            partId: canonicalPart,
          );
    final canonicalTopicModel = canonicalPart == null || canonicalTopic == null
        ? null
        : _syllabus.getCanonicalTopic(
            courseId: resolvedCourseId,
            paperId: resolvedPaperId,
            partId: canonicalPart,
            topicId: canonicalTopic,
          );
    final lesson =
        canonicalPart == null ||
            canonicalTopic == null ||
            canonicalLesson == null
        ? null
        : _syllabus.getLesson(
            courseId: resolvedCourseId,
            paperId: resolvedPaperId,
            partId: canonicalPart,
            topicId: canonicalTopic,
            lessonId: canonicalLesson,
          );

    final title = questionTitle ?? question.question;
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
        partId: canonicalPart ?? resolvedPartId,
        partName:
            area?.displayName ??
            canonicalPartModel?.displayName ??
            legacyPart?.title ??
            resolvedPartId,
        chapterId: canonicalTopic ?? resolvedChapterId,
        chapterName:
            lesson?.displayName ??
            content?.displayName ??
            canonicalTopicModel?.resolvedDisplayName ??
            legacyChapter?.title ??
            resolvedChapterId,
        questionType:
            questionType ??
            question.questionType.name,
        questionTitle: truncated,
        createdAt: DateTime.now(),
        majorStudyAreaId: canonicalAreaId,
        contentTopicId: canonicalContentId,
        canonicalPartId: canonicalPart,
        canonicalTopicId: canonicalTopic,
        lessonId: canonicalLesson,
      ),
    );

    QuestionActivityReporter.instance.reportBookmarkAdded(
      context: QuestionActivityContextFactory.forQuestion(
        questionId: questionId,
        courseId: resolvedCourseId,
        sourceModule: _activityModuleForBookmark(
          courseId: resolvedCourseId,
          questionType: questionType ?? question.questionType.name,
        ),
        sourceType: _activityTypeForBookmark(
          courseId: resolvedCourseId,
          questionType: questionType ?? question.questionType.name,
        ),
        paperId: resolvedPaperId,
        sectionId: resolvedPartId,
        partId: canonicalPart,
        topicId: canonicalTopic ?? resolvedChapterId,
        lessonId: canonicalLesson,
        majorStudyAreaId: canonicalAreaId,
        contentTopicId: canonicalContentId,
      ),
      session: session,
    );

    await _questions.setBookmarked(questionId, value: true);
    if (_sessions.isCurrent(session)) {
      _scheduleCloudSync(session: session);
    }
  }

  Future<void> removeBookmark(String questionId) async {
    final session = _sessions.capture();
    Bookmark? existing;
    for (final item in _bookmarks) {
      if (item.questionId == questionId) {
        existing = item;
        break;
      }
    }
    _bookmarks.removeWhere((item) => item.questionId == questionId);
    QuestionActivityReporter.instance.reportBookmarkRemoved(
      context: QuestionActivityContextFactory.forQuestion(
        questionId: questionId,
        courseId: existing?.courseId,
        sourceModule: _activityModuleForBookmark(
          courseId: existing?.courseId,
          questionType: existing?.questionType,
        ),
        sourceType: QuestionActivitySourceType.questionViewer,
        paperId: existing?.paperId,
        partId: existing?.canonicalPartId ?? existing?.partId,
        topicId: existing?.canonicalTopicId ?? existing?.chapterId,
        lessonId: existing?.lessonId,
        majorStudyAreaId: existing?.majorStudyAreaId,
        contentTopicId: existing?.contentTopicId,
      ),
      session: session,
    );
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

  /// Loads `user_bookmarks/{uid}` into the session cache for the active user.
  ///
  /// Missing documents become [BookmarkLoadState.loaded] with an empty list.
  /// Failures set [BookmarkLoadState.error] without inventing empty success.
  ///
  /// Does not automatically re-read while the session cache is already
  /// [BookmarkLoadState.loaded] unless [force] is true.
  Future<BookmarkLoadState> loadCurrentUserBookmarks({bool force = false}) {
    return _hydrate(force: force);
  }

  /// Forces a fresh cloud read and replaces the session cache when successful.
  Future<BookmarkLoadState> refreshCurrentUserBookmarks() {
    return _hydrate(force: true);
  }

  /// Clears only local bookmark state for the previous authenticated session.
  /// Cloud bookmark documents are not deleted or modified.
  void clear() {
    _bookmarks.clear();
    _cloudSyncGeneration++;
    _loadGeneration++;
    _loadInFlight = null;
    _loadState = BookmarkLoadState.notLoaded;
    _loadError = null;
  }

  @visibleForTesting
  void debugSetBookmarks(Iterable<Bookmark> bookmarks) {
    _bookmarks
      ..clear()
      ..addAll(bookmarks);
    _loadState = BookmarkLoadState.loaded;
    _loadError = null;
  }

  void _registerSessionReset() {
    UserSessionStateCoordinator.instance.register(clear);
  }

  Future<BookmarkLoadState> _hydrate({required bool force}) async {
    final session = _sessions.capture();
    final uid = session.uid?.trim();
    if (uid == null || uid.isEmpty) {
      _loadState = BookmarkLoadState.notLoaded;
      _loadError = null;
      return BookmarkLoadState.notLoaded;
    }

    if (!force && _loadState == BookmarkLoadState.loaded) {
      return BookmarkLoadState.loaded;
    }

    final inFlight = _loadInFlight;
    if (!force && inFlight != null) {
      return inFlight;
    }

    final loadGeneration = ++_loadGeneration;
    final future = _runHydrate(
      uid: uid,
      session: session,
      loadGeneration: loadGeneration,
    );
    _loadInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_loadInFlight, future)) {
        _loadInFlight = null;
      }
    }
  }

  Future<BookmarkLoadState> _runHydrate({
    required String uid,
    required UserSessionIdentity session,
    required int loadGeneration,
  }) async {
    if (!_sessions.isCurrent(session) || loadGeneration != _loadGeneration) {
      return BookmarkLoadState.notLoaded;
    }

    _loadState = BookmarkLoadState.loading;
    _loadError = null;

    // Snapshot local IDs so concurrent add/remove during hydrate can merge.
    final startIds = {for (final item in _bookmarks) item.questionId};

    try {
      final loaded = await _loadCloud(uid);

      if (!_sessions.isCurrent(session) || loadGeneration != _loadGeneration) {
        return BookmarkLoadState.notLoaded;
      }

      final activeUid = _sessions.activeUid?.trim();
      if (activeUid == null || activeUid.isEmpty || activeUid != uid) {
        return BookmarkLoadState.notLoaded;
      }

      if (loaded != null && loaded.uid != uid) {
        _loadState = BookmarkLoadState.error;
        _loadError = StateError(
          'Bookmark payload uid mismatch: expected $uid got ${loaded.uid}',
        );
        return BookmarkLoadState.error;
      }

      // Ignore lossy document courseId — resolve each question individually.
      final rawIds = loaded?.questionIds ?? const <String>[];
      final dedupedIds = _dedupePreserveOrder(rawIds);

      final resolved = <Bookmark>[];
      final baseTime = DateTime.now();
      for (var i = 0; i < dedupedIds.length; i++) {
        if (!_sessions.isCurrent(session) || loadGeneration != _loadGeneration) {
          return BookmarkLoadState.notLoaded;
        }
        final id = dedupedIds[i];
        final question = await _questions.getById(id);
        if (!_sessions.isCurrent(session) || loadGeneration != _loadGeneration) {
          return BookmarkLoadState.notLoaded;
        }
        if (question == null) continue; // stale id — skip safely
        resolved.add(
          _composeBookmark(
            questionId: id,
            question: question,
            createdAt: baseTime.subtract(Duration(microseconds: i)),
          ),
        );
      }

      if (!_sessions.isCurrent(session) || loadGeneration != _loadGeneration) {
        return BookmarkLoadState.notLoaded;
      }

      final activeUidAfter = _sessions.activeUid?.trim();
      if (activeUidAfter == null ||
          activeUidAfter.isEmpty ||
          activeUidAfter != uid) {
        return BookmarkLoadState.notLoaded;
      }

      final removedDuring = startIds.difference({
        for (final item in _bookmarks) item.questionId,
      });
      final cloudIdSet = {for (final b in resolved) b.questionId};
      final extras = [
        for (final item in _bookmarks)
          if (!startIds.contains(item.questionId) &&
              !cloudIdSet.contains(item.questionId))
            item,
      ];

      final merged = <Bookmark>[
        for (final item in resolved)
          if (!removedDuring.contains(item.questionId)) item,
        ...extras,
      ];

      _bookmarks
        ..clear()
        ..addAll(merged);

      for (final item in merged) {
        await _questions.setBookmarked(item.questionId, value: true);
        if (!_sessions.isCurrent(session) || loadGeneration != _loadGeneration) {
          return BookmarkLoadState.notLoaded;
        }
      }

      _loadError = null;
      _loadState = BookmarkLoadState.loaded;
      return BookmarkLoadState.loaded;
    } catch (error) {
      if (!_sessions.isCurrent(session) || loadGeneration != _loadGeneration) {
        return BookmarkLoadState.notLoaded;
      }
      _loadError = error;
      _loadState = BookmarkLoadState.error;
      // Keep prior successful bookmarks if any (do not invent empty success).
      return BookmarkLoadState.error;
    }
  }

  /// Deduplicates IDs preserving first occurrence and original order.
  static List<String> _dedupePreserveOrder(List<String> ids) {
    final seen = <String>{};
    final out = <String>[];
    for (final id in ids) {
      final trimmed = id.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed)) out.add(trimmed);
    }
    return out;
  }

  Bookmark _composeBookmark({
    required String questionId,
    Question? question,
    String? courseId,
    String? paperId,
    String? partId,
    String? chapterId,
    String? majorStudyAreaId,
    String? contentTopicId,
    String? canonicalPartId,
    String? canonicalTopicId,
    String? lessonId,
    String? questionType,
    String? questionTitle,
    required DateTime createdAt,
  }) {
    // Question.courseId is authoritative when present — never invent from
    // the lossy cloud document courseId field.
    final resolvedCourseId = courseId ?? question?.courseId ?? '';
    final resolvedPaperId = paperId ?? question?.paperId ?? '';
    final resolvedPartId = partId ?? question?.sectionId ?? '';
    final resolvedChapterId = chapterId ?? question?.topicId ?? '';
    final canonicalAreaId = majorStudyAreaId ?? question?.majorStudyAreaId;
    final canonicalContentId = contentTopicId ?? question?.contentTopicId;
    final canonicalPart = canonicalPartId ?? question?.partId;
    final canonicalTopic = canonicalTopicId ?? question?.syllabus?.topicId;
    final canonicalLesson = lessonId ?? question?.lessonId;

    final course = _syllabus.getCourseById(resolvedCourseId);
    final paper = _syllabus.getPaper(
      courseId: resolvedCourseId,
      paperId: resolvedPaperId,
    );
    final legacyPart = _syllabus.getSection(
      courseId: resolvedCourseId,
      paperId: resolvedPaperId,
      sectionId: resolvedPartId,
    );
    final legacyChapter = _syllabus.getTopic(
      courseId: resolvedCourseId,
      paperId: resolvedPaperId,
      sectionId: resolvedPartId,
      topicId: resolvedChapterId,
    );
    final area = canonicalAreaId == null
        ? null
        : _syllabus.getMajorStudyArea(
            courseId: resolvedCourseId,
            paperId: resolvedPaperId,
            majorStudyAreaId: canonicalAreaId,
          );
    final content = canonicalAreaId == null || canonicalContentId == null
        ? null
        : _syllabus.getContentTopic(
            courseId: resolvedCourseId,
            paperId: resolvedPaperId,
            majorStudyAreaId: canonicalAreaId,
            contentTopicId: canonicalContentId,
          );
    final canonicalPartModel = canonicalPart == null
        ? null
        : _syllabus.getPart(
            courseId: resolvedCourseId,
            paperId: resolvedPaperId,
            partId: canonicalPart,
          );
    final canonicalTopicModel = canonicalPart == null || canonicalTopic == null
        ? null
        : _syllabus.getCanonicalTopic(
            courseId: resolvedCourseId,
            paperId: resolvedPaperId,
            partId: canonicalPart,
            topicId: canonicalTopic,
          );
    final lesson =
        canonicalPart == null ||
            canonicalTopic == null ||
            canonicalLesson == null
        ? null
        : _syllabus.getLesson(
            courseId: resolvedCourseId,
            paperId: resolvedPaperId,
            partId: canonicalPart,
            topicId: canonicalTopic,
            lessonId: canonicalLesson,
          );

    final title = questionTitle ?? question?.question ?? 'Question';
    final truncated = title.length > 90 ? '${title.substring(0, 90)}…' : title;

    return Bookmark(
      questionId: questionId,
      courseId: resolvedCourseId,
      courseName:
          course?.name ??
          (resolvedCourseId == 'current-affairs'
              ? 'Current Affairs'
              : resolvedCourseId),
      paperId: resolvedPaperId,
      paperName: paper?.title ?? resolvedPaperId,
      partId: canonicalPart ?? resolvedPartId,
      partName:
          area?.displayName ??
          canonicalPartModel?.displayName ??
          legacyPart?.title ??
          resolvedPartId,
      chapterId: canonicalTopic ?? resolvedChapterId,
      chapterName:
          lesson?.displayName ??
          content?.displayName ??
          canonicalTopicModel?.resolvedDisplayName ??
          legacyChapter?.title ??
          resolvedChapterId,
      questionType:
          questionType ??
          question?.questionType.name ??
          QuestionType.practice.name,
      questionTitle: truncated,
      createdAt: createdAt,
      majorStudyAreaId: canonicalAreaId,
      contentTopicId: canonicalContentId,
      canonicalPartId: canonicalPart,
      canonicalTopicId: canonicalTopic,
      lessonId: canonicalLesson,
    );
  }

  // ---------------------------------------------------------------------------
  // Question activity (shared reporter — does not replace cloud sync)
  // ---------------------------------------------------------------------------

  QuestionActivitySourceModule _activityModuleForBookmark({
    String? courseId,
    String? questionType,
  }) {
    final course = courseId?.trim().toLowerCase();
    if (course == 'current-affairs') {
      return QuestionActivitySourceModule.currentAffairs;
    }
    final type = questionType?.trim().toLowerCase() ?? '';
    if (type.contains('revision')) {
      return QuestionActivitySourceModule.revision;
    }
    if (type == 'practice' || type.isEmpty) {
      return QuestionActivitySourceModule.practice;
    }
    // Catalog modes recorded as questionType = TestMode.name
    if (type == 'topic' ||
        type == 'section' ||
        type == 'paper' ||
        type == 'mock' ||
        type == 'previousyear' ||
        type == 'grand') {
      return QuestionActivitySourceModule.unknown;
    }
    return QuestionActivitySourceModule.other;
  }

  QuestionActivitySourceType _activityTypeForBookmark({
    String? courseId,
    String? questionType,
  }) {
    final course = courseId?.trim().toLowerCase();
    if (course == 'current-affairs') {
      return QuestionActivitySourceType.unknown;
    }
    final type = questionType?.trim().toLowerCase() ?? '';
    if (type.contains('revision')) {
      return QuestionActivitySourceType.revisionPractice;
    }
    if (type == 'practice' || type.isEmpty) {
      return QuestionActivitySourceType.topicPractice;
    }
    return QuestionActivitySourceType.unknown;
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
