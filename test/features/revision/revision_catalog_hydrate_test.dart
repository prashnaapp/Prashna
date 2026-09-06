import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/authentication/services/user_session_state_coordinator.dart';
import 'package:telangana_prep/features/revision/data/repositories/revision_repository.dart';
import 'package:telangana_prep/features/revision_cloud/model/revision_cloud.dart';

void main() {
  late UserSessionStateCoordinator coordinator;

  setUp(() {
    coordinator = UserSessionStateCoordinator.debug();
  });

  RevisionRepository buildRepo({
    required Future<RevisionCloud?> Function(String uid) cloudLoader,
  }) {
    final repo = RevisionRepository(
      sessionCoordinator: coordinator,
      cloudLoader: cloudLoader,
    );
    coordinator.register(repo.clear);
    return repo;
  }

  RevisionCloud snap({
    required String uid,
    List<String> wrong = const [],
    List<String> frequent = const [],
    Map<String, int> counts = const {},
  }) {
    return RevisionCloud(
      uid: uid,
      courseId: null,
      wrongQuestions: wrong,
      weakQuestions: const [],
      frequentlyWrongQuestions: frequent,
      mistakeCounts: counts,
      updatedAt: null,
      appVersion: null,
    );
  }

  test('A: no authenticated user does not read cloud and stays notLoaded',
      () async {
    var loads = 0;
    final repo = buildRepo(
      cloudLoader: (_) async {
        loads++;
        return null;
      },
    );

    final state = await repo.loadCurrentUserRevision();

    expect(state, CatalogRevisionLoadState.notLoaded);
    expect(repo.currentCatalogRevision, isNull);
    expect(loads, 0);
  });

  test('B: missing document becomes valid empty loaded snapshot', () async {
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
    final repo = buildRepo(cloudLoader: (_) async => null);

    final state = await repo.loadCurrentUserRevision();

    expect(state, CatalogRevisionLoadState.loaded);
    final loaded = repo.currentCatalogRevision!;
    expect(loaded.uid, 'user-a');
    expect(loaded.wrongQuestions, isEmpty);
    expect(loaded.frequentlyWrongQuestions, isEmpty);
    expect(loaded.mistakeCounts, isEmpty);
    expect(repo.isCatalogRevisionEmpty, isTrue);
  });

  test('C: load preserves wrong IDs, frequent IDs, and mistakeCounts', () async {
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
    final repo = buildRepo(
      cloudLoader: (_) async => snap(
        uid: 'user-a',
        wrong: const ['q-g2-1', 'q-g3-1'],
        frequent: const ['q-g2-1'],
        counts: const {'q-g2-1': 3, 'q-g3-1': 1},
      ).copyWith(authority: 'server_verified', appVersion: 'server-5.27'),
    );

    final state = await repo.loadCurrentUserRevision();

    expect(state, CatalogRevisionLoadState.loaded);
    final loaded = repo.currentCatalogRevision!;
    expect(loaded.wrongQuestions, ['q-g2-1', 'q-g3-1']);
    expect(loaded.frequentlyWrongQuestions, ['q-g2-1']);
    expect(loaded.mistakeCounts['q-g2-1'], 3);
    expect(loaded.mistakeCounts['q-g3-1'], 1);
    expect(loaded.authority, 'server_verified');
    expect(repo.isCatalogRevisionEmpty, isFalse);
  });

  test('D: refresh replaces cache with latest authoritative cloud data',
      () async {
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
    var version = 1;
    final repo = buildRepo(
      cloudLoader: (_) async {
        if (version == 1) {
          return snap(
            uid: 'user-a',
            wrong: const ['q-old'],
            counts: const {'q-old': 1},
          );
        }
        return snap(
          uid: 'user-a',
          wrong: const ['q-new', 'q-old'],
          frequent: const ['q-old'],
          counts: const {'q-old': 2, 'q-new': 1},
        );
      },
    );

    await repo.loadCurrentUserRevision();
    expect(repo.currentCatalogRevision!.wrongQuestions, ['q-old']);

    version = 2;
    final state = await repo.refreshCurrentUserRevision();

    expect(state, CatalogRevisionLoadState.loaded);
    expect(repo.currentCatalogRevision!.wrongQuestions, ['q-new', 'q-old']);
    expect(repo.currentCatalogRevision!.mistakeCounts['q-old'], 2);
  });

  test('E: logout clears catalog revision cache', () async {
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
    final repo = buildRepo(
      cloudLoader: (_) async => snap(
        uid: 'user-a',
        wrong: const ['q-a'],
        counts: const {'q-a': 1},
      ),
    );
    await repo.loadCurrentUserRevision();
    expect(repo.currentCatalogRevision, isNotNull);

    coordinator.handleAuthState(null);

    expect(repo.catalogLoadState, CatalogRevisionLoadState.notLoaded);
    expect(repo.currentCatalogRevision, isNull);
  });

  test('F: user switch clears A and loads only B', () async {
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
    final repo = buildRepo(
      cloudLoader: (uid) async {
        if (uid == 'user-a') {
          return snap(
            uid: 'user-a',
            wrong: const ['q-a'],
            counts: const {'q-a': 2},
          );
        }
        return snap(
          uid: 'user-b',
          wrong: const ['q-b'],
          frequent: const ['q-b'],
          counts: const {'q-b': 4},
        );
      },
    );

    await repo.loadCurrentUserRevision();
    expect(repo.currentCatalogRevision!.wrongQuestions, ['q-a']);

    coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
    expect(repo.currentCatalogRevision, isNull);

    final state = await repo.loadCurrentUserRevision();
    expect(state, CatalogRevisionLoadState.loaded);
    expect(repo.currentCatalogRevision!.uid, 'user-b');
    expect(repo.currentCatalogRevision!.wrongQuestions, ['q-b']);
    expect(repo.currentCatalogRevision!.mistakeCounts['q-b'], 4);
  });

  test('G: late User A response does not overwrite User B cache', () async {
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
    final aGate = Completer<RevisionCloud?>();
    var loadCount = 0;

    final repo = buildRepo(
      cloudLoader: (uid) async {
        loadCount++;
        if (uid == 'user-a') {
          return aGate.future;
        }
        return snap(
          uid: 'user-b',
          wrong: const ['q-b'],
          counts: const {'q-b': 1},
        );
      },
    );

    final aLoad = repo.loadCurrentUserRevision();
    await Future<void>.delayed(Duration.zero);
    expect(repo.catalogLoadState, CatalogRevisionLoadState.loading);

    coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
    final bState = await repo.loadCurrentUserRevision();
    expect(bState, CatalogRevisionLoadState.loaded);
    expect(repo.currentCatalogRevision!.uid, 'user-b');
    expect(repo.currentCatalogRevision!.wrongQuestions, ['q-b']);

    aGate.complete(
      snap(
        uid: 'user-a',
        wrong: const ['q-a-stale'],
        counts: const {'q-a-stale': 9},
      ),
    );
    final aState = await aLoad;

    expect(aState, CatalogRevisionLoadState.notLoaded);
    expect(repo.currentCatalogRevision!.uid, 'user-b');
    expect(repo.currentCatalogRevision!.wrongQuestions, ['q-b']);
    expect(loadCount, greaterThanOrEqualTo(2));
  });

  test('network failure does not invent confirmed empty success', () async {
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
    final repo = buildRepo(
      cloudLoader: (_) async => throw Exception('network down'),
    );

    final state = await repo.loadCurrentUserRevision();

    expect(state, CatalogRevisionLoadState.error);
    expect(repo.catalogLoadState, CatalogRevisionLoadState.error);
    expect(repo.catalogLoadError, isA<Exception>());
    expect(repo.currentCatalogRevision, isNull);
  });

  test('RevisionCloud.fromFirestore reads mistakeCounts map', () {
    final cloud = RevisionCloud.fromFirestore('uid-1', {
      'uid': 'uid-1',
      'courseId': 'group-ii',
      'wrongQuestions': ['q1', 'q2'],
      'weakQuestions': <String>[],
      'frequentlyWrongQuestions': ['q1'],
      'mistakeCounts': {'q1': 2, 'q2': 1},
      'authority': 'server_verified',
      'appVersion': 'server-5.27',
    });

    expect(cloud.wrongQuestions, ['q1', 'q2']);
    expect(cloud.frequentlyWrongQuestions, ['q1']);
    expect(cloud.mistakeCounts, {'q1': 2, 'q2': 1});
    expect(cloud.authority, 'server_verified');
  });
}
