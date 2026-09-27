import '../../tests/data/models/test_models.dart';
import '../../tests/repository/test_cloud_repository.dart';
import '../data/admin_compatible_test_query.dart';
import '../data/admin_question_scope.dart';

/// Optional assignment of one newly created Question through the existing
/// Phase 3A test-update callable.
///
/// Does not write `questionIds` directly, does not write `assignedTestId` on
/// the Question, and does not set Question status. The callable transaction
/// owns assignment and status coupling.
class AdminQuestionTestAssignment {
  static const maxAssignedQuestionsPerTest = 160;

  AdminQuestionTestAssignment({TestCloudRepository? tests})
    : _tests = tests ?? TestCloudRepository();

  final TestCloudRepository _tests;

  Future<List<TestModel>> loadCompatibleTests(AdminQuestionScope scope) async {
    final query = AdminCompatibleTestQuery.fromScope(scope);
    final tests = await _tests.loadCompatibleTests(query);
    return [
      for (final test in tests)
        if (query.matches(test)) test,
    ];
  }

  /// Appends [questionId] to one compatible Test and calls [TestCloudRepository.updateTest].
  ///
  /// [TestModel.questionCount] is aligned with the new id list so the existing
  /// client writer accepts the payload. The callable recomputes stored
  /// aggregates and assigned Question status.
  Future<void> assignCreatedQuestion({
    required AdminQuestionScope scope,
    required String testId,
    required String questionId,
  }) async {
    final id = testId.trim();
    final question = questionId.trim();
    if (id.isEmpty || question.isEmpty) {
      throw const FormatException('Test and Question are required.');
    }
    final current = await _tests.getAdminTestById(id);
    if (current == null) {
      throw const FormatException('Test was not found.');
    }
    final query = AdminCompatibleTestQuery.fromScope(scope);
    if (!query.matches(current)) {
      throw const FormatException(
        'Selected test is not compatible with this question bank.',
      );
    }
    if (current.questionIds.contains(question)) return;
    final nextIds = [...current.questionIds, question];
    await _tests.updateTest(
      TestModel(
        id: current.id,
        examId: current.examId,
        category: current.category,
        title: current.title,
        description: current.description,
        questionCount: nextIds.length,
        marks: current.marks,
        durationMinutes: current.durationMinutes,
        negativeMarking: current.negativeMarking,
        difficulty: current.difficulty,
        questionIds: nextIds,
        status: current.status,
        paperId: current.paperId,
        partId: current.partId,
        syllabusUnitId: current.syllabusUnitId,
        majorStudyAreaId: current.majorStudyAreaId,
        contentTopicId: current.contentTopicId,
        canonicalTopicId: current.canonicalTopicId,
        lessonId: current.lessonId,
        scopeShape: current.scopeShape,
        year: current.year,
        seriesId: current.seriesId,
      ),
    );
  }
}
