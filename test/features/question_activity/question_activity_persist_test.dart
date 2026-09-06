import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/authentication/services/user_session_state_coordinator.dart';
import 'package:telangana_prep/features/question_activity/data/models/question_activity_models.dart';
import 'package:telangana_prep/features/question_activity/data/question_activity_api.dart';
import 'package:telangana_prep/features/question_activity/data/question_activity_context_factory.dart';
import 'package:telangana_prep/features/question_activity/services/question_activity_reporter.dart';

void main() {
  late UserSessionStateCoordinator sessions;

  setUp(() {
    sessions = UserSessionStateCoordinator.debug();
    sessions.handleAuthState(const AuthUser(uid: 'user-a'));
  });

  test('activityEventId is stable for session + question retries', () {
    final a = QuestionActivityReporter.activityEventIdFor(
      activitySessionId: 's100',
      questionId: 'Q1',
    );
    final b = QuestionActivityReporter.activityEventIdFor(
      activitySessionId: 's100',
      questionId: 'Q1',
    );
    final c = QuestionActivityReporter.activityEventIdFor(
      activitySessionId: 's200',
      questionId: 'Q1',
    );
    expect(a, b);
    expect(a, isNot(c));
  });

  test('practice module is eligible; currentAffairs is blocked from persist', () {
    expect(
      QuestionActivityReporter.shouldPersistVerifiedActivity(
        QuestionActivitySourceModule.practice,
      ),
      isTrue,
    );
    expect(
      QuestionActivityReporter.shouldPersistVerifiedActivity(
        QuestionActivitySourceModule.revision,
      ),
      isTrue,
    );
    expect(
      QuestionActivityReporter.shouldPersistVerifiedActivity(
        QuestionActivitySourceModule.currentAffairs,
      ),
      isFalse,
    );
  });

  test('reportAndPersistWrongAnswers records local + server persisted', () async {
    final calls = <Map<String, dynamic>>[];
    final reporter = QuestionActivityReporter.debug(
      sessionCoordinator: sessions,
      activityApi: QuestionActivityApi(
        callOverride: (name, data) async {
          calls.add(data);
          expect(name, 'reportQuestionActivity');
          return {
            'duplicate': false,
            'isWrong': true,
            'revisionApplied': true,
            'questionId': data['questionId'],
          };
        },
      ),
    );

    final results = await reporter.reportAndPersistWrongAnswers(
      submissions: [
        QuestionActivityWrongSubmission(
          activityEventId: 'qa_s1_Q1',
          selectedOption: 'B',
          context: QuestionActivityContextFactory.forQuestion(
            questionId: 'Q1',
            courseId: 'group-ii',
            sourceModule: QuestionActivitySourceModule.practice,
            sourceType: QuestionActivitySourceType.topicPractice,
            testId: 'practice-1',
          ),
        ),
      ],
    );

    expect(results, hasLength(1));
    expect(results.single.state, QuestionActivityPersistState.serverPersisted);
    expect(results.single.isServerAuthoritative, isTrue);
    expect(calls, hasLength(1));
    expect(calls.single['activityEventId'], 'qa_s1_Q1');
    expect(calls.single.containsKey('isWrong'), isFalse);
    expect(reporter.encounters.questionIds, {'Q1'});
  });

  test('Current Affairs wrong is local-only / not dispatched to callable', () async {
    var calls = 0;
    final reporter = QuestionActivityReporter.debug(
      sessionCoordinator: sessions,
      activityApi: QuestionActivityApi(
        callOverride: (name, data) async {
          calls++;
          return {};
        },
      ),
    );

    final results = await reporter.reportAndPersistWrongAnswers(
      submissions: [
        QuestionActivityWrongSubmission(
          activityEventId: 'qa_s1_QCA',
          selectedOption: 'B',
          context: QuestionActivityContextFactory.forQuestion(
            questionId: 'QCA',
            courseId: 'current-affairs',
            sourceModule: QuestionActivitySourceModule.currentAffairs,
            sourceType: QuestionActivitySourceType.currentAffairsWeekly,
          ),
        ),
      ],
    );

    expect(calls, 0);
    expect(results.single.state, QuestionActivityPersistState.notDispatched);
    expect(reporter.encounters.questionIds, {'QCA'});
  });

  test('server failure does not claim authoritative persistence', () async {
    final reporter = QuestionActivityReporter.debug(
      sessionCoordinator: sessions,
      activityApi: QuestionActivityApi(
        callOverride: (name, data) async {
          throw StateError('network down');
        },
      ),
    );

    final results = await reporter.reportAndPersistWrongAnswers(
      submissions: [
        QuestionActivityWrongSubmission(
          activityEventId: 'qa_s1_Qfail',
          selectedOption: 'B',
          context: QuestionActivityContextFactory.forQuestion(
            questionId: 'Qfail',
            sourceModule: QuestionActivitySourceModule.practice,
          ),
        ),
      ],
    );

    expect(results.single.state, QuestionActivityPersistState.serverFailed);
    expect(results.single.isServerAuthoritative, isFalse);
    expect(reporter.encounters.questionIds, {'Qfail'});
  });

  test('late persist after logout is not dispatched as success', () async {
    final reporter = QuestionActivityReporter.debug(
      sessionCoordinator: sessions,
      activityApi: QuestionActivityApi(
        callOverride: (name, data) async => {
          'duplicate': false,
          'isWrong': true,
          'revisionApplied': true,
        },
      ),
    );
    final session = sessions.capture();
    sessions.handleAuthState(null);

    final results = await reporter.reportAndPersistWrongAnswers(
      session: session,
      submissions: [
        QuestionActivityWrongSubmission(
          activityEventId: 'qa_late_Q1',
          selectedOption: 'B',
          context: QuestionActivityContextFactory.forQuestion(
            questionId: 'Q1',
            sourceModule: QuestionActivitySourceModule.practice,
          ),
        ),
      ],
    );

    expect(results.single.state, QuestionActivityPersistState.notDispatched);
  });
}
