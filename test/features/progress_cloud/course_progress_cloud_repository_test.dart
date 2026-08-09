import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/authentication/services/user_session_state_coordinator.dart';
import 'package:telangana_prep/features/progress_cloud/model/user_progress.dart';
import 'package:telangana_prep/features/progress_cloud/repository/course_progress_cloud_repository.dart';
import 'package:telangana_prep/features/progress_cloud/repository/course_progress_document_store.dart';

void main() {
  const uid = 'user-a';
  const courseA = 'group-ii';
  const courseB = 'group-iii';

  UserProgress snapshot({
    required String courseId,
    num completion = 10,
  }) {
    return UserProgress(
      uid: uid,
      courseId: courseId,
      overall: ProgressOverall(
        completion: completion,
        accuracy: 0.5,
        chaptersCompleted: 1,
        totalChapters: 5,
        questionsAttempted: 10,
        questionsCorrect: 5,
      ),
      papers: {
        'paper-i': {'id': 'paper-i', 'progressPercent': completion},
      },
      chapters: {
        'ch-1': {'id': 'ch-1', 'paperId': 'paper-i', 'progressPercent': completion},
      },
      lastUpdated: null,
      appVersion: '1.0.0',
      schemaVersion: UserProgress.currentSchemaVersion,
    );
  }

  group('CourseProgressCloudRepository', () {
    late InMemoryCourseProgressDocumentStore store;
    late CourseProgressCloudRepository repo;

    setUp(() {
      store = InMemoryCourseProgressDocumentStore();
      repo = CourseProgressCloudRepository(
        store: store,
        appVersionResolver: () async => '1.0.0',
      );
    });

    test('missing course returns null', () async {
      final loaded = await repo.loadCourse(uid, courseA);
      expect(loaded, isNull);
    });

    test('createCourseIfMissing creates zeroed course doc only', () async {
      await repo.createCourseIfMissing(uid, courseA);
      final loaded = await repo.loadCourse(uid, courseA);
      expect(loaded, isNotNull);
      expect(loaded!.uid, uid);
      expect(loaded.courseId, courseA);
      expect(loaded.overall.completion, 0);
      expect(loaded.papers, isEmpty);
      expect(loaded.chapters, isEmpty);
      expect(loaded.schemaVersion, UserProgress.currentSchemaVersion);

      // Sibling course untouched / missing.
      expect(await repo.loadCourse(uid, courseB), isNull);
    });

    test('createCourseIfMissing does not overwrite existing course', () async {
      await repo.updateCourse(uid, courseA, snapshot(courseId: courseA, completion: 42));
      await repo.createCourseIfMissing(uid, courseA);
      final loaded = await repo.loadCourse(uid, courseA);
      expect(loaded!.overall.completion, 42);
    });

    test('A/B isolation: updateCourse A does not affect B', () async {
      await repo.updateCourse(uid, courseA, snapshot(courseId: courseA, completion: 11));
      await repo.updateCourse(uid, courseB, snapshot(courseId: courseB, completion: 22));

      final a = await repo.loadCourse(uid, courseA);
      final b = await repo.loadCourse(uid, courseB);
      expect(a!.overall.completion, 11);
      expect(b!.overall.completion, 22);

      await repo.updateCourse(
        uid,
        courseA,
        snapshot(courseId: courseA, completion: 99),
      );

      final aAfter = await repo.loadCourse(uid, courseA);
      final bAfter = await repo.loadCourse(uid, courseB);
      expect(aAfter!.overall.completion, 99);
      expect(bAfter!.overall.completion, 22);
    });

    test('loadAllCourses returns both courses', () async {
      await repo.updateCourse(uid, courseA, snapshot(courseId: courseA, completion: 1));
      await repo.updateCourse(uid, courseB, snapshot(courseId: courseB, completion: 2));

      final all = await repo.loadAllCourses(uid);
      final byId = {for (final item in all) item.courseId!: item};
      expect(byId.keys, containsAll([courseA, courseB]));
      expect(byId[courseA]!.overall.completion, 1);
      expect(byId[courseB]!.overall.completion, 2);
    });

    test('updateCourse rejects uid / courseId ownership mismatch', () async {
      await expectLater(
        repo.updateCourse(
          uid,
          courseA,
          snapshot(courseId: courseA).copyWith(uid: 'other-user'),
        ),
        throwsA(isA<ArgumentError>()),
      );

      await expectLater(
        repo.updateCourse(
          uid,
          courseA,
          snapshot(courseId: courseB),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(await store.listCourses(uid), isEmpty);
    });

    test('rejects empty or illegal courseId / uid', () async {
      await expectLater(
        repo.loadCourse('', courseA),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        repo.loadCourse(uid, ''),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        repo.loadCourse(uid, 'group/ii'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('malformed course document throws on loadCourse', () async {
      await store.setCourse(uid, courseA, {
        'uid': uid,
        'courseId': courseA,
        'overall': 'not-a-map',
        'papers': <String, dynamic>{},
        'chapters': <String, dynamic>{},
      });

      await expectLater(
        repo.loadCourse(uid, courseA),
        throwsA(isA<FormatException>()),
      );
    });

    test('loadAllCourses skips malformed siblings', () async {
      await repo.updateCourse(uid, courseA, snapshot(courseId: courseA, completion: 7));
      await store.setCourse(uid, courseB, {
        'uid': uid,
        'courseId': 'wrong-id',
        'overall': <String, dynamic>{},
        'papers': <String, dynamic>{},
        'chapters': <String, dynamic>{},
      });

      final all = await repo.loadAllCourses(uid);
      expect(all, hasLength(1));
      expect(all.single.courseId, courseA);
      expect(all.single.overall.completion, 7);
    });

    test('store never exposes parent write API; only course keys exist', () async {
      await repo.updateCourse(uid, courseA, snapshot(courseId: courseA));
      final listed = await store.listCourses(uid);
      expect(listed.keys, [courseA]);
      expect(store.parentWriteAttempts, 0);
    });
  });

  group('CourseProgressCloudRepository stale session', () {
    test('stale updateCourse does not write after A→B', () async {
      final coordinator = UserSessionStateCoordinator.debug();
      final store = InMemoryCourseProgressDocumentStore();
      final versionGate = Completer<String>();
      final repo = CourseProgressCloudRepository(
        store: store,
        sessionCoordinator: coordinator,
        appVersionResolver: () => versionGate.future,
      );

      coordinator.handleAuthState(const AuthUser(uid: uid));
      final sessionA = coordinator.capture();

      // Null appVersion forces an await on the resolver (session can change).
      final pending = repo.updateCourse(
        uid,
        courseA,
        UserProgress(
          uid: uid,
          courseId: courseA,
          overall: const ProgressOverall(
            completion: 55,
            accuracy: 0.5,
            chaptersCompleted: 1,
            totalChapters: 5,
            questionsAttempted: 10,
            questionsCorrect: 5,
          ),
          papers: const {
            'paper-i': {'id': 'paper-i', 'progressPercent': 55},
          },
          chapters: const {
            'ch-1': {
              'id': 'ch-1',
              'paperId': 'paper-i',
              'progressPercent': 55,
            },
          },
          lastUpdated: null,
          appVersion: null,
          schemaVersion: UserProgress.currentSchemaVersion,
        ),
        session: sessionA,
      );

      // Let updateCourse reach the awaited app-version resolver.
      await Future<void>.delayed(Duration.zero);
      coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
      versionGate.complete('1.0.0');
      await pending;

      expect(await store.listCourses(uid), isEmpty);
      expect(await store.listCourses('user-b'), isEmpty);
    });

    test('stale loadCourse returns null after A→B', () async {
      final coordinator = UserSessionStateCoordinator.debug();
      final store = InMemoryCourseProgressDocumentStore();
      await store.setCourse(uid, courseA, {
        'uid': uid,
        'courseId': courseA,
        'overall': ProgressOverall.zero.toMap(),
        'papers': <String, dynamic>{},
        'chapters': <String, dynamic>{},
        'appVersion': '1.0.0',
        'schemaVersion': 1,
      });

      final repo = CourseProgressCloudRepository(
        store: _DelayedGetStore(store),
        sessionCoordinator: coordinator,
        appVersionResolver: () async => '1.0.0',
      );

      coordinator.handleAuthState(const AuthUser(uid: uid));
      final sessionA = coordinator.capture();
      final future = repo.loadCourse(uid, courseA, session: sessionA);
      coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
      final loaded = await future;
      expect(loaded, isNull);
    });
  });

  group('UserProgress course maps', () {
    test('toCourseUpdateMap includes schemaVersion and ownership fields', () {
      final data = snapshot(courseId: courseA).toCourseUpdateMap(appVersion: '9.9.9');
      expect(data['uid'], uid);
      expect(data['courseId'], courseA);
      expect(data['schemaVersion'], UserProgress.currentSchemaVersion);
      expect(data['appVersion'], '9.9.9');
      expect(data['overall'], isA<Map<String, dynamic>>());
      expect(data['papers'], isA<Map<String, dynamic>>());
      expect(data['chapters'], isA<Map<String, dynamic>>());
    });

    test('fromCourseFirestore rejects body courseId mismatch', () {
      expect(
        () => UserProgress.fromCourseFirestore(
          uid: uid,
          courseId: courseA,
          data: {
            'uid': uid,
            'courseId': courseB,
            'overall': ProgressOverall.zero.toMap(),
            'papers': <String, dynamic>{},
            'chapters': <String, dynamic>{},
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

/// Delays getCourse so a session switch can land mid-load.
class _DelayedGetStore implements CourseProgressDocumentStore {
  _DelayedGetStore(this._inner);

  final CourseProgressDocumentStore _inner;

  @override
  Future<bool> courseExists(String uid, String courseId) =>
      _inner.courseExists(uid, courseId);

  @override
  Future<Map<String, dynamic>?> getCourse(String uid, String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return _inner.getCourse(uid, courseId);
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
}

