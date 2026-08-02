import '../../progress/data/models/attempt_analytics_models.dart';
import '../../progress/services/progress_service.dart';
import '../models/course_dashboard_models.dart';
import 'course_service.dart';

/// Course Dashboard — Progress Engine backed (no Firebase).
class CourseDashboardService {
  CourseDashboardService._();

  static final CourseDashboardService instance = CourseDashboardService._();

  Future<CourseDashboardData> loadDashboard(String courseId) async {
    final progress = ProgressService.instance;
    final course = CourseService.instance.getCourseById(courseId);

    final summary = await progress.generateSummary(courseId: courseId);
    final paperStats =
        await progress.loadPaperStatistics(courseId: courseId);
    final history =
        await progress.loadHistory(courseId: courseId, limit: 1);
    final weak =
        await progress.calculateWeakAreas(courseId: courseId, limit: 3);

    final title = course?.name ?? _overallTitle(courseId) ?? 'Course';
    final marksLabel = _marksLabel(courseId, course?.totalMarks, course?.totalPapers);

    final overallPercent = summary.totalTests == 0
        ? 0
        : summary.averageAccuracy.round().clamp(0, 100);

    return CourseDashboardData(
      courseId: courseId,
      title: title,
      marksLabel: marksLabel,
      overallProgressPercent: overallPercent,
      continueLearning: _continueLearningPlaceholder(courseId),
      papers: paperStats
          .map(
            (paper) => PaperProgressItem(
              title: paper.paperName,
              progressPercent: paper.averagePercentage.round().clamp(0, 100),
            ),
          )
          .toList(growable: false),
      recentActivity:
          history.isEmpty ? null : _mapRecent(history.first),
      weakTopics: weak
          .map((topic) => topic.topicName)
          .toList(growable: false),
    );
  }

  String? _overallTitle(String courseId) {
    try {
      return ProgressService.instance.getOverallProgress(courseId).examTitle;
    } catch (_) {
      return null;
    }
  }

  String _marksLabel(String courseId, int? marks, int? papers) {
    try {
      final overall = ProgressService.instance.getOverallProgress(courseId);
      final marksLabel = overall.maxMarks % 1 == 0
          ? overall.maxMarks.toStringAsFixed(0)
          : overall.maxMarks.toStringAsFixed(1);
      return '$marksLabel Marks • ${overall.papers.length} Papers';
    } catch (_) {
      if (marks != null && papers != null) {
        return '$marks Marks • $papers Papers';
      }
      return '';
    }
  }

  ContinueLearningDummy _continueLearningPlaceholder(String courseId) {
    return switch (courseId) {
      'group-iii' => const ContinueLearningDummy(
          paperLabel: 'Paper I',
          partLabel: 'Part II',
          chapterLabel: 'Chapter 3',
        ),
      _ => const ContinueLearningDummy(
          paperLabel: 'Paper II',
          partLabel: 'Part I',
          chapterLabel: 'Chapter 6',
        ),
    };
  }

  RecentActivityItem _mapRecent(AttemptHistory attempt) {
    final title = attempt.paperName?.isNotEmpty == true
        ? '${_modeLabel(attempt.testMode)} · ${attempt.paperName}'
        : _modeLabel(attempt.testMode);
    final total = attempt.totalQuestions;
    final scoreLabel = total > 0
        ? '${attempt.correct} / $total'
        : '${attempt.score.round()}';
    return RecentActivityItem(
      title: title,
      scoreLabel: scoreLabel,
      metaLabel: _relativeDay(attempt.dateTime),
    );
  }

  String _modeLabel(String mode) {
    return switch (mode) {
      'mock' => 'Mock Test',
      'practice' => 'Practice',
      'previousYear' || 'previous_year' => 'Previous Paper',
      'section' => 'Paper-wise Test',
      'paper' => 'Paper Test',
      _ => 'Test',
    };
  }

  String _relativeDay(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Completed Today';
    if (diff == 1) return 'Completed Yesterday';
    return 'Completed $diff days ago';
  }
}
