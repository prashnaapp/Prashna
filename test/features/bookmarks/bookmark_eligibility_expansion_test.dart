import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/authentication/services/user_session_state_coordinator.dart';
import 'package:telangana_prep/features/bookmarks/data/services/bookmark_service.dart';
import 'package:telangana_prep/features/bookmarks_cloud/model/bookmark_cloud.dart';
import 'package:telangana_prep/features/question_activity/data/models/question_activity_models.dart';
import 'package:telangana_prep/features/question_activity/services/bookmark_eligibility.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/presentation/controllers/test_engine_controller.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

class _FakeQuestionService extends QuestionService {
  _FakeQuestionService(this._byId);

  final Map<String, Question> _byId;

  @override
  Future<Question?> getById(String id) async => _byId[id];

  @override
  Future<void> setBookmarked(String questionId, {required bool value}) async {}
}

final _now = DateTime(2026, 9, 6);

Question _q({
  required String id,
  required String courseId,
}) {
  return Question(
    id: id,
    courseId: courseId,
    paperId: 'paper-i',
    question: 'Text $id',
    options: const ['A', 'B', 'C', 'D'],
    correctOption: 'A',
    explanation: 'e',
    questionType: QuestionType.practice,
    difficulty: QuestionDifficulty.easy,
    marks: 1,
    negativeMarks: 0,
    estimatedTime: const Duration(seconds: 30),
    tags: const [],
    createdAt: _now,
    updatedAt: _now,
    isActive: true,
    status: QuestionPublicationStatus.published,
  );
}

Test _test({
  required String id,
  required TestMode mode,
  required String courseId,
  QuestionActivitySourceModule? module,
  String? currentAffairsSetId,
  List<TestQuestion> questions = const [],
}) {
  return Test(
    id: id,
    title: id,
    courseId: courseId,
    duration: const Duration(minutes: 10),
    totalQuestions: questions.isEmpty ? 1 : questions.length,
    totalMarks: 1,
    negativeMarks: 0,
    instructions: const [],
    mode: mode,
    questions: questions,
    activitySourceModule: module,
    currentAffairsSetId: currentAffairsSetId,
  );
}

void main() {
  group('BookmarkEligibility source policy', () {
    test('allows Chapters / Test Series / Practice / Revision for safe courses', () {
      expect(
        BookmarkEligibility.forTest(
          _test(
            id: 'ch',
            mode: TestMode.topic,
            courseId: 'group-ii',
            module: QuestionActivitySourceModule.chapters,
          ),
        ),
        isTrue,
      );
      expect(
        BookmarkEligibility.forTest(
          _test(
            id: 'ts',
            mode: TestMode.section,
            courseId: 'group-iii',
            module: QuestionActivitySourceModule.testSeries,
          ),
        ),
        isTrue,
      );
      expect(
        BookmarkEligibility.forTest(
          _test(
            id: 'gt',
            mode: TestMode.mock,
            courseId: 'group-ii',
            module: QuestionActivitySourceModule.testSeries,
          ),
        ),
        isTrue,
      );
      expect(
        BookmarkEligibility.forTest(
          _test(
            id: 'py',
            mode: TestMode.previousYear,
            courseId: 'group-ii',
            module: QuestionActivitySourceModule.testSeries,
          ),
        ),
        isTrue,
      );
      expect(
        BookmarkEligibility.forTest(
          _test(
            id: 'pr',
            mode: TestMode.practice,
            courseId: 'group-ii',
            module: QuestionActivitySourceModule.practice,
          ),
        ),
        isTrue,
      );
      expect(
        BookmarkEligibility.forTest(
          _test(
            id: 'rev',
            mode: TestMode.practice,
            courseId: 'group-ii',
            module: QuestionActivitySourceModule.revision,
          ),
        ),
        isTrue,
      );
    });

    test('blocks Current Affairs even when TestMode.practice', () {
      expect(
        BookmarkEligibility.forTest(
          _test(
            id: 'ca-week-1',
            mode: TestMode.practice,
            courseId: 'current-affairs',
            module: QuestionActivitySourceModule.currentAffairs,
            currentAffairsSetId: 'ca-week-1',
          ),
        ),
        isFalse,
      );
      expect(
        BookmarkEligibility.forQuestion(
          _q(id: 'ca-q', courseId: 'current-affairs'),
        ),
        isFalse,
      );
    });

    test('blocks unresolved and non-safe courses for questions', () {
      expect(BookmarkEligibility.forQuestion(null), isFalse);
      expect(
        BookmarkEligibility.forQuestion(_q(id: 'x', courseId: 'unknown-course')),
        isFalse,
      );
      expect(
        BookmarkEligibility.forQuestion(_q(id: 'g2', courseId: 'group-ii')),
        isTrue,
      );
      expect(
        BookmarkEligibility.forQuestion(_q(id: 'g3', courseId: 'group-iii')),
        isTrue,
      );
    });

    test('unknown module allows identity-safe catalog modes only', () {
      expect(
        BookmarkEligibility.forSourceModule(
          QuestionActivitySourceModule.unknown,
          courseId: 'group-ii',
          mode: TestMode.mock,
        ),
        isTrue,
      );
      expect(
        BookmarkEligibility.forSourceModule(
          QuestionActivitySourceModule.unknown,
          courseId: 'current-affairs',
          mode: TestMode.practice,
        ),
        isFalse,
      );
      expect(
        BookmarkEligibility.forSourceModule(
          QuestionActivitySourceModule.other,
          courseId: 'group-ii',
          mode: TestMode.practice,
        ),
        isFalse,
      );
    });
  });

  group('TestEngineController bookmarksEnabled', () {
    test('enabled for stamped catalog chapter test', () {
      final controller = TestEngineController(
        test: _test(
          id: 'unit',
          mode: TestMode.topic,
          courseId: 'group-ii',
          module: QuestionActivitySourceModule.chapters,
          questions: const [
            TestQuestion(
              id: 'q1',
              text: 'Q',
              options: [TestOption(label: 'A', text: 'a')],
              correctOption: 'A',
              explanation: '',
            ),
          ],
        ),
        service: TestService(),
      );
      expect(controller.bookmarksEnabled, isTrue);
      controller.dispose();
    });

    test('disabled for Current Affairs practice', () {
      final controller = TestEngineController(
        test: _test(
          id: 'ca',
          mode: TestMode.practice,
          courseId: 'current-affairs',
          module: QuestionActivitySourceModule.currentAffairs,
          currentAffairsSetId: 'ca-week-1',
          questions: const [
            TestQuestion(
              id: 'q1',
              text: 'Q',
              options: [TestOption(label: 'A', text: 'a')],
              correctOption: 'A',
              explanation: '',
            ),
          ],
        ),
        service: TestService(),
      );
      expect(controller.bookmarksEnabled, isFalse);
      controller.dispose();
    });
  });

  group('BookmarkService identity guards + global dedupe', () {
    late UserSessionStateCoordinator sessions;

    setUp(() {
      sessions = UserSessionStateCoordinator.debug();
      sessions.handleAuthState(const AuthUser(uid: 'user-a'));
    });

    test('rejects unresolved and Current Affairs IDs', () async {
      final questions = _FakeQuestionService({
        'ok': _q(id: 'ok', courseId: 'group-ii'),
        'ca': _q(id: 'ca', courseId: 'current-affairs'),
      });
      final service = BookmarkService.debug(
        questionService: questions,
        sessionCoordinator: sessions,
        cloudLoader: (_) async => null,
        cloudSync: (_) async {},
      );
      sessions.register(service.clear);

      await service.addBookmark(questionId: 'missing');
      await service.addBookmark(questionId: 'ca');
      await service.addBookmark(questionId: 'ok');

      expect(service.getBookmarks().map((b) => b.questionId), ['ok']);
    });

    test('same questionId from multiple sources remains one bookmark', () async {
      final questions = _FakeQuestionService({
        'Q123': _q(id: 'Q123', courseId: 'group-ii'),
      });
      final snaps = <BookmarkCloud>[];
      final service = BookmarkService.debug(
        questionService: questions,
        sessionCoordinator: sessions,
        cloudLoader: (_) async => null,
        cloudSync: (snap) async => snaps.add(snap),
      );
      sessions.register(service.clear);

      await service.addBookmark(questionId: 'Q123', questionType: 'topic');
      await service.addBookmark(questionId: 'Q123', questionType: 'mock');
      expect(service.getBookmarks(), hasLength(1));

      await service.removeBookmark('Q123');
      expect(service.isBookmarked('Q123'), isFalse);
    });

    test('Group-II + Group-III both persist in one list', () async {
      final questions = _FakeQuestionService({
        'gii': _q(id: 'gii', courseId: 'group-ii'),
        'giii': _q(id: 'giii', courseId: 'group-iii'),
      });
      BookmarkCloud? last;
      final service = BookmarkService.debug(
        questionService: questions,
        sessionCoordinator: sessions,
        cloudLoader: (_) async => null,
        cloudSync: (snap) async => last = snap,
      );
      sessions.register(service.clear);

      await service.addBookmark(questionId: 'gii');
      await service.addBookmark(questionId: 'giii');
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(service.getBookmarks().map((b) => b.questionId).toSet(), {
        'gii',
        'giii',
      });
      expect(last?.questionIds.toSet(), {'gii', 'giii'});
    });

    test('logout clears session bookmarks', () async {
      final questions = _FakeQuestionService({
        'q1': _q(id: 'q1', courseId: 'group-ii'),
      });
      final service = BookmarkService.debug(
        questionService: questions,
        sessionCoordinator: sessions,
        cloudLoader: (_) async => null,
        cloudSync: (_) async {},
      );
      sessions.register(service.clear);

      await service.addBookmark(questionId: 'q1');
      expect(service.getBookmarks(), isNotEmpty);
      sessions.handleAuthState(null);
      expect(service.getBookmarks(), isEmpty);
    });
  });
}
