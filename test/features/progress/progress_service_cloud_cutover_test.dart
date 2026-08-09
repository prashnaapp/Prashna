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
    await progress.hydrateCourse(courseA);
    progress.applyTestCompletion(
      examId: courseA,
      correctAnswers: 4,
      totalQuestions: 5,
    );
    await flushSync();

    await progress.hydrateCourse(courseB);
    progress.applyTestCompletion(
      examId: courseB,
      correctAnswers: 1,
      totalQuestions: 5,
    );
    await flushSync();

    // Return to A with more progress.
    progress.applyTestCompletion(
      examId: courseA,
      correctAnswers: 1,
      totalQuestions: 5,
    );
    await flushSync();

    final aWrites = synced.where((s) => s.courseId == courseA).toList();
    final bWrites = synced.where((s) => s.courseId == courseB).toList();
    expect(aWrites, isNotEmpty);
    expect(bWrites, isNotEmpty);
    expect(aWrites.every((s) => s.courseId == courseA), isTrue);
    expect(bWrites.every((s) => s.courseId == courseB), isTrue);

    // Direct course-repo writes also stay isolated when bypassing override.
    final direct = ProgressService.debug(
      repository: ProgressRepository(seed: false),
      sessionCoordinator: coordinator,
      courseCloudRepository: courseCloud,
    );
    coordinator.register(direct.clear);
    await direct.hydrateCourse(courseA);
    await direct.hydrateCourse(courseB);
    direct.applyTestCompletion(
      examId: courseA,
      correctAnswers: 2,
      totalQuestions: 2,
    );
    await flushSync();
    direct.applyTestCompletion(
      examId: courseB,
      correctAnswers: 1,
      totalQuestions: 2,
    );
    await flushSync();

    final aDoc = await store.getCourse(uid, courseA);
    final bDoc = await store.getCourse(uid, courseB);
    expect(aDoc, isNotNull);
    expect(bDoc, isNotNull);
    expect(aDoc!['courseId'], courseA);
    expect(bDoc!['courseId'], courseB);
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

  test('12: production repository instance does not seed fake attempts', () async {
    final repo = ProgressRepository(seed: false);
    expect(await repo.loadHistory(), isEmpty);
    expect(await repo.loadWrongQuestionIds(), isEmpty);

    // Structural syllabus remains, but chapter seed scores are zero.
    final overall = progress.getOverallProgress(courseA);
    expect(overall.progressPercent, 0);
  });

  test('empty local does not overwrite non-empty hydrated cloud', () async {
    await store.setCourse(uid, courseA, {
      'uid': uid,
      'courseId': courseA,
      'overall': {
        'completion': 66,
        'accuracy': 0.9,
        'chaptersCompleted': 3,
        'totalChapters': 5,
        'questionsAttempted': 30,
        'questionsCorrect': 27,
      },
      'papers': {
        'paper-i': {'id': 'paper-i', 'progressPercent': 66},
      },
      'chapters': <String, dynamic>{},
      'appVersion': '1.0.0',
      'schemaVersion': 1,
    });

    final direct = ProgressService.debug(
      repository: ProgressRepository(seed: false),
      sessionCoordinator: coordinator,
      courseCloudRepository: courseCloud,
    );
    coordinator.register(direct.clear);
    await direct.hydrateCourse(courseA);

    // Schedule a sync without meaningful local attempt growth by forcing
    // apply with 0/0 which no-ops — use generation bump via clear? Instead
    // call apply with totalQuestions <= 0 which returns early.
    // Trigger sync path via record with empty questions still schedules.
    // Use applyTestCompletion with valid totals but then clear credits?
    // Safer: hydrate then manually schedule by apply with 0 correct of 1
    // which still marks non-empty local credits of 0 — empty check uses
    // questionsAttempted from history which is empty and completion from
    // prior cloud via snapshot builder.
    direct.applyTestCompletion(
      examId: courseA,
      correctAnswers: 0,
      totalQuestions: 1,
    );
    await flushSync();

    final cloud = await store.getCourse(uid, courseA);
    // Snapshot may update with credits 0 but prior questions should be
    // preserved by empty-overwrite guard when local is effectively empty.
    expect(cloud!['overall']['completion'], 66);
  });
}

Test _test({required String courseId}) {
  return Test(
    id: 't-$courseId',
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

TestResult _result({required int correct, required int total}) {
  return TestResult(
    totalQuestions: total,
    attempted: correct,
    correct: correct,
    wrong: 0,
    skipped: total - correct,
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
