import '../../../question_bank/data/services/question_service.dart';
import '../mappers/question_bank_mapper.dart';
import '../models/test_engine_models.dart';
import '../test_engine_defaults.dart';

/// Persistence boundary for test attempts.
/// Currently in-memory; swap implementation for Firebase later.
/// Does not own question content — loads via Question Bank.
class TestRepository {
  TestRepository._();

  static final TestRepository instance = TestRepository._();

  final Map<String, Test> _tests = {};
  final Map<String, List<QuestionAttempt>> _attempts = {};
  final Map<String, TestResult> _results = {};

  Future<Test> loadTest(String testId) async {
    final cached = _tests[testId];
    if (cached != null) return cached;

    final bankQuestions = await QuestionService.instance.getQuestionsForTest(
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
    _attempts[testId] =
        attempts.map((attempt) => attempt.copy()).toList(growable: false);
  }

  Future<void> submitAttempt({
    required String testId,
    required List<QuestionAttempt> attempts,
    required TestResult result,
  }) async {
    await saveAttempt(testId: testId, attempts: attempts);
    _results[testId] = result;

    for (final attempt in attempts) {
      if (attempt.answered) {
        await QuestionService.instance.markAttempted(attempt.questionId);
      }
    }
  }

  Future<TestResult?> getResult(String testId) async => _results[testId];

  Future<List<QuestionAttempt>?> getAttempt(String testId) async =>
      _attempts[testId];
}
