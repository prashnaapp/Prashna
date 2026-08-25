import '../../practice/data/models/practice_models.dart';
import '../../practice/data/quiz_completion_bridge.dart';
import '../../progress/services/progress_service.dart';
import '../../syllabus/services/syllabus_service.dart';
import '../data/models/test_models.dart';
import '../data/tests_dummy_data.dart';
import '../repository/test_cloud_repository.dart';

/// Test Series **catalog** service (definitions / navigation metadata).
///
/// Not the attempt engine (`features/test_engine/services/test_service.dart`).
///
/// Published test lists for [getTests] load from Firestore via
/// [TestCloudRepository]. Paper-wise / mock / previous-paper helpers still use
/// [TestsDummyData] until those catalogs are migrated.
///
/// On Firestore failure, errors propagate — there is **no** silent dummy
/// fallback for test definitions.
class TestService {
  TestService({TestCloudRepository? cloudRepository})
    : _cloudRepository = cloudRepository ?? TestCloudRepository();

  static final TestService instance = TestService();

  final TestCloudRepository _cloudRepository;

  /// Exam catalog from [SyllabusService] — same MVP list as Progress / Home.
  List<TestExamSummary> getExamSummaries() {
    return SyllabusService.instance
        .getAllCourses()
        .map((course) {
          return TestExamSummary(
            examId: course.id,
            title: course.name,
            maxMarks: course.totalMarks.toDouble(),
            paperCount: course.totalPapers,
            isEnabled: course.isAvailable,
          );
        })
        .toList(growable: false);
  }

  List<TestCategoryModel> getCategories(String examId) =>
      TestsDummyData.categoriesFor(examId);

  List<PaperWisePaper> getPaperWisePapers(String examId) =>
      TestsDummyData.paperWisePapersFor(examId);

  List<TestModel> getPaperWiseParts({
    required String examId,
    required String paperId,
  }) => TestsDummyData.paperWisePartsFor(examId: examId, paperId: paperId);

  List<MockTestEntry> getMockTests(String examId) =>
      TestsDummyData.mockTestsListFor(examId);

  List<PaperWisePaper> getMockPapers(String examId) =>
      TestsDummyData.mockPapersFor(examId);

  TestModel getMockPaperTest({
    required String examId,
    required MockTestEntry mock,
    required PaperWisePaper paper,
  }) => TestsDummyData.mockPaperTest(examId: examId, mock: mock, paper: paper);

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
  }) => TestsDummyData.previousPaperTest(
    examId: examId,
    year: year,
    paper: paper,
  );

  /// Published Firestore test definitions for [examId], filtered by [category].
  ///
  /// Primary source: `tests` collection (`courseId` + `isPublished`).
  /// Does not fall back to [TestsDummyData] on error.
  ///
  /// Product UI exposes only Paper-wise / Grand / Previous Papers. Legacy
  /// Firestore `chapter` tests ([TestCategoryType.chapterTests]) are included
  /// when loading Paper-wise ([TestCategoryType.partTests]) so existing
  /// published catalog rows remain reachable without a Chapter Tests UI.
  Future<List<TestModel>> getTests({
    required String examId,
    required TestCategoryType category,
  }) async {
    final published = await _cloudRepository.loadPublishedTests(examId);
    final matching = _categoriesMatchingProductFilter(category);
    return [
      for (final test in published)
        if (matching.contains(test.category)) test,
    ];
  }

  /// Categories that belong under a product-facing Test Series filter.
  static Set<TestCategoryType> _categoriesMatchingProductFilter(
    TestCategoryType category,
  ) {
    switch (category) {
      case TestCategoryType.partTests:
        return const {
          TestCategoryType.partTests,
          TestCategoryType.chapterTests,
        };
      case TestCategoryType.chapterTests:
      case TestCategoryType.paperTests:
      case TestCategoryType.mockTests:
      case TestCategoryType.previousYear:
        return {category};
    }
  }

  /// Published tests linked to a Group-III syllabus unit.
  ///
  /// Uses the existing course-scoped published query, then filters client-side
  /// by [syllabusUnitId] (and optional paper/part for defense in depth).
  Future<List<TestModel>> getTestsForSyllabusUnit({
    required String courseId,
    required String syllabusUnitId,
    String? paperId,
    String? partId,
  }) async {
    final unit = syllabusUnitId.trim();
    if (unit.isEmpty) return const [];
    final published = await _cloudRepository.loadPublishedTests(courseId);
    return [
      for (final test in published)
        if (test.syllabusUnitId == unit &&
            (paperId == null || paperId.isEmpty || test.paperId == paperId) &&
            (partId == null || partId.isEmpty || test.partId == partId))
          test,
    ];
  }

  Future<TestModel> getTest(String testId) async {
    for (final exam in getExamSummaries().where((e) => e.isEnabled)) {
      final tests = await _cloudRepository.loadPublishedTests(exam.examId);
      for (final test in tests) {
        if (test.id == testId) return test;
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
