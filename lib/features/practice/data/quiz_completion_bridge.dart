/// Optional hook for test series (or future flows) after quiz completion.
class QuizCompletionBridge {
  QuizCompletionBridge._();

  static void Function(int correctAnswers, int totalQuestions)? handler;

  static void run(int correctAnswers, int totalQuestions) {
    handler?.call(correctAnswers, totalQuestions);
    handler = null;
  }

  static void clear() => handler = null;
}
