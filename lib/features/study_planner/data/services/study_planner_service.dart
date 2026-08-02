import '../../../progress/data/models/attempt_analytics_models.dart';
import '../../../progress/services/progress_service.dart';
import '../models/study_planner_models.dart';
import 'study_planner_calculator.dart';

/// Generates the Smart Study Plan from ProgressService + syllabus progress tree.
class StudyPlannerService {
  StudyPlannerService._();

  static final StudyPlannerService instance = StudyPlannerService._();

  static const _defaultCourseId = 'group-ii';
  static const _questionsPerChapter = 10;
  static const _minutesPerChapter = 15;

  Future<StudyPlannerData> getPlan({String courseId = _defaultCourseId}) async {
    final progress = ProgressService.instance;
    final overall = progress.getOverallProgress(courseId);
    final chapters = StudyPlannerCalculator.flattenChapters(overall);
    final incomplete = StudyPlannerCalculator.incompleteChapters(chapters);
    final completed = StudyPlannerCalculator.completedCount(chapters);
    final total = chapters.length;
    final remaining = (total - completed).clamp(0, total);
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();

    final summary = await progress.generateSummary(courseId: courseId);
    final history = await progress.loadHistory(courseId: courseId);
    final studyDays = _studyDaysThisMonth(history);
    final streak = _streak(summary, history);

    final today = incomplete.isEmpty ? null : incomplete.first;
    final upcoming = incomplete.skip(1).take(2).toList(growable: false);

    return StudyPlannerData(
      courseId: courseId,
      courseTitle: overall.examTitle,
      isCourseComplete: incomplete.isEmpty && total > 0,
      todayGoal: today == null
          ? null
          : TodayGoalPlan(
              paperLabel: today.paperLabel,
              partLabel: today.partLabel,
              chapterLabel: today.chapterLabel,
              questionCount: _questionsPerChapter,
              estimatedMinutes: _minutesPerChapter,
            ),
      studyProgress: StudyProgressPlan(
        percent: percent,
        solved: completed,
        total: total,
        completedChapters: completed,
        remainingChapters: remaining,
      ),
      weeklyPlan: _buildWeeklyPlan(),
      monthlyProgress: MonthlyProgressPlan(
        percent: percent,
        studyDays: studyDays,
        remainingChapters: remaining,
      ),
      streak: streak,
      upcomingTasks: upcoming
          .map(
            (item) => UpcomingTaskPlan(
              paperLabel: item.paperLabel,
              chapterLabel: item.chapterLabel,
              estimatedMinutes: _minutesPerChapter,
            ),
          )
          .toList(growable: false),
    );
  }

  /// Synced helper for screens that prefer a non-async first paint.
  StudyPlannerData getPlanSync({String courseId = _defaultCourseId}) {
    final progress = ProgressService.instance;
    final overall = progress.getOverallProgress(courseId);
    final chapters = StudyPlannerCalculator.flattenChapters(overall);
    final incomplete = StudyPlannerCalculator.incompleteChapters(chapters);
    final completed = StudyPlannerCalculator.completedCount(chapters);
    final total = chapters.length;
    final remaining = (total - completed).clamp(0, total);
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();

    final today = incomplete.isEmpty ? null : incomplete.first;
    final upcoming = incomplete.skip(1).take(2).toList(growable: false);

    return StudyPlannerData(
      courseId: courseId,
      courseTitle: overall.examTitle,
      isCourseComplete: incomplete.isEmpty && total > 0,
      todayGoal: today == null
          ? null
          : TodayGoalPlan(
              paperLabel: today.paperLabel,
              partLabel: today.partLabel,
              chapterLabel: today.chapterLabel,
              questionCount: _questionsPerChapter,
              estimatedMinutes: _minutesPerChapter,
            ),
      studyProgress: StudyProgressPlan(
        percent: percent,
        solved: completed,
        total: total,
        completedChapters: completed,
        remainingChapters: remaining,
      ),
      weeklyPlan: _buildWeeklyPlan(),
      monthlyProgress: MonthlyProgressPlan(
        percent: percent,
        studyDays: 0,
        remainingChapters: remaining,
      ),
      streak: const StudyStreakPlan(currentDays: 0, longestDays: 0),
      upcomingTasks: upcoming
          .map(
            (item) => UpcomingTaskPlan(
              paperLabel: item.paperLabel,
              chapterLabel: item.chapterLabel,
              estimatedMinutes: _minutesPerChapter,
            ),
          )
          .toList(growable: false),
    );
  }

  List<WeeklyPlanDay> _buildWeeklyPlan() {
    const labels = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final today = DateTime.now().weekday; // 1=Mon … 7=Sun

    return [
      for (var weekday = 1; weekday <= 7; weekday++)
        WeeklyPlanDay(
          dayLabel: labels[weekday - 1],
          status: _statusForWeekday(weekday, today),
        ),
    ];
  }

  WeeklyPlanStatus _statusForWeekday(int weekday, int today) {
    if (weekday < today) return WeeklyPlanStatus.completed;
    if (weekday == DateTime.saturday) return WeeklyPlanStatus.revision;
    if (weekday == DateTime.sunday) return WeeklyPlanStatus.mockTest;
    if (weekday == today) return WeeklyPlanStatus.current;
    return WeeklyPlanStatus.upcoming;
  }

  int _studyDaysThisMonth(List<AttemptHistory> history) {
    final now = DateTime.now();
    final days = <String>{};
    for (final item in history) {
      final d = item.dateTime;
      if (d.year == now.year && d.month == now.month) {
        days.add('${d.year}-${d.month}-${d.day}');
      }
    }
    return days.length;
  }

  StudyStreakPlan _streak(
    ProgressSummary summary,
    List<AttemptHistory> history,
  ) {
    var current = summary.currentStreak;
    final longest = summary.longestStreak;
    if (_practicedToday(history) && current < 1) {
      current = 1;
    }
    return StudyStreakPlan(
      currentDays: current,
      longestDays: longest < current ? current : longest,
    );
  }

  bool _practicedToday(List<AttemptHistory> history) {
    final now = DateTime.now();
    return history.any((item) {
      final d = item.dateTime;
      return d.year == now.year &&
          d.month == now.month &&
          d.day == now.day &&
          (item.testMode == 'practice' || item.testMode == 'topic');
    });
  }
}
