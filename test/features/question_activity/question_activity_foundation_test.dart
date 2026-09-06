import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/authentication/services/user_session_state_coordinator.dart';
import 'package:telangana_prep/features/question_activity/data/models/question_activity_models.dart';
import 'package:telangana_prep/features/question_activity/data/question_activity_context_factory.dart';
import 'package:telangana_prep/features/question_activity/services/bookmark_eligibility.dart';
import 'package:telangana_prep/features/question_activity/services/question_activity_reporter.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';

void main() {
  late UserSessionStateCoordinator sessions;
  late QuestionActivityReporter reporter;

  setUp(() {
    sessions = UserSessionStateCoordinator.debug();
    sessions.handleAuthState(
      const AuthUser(uid: 'user-a'),
    );
    reporter = QuestionActivityReporter.debug(sessionCoordinator: sessions);
  });

  Test buildTest({
    required String id,
    required TestMode mode,
    QuestionActivitySourceModule? module,
    QuestionActivitySourceType? type,
    String courseId = 'group-ii',
  }) {
    return Test(
      id: id,
      title: 'T',
      courseId: courseId,
      duration: const Duration(minutes: 10),
      totalQuestions: 1,
      totalMarks: 1,
      negativeMarks: 0,
      instructions: const [],
      mode: mode,
      questions: const [
        TestQuestion(
          id: 'Q123',
          text: 'Question',
          options: [
            TestOption(label: 'A', text: 'A'),
            TestOption(label: 'B', text: 'B'),
          ],
          correctOption: 'A',
          explanation: '',
        ),
      ],
      activitySourceModule: module,
      activitySourceType: type,
    );
  }

  test('same questionId from Chapters + Test Series = one global identity', () {
    reporter.reportWrongAnswers(
      contexts: [
        QuestionActivityContextFactory.forQuestion(
          questionId: 'Q123',
          courseId: 'group-ii',
          sourceModule: QuestionActivitySourceModule.chapters,
          sourceType: QuestionActivitySourceType.chapterTests,
          testId: 'chapter-test-1',
        ),
        QuestionActivityContextFactory.forQuestion(
          questionId: 'Q123',
          courseId: 'group-ii',
          sourceModule: QuestionActivitySourceModule.testSeries,
          sourceType: QuestionActivitySourceType.partTests,
          testId: 'paper-wise-1',
        ),
      ],
      authority: QuestionActivityAuthority.serverVerified,
    );

    expect(reporter.encounters.questionIds, {'Q123'});
    expect(reporter.encounters.encountersFor('Q123'), hasLength(2));
    expect(
      reporter.encounters.encountersFor('Q123').map((e) => e.sourceModule),
      containsAll([
        QuestionActivitySourceModule.chapters,
        QuestionActivitySourceModule.testSeries,
      ]),
    );
  });

  test('duplicate identical encounter is not stored twice', () {
    final context = QuestionActivityContextFactory.forQuestion(
      questionId: 'Q123',
      courseId: 'group-ii',
      sourceModule: QuestionActivitySourceModule.practice,
      sourceType: QuestionActivitySourceType.topicPractice,
      testId: 'practice-1',
      encounterId: 'enc-1',
    );
    reporter.reportWrongAnswers(
      contexts: [context, context],
      authority: QuestionActivityAuthority.localSession,
    );
    expect(reporter.encounters.encountersFor('Q123'), hasLength(1));
    expect(reporter.recentEvents, hasLength(1));
  });

  test('legacy questionId-only context remains valid', () {
    reporter.reportWrongAnswers(
      contexts: [QuestionActivityContext.legacyQuestionId('Q-legacy')],
      authority: QuestionActivityAuthority.serverVerified,
    );
    final encounters = reporter.encounters.encountersFor('Q-legacy');
    expect(encounters, hasLength(1));
    expect(encounters.single.sourceModule, QuestionActivitySourceModule.unknown);
    expect(encounters.single.sourceType, QuestionActivitySourceType.unknown);
  });

  test('bookmark activity uses shared reporter without duplicating identity', () {
    reporter.reportBookmarkAdded(
      context: QuestionActivityContextFactory.forQuestion(
        questionId: 'Q123',
        courseId: 'group-ii',
        sourceModule: QuestionActivitySourceModule.practice,
        sourceType: QuestionActivitySourceType.topicPractice,
      ),
    );
    reporter.reportWrongAnswers(
      contexts: [
        QuestionActivityContextFactory.forQuestion(
          questionId: 'Q123',
          courseId: 'group-ii',
          sourceModule: QuestionActivitySourceModule.testSeries,
          sourceType: QuestionActivitySourceType.grandTest,
          testId: 'grand-1',
        ),
      ],
      authority: QuestionActivityAuthority.serverVerified,
    );
    expect(reporter.encounters.questionIds, {'Q123'});
    expect(reporter.encounters.encountersFor('Q123'), hasLength(2));
  });

  test('factory stamps Chapters vs Test Series from catalog flags', () {
    expect(
      QuestionActivityContextFactory.moduleForCatalog(
        category: TestCategoryType.chapterTests,
        fromSyllabusUnit: true,
      ),
      QuestionActivitySourceModule.chapters,
    );
    expect(
      QuestionActivityContextFactory.moduleForCatalog(
        category: TestCategoryType.partTests,
        fromSyllabusUnit: false,
      ),
      QuestionActivitySourceModule.testSeries,
    );
  });

  test('fromTest prefers explicit activity metadata on Test', () {
    final test = buildTest(
      id: 'unit-1',
      mode: TestMode.topic,
      module: QuestionActivitySourceModule.chapters,
      type: QuestionActivitySourceType.chapterTests,
    );
    final context = QuestionActivityContextFactory.fromTest(
      test,
      questionId: 'Q123',
    );
    expect(context.sourceModule, QuestionActivitySourceModule.chapters);
    expect(context.sourceType, QuestionActivitySourceType.chapterTests);
    expect(context.testId, 'unit-1');
  });

  test('BookmarkEligibility allows catalog modes via forTest, blocks Current Affairs', () {
    final chapters = Test(
      id: 'unit-1',
      title: 'Unit',
      courseId: 'group-ii',
      duration: const Duration(minutes: 10),
      totalQuestions: 1,
      totalMarks: 1,
      negativeMarks: 0,
      instructions: const [],
      mode: TestMode.topic,
      questions: const [],
      activitySourceModule: QuestionActivitySourceModule.chapters,
    );
    final series = chapters.copyWith(
      mode: TestMode.section,
      activitySourceModule: QuestionActivitySourceModule.testSeries,
    );
    final ca = chapters.copyWith(
      courseId: 'current-affairs',
      mode: TestMode.practice,
      activitySourceModule: QuestionActivitySourceModule.currentAffairs,
      currentAffairsSetId: 'ca-week-1',
    );

    expect(BookmarkEligibility.forTest(chapters), isTrue);
    expect(BookmarkEligibility.forTest(series), isTrue);
    expect(BookmarkEligibility.forTest(ca), isFalse);
    expect(
      BookmarkEligibility.forSourceModule(
        QuestionActivitySourceModule.currentAffairs,
        courseId: 'current-affairs',
      ),
      isFalse,
    );
  });

  test('session clear drops User A encounters before User B', () async {
    reporter.reportWrongAnswers(
      contexts: [
        QuestionActivityContextFactory.forQuestion(
          questionId: 'Q-A',
          sourceModule: QuestionActivitySourceModule.chapters,
        ),
      ],
      authority: QuestionActivityAuthority.localSession,
    );
    expect(reporter.encounters.questionIds, {'Q-A'});

    sessions.handleAuthState(null);
    expect(reporter.encounters.questionIds, isEmpty);

    sessions.handleAuthState(
      const AuthUser(uid: 'user-b'),
    );
    reporter.reportWrongAnswers(
      contexts: [
        QuestionActivityContextFactory.forQuestion(
          questionId: 'Q-B',
          sourceModule: QuestionActivitySourceModule.testSeries,
        ),
      ],
      authority: QuestionActivityAuthority.serverVerified,
    );
    expect(reporter.encounters.questionIds, {'Q-B'});
  });

  test('late report after logout is ignored', () {
    final session = sessions.capture();
    sessions.handleAuthState(null);
    reporter.reportWrongAnswers(
      contexts: [
        QuestionActivityContextFactory.forQuestion(questionId: 'Q-late'),
      ],
      authority: QuestionActivityAuthority.localSession,
      session: session,
    );
    expect(reporter.encounters.questionIds, isEmpty);
    expect(reporter.recentEvents, isEmpty);
  });
}
