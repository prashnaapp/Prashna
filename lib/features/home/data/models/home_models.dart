class ContinueLearningModel {
  const ContinueLearningModel({
    required this.hasHistory,
    required this.courseId,
    required this.courseName,
    required this.paperLabel,
    required this.partLabel,
    required this.chapterLabel,
    required this.progressPercent,
  });

  final bool hasHistory;
  final String courseId;
  final String courseName;
  final String paperLabel;
  final String partLabel;
  final String chapterLabel;
  final double progressPercent;
}

class TodayGoalModel {
  const TodayGoalModel({
    required this.completedQuestions,
    required this.targetQuestions,
    required this.motivationText,
  });

  final int completedQuestions;
  final int targetQuestions;
  final String motivationText;

  double get progress {
    if (targetQuestions <= 0) return 0;
    return (completedQuestions / targetQuestions).clamp(0.0, 1.0);
  }

  int get progressPercent => (progress * 100).round();
}
