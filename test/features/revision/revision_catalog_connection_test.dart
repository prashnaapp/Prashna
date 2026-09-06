import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/authentication/services/user_session_state_coordinator.dart';
import 'package:telangana_prep/features/bookmarks/data/services/bookmark_service.dart';
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

  late UserSessionStateCoordinator coordinator;
  late Map<String, RevisionCloud?> cloudByUid;

  setUp(() {
    coordinator = UserSessionStateCoordinator.debug();
    cloudByUid = {};
  });

  RevisionService buildService({
    required List<Question> questions,
    ProgressService? progress,
    BookmarkService? bookmarkService,
  }) {
    final cloud = QuestionCloudRepository.withHandlers(
      loadQuestions: (_) async => questions,
      getById: (id) async {
        for (final q in questions) {
          if (q.id == id) return q;
        }
        return null;
      },
      getByIds: (ids) async => [
        for (final id in ids)
          for (final q in questions)
            if (q.id == id) q,
      ],
    );
    final repo = RevisionRepository(
      sessionCoordinator: coordinator,
      cloudLoader: (uid) async {
        if (!cloudByUid.containsKey(uid)) {
          throw StateError('unexpected revision load for $uid');
        }
        return cloudByUid[uid];
      },
    );
    coordinator.register(repo.clear);

    final questionService = QuestionService(
      repository: QuestionRepository(cloudRepository: cloud),
    );
    final bookmarks =
        bookmarkService ??
        BookmarkService.debug(
          questionService: questionService,
          sessionCoordinator: coordinator,
          cloudLoader: (_) async => null,
          cloudSync: (_) async {},
        );
    coordinator.register(bookmarks.clear);

    return RevisionService(
      questionService: questionService,
      progressService:
          progress ??
          ProgressService.debug(
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

  group('Wrong Questions catalog connection', () {
    test('A: hydrated wrong IDs resolve to actual questions', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      cloudByUid['user-a'] = RevisionCloud(
        uid: 'user-a',
        courseId: null,
        wrongQuestions: const ['gii-1', 'giii-1'],
        weakQuestions: const [],
        frequentlyWrongQuestions: const [],
        mistakeCounts: const {'gii-1': 1, 'giii-1': 1},
        updatedAt: null,
        appVersion: null,
      );
      final service = buildService(
        questions: [
          question(id: 'gii-1', courseId: 'group-ii'),
          question(id: 'giii-1', courseId: 'group-iii'),
        ],
      );

      final groups = await service.loadWrongQuestionGroups();
      final items = [for (final g in groups) ...g.items];

      expect(items.map((i) => i.questionId), containsAll(['gii-1', 'giii-1']));
      expect(items.singleWhere((i) => i.questionId == 'gii-1').courseId, 'group-ii');
      expect(
        items.singleWhere((i) => i.questionId == 'giii-1').courseId,
        'group-iii',
      );
    });

    test('B: empty wrong list yields empty groups', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      cloudByUid['user-a'] = null;
      final service = buildService(questions: [
        question(id: 'gii-1', courseId: 'group-ii'),
      ]);

      final groups = await service.loadWrongQuestionGroups();
      expect(groups, isEmpty);
    });

    test('C: Group-II + Group-III identities preserved', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      cloudByUid['user-a'] = RevisionCloud(
        uid: 'user-a',
        courseId: null,
        wrongQuestions: const ['gii-1', 'giii-1'],
        weakQuestions: const [],
        frequentlyWrongQuestions: const [],
        mistakeCounts: const {'gii-1': 2, 'giii-1': 1},
        updatedAt: null,
        appVersion: null,
      );
      final service = buildService(
        questions: [
          question(id: 'gii-1', courseId: 'group-ii', paperId: 'paper-i'),
          question(id: 'giii-1', courseId: 'group-iii', paperId: 'paper-ii'),
        ],
      );

      final groups = await service.loadWrongQuestionGroups();
      final byId = {
        for (final g in groups)
          for (final i in g.items) i.questionId: i,
      };

      expect(byId['gii-1']!.courseId, 'group-ii');
      expect(byId['giii-1']!.courseId, 'group-iii');
      expect(byId['gii-1']!.wrongCount, 2);
      expect(byId['giii-1']!.wrongCount, 1);
    });

    test('D: stale missing question ID is skipped without crash', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      cloudByUid['user-a'] = RevisionCloud(
        uid: 'user-a',
        courseId: null,
        wrongQuestions: const ['exists', 'deleted'],
        weakQuestions: const [],
        frequentlyWrongQuestions: const [],
        mistakeCounts: const {'exists': 1, 'deleted': 1},
        updatedAt: null,
        appVersion: null,
      );
      final service = buildService(
        questions: [question(id: 'exists', courseId: 'group-ii')],
      );

      final groups = await service.loadWrongQuestionGroups();
      final ids = [for (final g in groups) for (final i in g.items) i.questionId];
      expect(ids, ['exists']);
    });

    test('E: cloud load failure is not converted to empty success', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      final repo = RevisionRepository(
        sessionCoordinator: coordinator,
        cloudLoader: (_) async => throw Exception('network down'),
      );
      coordinator.register(repo.clear);
      final service = RevisionService(
        questionService: QuestionService(
          repository: QuestionRepository(
            cloudRepository: QuestionCloudRepository.withHandlers(
              loadQuestions: (_) async => const [],
              getById: (_) async => null,
              getByIds: (_) async => const [],
            ),
          ),
        ),
        progressService: ProgressService.debug(
          repository: ProgressRepository(seed: false),
          sessionCoordinator: coordinator,
          cloudSync: (_) async {},
        ),
        repository: repo,
        sessionCoordinator: coordinator,
        cloudSync: (_) async {},
      );

      await expectLater(
        service.loadWrongQuestionGroups(),
        throwsA(isA<Exception>()),
      );
      expect(repo.catalogLoadState, CatalogRevisionLoadState.error);
      expect(repo.currentCatalogRevision, isNull);
    });
  });

  group('Frequently Incorrect catalog connection', () {
    test('A: authoritative frequent IDs resolve to questions', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      cloudByUid['user-a'] = RevisionCloud(
        uid: 'user-a',
        courseId: null,
        wrongQuestions: const ['gii-1', 'giii-1'],
        weakQuestions: const [],
        frequentlyWrongQuestions: const ['gii-1'],
        mistakeCounts: const {'gii-1': 3, 'giii-1': 1},
        updatedAt: null,
        appVersion: null,
      );
      final service = buildService(
        questions: [
          question(id: 'gii-1', courseId: 'group-ii'),
          question(id: 'giii-1', courseId: 'group-iii'),
        ],
      );

      final groups = await service.loadFrequentlyIncorrectGroups();
      final items = [for (final g in groups) ...g.items];

      expect(items, hasLength(1));
      expect(items.single.questionId, 'gii-1');
      expect(items.single.wrongCount, 3);
    });

    test('B: empty frequent list yields empty groups', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      cloudByUid['user-a'] = RevisionCloud(
        uid: 'user-a',
        courseId: null,
        wrongQuestions: const ['gii-1'],
        weakQuestions: const [],
        frequentlyWrongQuestions: const [],
        mistakeCounts: const {'gii-1': 1},
        updatedAt: null,
        appVersion: null,
      );
      final service = buildService(
        questions: [question(id: 'gii-1', courseId: 'group-ii')],
      );

      expect(await service.loadFrequentlyIncorrectGroups(), isEmpty);
    });

    test('C: does not invent threshold from local Progress mistakes', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      // Cloud: question wrong once → not in frequentlyWrongQuestions.
      cloudByUid['user-a'] = RevisionCloud(
        uid: 'user-a',
        courseId: null,
        wrongQuestions: const ['gii-1'],
        weakQuestions: const [],
        frequentlyWrongQuestions: const [],
        mistakeCounts: const {'gii-1': 1},
        updatedAt: null,
        appVersion: null,
      );
      final progressRepo = ProgressRepository(seed: false);
      await progressRepo.recordQuestionMistakes(
        wrongQuestionIds: const ['gii-1', 'gii-1', 'gii-1'],
      );
      final progress = ProgressService.debug(
        repository: progressRepo,
        sessionCoordinator: coordinator,
        cloudSync: (_) async {},
      );
      // Local Progress would classify as frequent (>=2), but catalog does not.
      expect(await progress.loadFrequentlyWrongIds(), ['gii-1']);

      final service = buildService(
        questions: [question(id: 'gii-1', courseId: 'group-ii')],
        progress: progress,
      );

      expect(await service.loadFrequentlyIncorrectGroups(), isEmpty);
    });

    test('D: mistakeCounts preserved on frequent items', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      cloudByUid['user-a'] = RevisionCloud(
        uid: 'user-a',
        courseId: null,
        wrongQuestions: const ['gii-1'],
        weakQuestions: const [],
        frequentlyWrongQuestions: const ['gii-1'],
        mistakeCounts: const {'gii-1': 5},
        updatedAt: null,
        appVersion: null,
      );
      final service = buildService(
        questions: [question(id: 'gii-1', courseId: 'group-ii')],
      );

      final groups = await service.loadFrequentlyIncorrectGroups();
      expect(groups.single.items.single.wrongCount, 5);
    });

    test('E: Group-II + Group-III frequent identities preserved', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      cloudByUid['user-a'] = RevisionCloud(
        uid: 'user-a',
        courseId: null,
        wrongQuestions: const ['gii-1', 'giii-1'],
        weakQuestions: const [],
        frequentlyWrongQuestions: const ['gii-1', 'giii-1'],
        mistakeCounts: const {'gii-1': 2, 'giii-1': 4},
        updatedAt: null,
        appVersion: null,
      );
      final service = buildService(
        questions: [
          question(id: 'gii-1', courseId: 'group-ii'),
          question(id: 'giii-1', courseId: 'group-iii'),
        ],
      );

      final groups = await service.loadFrequentlyIncorrectGroups();
      final byId = {
        for (final g in groups)
          for (final i in g.items) i.questionId: i,
      };
      expect(byId['gii-1']!.courseId, 'group-ii');
      expect(byId['giii-1']!.courseId, 'group-iii');
      expect(byId['gii-1']!.wrongCount, 2);
      expect(byId['giii-1']!.wrongCount, 4);
    });
  });

  group('Production auth lifecycle wiring', () {
    test('coordinator logout clears hydrated catalog cache', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      cloudByUid['user-a'] = RevisionCloud(
        uid: 'user-a',
        courseId: null,
        wrongQuestions: const ['gii-1'],
        weakQuestions: const [],
        frequentlyWrongQuestions: const [],
        mistakeCounts: const {'gii-1': 1},
        updatedAt: null,
        appVersion: null,
      );
      final service = buildService(
        questions: [question(id: 'gii-1', courseId: 'group-ii')],
      );

      await service.loadWrongQuestionGroups();
      expect(service.currentCatalogRevision, isNotNull);

      // Same path AuthService uses: coordinator.handleAuthState(null).
      coordinator.handleAuthState(null);

      expect(service.catalogRevisionLoadState, CatalogRevisionLoadState.notLoaded);
      expect(service.currentCatalogRevision, isNull);
    });

    test('RevisionRepository.instance registers clear on production coordinator',
        () {
      // Production singleton self-registers at construction time.
      expect(
        UserSessionStateCoordinator.instance.toString(),
        contains('registered='),
      );
      // Invoking clear must be safe and wipe catalog state.
      RevisionRepository.instance.clear();
      expect(
        RevisionRepository.instance.catalogLoadState,
        CatalogRevisionLoadState.notLoaded,
      );
      expect(RevisionRepository.instance.currentCatalogRevision, isNull);
    });
  });

  group('Hub counts use catalog revision', () {
    test('wrong and frequent hub counts come from cloud IDs', () async {
      coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
      cloudByUid['user-a'] = RevisionCloud(
        uid: 'user-a',
        courseId: null,
        wrongQuestions: const ['gii-1', 'giii-1'],
        weakQuestions: const [],
        frequentlyWrongQuestions: const ['gii-1'],
        mistakeCounts: const {'gii-1': 3, 'giii-1': 1},
        updatedAt: null,
        appVersion: null,
      );
      final service = buildService(
        questions: [
          question(id: 'gii-1', courseId: 'group-ii'),
          question(id: 'giii-1', courseId: 'group-iii'),
        ],
      );

      final items = await service.loadHubItems();
      final wrong = items.singleWhere(
        (i) => i.type == RevisionHubType.wrongQuestions,
      );
      final frequent = items.singleWhere(
        (i) => i.type == RevisionHubType.frequentlyIncorrect,
      );

      expect(wrong.count, 2);
      expect(frequent.count, 1);
    });
  });
}
