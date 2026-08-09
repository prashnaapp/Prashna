import '../../../question_bank/data/services/question_service.dart';
import '../../../practice/data/quiz_completion_bridge.dart';
import '../../../authentication/services/user_session_state_coordinator.dart';
import '../mappers/question_bank_mapper.dart';
import '../models/test_engine_models.dart';
import '../test_engine_defaults.dart';

/// Persistence boundary for test attempts.
/// Currently in-memory; swap implementation for Firebase later.
/// Does not own question content — loads via Question Bank.
class TestRepository {
  TestRepository({
    QuestionService? questionService,
    UserSessionStateCoordinator? sessionCoordinator,
  }) : _questions = questionService ?? QuestionService.instance,
       _sessions = sessionCoordinator ?? UserSessionStateCoordinator.instance;

  static final TestRepository instance = TestRepository()
    .._registerSessionReset();

  final QuestionService _questions;
  final UserSessionStateCoordinator _sessions;
  final Map<String, Test> _tests = {};
  final Map<String, List<QuestionAttempt>> _attempts = {};
  final Map<String, TestResult> _results = {};

  Future<Test> loadTest(String testId) async {
    final cached = _tests[testId];
    if (cached != null) return cached;

    final bankQuestions = await _questions.getQuestionsForTest(
      count: 10,
      courseId: 'group-ii',
      questionType: QuestionBankMapper.questionTypeForMode(TestMode.practice),
    );

    final questions = QuestionBankMapper.toTestQuestions(bankQuestions);
    final test = Test(
      id: testId,
      title: 'Practice Session',
      courseId: 'group-ii',
      duration: const Duration(minutes: 15),
      totalQuestions: questions.length,
      totalMarks: questions.length,
      negativeMarks: 0.25,
      instructions: TestEngineDefaults.instructions,
      mode: TestMode.practice,
      questions: questions,
    );
    _tests[testId] = test;
    return test;
  }

  Future<Test> loadOrCache(Test test) async {
    _tests[test.id] = test;
    return test;
  }

  Future<void> saveAttempt({
    required String testId,
    required List<QuestionAttempt> attempts,
  }) async {
    _attempts[testId] = attempts
        .map((attempt) => attempt.copy())
        .toList(growable: false);
  }

  Future<void> submitAttempt({
    required String testId,
    required List<QuestionAttempt> attempts,
    required TestResult result,
  }) async {
    final session = _sessions.capture();
    if (!_sessions.isCurrent(session)) return;
    await saveAttempt(testId: testId, attempts: attempts);
    if (!_sessions.isCurrent(session)) return;
    _results[testId] = result;

    for (final attempt in attempts) {
      if (!_sessions.isCurrent(session)) return;
      if (attempt.answered) {
        await _questions.markAttempted(attempt.questionId);
        if (!_sessions.isCurrent(session)) return;
      }
    }
  }

  /// Clears only in-memory test/session state for the previous user.
  void clear() {
    _tests.clear();
    _attempts.clear();
    _results.clear();
    QuizCompletionBridge.clear();
  }

  void _registerSessionReset() {
    UserSessionStateCoordinator.instance.register(clear);
  }

  Future<TestResult?> getResult(String testId) async => _results[testId];

  Future<List<QuestionAttempt>?> getAttempt(String testId) async =>
      _attempts[testId];
}
