import '../attempt_history_dummy_data.dart';
import '../models/attempt_analytics_models.dart';

/// Per-question mistake tracking for Revision Center.
class QuestionMistakeStat {
  const QuestionMistakeStat({
    required this.questionId,
    required this.wrongCount,
    required this.lastWrongAt,
  });

  final String questionId;
  final int wrongCount;
  final DateTime lastWrongAt;
}

/// Persistence boundary for attempt analytics.
/// In-memory dummy today; swap for Firebase without changing ProgressService.
class ProgressRepository {
  /// When [seed] is true, loads fixture attempt/mistake data (tests only).
  /// Production [instance] uses [seed] `false` — cloud + live attempts are SoT.
  ProgressRepository({bool seed = false}) {
    if (seed) {
      _history.addAll(AttemptHistoryDummyData.seed());
      _seedMistakes();
    }
  }

  static final ProgressRepository instance = ProgressRepository(seed: false);

  final List<AttemptHistory> _history = [];
  final Map<String, QuestionMistakeStat> _mistakes = {};

  void _seedMistakes() {
    final now = DateTime.now();
    _mistakes['qb-1'] = QuestionMistakeStat(
      questionId: 'qb-1',
      wrongCount: 3,
      lastWrongAt: now.subtract(const Duration(days: 1)),
    );
    _mistakes['qb-3'] = QuestionMistakeStat(
      questionId: 'qb-3',
      wrongCount: 2,
      lastWrongAt: now.subtract(const Duration(days: 2)),
    );
    _mistakes['qb-6'] = QuestionMistakeStat(
      questionId: 'qb-6',
      wrongCount: 4,
      lastWrongAt: now.subtract(const Duration(hours: 8)),
    );
    _mistakes['qb-8'] = QuestionMistakeStat(
      questionId: 'qb-8',
      wrongCount: 1,
      lastWrongAt: now.subtract(const Duration(days: 3)),
    );
    _mistakes['qb-12'] = QuestionMistakeStat(
      questionId: 'qb-12',
      wrongCount: 2,
      lastWrongAt: now.subtract(const Duration(days: 4)),
    );
  }

  Future<void> saveAttempt(AttemptHistory attempt) async {
    _history.removeWhere((item) => item.attemptId == attempt.attemptId);
    _history.insert(0, attempt);
  }

  Future<void> recordQuestionMistakes({
    required List<String> wrongQuestionIds,
    DateTime? at,
  }) async {
    final when = at ?? DateTime.now();
    for (final id in wrongQuestionIds) {
      final existing = _mistakes[id];
      if (existing == null) {
        _mistakes[id] = QuestionMistakeStat(
          questionId: id,
          wrongCount: 1,
          lastWrongAt: when,
        );
      } else {
        _mistakes[id] = QuestionMistakeStat(
          questionId: id,
          wrongCount: existing.wrongCount + 1,
          lastWrongAt: when,
        );
      }
    }
  }

  /// Clears only in-memory user state. It never touches cloud progress.
  void clear() {
    _history.clear();
    _mistakes.clear();
  }

  Future<List<QuestionMistakeStat>> loadMistakeStats() async {
    final items = _mistakes.values.toList()
      ..sort((a, b) => b.lastWrongAt.compareTo(a.lastWrongAt));
    return items;
  }

  Future<List<String>> loadWrongQuestionIds() async {
    return _mistakes.keys.toList(growable: false);
  }

  Future<List<String>> loadFrequentlyWrongIds({int minWrongCount = 2}) async {
    return _mistakes.values
        .where((item) => item.wrongCount >= minWrongCount)
        .map((item) => item.questionId)
        .toList(growable: false);
  }

  Future<List<String>> loadRecentMistakeIds({
    Duration within = const Duration(days: 7),
    int limit = 20,
  }) async {
    final cutoff = DateTime.now().subtract(within);
    final recent =
        _mistakes.values
            .where((item) => !item.lastWrongAt.isBefore(cutoff))
            .toList()
          ..sort((a, b) => b.lastWrongAt.compareTo(a.lastWrongAt));
    return recent.take(limit).map((item) => item.questionId).toList();
  }

  Future<List<AttemptHistory>> loadHistory({
    String? courseId,
    int? limit,
  }) async {
    var items = List<AttemptHistory>.from(_history);
    if (courseId != null) {
      items = items.where((item) => item.courseId == courseId).toList();
    }
    items.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    if (limit != null && limit < items.length) {
      return items.take(limit).toList(growable: false);
    }
    return items;
  }

  Future<ProgressSummary> loadSummary({String? courseId}) async {
    final history = await loadHistory(courseId: courseId);
    return summaryFromHistory(history);
  }

  /// Builds aggregate Attempt Analytics from an already-loaded history list.
  ///
  /// Used when history comes from server `test_attempts` rather than the
  /// in-memory session cache.
  ProgressSummary summaryFromHistory(List<AttemptHistory> history) {
    return _buildSummary(history);
  }

  Future<List<TopicStatistics>> loadTopicStatistics({String? courseId}) async {
    final history = await loadHistory(courseId: courseId);
    return _aggregateTopics(history);
  }

  Future<List<PaperStatistics>> loadPaperStatistics({String? courseId}) async {
    final history = await loadHistory(courseId: courseId);
    return _aggregatePapers(history);
  }

  Future<List<CourseStatistics>> loadCourseStatistics() async {
    final history = await loadHistory();
    return _aggregateCourses(history);
  }

  ProgressSummary _buildSummary(List<AttemptHistory> history) {
    if (history.isEmpty) return ProgressSummary.empty;

    final totalTests = history.length;
    final totalQuestions = history.fold<int>(
      0,
      (sum, item) => sum + item.totalQuestions,
    );
    final averageScore =
        history.fold<double>(0, (sum, item) => sum + item.score) / totalTests;
    final averageAccuracy =
        history.fold<double>(0, (sum, item) => sum + item.accuracy) /
        totalTests;
    final averageSeconds =
        history.fold<int>(0, (sum, item) => sum + item.timeTaken.inSeconds) ~/
        totalTests;
    final scores = history.map((item) => item.score).toList()..sort();
    final streaks = _computeStreaks(history);

    return ProgressSummary(
      totalTests: totalTests,
      totalQuestions: totalQuestions,
      averageScore: _round1(averageScore),
      averageAccuracy: _round1(averageAccuracy),
      averageTime: Duration(seconds: averageSeconds),
      highestScore: scores.last,
      lowestScore: scores.first,
      currentStreak: streaks.current,
      longestStreak: streaks.longest,
    );
  }

  List<TopicStatistics> _aggregateTopics(List<AttemptHistory> history) {
    final map = <String, _TopicBucket>{};
    for (final item in history) {
      final id = item.topicId;
      if (id == null || id.isEmpty) continue;
      final bucket = map.putIfAbsent(
        id,
        () => _TopicBucket(
          id: id,
          name: item.topicName ?? id,
          paperId: item.paperId,
          paperName: item.paperName,
          courseId: item.courseId,
        ),
      );
      bucket.paperId ??= item.paperId;
      bucket.paperName ??= item.paperName;
      bucket.courseId ??= item.courseId;
      bucket.attempts += 1;
      bucket.correct += item.correct;
      bucket.wrong += item.wrong;
      bucket.skipped += item.skipped;
      bucket.scoreSum += item.score;
    }

    return map.values.map((bucket) {
      final total = bucket.correct + bucket.wrong + bucket.skipped;
      final answered = bucket.correct + bucket.wrong;
      final accuracy = answered == 0 ? 0.0 : (bucket.correct / answered) * 100;
      return TopicStatistics(
        topicId: bucket.id,
        topicName: bucket.name,
        attempts: bucket.attempts,
        totalQuestions: total,
        correct: bucket.correct,
        wrong: bucket.wrong,
        accuracy: _round1(accuracy),
        averageScore: _round1(bucket.scoreSum / bucket.attempts),
        paperId: bucket.paperId,
        paperName: bucket.paperName,
        courseId: bucket.courseId,
      );
    }).toList()..sort((a, b) => a.topicName.compareTo(b.topicName));
  }

  List<PaperStatistics> _aggregatePapers(List<AttemptHistory> history) {
    final map = <String, _PaperBucket>{};
    for (final item in history) {
      final id = item.paperId;
      if (id == null || id.isEmpty) continue;
      final bucket = map.putIfAbsent(
        id,
        () => _PaperBucket(id: id, name: item.paperName ?? id),
      );
      bucket.attempts += 1;
      bucket.accuracySum += item.accuracy;
      bucket.scoreSum += item.score;
      bucket.percentageSum += item.percentage;
    }

    return map.values.map((bucket) {
      return PaperStatistics(
        paperId: bucket.id,
        paperName: bucket.name,
        attempts: bucket.attempts,
        averageAccuracy: _round1(bucket.accuracySum / bucket.attempts),
        averageScore: _round1(bucket.scoreSum / bucket.attempts),
        averagePercentage: _round1(bucket.percentageSum / bucket.attempts),
      );
    }).toList()..sort((a, b) => a.paperName.compareTo(b.paperName));
  }

  List<CourseStatistics> _aggregateCourses(List<AttemptHistory> history) {
    final map = <String, _CourseBucket>{};
    for (final item in history) {
      final bucket = map.putIfAbsent(
        item.courseId,
        () => _CourseBucket(
          id: item.courseId,
          name: item.courseName ?? item.courseId,
        ),
      );
      bucket.attempts += 1;
      bucket.accuracySum += item.accuracy;
      bucket.scoreSum += item.score;
      bucket.percentageSum += item.percentage;
      bucket.questions += item.totalQuestions;
    }

    return map.values.map((bucket) {
      return CourseStatistics(
        courseId: bucket.id,
        courseName: bucket.name,
        attempts: bucket.attempts,
        averageAccuracy: _round1(bucket.accuracySum / bucket.attempts),
        averageScore: _round1(bucket.scoreSum / bucket.attempts),
        averagePercentage: _round1(bucket.percentageSum / bucket.attempts),
        totalQuestions: bucket.questions,
      );
    }).toList()..sort((a, b) => a.courseName.compareTo(b.courseName));
  }

  ({int current, int longest}) _computeStreaks(List<AttemptHistory> history) {
    if (history.isEmpty) return (current: 0, longest: 0);

    final days =
        history
            .map(
              (item) => DateTime(
                item.dateTime.year,
                item.dateTime.month,
                item.dateTime.day,
              ),
            )
            .toSet()
            .toList()
          ..sort();

    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap == 1) {
        run += 1;
        if (run > longest) longest = run;
      } else if (gap > 1) {
        run = 1;
      }
    }

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final yesterday = todayKey.subtract(const Duration(days: 1));
    var current = 0;
    var cursor = days.contains(todayKey)
        ? todayKey
        : days.contains(yesterday)
        ? yesterday
        : null;
    if (cursor != null) {
      while (days.contains(cursor)) {
        current += 1;
        cursor = cursor!.subtract(const Duration(days: 1));
      }
    }

    return (current: current, longest: longest);
  }

  double _round1(double value) => double.parse(value.toStringAsFixed(1));
}

class _TopicBucket {
  _TopicBucket({
    required this.id,
    required this.name,
    this.paperId,
    this.paperName,
    this.courseId,
  });
  final String id;
  final String name;
  String? paperId;
  String? paperName;
  String? courseId;
  int attempts = 0;
  int correct = 0;
  int wrong = 0;
  int skipped = 0;
  double scoreSum = 0;
}

class _PaperBucket {
  _PaperBucket({required this.id, required this.name});
  final String id;
  final String name;
  int attempts = 0;
  double accuracySum = 0;
  double scoreSum = 0;
  double percentageSum = 0;
}

class _CourseBucket {
  _CourseBucket({required this.id, required this.name});
  final String id;
  final String name;
  int attempts = 0;
  double accuracySum = 0;
  double scoreSum = 0;
  double percentageSum = 0;
  int questions = 0;
}
