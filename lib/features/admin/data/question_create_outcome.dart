/// Result of creating a Test Series Question, including optional assignment.
class QuestionCreateOutcome {
  const QuestionCreateOutcome({this.assignmentFailed = false, this.message});

  final bool assignmentFailed;
  final String? message;

  static const created = QuestionCreateOutcome();
}

/// Question creation succeeded and the following assignment call failed.
///
/// The Question is kept. This is not a failed create.
class QuestionAssignmentFailed implements Exception {
  QuestionAssignmentFailed(this.cause);

  final Object cause;

  static const message =
      'Question was created, but assigning it to the test failed. '
      'The question remains in this bank and is not assigned.';

  QuestionCreateOutcome get outcome =>
      const QuestionCreateOutcome(assignmentFailed: true, message: message);

  @override
  String toString() => message;
}
