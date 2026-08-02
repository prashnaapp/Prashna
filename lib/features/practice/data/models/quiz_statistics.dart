import 'answer_outcome.dart';

class QuizStatistics {
  QuizStatistics({required this.totalQuestions});

  final int totalQuestions;

  int correctAnswers = 0;
  int wrongAnswers = 0;
  int unansweredQuestions = 0;

  int get attemptedQuestions => correctAnswers + wrongAnswers;

  int get score => correctAnswers;

  double get accuracyPercent {
    if (totalQuestions == 0) return 0;
    return (correctAnswers / totalQuestions) * 100;
  }

  void record(AnswerOutcome outcome) {
    switch (outcome) {
      case AnswerOutcome.correct:
        correctAnswers++;
      case AnswerOutcome.wrong:
        wrongAnswers++;
      case AnswerOutcome.unanswered:
        unansweredQuestions++;
    }
  }
}
