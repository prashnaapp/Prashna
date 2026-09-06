import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/authentication/services/user_session_state_coordinator.dart';
import 'package:telangana_prep/features/bookmarks/data/models/bookmark_models.dart';
import 'package:telangana_prep/features/bookmarks/data/services/bookmark_service.dart';
import 'package:telangana_prep/features/bookmarks/presentation/screens/bookmarks_screen.dart';
import 'package:telangana_prep/features/bookmarks_cloud/model/bookmark_cloud.dart';
import 'package:telangana_prep/features/progress/data/repositories/progress_repository.dart';
import 'package:telangana_prep/features/progress/services/progress_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/revision/data/models/revision_models.dart';
import 'package:telangana_prep/features/revision/data/repositories/revision_repository.dart';
import 'package:telangana_prep/features/revision/services/revision_service.dart';
import 'package:telangana_prep/features/revision_cloud/model/revision_cloud.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

void main() {
  final now = DateTime(2026, 9, 6);

  Question question({
    required String id,
    required String courseId,
    String paperId = 'paper-i',
    String text = '',
  }) {
    return Question(
      id: id,
      courseId: courseId,
      paperId: paperId,
      correctOption: 'A',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 30),
      createdAt: now,
      updatedAt: now,
      isActive: true,
      status: QuestionPublicationStatus.published,
      question: text.isEmpty ? 'Q $id' : text,
      options: const ['A', 'B', 'C', 'D'],
      syllabus: QuestionSyllabusAttribution(
        courseId: courseId,
        paperId: paperId,
      ),
    );
  }

  BookmarkCloud cloud({
    required String uid,
    required List<String> questionIds,
    String? courseId,
  }) {
    return BookmarkCloud(
      uid: uid,
      courseId: courseId,
      questionIds: questionIds,
      updatedAt: null,
      appVersion: null,
    );
  }

  late UserSessionStateCoordinator coordinator;

  setUp(() {
    coordinator = UserSessionStateCoordinator.debug();
  });

  QuestionService questionsFor(List<Question> items) {
    return QuestionService(
      repository: QuestionRepository(
        cloudRepository: QuestionCloudRepository.withHandlers(
          loadQuestions: (_) async => items,
          getById: (id) async {
            for (final q in items) {
              if (q.id == id) return q;
            }
            return null;
          },
          getByIds: (ids) async => [
            for (final id in ids)
              for (final q in items)
                if (q.id == id) q,
          ],
        ),
      ),
    );
  }

  BookmarkService buildBookmarks({
    required List<Question> questions,
    required Future<BookmarkCloud?> Function(String uid) cloudLoader,
    Future<void> Function(BookmarkCloud snapshot)? cloudSync,
  }) {
    final service = BookmarkService.debug(
      questionService: questionsFor(questions),
      sessionCoordinator: coordinator,
      cloudLoader: cloudLoader,
      cloudSync: cloudSync ?? (_) async {},
    );
    coordinator.register(service.clear);
    return service;
  }

  group('Bookmark cloud hydration', () {
    test('1: successful cloud bookmark hydration', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final service = buildBookmarks(
        questions: [
          question(id: 'q1', courseId: 'group-ii'),
          question(id: 'q2', courseId: 'group-iii'),
        ],
        cloudLoader: (_) async => cloud(
          uid: 'user-a',
          questionIds: const ['q1', 'q2'],
          courseId: 'stale-last-write',
        ),
      );

      final state = await service.loadCurrentUserBookmarks();

      expect(state, BookmarkLoadState.loaded);
      expect(
        service.currentBookmarks.map((b) => b.questionId),
        ['q1', 'q2'],
      );
      expect(service.bookmarkLoadState, BookmarkLoadState.loaded);
    });

    test('2: missing Firestore document → loaded + empty', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final service = buildBookmarks(
        questions: [question(id: 'q1', courseId: 'group-ii')],
        cloudLoader: (_) async => null,
      );

      final state = await service.loadCurrentUserBookmarks();

      expect(state, BookmarkLoadState.loaded);
      expect(service.currentBookmarks, isEmpty);
      expect(service.bookmarkLoadError, isNull);
    });

    test('3: cloud/network error → error, NOT empty success', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final service = buildBookmarks(
        questions: [question(id: 'q1', courseId: 'group-ii')],
        cloudLoader: (_) async => throw Exception('network down'),
      );

      final state = await service.loadCurrentUserBookmarks();

      expect(state, BookmarkLoadState.error);
      expect(service.bookmarkLoadState, BookmarkLoadState.error);
      expect(service.bookmarkLoadError, isNotNull);
      expect(service.currentBookmarks, isEmpty);
    });

    test('4: duplicate IDs dedupe preserving order', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final service = buildBookmarks(
        questions: [
          question(id: 'q1', courseId: 'group-ii'),
          question(id: 'q2', courseId: 'group-ii'),
          question(id: 'q3', courseId: 'group-ii'),
        ],
        cloudLoader: (_) async => cloud(
          uid: 'user-a',
          questionIds: const ['q1', 'q2', 'q1', 'q3'],
        ),
      );

      await service.loadCurrentUserBookmarks();

      expect(
        service.currentBookmarks.map((b) => b.questionId),
        ['q1', 'q2', 'q3'],
      );
    });

    test('5: stale question IDs are safely skipped', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final service = buildBookmarks(
        questions: [
          question(id: 'q1', courseId: 'group-ii'),
          question(id: 'q3', courseId: 'group-ii'),
        ],
        cloudLoader: (_) async => cloud(
          uid: 'user-a',
          questionIds: const ['q1', 'q2', 'q3'],
        ),
      );

      await service.loadCurrentUserBookmarks();

      expect(
        service.currentBookmarks.map((b) => b.questionId),
        ['q1', 'q3'],
      );
    });

    test('6: partial question resolution still shows valid bookmarks', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final service = buildBookmarks(
        questions: [question(id: 'valid', courseId: 'group-ii')],
        cloudLoader: (_) async => cloud(
          uid: 'user-a',
          questionIds: const ['missing-a', 'valid', 'missing-b'],
        ),
      );

      final state = await service.loadCurrentUserBookmarks();

      expect(state, BookmarkLoadState.loaded);
      expect(service.currentBookmarks.single.questionId, 'valid');
    });

    test('7: mixed Group-II + Group-III hydrate via Question.courseId', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final service = buildBookmarks(
        questions: [
          question(id: 'gii-1', courseId: 'group-ii'),
          question(id: 'giii-1', courseId: 'group-iii'),
        ],
        cloudLoader: (_) async => cloud(
          uid: 'user-a',
          courseId: 'group-ii',
          questionIds: const ['gii-1', 'giii-1'],
        ),
      );

      await service.loadCurrentUserBookmarks();
      final byId = {
        for (final b in service.currentBookmarks) b.questionId: b,
      };

      expect(byId['gii-1']!.courseId, 'group-ii');
      expect(byId['giii-1']!.courseId, 'group-iii');
    });

    test('8: logout clears bookmark cache', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final service = buildBookmarks(
        questions: [question(id: 'q1', courseId: 'group-ii')],
        cloudLoader: (_) async =>
            cloud(uid: 'user-a', questionIds: const ['q1']),
      );
      await service.loadCurrentUserBookmarks();
      expect(service.currentBookmarks, isNotEmpty);

      coordinator.handleAuthState(null);

      expect(service.bookmarkLoadState, BookmarkLoadState.notLoaded);
      expect(service.currentBookmarks, isEmpty);
    });

    test('9: user switch never leaks User A bookmarks to User B', () async {
      final clouds = <String, BookmarkCloud?>{
        'user-a': cloud(uid: 'user-a', questionIds: const ['qa']),
        'user-b': cloud(uid: 'user-b', questionIds: const ['qb']),
      };
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final service = buildBookmarks(
        questions: [
          question(id: 'qa', courseId: 'group-ii'),
          question(id: 'qb', courseId: 'group-iii'),
        ],
        cloudLoader: (uid) async => clouds[uid],
      );

      await service.loadCurrentUserBookmarks();
      expect(service.currentBookmarks.single.questionId, 'qa');

      coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
      expect(service.currentBookmarks, isEmpty);
      expect(service.bookmarkLoadState, BookmarkLoadState.notLoaded);

      await service.loadCurrentUserBookmarks();
      expect(service.currentBookmarks.single.questionId, 'qb');
    });

    test('10: async race — late User A response cannot overwrite User B',
        () async {
      final gate = Completer<BookmarkCloud?>();
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final service = buildBookmarks(
        questions: [
          question(id: 'qa', courseId: 'group-ii'),
          question(id: 'qb', courseId: 'group-iii'),
        ],
        cloudLoader: (uid) async {
          if (uid == 'user-a') return gate.future;
          return cloud(uid: 'user-b', questionIds: const ['qb']);
        },
      );

      final lateLoad = service.loadCurrentUserBookmarks();
      coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
      await service.loadCurrentUserBookmarks();
      expect(service.currentBookmarks.single.questionId, 'qb');

      gate.complete(cloud(uid: 'user-a', questionIds: const ['qa']));
      final lateState = await lateLoad;

      expect(lateState, BookmarkLoadState.notLoaded);
      expect(service.currentBookmarks.single.questionId, 'qb');
      expect(
        service.currentBookmarks.map((b) => b.questionId),
        isNot(contains('qa')),
      );
    });

    test('11: concurrent load requests are coalesced', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      var loads = 0;
      final gate = Completer<BookmarkCloud?>();
      final service = buildBookmarks(
        questions: [question(id: 'q1', courseId: 'group-ii')],
        cloudLoader: (_) async {
          loads++;
          return gate.future;
        },
      );

      final a = service.loadCurrentUserBookmarks();
      final b = service.loadCurrentUserBookmarks();
      expect(service.bookmarkLoadState, BookmarkLoadState.loading);

      gate.complete(cloud(uid: 'user-a', questionIds: const ['q1']));
      expect(await a, BookmarkLoadState.loaded);
      expect(await b, BookmarkLoadState.loaded);
      expect(loads, 1);
    });

    test('12: session reuse skips unnecessary cloud reload', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      var loads = 0;
      final service = buildBookmarks(
        questions: [question(id: 'q1', courseId: 'group-ii')],
        cloudLoader: (_) async {
          loads++;
          return cloud(uid: 'user-a', questionIds: const ['q1']);
        },
      );

      await service.loadCurrentUserBookmarks();
      await service.loadCurrentUserBookmarks();
      await service.loadCurrentUserBookmarks();

      expect(loads, 1);
      expect(service.bookmarkLoadState, BookmarkLoadState.loaded);
    });

    test('no authenticated user does not read cloud', () async {
      var loads = 0;
      final service = buildBookmarks(
        questions: const [],
        cloudLoader: (_) async {
          loads++;
          return null;
        },
      );

      final state = await service.loadCurrentUserBookmarks();
      expect(state, BookmarkLoadState.notLoaded);
      expect(loads, 0);
    });

    test('add/remove updates session cache without waiting for hydrate',
        () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      var syncs = 0;
      final service = buildBookmarks(
        questions: [question(id: 'q1', courseId: 'group-ii')],
        cloudLoader: (_) async => null,
        cloudSync: (_) async {
          syncs++;
        },
      );
      await service.loadCurrentUserBookmarks();

      await service.addBookmark(questionId: 'q1');
      expect(service.isBookmarked('q1'), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(syncs, greaterThan(0));

      await service.removeBookmark('q1');
      expect(service.isBookmarked('q1'), isFalse);
    });
  });

  group('Revision Center bookmark states', () {
    RevisionService buildHub({
      required BookmarkService bookmarks,
      RevisionCloud? revision,
    }) {
      final repo = RevisionRepository(
        sessionCoordinator: coordinator,
        cloudLoader: (_) async => revision,
      );
      coordinator.register(repo.clear);
      return RevisionService(
        questionService: questionsFor(const []),
        progressService: ProgressService.debug(
          repository: ProgressRepository(seed: false),
          sessionCoordinator: coordinator,
          cloudSync: (_) async {},
        ),
        testService: TestService(),
        bookmarkService: bookmarks,
        repository: repo,
        sessionCoordinator: coordinator,
        cloudSync: (_) async {},
      );
    }

    test('13a: loaded with bookmarks reports count', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final bookmarks = buildBookmarks(
        questions: [question(id: 'q1', courseId: 'group-ii')],
        cloudLoader: (_) async =>
            cloud(uid: 'user-a', questionIds: const ['q1']),
      );
      final hub = buildHub(bookmarks: bookmarks);

      final items = await hub.loadHubItems();
      final card =
          items.singleWhere((i) => i.type == RevisionHubType.bookmarked);
      expect(card.hasError, isFalse);
      expect(card.count, 1);
    });

    test('13b: loaded empty reports Empty (count 0, no error)', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final bookmarks = buildBookmarks(
        questions: const [],
        cloudLoader: (_) async => null,
      );
      final hub = buildHub(bookmarks: bookmarks);

      final items = await hub.loadHubItems();
      final card =
          items.singleWhere((i) => i.type == RevisionHubType.bookmarked);
      expect(card.hasError, isFalse);
      expect(card.count, 0);
    });

    test('13c: error never looks like empty', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final bookmarks = buildBookmarks(
        questions: const [],
        cloudLoader: (_) async => throw Exception('offline'),
      );
      final hub = buildHub(bookmarks: bookmarks);

      final items = await hub.loadHubItems();
      final card =
          items.singleWhere((i) => i.type == RevisionHubType.bookmarked);
      expect(card.hasError, isTrue);
      expect(card.count, 0);
    });

    test('forceRefresh does not force bookmark cloud reload', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      var bookmarkLoads = 0;
      var revisionLoads = 0;
      final bookmarks = buildBookmarks(
        questions: [question(id: 'q1', courseId: 'group-ii')],
        cloudLoader: (_) async {
          bookmarkLoads++;
          return cloud(uid: 'user-a', questionIds: const ['q1']);
        },
      );
      final repo = RevisionRepository(
        sessionCoordinator: coordinator,
        cloudLoader: (_) async {
          revisionLoads++;
          return RevisionCloud.emptyForUser('user-a');
        },
      );
      coordinator.register(repo.clear);
      final hub = RevisionService(
        questionService: questionsFor([
          question(id: 'q1', courseId: 'group-ii'),
        ]),
        progressService: ProgressService.debug(
          repository: ProgressRepository(seed: false),
          sessionCoordinator: coordinator,
          cloudSync: (_) async {},
        ),
        testService: TestService(),
        bookmarkService: bookmarks,
        repository: repo,
        sessionCoordinator: coordinator,
        cloudSync: (_) async {},
      );

      await hub.loadHubItems();
      await hub.loadHubItems(forceRefresh: true);

      expect(bookmarkLoads, 1);
      expect(revisionLoads, 2);
    });
  });

  group('Bookmarks Screen direct loading', () {
    testWidgets(
      '14: loads via shared BookmarkService without Revision Center',
      (tester) async {
        coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
        final gate = Completer<BookmarkCloud?>();
        final bookmarks = buildBookmarks(
          questions: [
            question(
              id: 'q1',
              courseId: 'group-ii',
              text: 'Bookmarked stem',
            ),
          ],
          cloudLoader: (_) => gate.future,
        );

        await tester.pumpWidget(
          MaterialApp(home: BookmarksScreen(bookmarkService: bookmarks)),
        );
        expect(find.byType(CircularProgressIndicator), findsWidgets);

        gate.complete(cloud(uid: 'user-a', questionIds: const ['q1']));
        await tester.pumpAndSettle();

        expect(find.text('Bookmarked stem'), findsOneWidget);
        expect(find.text('No bookmarked questions.'), findsNothing);
      },
    );

    testWidgets('14b: error state is distinct from empty', (tester) async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final bookmarks = buildBookmarks(
        questions: const [],
        cloudLoader: (_) async => throw Exception('offline'),
      );

      await tester.pumpWidget(
        MaterialApp(home: BookmarksScreen(bookmarkService: bookmarks)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load bookmarks'), findsOneWidget);
      expect(find.text('No bookmarked questions.'), findsNothing);
    });
  });

  group('Regression: wrong / frequent / revision hydrate / session races', () {
    test('15a: wrong questions still hydrate from catalog', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final bookmarks = buildBookmarks(
        questions: [question(id: 'gii-1', courseId: 'group-ii')],
        cloudLoader: (_) async => null,
      );
      final repo = RevisionRepository(
        sessionCoordinator: coordinator,
        cloudLoader: (_) async => RevisionCloud(
          uid: 'user-a',
          courseId: null,
          wrongQuestions: const ['gii-1'],
          weakQuestions: const [],
          frequentlyWrongQuestions: const [],
          mistakeCounts: const {'gii-1': 1},
          updatedAt: null,
          appVersion: null,
        ),
      );
      coordinator.register(repo.clear);
      final service = RevisionService(
        questionService: questionsFor([
          question(id: 'gii-1', courseId: 'group-ii'),
        ]),
        progressService: ProgressService.debug(
          repository: ProgressRepository(seed: false),
          sessionCoordinator: coordinator,
          cloudSync: (_) async {},
        ),
        bookmarkService: bookmarks,
        repository: repo,
        sessionCoordinator: coordinator,
        cloudSync: (_) async {},
      );

      final groups = await service.loadWrongQuestionGroups();
      expect(groups.single.items.single.questionId, 'gii-1');
    });

    test('15b: frequently incorrect still hydrate from catalog', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final bookmarks = buildBookmarks(
        questions: [question(id: 'gii-1', courseId: 'group-ii')],
        cloudLoader: (_) async => null,
      );
      final repo = RevisionRepository(
        sessionCoordinator: coordinator,
        cloudLoader: (_) async => RevisionCloud(
          uid: 'user-a',
          courseId: null,
          wrongQuestions: const ['gii-1'],
          weakQuestions: const [],
          frequentlyWrongQuestions: const ['gii-1'],
          mistakeCounts: const {'gii-1': 3},
          updatedAt: null,
          appVersion: null,
        ),
      );
      coordinator.register(repo.clear);
      final service = RevisionService(
        questionService: questionsFor([
          question(id: 'gii-1', courseId: 'group-ii'),
        ]),
        progressService: ProgressService.debug(
          repository: ProgressRepository(seed: false),
          sessionCoordinator: coordinator,
          cloudSync: (_) async {},
        ),
        bookmarkService: bookmarks,
        repository: repo,
        sessionCoordinator: coordinator,
        cloudSync: (_) async {},
      );

      final groups = await service.loadFrequentlyIncorrectGroups();
      expect(groups.single.items.single.wrongCount, 3);
    });

    test('15c: revision catalog session race still protected', () async {
      final gate = Completer<RevisionCloud?>();
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final repo = RevisionRepository(
        sessionCoordinator: coordinator,
        cloudLoader: (uid) async {
          if (uid == 'user-a') return gate.future;
          return RevisionCloud.emptyForUser(uid);
        },
      );
      coordinator.register(repo.clear);

      final late = repo.loadCurrentUserRevision();
      coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
      await repo.loadCurrentUserRevision();
      gate.complete(
        RevisionCloud(
          uid: 'user-a',
          courseId: null,
          wrongQuestions: const ['qa'],
          weakQuestions: const [],
          frequentlyWrongQuestions: const [],
          mistakeCounts: const {'qa': 1},
          updatedAt: null,
          appVersion: null,
        ),
      );
      await late;
      expect(repo.currentCatalogRevision!.uid, 'user-b');
      expect(repo.currentCatalogRevision!.wrongQuestions, isEmpty);
    });
  });
}
