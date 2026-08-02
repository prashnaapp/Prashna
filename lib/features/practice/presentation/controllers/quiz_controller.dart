import 'dart:async';

import '../../data/dummy_questions.dart';
import '../../data/models/answer_outcome.dart';
import '../../data/models/question_models.dart';
import '../../data/models/quiz_statistics.dart';

/// Local quiz engine state (timer, scoring, navigation).
class QuizController {
  QuizController({
    required this.onUpdated,
    int? totalQuestions,
  }) : statistics = QuizStatistics(
          totalQuestions: totalQuestions ?? DummyQuestions.totalCount,
        );

  final void Function() onUpdated;
  final QuizStatistics statistics;

  int questionIndex = 0;
  String? selectedLabel;
  bool submitted = false;
  int secondsRemaining = DummyQuestions.timerSeconds;

  Timer? _timer;

  QuestionModel get currentQuestion =>
      DummyQuestions.at(questionIndex % DummyQuestions.totalCount);

  int get currentNumber => questionIndex + 1;

  bool get isLastQuestion => currentNumber >= statistics.totalQuestions;

  void startQuestion() {
    selectedLabel = null;
    submitted = false;
    secondsRemaining = DummyQuestions.timerSeconds;
    _startTimer();
    onUpdated();
  }

  void selectOption(String label) {
    if (submitted) return;
    selectedLabel = label;
    onUpdated();
  }

  void submit() {
    if (submitted) return;
    _finalizeAnswer();
  }

  void nextQuestion() {
    if (!submitted || isLastQuestion) return;
    questionIndex++;
    startQuestion();
  }

  void dispose() {
    _timer?.cancel();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining <= 1) {
        secondsRemaining = 0;
        timer.cancel();
        if (!submitted) {
          _finalizeAnswer();
        }
        return;
      }
      secondsRemaining--;
      onUpdated();
    });
  }

  void _finalizeAnswer() {
    submitted = true;
    _timer?.cancel();

    final outcome = _evaluateAnswer(currentQuestion, selectedLabel);
    statistics.record(outcome);
    onUpdated();
  }

  AnswerOutcome _evaluateAnswer(QuestionModel question, String? selected) {
    if (selected == null) return AnswerOutcome.unanswered;
    if (selected == question.correctOption) return AnswerOutcome.correct;
    return AnswerOutcome.wrong;
  }
}
