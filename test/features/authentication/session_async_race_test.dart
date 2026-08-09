import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/authentication/repositories/auth_repository.dart';
import 'package:telangana_prep/features/authentication/services/auth_service.dart';
import 'package:telangana_prep/features/authentication/services/user_session_state_coordinator.dart';
import 'package:telangana_prep/features/bookmarks/data/services/bookmark_service.dart';
import 'package:telangana_prep/features/progress/data/models/attempt_analytics_models.dart';
import 'package:telangana_prep/features/progress/data/repositories/progress_repository.dart';
import 'package:telangana_prep/features/progress/services/progress_service.dart';
import 'package:telangana_prep/features/revision/data/repositories/revision_repository.dart';
import 'package:telangana_prep/features/revision/data/models/revision_models.dart';
import 'package:telangana_prep/features/revision/services/revision_service.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/repositories/test_repository.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/user_profile/service/user_profile_service.dart';

void main() {
  test('AuthService auth stream drives coordinator resets', () async {
    final coordinator = UserSessionStateCoordinator.debug();
    final states = StreamController<AuthUser?>();
    var resets = 0;
    coordinator.register(() => resets++);

    final auth = AuthService(
      repository: AuthRepository.debug(authStateChanges: states.stream),
      userProfileService: _NoopUserProfileService(),
      sessionCoordinator: coordinator,
    );
    await auth.initialize();

    states.add(const AuthUser(uid: 'user-a'));
    await _flush();
    states.add(const AuthUser(uid: 'user-b'));
    await _flush();
    states.add(null);
    await _flush();

    expect(resets, 3);
    expect(coordinator.activeUid, isNull);
    await states.close();
  });

  test('stale bookmark operation cannot repopulate User B state', () async {
    final coordinator = UserSessionStateCoordinator.debug();
    final questions = _DelayedQuestionService();
    final bookmarks = BookmarkService.debug(
      questionService: questions,
      sessionCoordinator: coordinator,
      cloudSync: (_) async => fail('stale bookmark must not sync'),
    );
    coordinator.register(bookmarks.clear);
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));

    final operation = bookmarks.addBookmark(questionId: 'question-a');
    coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
    questions.questionById.complete(null);
    await operation;

    expect(bookmarks.getBookmarks(), isEmpty);
  });

  test('stale progress operation cannot append into User B state', () async {
    final coordinator = UserSessionStateCoordinator.debug();
    final repository = _DelayedProgressRepository();
    final progress = ProgressService.debug(
      repository: repository,
      sessionCoordinator: coordinator,
      cloudSync: (_) async => fail('stale progress must not sync'),
    );
    coordinator.register(progress.clear);
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));

    final operation = progress.recordTestAttempt(
      test: _test('test-a'),
      result: _result(),
    );
    coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
    repository.saveGate.complete();
    await operation;

    expect(await progress.loadHistory(), isEmpty);
  });

  test('stale revision operation cannot record User B session state', () async {
    final coordinator = UserSessionStateCoordinator.debug();
    final questions = _DelayedQuestionService();
    final repository = RevisionRepository();
    final revision = RevisionService(
      questionService: questions,
      repository: repository,
      sessionCoordinator: coordinator,
      cloudSync: (_) async => fail('stale revision must not sync'),
    );
    coordinator.register(revision.clear);
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));

    final operation = revision.buildRevisionTest(
      collection: const RevisionCollection(
        type: RevisionCollectionType.wrongQuestions,
        title: 'Wrong',
        subtitle: 'Wrong questions',
        questionIds: ['question-a'],
      ),
    );
    coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
    questions.questionsByIds.complete(const []);
    await operation;

    expect(await repository.loadRecentSessionTypes(), isEmpty);
  });

  test('stale test attempt cannot write User B test state', () async {
    final coordinator = UserSessionStateCoordinator.debug();
    final questions = _DelayedQuestionService();
    final repository = TestRepository(
      questionService: questions,
      sessionCoordinator: coordinator,
    );
    coordinator.register(repository.clear);
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));

    final operation = repository.submitAttempt(
      testId: 'test-a',
      attempts: [_questionAttempt('question-a')],
      result: _result(),
    );
    coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
    questions.attemptedGate.complete();
    await operation;

    expect(await repository.getAttempt('test-a'), isNull);
    expect(await repository.getResult('test-a'), isNull);
  });

  test('stale cloud sync is rejected after A → B', () async {
    final coordinator = UserSessionStateCoordinator.debug();
    final repository = ProgressRepository(seed: false);
    final syncedUids = <String>[];
    final progress = ProgressService.debug(
      repository: repository,
      sessionCoordinator: coordinator,
      cloudSync: (snapshot) async => syncedUids.add(snapshot.uid),
    );
    coordinator.register(progress.clear);
    coordinator.handleAuthState(const AuthUser(uid: 'user-a'));

    progress.applyTestCompletion(
      examId: 'group-ii',
      correctAnswers: 1,
      totalQuestions: 1,
    );
    coordinator.handleAuthState(const AuthUser(uid: 'user-b'));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(syncedUids, isEmpty);
  });
}

class _NoopUserProfileService extends UserProfileService {
  @override
  Future<void> ensureProfileAfterLogin(AuthUser user) async {}
}

class _DelayedQuestionService extends QuestionService {
  final questionById = Completer<Question?>();
  final questionsByIds = Completer<List<Question>>();
  final attemptedGate = Completer<void>();

  @override
  Future<Question?> getById(String id) => questionById.future;

  @override
  Future<List<Question>> getByIds(List<String> ids) => questionsByIds.future;

  @override
  Future<void> markAttempted(String questionId) => attemptedGate.future;

  @override
  Future<void> setBookmarked(String questionId, {required bool value}) async {}
}

class _DelayedProgressRepository extends ProgressRepository {
  final saveGate = Completer<void>();

  _DelayedProgressRepository() : super(seed: false);

  @override
  Future<void> saveAttempt(AttemptHistory attempt) async {
    await saveGate.future;
  }
}

Test _test(String id) {
  return Test(
    id: id,
    title: 'Test',
    courseId: 'group-ii',
    duration: const Duration(minutes: 1),
    totalQuestions: 1,
    totalMarks: 1,
    negativeMarks: 0,
    instructions: const [],
    mode: TestMode.practice,
    questions: const [],
  );
}

QuestionAttempt _questionAttempt(String questionId) {
  return QuestionAttempt(questionId: questionId);
}

TestResult _result() {
  return const TestResult(
    totalQuestions: 1,
    attempted: 1,
    correct: 1,
    wrong: 0,
    skipped: 0,
    score: 1,
    accuracy: 100,
    percentage: 100,
    timeTaken: Duration(seconds: 1),
    passed: true,
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);
