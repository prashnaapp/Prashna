import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../authentication/services/auth_service.dart';
import '../../progress_cloud/model/user_progress.dart';
import '../../progress_cloud/service/progress_cloud_service.dart';
import '../../syllabus/services/syllabus_service.dart';
import '../../test_engine/data/models/test_engine_models.dart';
import '../calculators/progress_calculator.dart';
import '../data/models/attempt_analytics_models.dart';
import '../data/models/progress_models.dart';
import '../data/progress_dummy_data.dart';
import '../data/repositories/progress_repository.dart';

/// Single source of truth for syllabus progress + attempt analytics.
///
/// Local storage remains authoritative. Cloud sync is asynchronous and best-effort.
class ProgressService {
  ProgressService._();

  static final ProgressService instance = ProgressService._();

  final ProgressCalculator _calculator = ProgressCalculator();
  final ProgressRepository _repository = ProgressRepository.instance;
  final ProgressCloudService _cloud = ProgressCloudService.instance;
  final Map<String, OverallProgress> _overallCache = {};
  final Map<String, double> _testMarkCredits = {};

  /// Coalesces rapid sync requests so only the latest snapshot is written.
  int _cloudSyncGeneration = 0;
  String? _pendingCloudCourseId;

  // ---------------------------------------------------------------------------
  // Attempt analytics (Progress Engine)
  // ---------------------------------------------------------------------------

  /// Called by Test Engine after every completed attempt.
  Future<void> recordTestAttempt({
    required Test test,
    required TestResult result,
    List<QuestionAttempt>? attempts,
  }) async {
    final attempt = AttemptHistory(
      attemptId: '${test.id}-${DateTime.now().millisecondsSinceEpoch}',
      testId: test.id,
      courseId: test.courseId,
      courseName: _courseLabel(test.courseId),
      paperId: test.paperId,
      paperName: test.paperId == null ? null : _paperLabel(test.paperId!),
      sectionId: test.sectionId,
      topicId: test.topicId,
      topicName: test.topicId == null ? null : _topicLabel(test.topicId!),
      testMode: test.mode.name,
      dateTime: DateTime.now(),
      score: result.score,
      percentage: result.percentage,
      accuracy: result.accuracy,
      correct: result.correct,
      wrong: result.wrong,
      skipped: result.skipped,
      timeTaken: result.timeTaken,
    );

    await updateProgress(attempt);

    if (attempts != null) {
      final byId = {
        for (final question in test.questions) question.id: question,
      };
      final wrongIds = <String>[];
      for (final item in attempts) {
        final question = byId[item.questionId];
        if (question == null) continue;
        if (item.answered &&
            item.selectedOption != null &&
            item.selectedOption != question.correctOption) {
          wrongIds.add(item.questionId);
        }
      }
      if (wrongIds.isNotEmpty) {
        await _repository.recordQuestionMistakes(wrongQuestionIds: wrongIds);
      }
    }

    applyTestCompletion(
      examId: test.courseId,
      correctAnswers: result.correct,
      totalQuestions: result.totalQuestions,
    );

    // Ensure attempt history is mirrored even if applyTestCompletion no-ops.
    // Coalesced with the schedule inside applyTestCompletion when both run.
    _scheduleCloudSync(courseId: test.courseId);
  }

  Future<List<String>> loadWrongQuestionIds() =>
      _repository.loadWrongQuestionIds();

  Future<List<String>> loadFrequentlyWrongIds({int minWrongCount = 2}) =>
      _repository.loadFrequentlyWrongIds(minWrongCount: minWrongCount);

  Future<List<String>> loadRecentMistakeIds({
    Duration within = const Duration(days: 7),
    int limit = 20,
  }) =>
      _repository.loadRecentMistakeIds(within: within, limit: limit);

  Future<List<QuestionMistakeStat>> loadMistakeStats() =>
      _repository.loadMistakeStats();


  Future<void> updateProgress(AttemptHistory attempt) {
    return _repository.saveAttempt(attempt);
  }

  Future<ProgressSummary> generateSummary({String? courseId}) {
    return _repository.loadSummary(courseId: courseId);
  }

  Future<List<AttemptHistory>> loadHistory({
    String? courseId,
    int? limit,
  }) {
    return _repository.loadHistory(courseId: courseId, limit: limit);
  }

  Future<List<WeakTopic>> calculateWeakAreas({
    String? courseId,
    int limit = 5,
  }) async {
    final topics = await _repository.loadTopicStatistics(courseId: courseId);
    final ranked = [...topics]
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return ranked
        .take(limit)
        .map(
          (topic) => WeakTopic(
            topicId: topic.topicId,
            topicName: topic.topicName,
            accuracy: topic.accuracy,
            attempts: topic.attempts,
            paperId: topic.paperId,
            paperName: topic.paperName,
            courseId: topic.courseId ?? courseId,
          ),
        )
        .toList(growable: false);
  }

  Future<List<StrongTopic>> calculateStrongAreas({
    String? courseId,
    int limit = 5,
  }) async {
    final topics = await _repository.loadTopicStatistics(courseId: courseId);
    final ranked = [...topics]
      ..sort((a, b) => b.accuracy.compareTo(a.accuracy));
    return ranked
        .take(limit)
        .map(
          (topic) => StrongTopic(
            topicId: topic.topicId,
            topicName: topic.topicName,
            accuracy: topic.accuracy,
            attempts: topic.attempts,
          ),
        )
        .toList(growable: false);
  }

  Future<List<PeriodProgressPoint>> generateDailyProgress({
    String? courseId,
    int days = 7,
  }) async {
    final history = await _repository.loadHistory(courseId: courseId);
    final now = DateTime.now();
    final points = <PeriodProgressPoint>[];

    for (var i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final items = history.where((item) {
        final d = item.dateTime;
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).toList();
      points.add(_periodPoint(_weekday(day), day, items));
    }
    return points;
  }

  Future<List<PeriodProgressPoint>> generateWeeklyProgress({
    String? courseId,
    int weeks = 4,
  }) async {
    final history = await _repository.loadHistory(courseId: courseId);
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final points = <PeriodProgressPoint>[];

    for (var i = weeks - 1; i >= 0; i--) {
      final from = weekStart.subtract(Duration(days: 7 * i));
      final to = from.add(const Duration(days: 7));
      final items = history
          .where(
            (item) =>
                !item.dateTime.isBefore(from) && item.dateTime.isBefore(to),
          )
          .toList();
      points.add(_periodPoint('W${weeks - i}', from, items));
    }
    return points;
  }

  Future<List<PeriodProgressPoint>> generateMonthlyProgress({
    String? courseId,
    int months = 6,
  }) async {
    final history = await _repository.loadHistory(courseId: courseId);
    final now = DateTime.now();
    final points = <PeriodProgressPoint>[];

    for (var i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final next = DateTime(month.year, month.month + 1, 1);
      final items = history
          .where(
            (item) =>
                !item.dateTime.isBefore(month) && item.dateTime.isBefore(next),
          )
          .toList();
      points.add(_periodPoint(_monthLabel(month), month, items));
    }
    return points;
  }

  Future<List<TopicStatistics>> loadTopicStatistics({String? courseId}) {
    return _repository.loadTopicStatistics(courseId: courseId);
  }

  Future<List<PaperStatistics>> loadPaperStatistics({String? courseId}) {
    return _repository.loadPaperStatistics(courseId: courseId);
  }

  Future<List<CourseStatistics>> loadCourseStatistics() {
    return _repository.loadCourseStatistics();
  }

  Future<ProgressAnalytics> generateAnalytics({String? courseId}) async {
    final topics = await loadTopicStatistics(courseId: courseId);
    final papers = await loadPaperStatistics(courseId: courseId);
    final history = await loadHistory(courseId: courseId);

    if (topics.isEmpty && papers.isEmpty) return ProgressAnalytics.empty;

    TopicStatistics? mostPracticed;
    TopicStatistics? leastPracticed;
    TopicStatistics? mostIncorrect;
    for (final topic in topics) {
      if (mostPracticed == null || topic.attempts > mostPracticed.attempts) {
        mostPracticed = topic;
      }
      if (leastPracticed == null || topic.attempts < leastPracticed.attempts) {
        leastPracticed = topic;
      }
      if (mostIncorrect == null || topic.wrong > mostIncorrect.wrong) {
        mostIncorrect = topic;
      }
    }

    PaperStatistics? bestPaper;
    PaperStatistics? lowestPaper;
    for (final paper in papers) {
      if (bestPaper == null ||
          paper.averageAccuracy > bestPaper.averageAccuracy) {
        bestPaper = paper;
      }
      if (lowestPaper == null ||
          paper.averageAccuracy < lowestPaper.averageAccuracy) {
        lowestPaper = paper;
      }
    }

    final recentImprovement = _recentImprovement(history);
    final consistency = _consistencyScore(history);

    return ProgressAnalytics(
      mostPracticedTopic: mostPracticed,
      leastPracticedTopic: leastPracticed,
      mostIncorrectTopic: mostIncorrect,
      bestPerformingPaper: bestPaper,
      lowestPerformingPaper: lowestPaper,
      recentImprovement: recentImprovement,
      consistencyScore: consistency,
    );
  }

  // ---------------------------------------------------------------------------
  // Syllabus progress (existing)
  // ---------------------------------------------------------------------------

  /// Records marks earned from a completed test series attempt.
  void applyTestCompletion({
    required String examId,
    required int correctAnswers,
    required int totalQuestions,
  }) {
    if (totalQuestions <= 0) return;
    final earned = correctAnswers.toDouble();
    _testMarkCredits[examId] = (_testMarkCredits[examId] ?? 0) + earned;
    _overallCache.remove(examId);

    // Fire-and-forget — UI never awaits Firestore.
    _scheduleCloudSync(courseId: examId);
  }

  OverallProgress _withTestCredits(OverallProgress progress, String examId) {
    final credit = _testMarkCredits[examId] ?? 0;
    if (credit <= 0) return progress;

    final covered =
        (progress.coveredMarks + credit).clamp(0.0, progress.maxMarks).toDouble();
    final remaining =
        (progress.maxMarks - covered).clamp(0.0, progress.maxMarks).toDouble();
    final percent = progress.maxMarks <= 0
        ? 0.0
        : double.parse(
            ((covered / progress.maxMarks) * 100).toStringAsFixed(0),
          );

    return OverallProgress(
      examId: progress.examId,
      examTitle: progress.examTitle,
      maxMarks: progress.maxMarks,
      coveredMarks: covered,
      progressPercent: percent,
      remainingMarks: remaining,
      papers: progress.papers,
    );
  }

  /// Exam catalog from [SyllabusService] — same MVP list as Test Series.
  List<ExamProgressSummary> getExamSummaries() {
    return SyllabusService.instance.getAllCourses().map((course) {
      if (course.isAvailable) {
        final seed = ProgressDummyData.examSeeds[course.id];
        return ExamProgressSummary(
          examId: course.id,
          title: course.name,
          maxMarks: seed?.maxMarks ?? course.totalMarks.toDouble(),
          paperCount: seed?.papers.length ?? course.totalPapers,
          isEnabled: true,
        );
      }
      return ExamProgressSummary(
        examId: course.id,
        title: course.name,
        maxMarks: 0,
        paperCount: 0,
        isEnabled: false,
      );
    }).toList(growable: false);
  }

  OverallProgress getOverallProgress(String examId) {
    return _overallCache.putIfAbsent(examId, () {
      final seed = ProgressDummyData.examSeeds[examId];
      if (seed == null) {
        throw ArgumentError('Unknown examId: $examId');
      }
      return _withTestCredits(_calculator.calculateOverall(seed), examId);
    });
  }

  PaperProgress getPaperProgress({
    required String examId,
    required String paperId,
  }) {
    final paper = getOverallProgress(examId).papers.firstWhere(
          (item) => item.id == paperId,
        );
    return paper;
  }

  PartProgress getPartProgress({
    required String examId,
    required String paperId,
    required String partId,
  }) {
    return getPaperProgress(examId: examId, paperId: paperId).parts.firstWhere(
          (item) => item.id == partId,
        );
  }

  ChapterProgress getChapterProgress({
    required String examId,
    required String paperId,
    required String partId,
    required String chapterId,
  }) {
    return getPartProgress(
      examId: examId,
      paperId: paperId,
      partId: partId,
    ).chapters.firstWhere((item) => item.id == chapterId);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  PeriodProgressPoint _periodPoint(
    String label,
    DateTime date,
    List<AttemptHistory> items,
  ) {
    if (items.isEmpty) {
      return PeriodProgressPoint(
        label: label,
        date: date,
        attempts: 0,
        averageAccuracy: 0,
        averageScore: 0,
      );
    }
    final accuracy =
        items.fold<double>(0, (sum, item) => sum + item.accuracy) /
            items.length;
    final score =
        items.fold<double>(0, (sum, item) => sum + item.score) / items.length;
    return PeriodProgressPoint(
      label: label,
      date: date,
      attempts: items.length,
      averageAccuracy: double.parse(accuracy.toStringAsFixed(1)),
      averageScore: double.parse(score.toStringAsFixed(1)),
    );
  }

  double _recentImprovement(List<AttemptHistory> history) {
    if (history.length < 2) return 0;
    final sorted = [...history]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final mid = sorted.length ~/ 2;
    final older = sorted.sublist(0, mid);
    final newer = sorted.sublist(mid);
    final olderAvg =
        older.fold<double>(0, (sum, item) => sum + item.accuracy) / older.length;
    final newerAvg =
        newer.fold<double>(0, (sum, item) => sum + item.accuracy) / newer.length;
    return double.parse((newerAvg - olderAvg).toStringAsFixed(1));
  }

  double _consistencyScore(List<AttemptHistory> history) {
    if (history.isEmpty) return 0;
    if (history.length == 1) return 100;
    final accuracies = history.map((item) => item.accuracy).toList();
    final mean =
        accuracies.fold<double>(0, (sum, value) => sum + value) /
            accuracies.length;
    final variance = accuracies.fold<double>(
          0,
          (sum, value) => sum + (value - mean) * (value - mean),
        ) /
        accuracies.length;
    final stdDev = variance <= 0 ? 0.0 : _sqrt(variance);
    final score = (100 - stdDev).clamp(0, 100).toDouble();
    return double.parse(score.toStringAsFixed(1));
  }

  double _sqrt(double value) {
    if (value <= 0) return 0;
    var x = value;
    for (var i = 0; i < 8; i++) {
      x = 0.5 * (x + value / x);
    }
    return x;
  }

  String _weekday(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[date.weekday - 1];
  }

  String _monthLabel(DateTime date) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[date.month - 1];
  }

  String _courseLabel(String courseId) {
    switch (courseId) {
      case 'group-ii':
        return 'Group-II';
      case 'group-iii':
        return 'Group-III';
      default:
        return courseId;
    }
  }

  String _paperLabel(String paperId) =>
      'Paper ${paperId.replaceAll('paper-', '')}';

  String _topicLabel(String topicId) =>
      'Topic ${topicId.replaceAll('topic-', '')}';

  // ---------------------------------------------------------------------------
  // Cloud sync (best-effort mirror of local progress)
  // ---------------------------------------------------------------------------

  /// Schedules an async Firestore sync. Rapid calls are coalesced so only the
  /// latest local snapshot is written (prevents duplicate overlapping writes).
  void _scheduleCloudSync({required String courseId}) {
    // TEMP DEBUG (Milestone 15.3)
    debugPrint('Cloud sync requested');

    final user = AuthService.instance.currentUser;
    final uid = user?.uid;
    // TEMP DEBUG (Milestone 15.3)
    debugPrint('Current Firebase UID: ${uid ?? 'NULL'}');
    debugPrint('Current Firebase user email: ${user?.email ?? 'NULL'}');

    if (uid == null || uid.isEmpty) {
      // TEMP DEBUG (Milestone 15.3)
      debugPrint('_scheduleCloudSync returns early: YES (UID null/empty)');
      return;
    }

    // TEMP DEBUG (Milestone 15.3)
    debugPrint('_scheduleCloudSync returns early: NO');

    _pendingCloudCourseId = courseId;
    final generation = ++_cloudSyncGeneration;

    unawaited(_runCloudSync(uid: uid, generation: generation));
  }

  Future<void> _runCloudSync({
    required String uid,
    required int generation,
  }) async {
    // Brief delay lets recordTestAttempt → applyTestCompletion collapse into one write.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (generation != _cloudSyncGeneration) return;

    final courseId = _pendingCloudCourseId;
    if (courseId == null) return;

    try {
      final snapshot = await _buildCloudSnapshot(uid: uid, courseId: courseId);
      if (generation != _cloudSyncGeneration) return;
      await _cloud.syncSnapshot(snapshot);
    } catch (error, stack) {
      // Never crash — local progress already committed.
      debugPrint('ProgressService cloud sync failed: $error\n$stack');
    }
  }

  Future<UserProgress> _buildCloudSnapshot({
    required String uid,
    required String courseId,
  }) async {
    final summary = await generateSummary(courseId: courseId);
    final history = await loadHistory(courseId: courseId);

    final questionsCorrect =
        history.fold<int>(0, (sum, item) => sum + item.correct);
    final questionsAttempted = history.fold<int>(
      0,
      (sum, item) => sum + item.correct + item.wrong + item.skipped,
    );

    var completion = 0.0;
    var chaptersCompleted = 0;
    var totalChapters = 0;
    final papers = <String, dynamic>{};
    final chapters = <String, dynamic>{};

    if (ProgressDummyData.examSeeds.containsKey(courseId)) {
      try {
        final overall = getOverallProgress(courseId);
        completion = overall.progressPercent;
        for (final paper in overall.papers) {
          papers[paper.id] = {
            'id': paper.id,
            'label': paper.label,
            'maxMarks': paper.maxMarks,
            'coveredMarks': paper.coveredMarks,
            'progressPercent': paper.progressPercent,
            'remainingMarks': paper.remainingMarks,
          };
          for (final part in paper.parts) {
            for (final chapter in part.chapters) {
              totalChapters += 1;
              if (chapter.progressPercent >= 75 ||
                  chapter.status.toLowerCase() == 'completed') {
                chaptersCompleted += 1;
              }
              chapters[chapter.id] = {
                'id': chapter.id,
                'label': chapter.label,
                'paperId': paper.id,
                'partId': part.id,
                'maxMarks': chapter.maxMarks,
                'coveredMarks': chapter.coveredMarks,
                'progressPercent': chapter.progressPercent,
                'remainingMarks': chapter.remainingMarks,
                'status': chapter.status,
              };
            }
          }
        }
      } catch (error, stack) {
        debugPrint(
          'ProgressService cloud snapshot overall skipped: $error\n$stack',
        );
      }
    }

    return UserProgress(
      uid: uid,
      courseId: courseId,
      overall: ProgressOverall(
        completion: completion,
        accuracy: summary.averageAccuracy,
        chaptersCompleted: chaptersCompleted,
        totalChapters: totalChapters,
        questionsAttempted: questionsAttempted,
        questionsCorrect: questionsCorrect,
      ),
      papers: papers,
      chapters: chapters,
      lastUpdated: null,
      appVersion: null,
    );
  }
}
