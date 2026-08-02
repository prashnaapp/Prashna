/// Attempt-level analytics models for the Progress Engine.
class AttemptHistory {
  const AttemptHistory({
    required this.attemptId,
    required this.testId,
    required this.courseId,
    required this.testMode,
    required this.dateTime,
    required this.score,
    required this.percentage,
    required this.accuracy,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.timeTaken,
    this.paperId,
    this.sectionId,
    this.topicId,
    this.topicName,
    this.paperName,
    this.courseName,
  });

  final String attemptId;
  final String testId;
  final String courseId;
  final String? paperId;
  final String? sectionId;
  final String? topicId;
  final String testMode;
  final DateTime dateTime;
  final double score;
  final double percentage;
  final double accuracy;
  final int correct;
  final int wrong;
  final int skipped;
  final Duration timeTaken;
  final String? topicName;
  final String? paperName;
  final String? courseName;

  int get totalQuestions => correct + wrong + skipped;
}

/// Aggregate attempt performance summary.
class ProgressSummary {
  const ProgressSummary({
    required this.totalTests,
    required this.totalQuestions,
    required this.averageScore,
    required this.averageAccuracy,
    required this.averageTime,
    required this.highestScore,
    required this.lowestScore,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int totalTests;
  final int totalQuestions;
  final double averageScore;
  final double averageAccuracy;
  final Duration averageTime;
  final double highestScore;
  final double lowestScore;
  final int currentStreak;
  final int longestStreak;

  static const empty = ProgressSummary(
    totalTests: 0,
    totalQuestions: 0,
    averageScore: 0,
    averageAccuracy: 0,
    averageTime: Duration.zero,
    highestScore: 0,
    lowestScore: 0,
    currentStreak: 0,
    longestStreak: 0,
  );
}

class WeakTopic {
  const WeakTopic({
    required this.topicId,
    required this.topicName,
    required this.accuracy,
    required this.attempts,
    this.paperId,
    this.paperName,
    this.courseId,
  });

  final String topicId;
  final String topicName;
  final double accuracy;
  final int attempts;
  final String? paperId;
  final String? paperName;
  final String? courseId;
}

class StrongTopic {
  const StrongTopic({
    required this.topicId,
    required this.topicName,
    required this.accuracy,
    required this.attempts,
  });

  final String topicId;
  final String topicName;
  final double accuracy;
  final int attempts;
}

class TopicStatistics {
  const TopicStatistics({
    required this.topicId,
    required this.topicName,
    required this.attempts,
    required this.totalQuestions,
    required this.correct,
    required this.wrong,
    required this.accuracy,
    required this.averageScore,
    this.paperId,
    this.paperName,
    this.courseId,
  });

  final String topicId;
  final String topicName;
  final int attempts;
  final int totalQuestions;
  final int correct;
  final int wrong;
  final double accuracy;
  final String? paperId;
  final String? paperName;
  final String? courseId;
  final double averageScore;
}

class PaperStatistics {
  const PaperStatistics({
    required this.paperId,
    required this.paperName,
    required this.attempts,
    required this.averageAccuracy,
    required this.averageScore,
    required this.averagePercentage,
  });

  final String paperId;
  final String paperName;
  final int attempts;
  final double averageAccuracy;
  final double averageScore;
  final double averagePercentage;
}

class CourseStatistics {
  const CourseStatistics({
    required this.courseId,
    required this.courseName,
    required this.attempts,
    required this.averageAccuracy,
    required this.averageScore,
    required this.averagePercentage,
    required this.totalQuestions,
  });

  final String courseId;
  final String courseName;
  final int attempts;
  final double averageAccuracy;
  final double averageScore;
  final double averagePercentage;
  final int totalQuestions;
}

class PeriodProgressPoint {
  const PeriodProgressPoint({
    required this.label,
    required this.date,
    required this.attempts,
    required this.averageAccuracy,
    required this.averageScore,
  });

  final String label;
  final DateTime date;
  final int attempts;
  final double averageAccuracy;
  final double averageScore;
}

/// Derived insights for the Progress analytics surface.
class ProgressAnalytics {
  const ProgressAnalytics({
    required this.mostPracticedTopic,
    required this.leastPracticedTopic,
    required this.mostIncorrectTopic,
    required this.bestPerformingPaper,
    required this.lowestPerformingPaper,
    required this.recentImprovement,
    required this.consistencyScore,
  });

  final TopicStatistics? mostPracticedTopic;
  final TopicStatistics? leastPracticedTopic;
  final TopicStatistics? mostIncorrectTopic;
  final PaperStatistics? bestPerformingPaper;
  final PaperStatistics? lowestPerformingPaper;

  /// Positive = improving; negative = declining (accuracy delta, recent vs prior).
  final double recentImprovement;
  final double consistencyScore;

  static const empty = ProgressAnalytics(
    mostPracticedTopic: null,
    leastPracticedTopic: null,
    mostIncorrectTopic: null,
    bestPerformingPaper: null,
    lowestPerformingPaper: null,
    recentImprovement: 0,
    consistencyScore: 0,
  );
}
