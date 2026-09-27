import '../../question_bank/data/models/question_models.dart';
import '../data/admin_question_scope.dart';
import '../data/question_create_outcome.dart';
import 'admin_question_service.dart';
import 'admin_question_test_assignment.dart';

/// Creates a Question in a Test Series bank, then optionally assigns it.
///
/// Assignment uses the existing test-update callable. A failed assignment
/// leaves the created Question in place.
Future<QuestionCreateOutcome> createTestSeriesQuestion({
  required AdminQuestionService questions,
  required AdminQuestionTestAssignment assignment,
  required AdminQuestionScope scope,
  required Question question,
  String? assignToTestId,
}) async {
  final questionId = await questions.createQuestion(question, scope: scope);
  final testId = assignToTestId?.trim() ?? '';
  if (testId.isEmpty) return QuestionCreateOutcome.created;
  try {
    await assignment.assignCreatedQuestion(
      scope: scope,
      testId: testId,
      questionId: questionId,
    );
  } catch (error) {
    throw QuestionAssignmentFailed(error);
  }
  return QuestionCreateOutcome.created;
}
