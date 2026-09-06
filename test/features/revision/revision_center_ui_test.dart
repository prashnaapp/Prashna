import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/authentication/services/user_session_state_coordinator.dart';
import 'package:telangana_prep/features/bookmarks/data/models/bookmark_models.dart';
import 'package:telangana_prep/features/bookmarks/data/services/bookmark_service.dart';
import 'package:telangana_prep/features/bookmarks/presentation/screens/bookmarks_screen.dart';
import 'package:telangana_prep/features/progress/data/repositories/progress_repository.dart';
import 'package:telangana_prep/features/progress/services/progress_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/revision/data/models/revision_models.dart';
import 'package:telangana_prep/features/revision/data/repositories/revision_repository.dart';
import 'package:telangana_prep/features/revision/presentation/screens/frequently_incorrect_screen.dart';
import 'package:telangana_prep/features/revision/presentation/screens/revision_center_screen.dart';
import 'package:telangana_prep/features/revision/presentation/screens/wrong_questions_screen.dart';
import 'package:telangana_prep/features/revision/presentation/widgets/revision_hub_card.dart';
import 'package:telangana_prep/features/revision/services/revision_service.dart';
import 'package:telangana_prep/features/revision_cloud/model/revision_cloud.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

void main() {
  final now = DateTime(2026, 9, 6);

  Question question({
    required String id,
    required String courseId,
  }) {
    return Question(
      id: id,
      courseId: courseId,
      paperId: 'paper-i',
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
      question: 'Q $id',
      options: const ['A', 'B', 'C', 'D'],
      syllabus: QuestionSyllabusAttribution(
        courseId: courseId,
        paperId: 'paper-i',
      ),
    );
  }

  Bookmark bookmarkFor(Question q) {
    return Bookmark(
      questionId: q.id,
      courseId: q.courseId,
      courseName: q.courseId,
      paperId: q.paperId,
      paperName: q.paperId,
      partId: '',
      partName: '',
      chapterId: '',
      chapterName: '',
      questionType: q.questionType.name,
      questionTitle: q.question,
      createdAt: now,
    );
  }

  late UserSessionStateCoordinator coordinator;

  setUp(() {
    coordinator = UserSessionStateCoordinator.debug();
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));
  });

  RevisionService buildService({
    List<String> wrong = const ['q1'],
    List<String> frequent = const ['q1'],
    List<String> bookmarkIds = const [],
  }) {
    final questions = [
      question(id: 'q1', courseId: 'group-ii'),
      question(id: 'q2', courseId: 'group-iii'),
    ];
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
    final questionService = QuestionService(
      repository: QuestionRepository(cloudRepository: cloud),
    );
    final bookmarks = BookmarkService.debug(
      questionService: questionService,
      sessionCoordinator: coordinator,
      cloudLoader: (_) async => null,
      cloudSync: (_) async {},
    );
    if (bookmarkIds.isNotEmpty) {
      bookmarks.debugSetBookmarks([
        for (final id in bookmarkIds)
          bookmarkFor(questions.firstWhere((q) => q.id == id)),
      ]);
    }
    coordinator.register(bookmarks.clear);

    final repo = RevisionRepository(
      sessionCoordinator: coordinator,
      cloudLoader: (_) async => RevisionCloud(
        uid: 'user-a',
        courseId: null,
        wrongQuestions: wrong,
        weakQuestions: const [],
        frequentlyWrongQuestions: frequent,
        mistakeCounts: {
          for (final id in {...wrong, ...frequent}) id: 2,
        },
        updatedAt: null,
        appVersion: null,
      ),
    );
    coordinator.register(repo.clear);

    return RevisionService(
      questionService: questionService,
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

  group('Revision Center hub composition', () {
    test('loadHubItems returns exactly 3 cards without Weak Topics', () async {
      final service = buildService();
      final items = await service.loadHubItems();

      expect(items, hasLength(3));
      expect(
        items.map((i) => i.type),
        [
          RevisionHubType.wrongQuestions,
          RevisionHubType.bookmarked,
          RevisionHubType.frequentlyIncorrect,
        ],
      );
      expect(
        items.any((i) => i.type == RevisionHubType.weakTopics),
        isFalse,
      );
    });

    test('Weak Topics logic remains available via loadWeakTopicGroups',
        () async {
      final service = buildService();
      final groups = await service.loadWeakTopicGroups();
      expect(groups, isA<List<RevisionWeakTopicGroup>>());
    });
  });

  group('RevisionHubCard visual contract', () {
    testWidgets('renders title + count badge — no descriptive secondary text',
        (tester) async {
      const item = RevisionHubItem(
        type: RevisionHubType.wrongQuestions,
        title: 'Wrong Questions',
        subtitle: 'Questions answered incorrectly',
        count: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RevisionHubCard(item: item, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Wrong Questions'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Questions answered incorrectly'), findsNothing);
      expect(find.text('Empty'), findsNothing);
      expect(find.text('3 questions'), findsNothing);
      expect(find.text('Could not load'), findsNothing);
    });

    testWidgets('zero count badge displays 0 without empty copy', (tester) async {
      const item = RevisionHubItem(
        type: RevisionHubType.bookmarked,
        title: 'Bookmarked Questions',
        subtitle: 'Saved while practicing',
        count: 0,
        hasError: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RevisionHubCard(item: item, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Bookmarked Questions'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Saved while practicing'), findsNothing);
      expect(find.text('Could not load'), findsNothing);
      expect(find.text('Empty'), findsNothing);
    });
  });

  group('Revision Center screen layout', () {
    Future<void> pumpCenter(
      WidgetTester tester, {
      required RevisionService service,
      double width = 390,
    }) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 844)),
          child: MaterialApp(
            home: RevisionCenterScreen(revisionService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows premium hero, 3 cards in order, motivation footer',
        (tester) async {
      final service = buildService(bookmarkIds: const ['q1']);
      await pumpCenter(tester, service: service);

      expect(find.text('PRACTICE • REVIEW • IMPROVE'), findsOneWidget);
      expect(find.text('Practice what\nneeds your\nattention'), findsOneWidget);
      expect(find.text('Revise everything\nin one place'), findsNothing);
      expect(find.textContaining('Review your mistakes'), findsNothing);

      expect(find.text('Weak Topics'), findsNothing);
      expect(find.text('Wrong Questions'), findsOneWidget);
      expect(find.text('Bookmarked Questions'), findsOneWidget);
      expect(find.text('Frequently Incorrect'), findsOneWidget);
      expect(find.byType(RevisionHubCard), findsNWidgets(3));

      final cardKeys = tester
          .widgetList<RevisionHubCard>(find.byType(RevisionHubCard))
          .map((c) => c.item.type)
          .toList();
      expect(cardKeys, [
        RevisionHubType.wrongQuestions,
        RevisionHubType.bookmarked,
        RevisionHubType.frequentlyIncorrect,
      ]);

      expect(find.text('Questions answered incorrectly'), findsNothing);
      expect(find.text('Saved while practicing'), findsNothing);
      expect(find.text('Missed more than once'), findsNothing);
      expect(find.text('Empty'), findsNothing);
      expect(find.text('3 questions'), findsNothing);
      expect(find.text('Could not load'), findsNothing);

      expect(find.text('Small steps.\nStronger results.'), findsOneWidget);
      expect(find.text("Keep revising. You've got this."), findsOneWidget);
    });

    testWidgets('dynamic counts render from hydrated hub items', (tester) async {
      final service = buildService(
        wrong: const ['q1', 'q2'],
        frequent: const ['q1'],
        bookmarkIds: const [],
      );
      final items = await service.loadHubItems();
      await pumpCenter(tester, service: service);

      final wrong = items.singleWhere(
        (i) => i.type == RevisionHubType.wrongQuestions,
      );
      final bookmarked = items.singleWhere(
        (i) => i.type == RevisionHubType.bookmarked,
      );
      final frequent = items.singleWhere(
        (i) => i.type == RevisionHubType.frequentlyIncorrect,
      );

      expect(wrong.count, 2);
      expect(bookmarked.count, 0);
      expect(frequent.count, 1);

      // Badge texts from real counts (0 must appear).
      expect(find.text('0'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    for (final width in [360.0, 390.0, 412.0, 430.0]) {
      testWidgets('no overflow at width $width', (tester) async {
        final service = buildService();
        await pumpCenter(tester, service: service, width: width);

        expect(tester.takeException(), isNull);
        expect(find.byType(RevisionHubCard), findsNWidgets(3));
        expect(find.text('PRACTICE • REVIEW • IMPROVE'), findsOneWidget);
      });
    }

    testWidgets('Wrong Questions navigation remains intact', (tester) async {
      final service = buildService();
      await pumpCenter(tester, service: service);

      await tester.tap(find.text('Wrong Questions'));
      await tester.pumpAndSettle();

      expect(find.byType(WrongQuestionsScreen), findsOneWidget);
    });

    testWidgets('Bookmarks navigation remains intact', (tester) async {
      final service = buildService();
      await pumpCenter(tester, service: service);

      await tester.tap(find.text('Bookmarked Questions'));
      await tester.pumpAndSettle();

      expect(find.byType(BookmarksScreen), findsOneWidget);
      expect(find.text('Bookmarks'), findsOneWidget);
    });

    testWidgets('Frequently Incorrect navigation remains intact',
        (tester) async {
      final service = buildService();
      await pumpCenter(tester, service: service);

      await tester.tap(find.text('Frequently Incorrect'));
      await tester.pumpAndSettle();

      expect(find.byType(FrequentlyIncorrectScreen), findsOneWidget);
    });
  });
}
