import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../authentication/services/user_session_state_coordinator.dart';
import '../../bookmarks/data/services/bookmark_service.dart';
import '../../progress/services/progress_service.dart';
import '../../question_bank/data/models/question_models.dart';
import '../../question_bank/data/services/question_service.dart';
import '../../revision_cloud/model/revision_cloud.dart';
import '../../revision_cloud/service/revision_cloud_service.dart';
import '../../syllabus/services/syllabus_service.dart';
import '../../test_engine/data/models/test_engine_models.dart';
import '../../test_engine/services/test_service.dart';
import '../data/models/revision_models.dart';
import '../data/repositories/revision_repository.dart';

/// Builds revision views from Progress, Bookmarks, and Question Bank.
///
/// Local Progress/Question Bank data remains the source of truth.
/// Cloud sync is asynchronous and best-effort.
class RevisionService {
  RevisionService({
    QuestionService? questionService,
    ProgressService? progressService,
    TestService? testService,
    BookmarkService? bookmarkService,
    SyllabusService? syllabusService,
    RevisionRepository? repository,
    RevisionCloudService? cloudService,
    Future<void> Function(RevisionCloud snapshot)? cloudSync,
    UserSessionStateCoordinator? sessionCoordinator,
  }) : _questions = questionService ?? QuestionService.instance,
       _progress = progressService ?? ProgressService.instance,
       _tests = testService ?? TestService(),
       _bookmarks = bookmarkService ?? BookmarkService.instance,
       _syllabus = syllabusService ?? SyllabusService.instance,
       _repository = repository ?? RevisionRepository.instance,
       _cloudOverride = cloudService,
       _cloudSyncOverride = cloudSync,
       _sessions = sessionCoordinator ?? UserSessionStateCoordinator.instance;

  static final RevisionService instance = RevisionService()
    .._registerSessionReset();

  final QuestionService _questions;
  final ProgressService _progress;
  final TestService _tests;
  final BookmarkService _bookmarks;
  final SyllabusService _syllabus;
  final RevisionRepository _repository;
  final UserSessionStateCoordinator _sessions;
  final RevisionCloudService? _cloudOverride;
  final Future<void> Function(RevisionCloud snapshot)? _cloudSyncOverride;
  RevisionCloudService? _cloudCache;

  RevisionCloudService get _cloud =>
      _cloudCache ??= _cloudOverride ?? RevisionCloudService.instance;

  /// Coalesces rapid sync requests so only the latest snapshot is written.
  int _cloudSyncGeneration = 0;
  String? _pendingCloudCourseId;

  Future<List<RevisionHubItem>> loadHubItems({String? courseId}) async {
    final wrong = await _progress.loadWrongQuestionIds();
    final frequent = await _progress.loadFrequentlyWrongIds();
    final weak = await _progress.calculateWeakAreas(
      courseId: courseId,
      limit: 50,
    );
    final bookmarks = _bookmarks.getBookmarks();

    final wrongCount = await _countForCourse(wrong, courseId);
    final frequentCount = await _countForCourse(frequent, courseId);
    final bookmarkCount = courseId == null
        ? bookmarks.length
        : bookmarks.where((b) => b.courseId == courseId).length;
    final weakCount = weak.length;

    scheduleCloudSync(courseId: courseId);

    return [
      RevisionHubItem(
        type: RevisionHubType.wrongQuestions,
        title: 'Wrong Questions',
        subtitle: 'Questions answered incorrectly',
        count: wrongCount,
      ),
      RevisionHubItem(
        type: RevisionHubType.weakTopics,
        title: 'Weak Topics',
        subtitle: 'Automatically generated from Progress',
        count: weakCount,
      ),
      RevisionHubItem(
        type: RevisionHubType.bookmarked,
        title: 'Bookmarked Questions',
        subtitle: 'Saved while practicing',
        count: bookmarkCount,
      ),
      RevisionHubItem(
        type: RevisionHubType.frequentlyIncorrect,
        title: 'Frequently Incorrect',
        subtitle: 'Missed more than once',
        count: frequentCount,
      ),
    ];
  }

  Future<List<RevisionQuestionGroup>> loadWrongQuestionGroups({
    String? courseId,
  }) async {
    final ids = await _progress.loadWrongQuestionIds();
    scheduleCloudSync(courseId: courseId);
    return _groupQuestions(ids, courseId: courseId);
  }

  Future<List<RevisionQuestionGroup>> loadFrequentlyIncorrectGroups({
    String? courseId,
  }) async {
    final stats = await _progress.loadMistakeStats();
    final frequent = stats.where((s) => s.wrongCount >= 2).toList();
    final ids = [for (final s in frequent) s.questionId];
    final wrongCounts = {for (final s in frequent) s.questionId: s.wrongCount};
    scheduleCloudSync(courseId: courseId);
    return _groupQuestions(ids, courseId: courseId, wrongCounts: wrongCounts);
  }

  Future<List<RevisionWeakTopicGroup>> loadWeakTopicGroups({
    String? courseId,
  }) async {
    final weak = await _progress.calculateWeakAreas(
      courseId: courseId,
      limit: 50,
    );
    final map = <String, List<WeakTopicRevision>>{};
    for (final topic in weak) {
      final paperName = topic.paperName?.isNotEmpty == true
          ? topic.paperName!
          : (topic.paperId ?? 'Paper');
      map
          .putIfAbsent(paperName, () => [])
          .add(
            WeakTopicRevision(
              topicId: topic.topicId,
              topicName: topic.topicName,
              paperId: topic.paperId ?? '',
              paperName: paperName,
              accuracy: topic.accuracy,
              attempts: topic.attempts,
              courseId: topic.courseId ?? courseId ?? 'group-ii',
            ),
          );
    }

    final groups =
        map.entries
            .map(
              (e) => RevisionWeakTopicGroup(
                paperName: e.key,
                topics: e.value
                  ..sort((a, b) => a.accuracy.compareTo(b.accuracy)),
              ),
            )
            .toList()
          ..sort((a, b) => a.paperName.compareTo(b.paperName));

    scheduleCloudSync(courseId: courseId);
    return groups;
  }

  Future<Test?> buildTopicRevisionTest({
    required WeakTopicRevision topic,
    int maxQuestions = 20,
  }) async {
    final session = _sessions.capture();
    final questions = await _questions.getByTopic(topic.topicId);
    if (!_sessions.isCurrent(session)) return null;
    final filtered = questions
        .where((q) => q.courseId == topic.courseId || topic.courseId.isEmpty)
        .toList();
    final pool = filtered.isEmpty ? questions : filtered;
    if (pool.isEmpty) return null;

    await _repository.recordSessionStarted(RevisionCollectionType.weakTopics);
    if (!_sessions.isCurrent(session)) return null;
    scheduleCloudSync(courseId: topic.courseId, session: session);

    return _tests.createTestFromQuestions(
      id: 'revision-weak-${topic.topicId}-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Revision · ${topic.topicName}',
      courseId: topic.courseId,
      questions: pool.take(maxQuestions).toList(),
      mode: TestMode.practice,
      instructions: const [
        'This is a weak-topic revision session.',
        'Focus on understanding explanations after each attempt.',
        'Your results will update Progress analytics automatically.',
      ],
    );
  }

  Future<Test?> buildRevisionTest({
    required RevisionCollection collection,
    String courseId = 'group-ii',
    int maxQuestions = 20,
    int? durationMinutes,
  }) async {
    final session = _sessions.capture();
    if (collection.isEmpty) return null;

    final ids = collection.questionIds.take(maxQuestions).toList();
    final questions = await _questions.getByIds(ids);
    if (!_sessions.isCurrent(session)) return null;
    if (questions.isEmpty) return null;

    await _repository.recordSessionStarted(collection.type);
    if (!_sessions.isCurrent(session)) return null;
    scheduleCloudSync(courseId: courseId, session: session);

    return _tests.createTestFromQuestions(
      id: 'revision-${collection.type.name}-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Revision · ${collection.title}',
      courseId: courseId,
      questions: questions,
      mode: TestMode.practice,
      duration: durationMinutes == null
          ? null
          : Duration(minutes: durationMinutes),
      instructions: const [
        'This is a revision session generated from your Progress and Question Bank.',
        'Focus on understanding explanations after each attempt.',
        'Your results will update Progress analytics automatically.',
      ],
    );
  }

  /// Clears local revision-session state for the previous authenticated user.
  /// Cloud revision documents are intentionally untouched.
  void clear() {
    _cloudSyncGeneration++;
    _pendingCloudCourseId = null;
    _repository.clear();
  }

  void _registerSessionReset() {
    UserSessionStateCoordinator.instance.register(clear);
  }

  /// Schedules a best-effort cloud mirror of current local revision lists.
  ///
  /// Safe to call after practice/tests update Progress mistake data.
  void scheduleCloudSync({String? courseId, UserSessionIdentity? session}) {
    // TEMP DEBUG (Milestone 21.1)
    debugPrint('RevisionService.scheduleCloudSync() entered');

    final identity = session ?? _sessions.capture();
    if (!_sessions.isCurrent(identity)) return;
    final uid = identity.uid;
    // TEMP DEBUG (Milestone 21.1)
    debugPrint('Current Firebase UID: ${uid ?? 'NULL'}');

    if (uid == null || uid.isEmpty) {
      // TEMP DEBUG (Milestone 21.1)
      debugPrint('scheduleCloudSync exits early: YES (UID null/empty)');
      return;
    }

    // TEMP DEBUG (Milestone 21.1)
    debugPrint('scheduleCloudSync exits early: NO');

    _pendingCloudCourseId = courseId;
    final generation = ++_cloudSyncGeneration;
    unawaited(_runCloudSync(session: identity, generation: generation));
  }

  Future<void> _runCloudSync({
    required UserSessionIdentity session,
    required int generation,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (generation != _cloudSyncGeneration) return;
    if (!_sessions.isCurrent(session)) return;

    final courseId = _pendingCloudCourseId;

    try {
      final snapshot = await _buildCloudSnapshot(
        uid: session.uid!,
        courseId: courseId,
      );
      // TEMP DEBUG (Milestone 21.1)
      debugPrint('wrongQuestions count: ${snapshot.wrongQuestions.length}');
      debugPrint('weakQuestions count: ${snapshot.weakQuestions.length}');
      debugPrint(
        'frequentlyWrongQuestions count: '
        '${snapshot.frequentlyWrongQuestions.length}',
      );
      if (generation != _cloudSyncGeneration || !_sessions.isCurrent(session)) {
        return;
      }
      if (_cloudSyncOverride != null) {
        await _cloudSyncOverride(snapshot);
      } else {
        await _cloud.syncSnapshot(snapshot);
      }
    } catch (error, stack) {
      debugPrint('RevisionService cloud sync failed: $error\n$stack');
    }
  }

  Future<RevisionCloud> _buildCloudSnapshot({
    required String uid,
    String? courseId,
  }) async {
    final wrongIds = await _progress.loadWrongQuestionIds();
    final frequentIds = await _progress.loadFrequentlyWrongIds();
    final weakTopics = await _progress.calculateWeakAreas(
      courseId: courseId,
      limit: 50,
    );

    final wrongQuestions = await _filterIdsForCourse(
      wrongIds,
      courseId: courseId,
    );
    final frequentlyWrongQuestions = await _filterIdsForCourse(
      frequentIds,
      courseId: courseId,
    );

    final weakQuestions = <String>[];
    final seenWeak = <String>{};
    for (final topic in weakTopics) {
      final topicQuestions = await _questions.getByTopic(topic.topicId);
      for (final question in topicQuestions) {
        if (courseId != null &&
            courseId.isNotEmpty &&
            question.courseId != courseId) {
          continue;
        }
        if (seenWeak.add(question.id)) {
          weakQuestions.add(question.id);
        }
      }
    }

    return RevisionCloud(
      uid: uid,
      courseId: courseId,
      wrongQuestions: wrongQuestions,
      weakQuestions: weakQuestions,
      frequentlyWrongQuestions: frequentlyWrongQuestions,
      updatedAt: null,
      appVersion: null,
    );
  }

  Future<List<String>> _filterIdsForCourse(
    List<String> ids, {
    String? courseId,
  }) async {
    if (courseId == null || courseId.isEmpty) {
      return [...ids];
    }
    final filtered = <String>[];
    for (final id in ids) {
      final question = await _questions.getById(id);
      if (question != null && question.courseId == courseId) {
        filtered.add(id);
      }
    }
    return filtered;
  }

  Future<int> _countForCourse(List<String> ids, String? courseId) async {
    if (courseId == null) return ids.length;
    var count = 0;
    for (final id in ids) {
      final q = await _questions.getById(id);
      if (q != null && q.courseId == courseId) count++;
    }
    return count;
  }

  Future<List<RevisionQuestionGroup>> _groupQuestions(
    List<String> ids, {
    String? courseId,
    Map<String, int>? wrongCounts,
  }) async {
    final items = <RevisionQuestionItem>[];
    for (final id in ids) {
      final question = await _questions.getById(id);
      if (question == null) continue;
      if (courseId != null && question.courseId != courseId) continue;
      items.add(_toItem(question, wrongCount: wrongCounts?[id]));
    }

    final map = <String, List<RevisionQuestionItem>>{};
    for (final item in items) {
      final key = '${item.courseName}||${item.paperName}||${item.chapterName}';
      map.putIfAbsent(key, () => []).add(item);
    }

    final groups = <RevisionQuestionGroup>[];
    for (final entry in map.entries) {
      final parts = entry.key.split('||');
      groups.add(
        RevisionQuestionGroup(
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

  RevisionQuestionItem _toItem(Question question, {int? wrongCount}) {
    final course = _syllabus.getCourseById(question.courseId);
    final paper = _syllabus.getPaper(
      courseId: question.courseId,
      paperId: question.paperId,
    );
    final chapter = _syllabus.getTopic(
      courseId: question.courseId,
      paperId: question.paperId,
      sectionId: question.sectionId,
      topicId: question.topicId,
    );

    final title = question.question;
    final truncated = title.length > 90 ? '${title.substring(0, 90)}…' : title;

    return RevisionQuestionItem(
      questionId: question.id,
      title: truncated,
      courseId: question.courseId,
      courseName: course?.name ?? question.courseId,
      paperId: question.paperId,
      paperName: paper?.title ?? question.paperId,
      chapterId: question.topicId,
      chapterName: chapter?.title ?? question.topicId,
      wrongCount: wrongCount,
    );
  }
}
