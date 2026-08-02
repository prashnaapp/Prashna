class PracticeSessionModel {
  const PracticeSessionModel({
    required this.chapterLabel,
    required this.questionCount,
    required this.marks,
    required this.timeLimitLabel,
    required this.negativeMarking,
    required this.difficulty,
  });

  final String chapterLabel;
  final int questionCount;
  final int marks;
  final String timeLimitLabel;
  final String negativeMarking;
  final String difficulty;
}

class PracticeQuestionModel {
  const PracticeQuestionModel({
    required this.index,
    required this.total,
    required this.timerSeconds,
    required this.prompt,
    required this.options,
  });

  final int index;
  final int total;
  final int timerSeconds;
  final String prompt;
  final List<String> options;
}
