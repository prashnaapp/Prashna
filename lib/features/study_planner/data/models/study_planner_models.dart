/// Smart Study Planner view models — filled by [StudyPlannerService].
class StudyPlannerData {
  const StudyPlannerData({
    required this.courseId,
    required this.courseTitle,
    required this.isCourseComplete,
    required this.todayGoal,
    required this.studyProgress,
    required this.weeklyPlan,
    required this.monthlyProgress,
    required this.streak,
    required this.upcomingTasks,
  });

  final String courseId;
  final String courseTitle;
  final bool isCourseComplete;
  final TodayGoalPlan? todayGoal;
  final StudyProgressPlan studyProgress;
  final List<WeeklyPlanDay> weeklyPlan;
  final MonthlyProgressPlan monthlyProgress;
  final StudyStreakPlan streak;
  final List<UpcomingTaskPlan> upcomingTasks;
}

class TodayGoalPlan {
  const TodayGoalPlan({
    required this.paperLabel,
    required this.partLabel,
    required this.chapterLabel,
    required this.questionCount,
    required this.estimatedMinutes,
  });

  final String paperLabel;
  final String partLabel;
  final String chapterLabel;
  final int questionCount;
  final int estimatedMinutes;
}

class StudyProgressPlan {
  const StudyProgressPlan({
    required this.percent,
    required this.solved,
    required this.total,
    required this.completedChapters,
    required this.remainingChapters,
  });

  final int percent;

  /// Shown in existing UI as Questions Solved numerator/denominator.
  final int solved;
  final int total;
  final int completedChapters;
  final int remainingChapters;
}

enum WeeklyPlanStatus {
  completed,
  current,
  upcoming,
  revision,
  mockTest,
}

class WeeklyPlanDay {
  const WeeklyPlanDay({
    required this.dayLabel,
    required this.status,
  });

  final String dayLabel;
  final WeeklyPlanStatus status;

  String get statusLabel => switch (status) {
        WeeklyPlanStatus.completed => 'Completed',
        WeeklyPlanStatus.current => 'Current',
        WeeklyPlanStatus.upcoming => 'Upcoming',
        WeeklyPlanStatus.revision => 'Revision',
        WeeklyPlanStatus.mockTest => 'Mock Test',
      };
}

class MonthlyProgressPlan {
  const MonthlyProgressPlan({
    required this.percent,
    required this.studyDays,
    required this.remainingChapters,
  });

  final int percent;
  final int studyDays;
  final int remainingChapters;
}

class StudyStreakPlan {
  const StudyStreakPlan({
    required this.currentDays,
    required this.longestDays,
  });

  final int currentDays;
  final int longestDays;
}

class UpcomingTaskPlan {
  const UpcomingTaskPlan({
    required this.paperLabel,
    required this.chapterLabel,
    required this.estimatedMinutes,
  });

  final String paperLabel;
  final String chapterLabel;
  final int estimatedMinutes;
}
