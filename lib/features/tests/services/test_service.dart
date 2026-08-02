import '../../practice/data/models/practice_models.dart';
import '../../practice/data/quiz_completion_bridge.dart';
import '../../progress/services/progress_service.dart';
import '../../syllabus/services/syllabus_service.dart';
import '../data/models/test_models.dart';
import '../data/tests_dummy_data.dart';

class TestService {
  TestService._();

  static final TestService instance = TestService._();

  /// Exam catalog from [SyllabusService] — same MVP list as Progress / Home.
  List<TestExamSummary> getExamSummaries() {
    return SyllabusService.instance.getAllCourses().map((course) {
      return TestExamSummary(
        examId: course.id,
        title: course.name,
        maxMarks: course.totalMarks.toDouble(),
        paperCount: course.totalPapers,
        isEnabled: course.isAvailable,
      );
    }).toList(growable: false);
  }

  List<TestCategoryModel> getCategories(String examId) =>
      TestsDummyData.categoriesFor(examId);

  List<PaperWisePaper> getPaperWisePapers(String examId) =>
      TestsDummyData.paperWisePapersFor(examId);

  List<TestModel> getPaperWiseParts({
    required String examId,
    required String paperId,
  }) =>
      TestsDummyData.paperWisePartsFor(examId: examId, paperId: paperId);

  List<MockTestEntry> getMockTests(String examId) =>
      TestsDummyData.mockTestsListFor(examId);

  List<PaperWisePaper> getMockPapers(String examId) =>
      TestsDummyData.mockPapersFor(examId);

  TestModel getMockPaperTest({
    required String examId,
    required MockTestEntry mock,
    required PaperWisePaper paper,
  }) =>
      TestsDummyData.mockPaperTest(
        examId: examId,
        mock: mock,
        paper: paper,
      );

  List<PreviousPaperExam> getPreviousPaperExams() =>
      TestsDummyData.previousPaperExams();

  List<PreviousPaperYear> getPreviousPaperYears(String examId) =>
      TestsDummyData.previousPaperYearsFor(examId);

  List<PaperWisePaper> getPreviousPapers(String examId) =>
      TestsDummyData.previousPapersFor(examId);

  TestModel getPreviousPaperTest({
    required String examId,
    required PreviousPaperYear year,
    required PaperWisePaper paper,
  }) =>
      TestsDummyData.previousPaperTest(
        examId: examId,
        year: year,
        paper: paper,
      );

  List<TestModel> getTests({
    required String examId,
    required TestCategoryType category,
  }) =>
      TestsDummyData.testsFor(examId: examId, category: category);

  TestModel getTest(String testId) {
    for (final exam in getExamSummaries().where((e) => e.isEnabled)) {
      for (final category in TestCategoryType.values) {
        for (final test in getTests(examId: exam.examId, category: category)) {
          if (test.id == testId) return test;
        }
      }
    }
    throw ArgumentError('Unknown testId: $testId');
  }

  InstructionModel getInstructions(TestModel test) {
    return InstructionModel(
      testName: test.title,
      questionCount: test.questionCount,
      marks: test.marks,
      durationLabel: '${test.durationMinutes} Minutes',
      negativeMarking: test.negativeMarking,
      difficulty: test.difficulty,
      instructions: TestsDummyData.instructions,
    );
  }

  PracticeSessionModel toPracticeSession(TestModel test) {
    return PracticeSessionModel(
      chapterLabel: test.title,
      questionCount: test.questionCount,
      marks: test.marks,
      timeLimitLabel: '${test.durationMinutes} Minutes',
      negativeMarking: test.negativeMarking,
      difficulty: test.difficulty,
    );
  }

  void registerCompletionHook(TestModel test) {
    QuizCompletionBridge.handler = (correct, total) {
      ProgressService.instance.applyTestCompletion(
        examId: test.examId,
        correctAnswers: correct,
        totalQuestions: total,
      );
    };
  }
}
