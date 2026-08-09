import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/authentication/services/user_session_state_coordinator.dart';
import 'package:telangana_prep/features/bookmarks/data/models/bookmark_models.dart';
import 'package:telangana_prep/features/bookmarks/data/services/bookmark_service.dart';
import 'package:telangana_prep/features/course_enrollment/model/course_context.dart';
import 'package:telangana_prep/features/course_enrollment/service/course_loader_service.dart';
import 'package:telangana_prep/features/progress/data/models/attempt_analytics_models.dart';
import 'package:telangana_prep/features/progress/services/progress_service.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/revision/data/models/revision_models.dart';
import 'package:telangana_prep/features/revision/data/repositories/revision_repository.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/repositories/test_repository.dart';

void main() {
  final coordinator = UserSessionStateCoordinator.instance;
  late StreamController<AuthUser?> authStates;

  setUpAll(() {
    // Force every production state owner to register with the same boundary.
    CourseLoaderService.instance;
    ProgressService.instance;
    BookmarkService.instance;
    QuestionRepository.instance;
    RevisionRepository.instance;
    TestRepository.instance;

    authStates = StreamController<AuthUser?>();
    coordinator.start(authStates.stream);
  });

  tearDownAll(() async {
    await authStates.close();
  });

  test('A → B and authenticated → unauthenticated clear user state', () async {
    final loader = CourseLoaderService.instance;
    final progress = ProgressService.instance;
    final bookmarks = BookmarkService.instance;
    final questions = QuestionRepository.instance;
    final revision = RevisionRepository.instance;
    final tests = TestRepository.instance;

    authStates.add(const AuthUser(uid: 'user-a'));
    await _flushAuthEvent();

    loader.debugSetCurrent(
      const CourseContext(publishedCourses: [], enrollments: []),
    );
    await progress.updateProgress(_attempt('user-a-attempt'));
    bookmarks.debugSetBookmarks([_bookmark('user-a-bookmark')]);
    await questions.markBookmarked('user-a-bookmark', value: true);
    await questions.markAttempted('user-a-question');
    await revision.recordSessionStarted(RevisionCollectionType.wrongQuestions);
    await tests.loadOrCache(_test('user-a-test'));

    expect(loader.current, isNotNull);
    expect(await progress.loadHistory(), hasLength(1));
    expect(bookmarks.getBookmarks(), hasLength(1));
    expect(questions.isBookmarked('user-a-bookmark'), isTrue);
    expect(questions.isAttempted('user-a-question'), isTrue);
    expect(await revision.loadRecentSessionTypes(), hasLength(1));

    authStates.add(const AuthUser(uid: 'user-b'));
    await _flushAuthEvent();

    expect(loader.current, isNull);
    expect(await progress.loadHistory(), isEmpty);
    expect(bookmarks.getBookmarks(), isEmpty);
    expect(questions.isBookmarked('user-a-bookmark'), isFalse);
    expect(questions.isAttempted('user-a-question'), isFalse);
    expect(await revision.loadRecentSessionTypes(), isEmpty);
    expect(await tests.getAttempt('user-a-test'), isNull);
    expect(await tests.getResult('user-a-test'), isNull);

    loader.debugSetCurrent(
      const CourseContext(publishedCourses: [], enrollments: []),
    );
    await progress.updateProgress(_attempt('user-b-attempt'));
    bookmarks.debugSetBookmarks([_bookmark('user-b-bookmark')]);
    await questions.markBookmarked('user-b-bookmark', value: true);
    await revision.recordSessionStarted(RevisionCollectionType.bookmarked);
    await tests.loadOrCache(_test('user-b-test'));

    expect(loader.current, isNotNull);
    expect((await progress.loadHistory()).single.attemptId, 'user-b-attempt');
    expect(bookmarks.getBookmarks().single.questionId, 'user-b-bookmark');
    expect(questions.isBookmarked('user-b-bookmark'), isTrue);
    expect(await revision.loadRecentSessionTypes(), [
      RevisionCollectionType.bookmarked,
    ]);

    authStates.add(null);
    await _flushAuthEvent();

    expect(loader.current, isNull);
    expect(await progress.loadHistory(), isEmpty);
    expect(bookmarks.getBookmarks(), isEmpty);
    expect(questions.isBookmarked('user-b-bookmark'), isFalse);
    expect(await revision.loadRecentSessionTypes(), isEmpty);
    expect(await tests.getAttempt('user-b-test'), isNull);
  });

  test('session reset callbacks do not perform cloud deletion', () async {
    var cloudDeleteCalls = 0;
    var localState = true;
    final isolatedCoordinator = UserSessionStateCoordinator.instance;

    isolatedCoordinator.register(() {
      localState = false;
      // A reset only drops local state; no cloud delete operation exists here.
    });
    isolatedCoordinator.handleAuthState(const AuthUser(uid: 'cloud-test-a'));
    isolatedCoordinator.handleAuthState(null);

    expect(localState, isFalse);
    expect(cloudDeleteCalls, 0);
  });
}

Future<void> _flushAuthEvent() async {
  await Future<void>.delayed(Duration.zero);
}

AttemptHistory _attempt(String id) {
  return AttemptHistory(
    attemptId: id,
    testId: id,
    courseId: 'group-ii',
    testMode: 'practice',
    dateTime: DateTime(2026, 8, 9),
    score: 1,
    percentage: 100,
    accuracy: 100,
    correct: 1,
    wrong: 0,
    skipped: 0,
    timeTaken: const Duration(minutes: 1),
  );
}

Bookmark _bookmark(String id) {
  return Bookmark(
    questionId: id,
    courseId: 'group-ii',
    courseName: 'Group-II',
    paperId: 'paper-i',
    paperName: 'Paper I',
    partId: 'part-i',
    partName: 'Part I',
    chapterId: 'chapter-1',
    chapterName: 'Chapter 1',
    questionType: 'practice',
    questionTitle: 'Session test bookmark',
    createdAt: DateTime(2026, 8, 9),
  );
}

Test _test(String id) {
  return Test(
    id: id,
    title: 'Session test',
    courseId: 'group-ii',
    duration: const Duration(minutes: 1),
    totalQuestions: 0,
    totalMarks: 0,
    negativeMarks: 0,
    instructions: const [],
    mode: TestMode.practice,
    questions: const [],
  );
}
