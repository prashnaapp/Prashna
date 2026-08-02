/// Course Dashboard view model — mapped from Progress Engine.
class CourseDashboardData {
  const CourseDashboardData({
    required this.courseId,
    required this.title,
    required this.marksLabel,
    required this.overallProgressPercent,
    required this.continueLearning,
    required this.papers,
    required this.recentActivity,
    required this.weakTopics,
  });

  final String courseId;
  final String title;
  final String marksLabel;
  final int overallProgressPercent;
  final ContinueLearningDummy continueLearning;
  final List<PaperProgressItem> papers;
  final RecentActivityItem? recentActivity;
  final List<String> weakTopics;
}

/// Placeholder continue-learning copy until that feature is wired.
class ContinueLearningDummy {
  const ContinueLearningDummy({
    required this.paperLabel,
    required this.partLabel,
    required this.chapterLabel,
  });

  final String paperLabel;
  final String partLabel;
  final String chapterLabel;
}

class PaperProgressItem {
  const PaperProgressItem({
    required this.title,
    required this.progressPercent,
  });

  final String title;
  final int progressPercent;
}

class RecentActivityItem {
  const RecentActivityItem({
    required this.title,
    required this.scoreLabel,
    required this.metaLabel,
  });

  final String title;
  final String scoreLabel;
  final String metaLabel;
}
