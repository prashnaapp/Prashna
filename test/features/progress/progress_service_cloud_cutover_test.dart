import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/authentication/services/user_session_state_coordinator.dart';
import 'package:telangana_prep/features/progress/data/repositories/progress_repository.dart';
import 'package:telangana_prep/features/progress/services/progress_service.dart';
import 'package:telangana_prep/features/progress_cloud/model/user_progress.dart';
import 'package:telangana_prep/features/progress_cloud/repository/course_progress_cloud_repository.dart';
import 'package:telangana_prep/features/progress_cloud/repository/course_progress_document_store.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';

void main() {
  const uid = 'user-a';
  const courseA = 'group-ii';
  const courseB = 'group-iii';

  late UserSessionStateCoordinator coordinator;
  late InMemoryCourseProgressDocumentStore store;
  late CourseProgressCloudRepository courseCloud;
  late ProgressService progress;
  late List<UserProgress> synced;

  ProgressService buildService() {
    return ProgressService.debug(
      repository: ProgressRepository(seed: false),
      sessionCoordinator: coordinator,
      courseCloudRepository: courseCloud,
      cloudSync: (snapshot) async => synced.add(snapshot),
    );
  }

  setUp(() {
    coordinator = UserSessionStateCoordinator.debug();
    store = InMemoryCourseProgressDocumentStore();
    courseCloud = CourseProgressCloudRepository(
      store: store,
      sessionCoordinator: coordinator,
      appVersionResolver: () async => '1.0.0',
    );
    synced = <UserProgress>[];
    progress = buildService();
    coordinator.register(progress.clear);
    coordinator.handleAuthState(const AuthUser(uid: uid));
  });

  Future<void> flushSync() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  Future<void> seedCourse({
    required String courseId,
    required int completion,
    required double accuracy,
    required int chaptersCompleted,
    required int totalChapters,
    required int questionsAttempted,
    required int questionsCorrect,
    Map<String, dynamic> papers = const {},
    Map<String, dynamic> chapters = const {},
  }) {
    return store.setCourse(uid, courseId, {
      'uid': uid,
      'courseId': courseId,
      'overall': {
        'completion': completion,
        'accuracy': accuracy,
        'chaptersCompleted': chaptersCompleted,
        'totalChapters': totalChapters,
        'questionsAttempted': questionsAttempted,
        'questionsCorrect': questionsCorrect,
      },
      'papers': papers,
      'chapters': chapters,
      'appVersion': '1.0.0',
      'schemaVersion': 1,
    });
  }

  test('1: initial hydration blocks sync until hydrated', () async {
    expect(
      progress.hydrationStateFor(courseA),
      CourseProgressHydrationState.notHydrated,
    );

    // Fail hydration by using a throwing store wrapper.
    final failing = ProgressService.debug(
      repository: ProgressRepository(seed: false),
      sessionCoordinator: coordinator,
      courseCloudRepository: CourseProgressCloudRepository(
        store: _ThrowingLoadStore(store),
        sessionCoordinator: coordinator,
        appVersionResolver: () async => '1.0.0',
      ),
      cloudSync: (snapshot) async => synced.add(snapshot),
    );
    coordinator.register(failing.clear);

    failing.applyTestCompletion(
      examId: courseA,
      correctAnswers: 1,
      totalQuestions: 1,
    );
    await flushSync();

    expect(synced, isEmpty);
    expect(
      failing.hydrationStateFor(courseA),
      CourseProgressHydrationState.hydrationFailed,
    );
  });

  test('2: successful hydration enables sync', () async {
    final ok = await progress.hydrateCourse(courseA);
    expect(ok, isTrue);
    expect(
      progress.hydrationStateFor(courseA),
      CourseProgressHydrationState.hydrated,
    );

    progress.applyTestCompletion(
      examId: courseA,
      correctAnswers: 3,
      totalQuestions: 5,
    );
    await flushSync();

    expect(synced, isNotEmpty);
    expect(synced.last.uid, uid);
    expect(synced.last.courseId, courseA);
  });

  test('3: hydration failure does not write zeros', () async {
    await store.setCourse(uid, courseA, {
      'uid': uid,
      'courseId': courseA,
      'overall': {
        'completion': 40,
        'accuracy': 0.8,
        'chaptersCompleted': 2,
        'totalChapters': 5,
        'questionsAttempted': 20,
        'questionsCorrect': 16,
      },
      'papers': {
        'paper-i': {'id': 'paper-i', 'progressPercent': 40},
      },
      'chapters': <String, dynamic>{},
      'appVersion': '1.0.0',
      'schemaVersion': 1,
    });

    final failing = ProgressService.debug(
      repository: ProgressRepository(seed: false),
      sessionCoordinator: coordinator,
      courseCloudRepository: CourseProgressCloudRepository(
        store: _ThrowingLoadStore(store),
        sessionCoordinator: coordinator,
        appVersionResolver: () async => '1.0.0',
      ),
      cloudSync: (snapshot) async => synced.add(snapshot),
    );

    final ok = await failing.hydrateCourse(courseA);
    expect(ok, isFalse);
    failing.applyTestCompletion(
      examId: courseA,
      correctAnswers: 0,
      totalQuestions: 1,
    );
    await flushSync();

    expect(synced, isEmpty);
    final cloud = await store.getCourse(uid, courseA);
    expect(cloud!['overall']['completion'], 40);
  });

  test('4: missing course creates safely via create-only', () async {
    expect(await store.getCourse(uid, courseA), isNull);
    final ok = await progress.hydrateCourse(courseA);
    expect(ok, isTrue);
    final created = await store.getCourse(uid, courseA);
    expect(created, isNotNull);
    expect(created!['courseId'], courseA);
    expect(created['overall']['completion'], 0);
  });

  test('5/6/7: course A/B sync isolation and switching', () async {
    await seedCourse(
      courseId: courseA,
      completion: 29,
      accuracy: 57.8,
      chaptersCompleted: 4,
      totalChapters: 60,
      questionsAttempted: 51,
      questionsCorrect: 32,
    );
    await seedCourse(
      courseId: courseB,
      completion: 10,
      accuracy: 70,
      chaptersCompleted: 1,
      totalChapters: 40,
      questionsAttempted: 10,
      questionsCorrect: 7,
    );

    // Direct course-repo writes stay isolated and use each course's baseline.
    final direct = ProgressService.debug(
      repository: ProgressRepository(seed: false),
      sessionCoordinator: coordinator,
      courseCloudRepository: courseCloud,
    );
    coordinator.register(direct.clear);
    await direct.hydrateCourse(courseA);
    await direct.hydrateCourse(courseB);
    await direct.recordTestAttempt(
      test: _test(courseId: courseA, id: 'course-a'),
      result: _result(correct: 15, wrong: 5, total: 20),
    );
    await flushSync();
    await direct.recordTestAttempt(
      test: _test(courseId: courseB, id: 'course-b'),
      result: _result(correct: 4, wrong: 1, total: 5),
    );
    await flushSync();

    final aDoc = await store.getCourse(uid, courseA);
    final bDoc = await store.getCourse(uid, courseB);
    expect(aDoc, isNotNull);
    expect(bDoc, isNotNull);
    expect(aDoc!['courseId'], courseA);
    expect(bDoc!['courseId'], courseB);
    expect(aDoc['overall']['questionsAttempted'], 71);
    expect(aDoc['overall']['questionsCorrect'], 47);
    expect(bDoc['overall']['questionsAttempted'], 15);
    expect(bDoc['overall']['questionsCorrect'], 11);
    expect(aDoc['overall']['questionsCorrect'], isNot(11));
    expect(bDoc['overall']['questionsCorrect'], isNot(47));
  });

  test('8: User A → User B clears old progress', () async {
    await progress.hydrateCourse(courseA);
    progress.applyTestCompletion(
      examId: courseA,
      correctAnswers: 2,
      totalQuestions: 2,
    );
    await flushSync();

    coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
    expect(
      progress.hydrationStateFor(courseA),
      CourseProgressHydrationState.notHydrated,
    );
    final history = await progress.loadHistory(courseId: courseA);
    expect(history, isEmpty);
  });

  test('9: User A stale operation cannot write after User B', () async {
    await progress.hydrateCourse(courseA);
    progress.applyTestCompletion(
      examId: courseA,
      correctAnswers: 1,
      totalQuestions: 1,
    );
    coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
    await flushSync();
    expect(synced.where((s) => s.uid == uid), isEmpty);
  });

  test('10: correct UID is passed on sync snapshots', () async {
    await progress.hydrateCourse(courseA);
    progress.applyTestCompletion(
      examId: courseA,
      correctAnswers: 1,
      totalQuestions: 1,
    );
    await flushSync();
    expect(synced, isNotEmpty);
    expect(synced.every((s) => s.uid == uid), isTrue);
    expect(synced.every((s) => s.courseId == courseA), isTrue);
  });

  test('11: no legacy parent write — only course store keys', () async {
    final direct = ProgressService.debug(
      repository: ProgressRepository(seed: false),
      sessionCoordinator: coordinator,
      courseCloudRepository: courseCloud,
    );
    coordinator.register(direct.clear);
    await direct.hydrateCourse(courseA);
    await direct.recordTestAttempt(
      test: _test(courseId: courseA),
      result: _result(correct: 1, total: 1),
    );
    await flushSync();

    final listed = await store.listCourses(uid);
    expect(listed.keys, [courseA]);
    expect(store.parentWriteAttempts, 0);
  });

  test(
    '12: production repository instance does not seed fake attempts',
    () async {
      final repo = ProgressRepository(seed: false);
      expect(await repo.loadHistory(), isEmpty);
      expect(await repo.loadWrongQuestionIds(), isEmpty);

      // Structural syllabus remains, but chapter seed scores are zero.
      final overall = progress.getOverallProgress(courseA);
      expect(overall.progressPercent, 0);
    },
  );

  test('empty local does not overwrite non-empty hydrated cloud', () async {
    final papers = _historicalPapers();
    final chapters = _historicalChapters();
    await seedCourse(
      courseId: courseA,
      completion: 29,
      accuracy: 57.8,
      chaptersCompleted: 4,
      totalChapters: 60,
      questionsAttempted: 51,
      questionsCorrect: 32,
      papers: papers,
      chapters: chapters,
    );

    final direct = ProgressService.debug(
      repository: ProgressRepository(seed: false),
      sessionCoordinator: coordinator,
      courseCloudRepository: courseCloud,
    );
    coordinator.register(direct.clear);
    await direct.hydrateCourse(courseA);

    // Schedule a sync without creating a local AttemptHistory entry.
    direct.applyTestCompletion(
      examId: courseA,
      correctAnswers: 0,
      totalQuestions: 1,
    );
    await flushSync();

    final cloud = await store.getCourse(uid, courseA);
    expect(cloud!['overall']['completion'], 29);
    expect(cloud['overall']['accuracy'], 57.8);
    expect(cloud['overall']['chaptersCompleted'], 4);
    expect(cloud['overall']['totalChapters'], 60);
    expect(cloud['overall']['questionsAttempted'], 51);
    expect(cloud['overall']['questionsCorrect'], 32);
    expect(cloud['papers'], papers);
    expect(cloud['chapters'], chapters);
  });

  test('hydrated cumulative baseline survives a new attempt', () async {
    final papers = _historicalPapers();
    final chapters = _historicalChapters();
    await seedCourse(
      courseId: courseA,
      completion: 29,
      accuracy: 57.8,
      chaptersCompleted: 4,
      totalChapters: 60,
      questionsAttempted: 51,
      questionsCorrect: 32,
      papers: papers,
      chapters: chapters,
    );

    expect(await progress.hydrateCourse(courseA), isTrue);
    await progress.recordTestAttempt(
      test: _test(courseId: courseA, id: 'new-test'),
      result: _result(correct: 15, wrong: 5, total: 20),
    );
    await flushSync();

    final snapshot = synced.last;
    expect(snapshot.overall.questionsAttempted, 71);
    expect(snapshot.overall.questionsCorrect, 47);
    expect(snapshot.overall.completion, 29);
    expect(snapshot.overall.accuracy, 57.8);
    expect(snapshot.papers, papers);
    expect(snapshot.chapters, chapters);
  });

  test('repeated sync uses the immutable hydration baseline', () async {
    await seedCourse(
      courseId: courseA,
      completion: 29,
      accuracy: 57.8,
      chaptersCompleted: 4,
      totalChapters: 60,
      questionsAttempted: 51,
      questionsCorrect: 32,
    );
    expect(await progress.hydrateCourse(courseA), isTrue);
    await progress.recordTestAttempt(
      test: _test(courseId: courseA, id: 'duplicate-test'),
      result: _result(correct: 15, wrong: 5, total: 20),
    );
    await flushSync();
    final first = synced.last;
    progress.applyTestCompletion(
      examId: courseA,
      correctAnswers: 0,
      totalQuestions: 1,
    );
    await flushSync();
    final second = synced.last;
    progress.applyTestCompletion(
      examId: courseA,
      correctAnswers: 0,
      totalQuestions: 1,
    );
    await flushSync();
    final third = synced.last;

    for (final snapshot in [first, second, third]) {
      expect(snapshot.overall.questionsAttempted, 71);
      expect(snapshot.overall.questionsCorrect, 47);
    }
  });

  test('two session attempts add both deltas exactly once', () async {
    await seedCourse(
      courseId: courseA,
      completion: 29,
      accuracy: 57.8,
      chaptersCompleted: 4,
      totalChapters: 60,
      questionsAttempted: 51,
      questionsCorrect: 32,
    );
    expect(await progress.hydrateCourse(courseA), isTrue);
    await progress.recordTestAttempt(
      test: _test(courseId: courseA, id: 'test-a'),
      result: _result(correct: 15, wrong: 5, total: 20),
    );
    await progress.recordTestAttempt(
      test: _test(courseId: courseA, id: 'test-b'),
      result: _result(correct: 6, wrong: 4, total: 10),
    );
    await flushSync();

    expect(synced.last.overall.questionsAttempted, 81);
    expect(synced.last.overall.questionsCorrect, 53);
  });

  test('sign-out and sign-in establish a new cumulative baseline', () async {
    await seedCourse(
      courseId: courseA,
      completion: 0,
      accuracy: 0,
      chaptersCompleted: 0,
      totalChapters: 60,
      questionsAttempted: 51,
      questionsCorrect: 32,
    );
    final direct = ProgressService.debug(
      repository: ProgressRepository(seed: false),
      sessionCoordinator: coordinator,
      courseCloudRepository: courseCloud,
    );
    coordinator.register(direct.clear);

    expect(await direct.hydrateCourse(courseA), isTrue);
    await direct.recordTestAttempt(
      test: _test(courseId: courseA, id: 'session-a'),
      result: _result(correct: 15, wrong: 5, total: 20),
    );
    await flushSync();
    final afterA = await store.getCourse(uid, courseA);
    expect(afterA!['overall']['questionsAttempted'], 71);
    expect(afterA['overall']['questionsCorrect'], 47);

    coordinator.handleAuthState(null);
    coordinator.handleAuthState(const AuthUser(uid: uid));
    expect(await direct.hydrateCourse(courseA), isTrue);
    await direct.recordTestAttempt(
      test: _test(courseId: courseA, id: 'session-b'),
      result: _result(correct: 6, wrong: 4, total: 10),
    );
    await flushSync();
    final afterB = await store.getCourse(uid, courseA);
    expect(afterB!['overall']['questionsAttempted'], 81);
    expect(afterB['overall']['questionsCorrect'], 53);
  });
}

Map<String, dynamic> _historicalPapers() {
  return {
    'paper-i': {
      'id': 'paper-i',
      'label': 'Paper I',
      'maxMarks': 150,
      'coveredMarks': 55.5,
      'progressPercent': 37,
      'remainingMarks': 94.5,
    },
    'paper-ii': {
      'id': 'paper-ii',
      'label': 'Paper II',
      'maxMarks': 150,
      'coveredMarks': 33,
      'progressPercent': 22,
      'remainingMarks': 117,
    },
    'paper-iii': {
      'id': 'paper-iii',
      'label': 'Paper III',
      'maxMarks': 150,
      'coveredMarks': 10.5,
      'progressPercent': 7,
      'remainingMarks': 139.5,
    },
    'paper-iv': {
      'id': 'paper-iv',
      'label': 'Paper IV',
      'maxMarks': 150,
      'coveredMarks': 72,
      'progressPercent': 48,
      'remainingMarks': 78,
    },
  };
}

Map<String, dynamic> _historicalChapters() {
  final progress = <String, dynamic>{
    'chapter-1': {
      'id': 'chapter-1',
      'label': 'Chapter 1',
      'paperId': 'paper-i',
      'partId': 'part-i',
      'maxMarks': 5,
      'coveredMarks': 2,
      'progressPercent': 40,
      'remainingMarks': 3,
      'status': 'Needs Focus',
    },
    'chapter-2': {
      'id': 'chapter-2',
      'label': 'Chapter 2',
      'paperId': 'paper-ii',
      'partId': 'part-i',
      'maxMarks': 5,
      'coveredMarks': 1.8,
      'progressPercent': 36,
      'remainingMarks': 3.2,
      'status': 'Needs Focus',
    },
    'chapter-3': {
      'id': 'chapter-3',
      'label': 'Chapter 3',
      'paperId': 'paper-iii',
      'partId': 'part-i',
      'maxMarks': 5,
      'coveredMarks': 1.5,
      'progressPercent': 30,
      'remainingMarks': 3.5,
      'status': 'Needs Focus',
    },
    'chapter-4': {
      'id': 'chapter-4',
      'label': 'Chapter 4',
      'paperId': 'paper-iv',
      'partId': 'part-i',
      'maxMarks': 5,
      'coveredMarks': 1.3,
      'progressPercent': 26,
      'remainingMarks': 3.7,
      'status': 'Needs Focus',
    },
    'chapter-5': {
      'id': 'chapter-5',
      'label': 'Chapter 5',
      'paperId': 'paper-iv',
      'partId': 'part-ii',
      'maxMarks': 5,
      'coveredMarks': 1,
      'progressPercent': 20,
      'remainingMarks': 4,
      'status': 'Not Started',
    },
  };
  return progress;
}

Test _test({required String courseId, String id = 't'}) {
  return Test(
    id: '$id-$courseId',
    title: 'Test',
    courseId: courseId,
    duration: const Duration(minutes: 1),
    totalQuestions: 1,
    totalMarks: 1,
    negativeMarks: 0,
    instructions: const [],
    mode: TestMode.practice,
    questions: const [],
  );
}

TestResult _result({required int correct, int wrong = 0, required int total}) {
  return TestResult(
    totalQuestions: total,
    attempted: correct + wrong,
    correct: correct,
    wrong: wrong,
    skipped: total - correct - wrong,
    score: correct.toDouble(),
    accuracy: total == 0 ? 0 : correct / total,
    percentage: total == 0 ? 0 : (correct / total) * 100,
    timeTaken: const Duration(seconds: 1),
    passed: correct > 0,
  );
}

class _ThrowingLoadStore implements CourseProgressDocumentStore {
  _ThrowingLoadStore(this._inner);

  final CourseProgressDocumentStore _inner;

  @override
  Future<bool> courseExists(String uid, String courseId) =>
      _inner.courseExists(uid, courseId);

  @override
  Future<Map<String, dynamic>?> getCourse(String uid, String courseId) {
    throw StateError('simulated hydration failure');
  }

  @override
  Future<Map<String, Map<String, dynamic>>> listCourses(String uid) =>
      _inner.listCourses(uid);

  @override
  Future<void> setCourse(
    String uid,
    String courseId,
    Map<String, dynamic> data,
  ) {
    return _inner.setCourse(uid, courseId, data);
  }

  @override
  Future<bool> createCourseIfAbsent(
    String uid,
    String courseId,
    Map<String, dynamic> data,
  ) {
    return _inner.createCourseIfAbsent(uid, courseId, data);
  }
}
