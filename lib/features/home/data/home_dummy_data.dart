import 'models/home_models.dart';

abstract final class HomeDummyData {
  static const studentName = 'Mohan';

  static const continueLearning = ContinueLearningModel(
    hasHistory: true,
    courseId: 'group-ii',
    courseName: 'Group-II',
    paperLabel: 'Paper II',
    partLabel: 'Part I',
    chapterLabel: 'Chapter 5',
    progressPercent: 42,
  );

  static const todayGoal = TodayGoalModel(
    completedQuestions: 12,
    targetQuestions: 30,
    motivationText: "Keep going! You're making progress.",
  );
}
