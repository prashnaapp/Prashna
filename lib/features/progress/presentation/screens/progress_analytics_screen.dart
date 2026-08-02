import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/attempt_analytics_models.dart';
import '../../services/progress_service.dart';
import '../widgets/analytics_area_list_card.dart';
import '../widgets/analytics_stat_grid.dart';
import '../widgets/progress_info_card.dart';
import '../widgets/recent_attempts_list.dart';
import '../widgets/tracker_scroll_body.dart';

/// Attempt analytics surface — uses existing design tokens only.
class ProgressAnalyticsScreen extends StatefulWidget {
  const ProgressAnalyticsScreen({super.key});

  @override
  State<ProgressAnalyticsScreen> createState() =>
      _ProgressAnalyticsScreenState();
}

class _ProgressAnalyticsScreenState extends State<ProgressAnalyticsScreen> {
  late Future<_AnalyticsViewData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AnalyticsViewData> _load() async {
    final service = ProgressService.instance;
    final summary = await service.generateSummary();
    final recent = await service.loadHistory(limit: 8);
    final weak = await service.calculateWeakAreas(limit: 5);
    final strong = await service.calculateStrongAreas(limit: 5);
    final courses = await service.loadCourseStatistics();
    final papers = await service.loadPaperStatistics();
    final topics = await service.loadTopicStatistics();
    final analytics = await service.generateAnalytics();
    final daily = await service.generateDailyProgress();
    return _AnalyticsViewData(
      summary: summary,
      recent: recent,
      weak: weak,
      strong: strong,
      courses: courses,
      papers: papers,
      topics: topics,
      analytics: analytics,
      daily: daily,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analytics')),
      body: FutureBuilder<_AnalyticsViewData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final insights = data.analytics;

          return TrackerScrollBody(
            bottomInset: false,
            children: [
              Text(
                'Overall Statistics',
                style: AppTextStyles.headline(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnalyticsStatGrid(summary: data.summary),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Recent Tests',
                style: AppTextStyles.titleLarge(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              RecentAttemptsList(attempts: data.recent),
              const SizedBox(height: AppSpacing.xxl),
              ProgressInfoCard(
                label: 'Highest Score',
                value: data.summary.highestScore.toStringAsFixed(1),
              ),
              const SizedBox(height: AppSpacing.md),
              ProgressInfoCard(
                label: 'Lowest Score',
                value: data.summary.lowestScore.toStringAsFixed(1),
              ),
              const SizedBox(height: AppSpacing.md),
              ProgressInfoCard(
                label: 'Longest Streak',
                value: '${data.summary.longestStreak} days',
              ),
              const SizedBox(height: AppSpacing.md),
              ProgressInfoCard(
                label: 'Consistency Score',
                value: '${insights.consistencyScore.toStringAsFixed(1)}%',
              ),
              const SizedBox(height: AppSpacing.md),
              ProgressInfoCard(
                label: 'Recent Improvement',
                value:
                    '${insights.recentImprovement >= 0 ? '+' : ''}${insights.recentImprovement.toStringAsFixed(1)}%',
              ),
              if (data.strong.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                AnalyticsAreaListCard(
                  title: 'Strong Areas',
                  items: [
                    for (final item in data.strong)
                      (
                        name: item.topicName,
                        detail:
                            '${item.accuracy.toStringAsFixed(0)}% · ${item.attempts} attempts',
                      ),
                  ],
                ),
              ],
              if (data.weak.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                AnalyticsAreaListCard(
                  title: 'Weak Areas',
                  items: [
                    for (final item in data.weak)
                      (
                        name: item.topicName,
                        detail:
                            '${item.accuracy.toStringAsFixed(0)}% · ${item.attempts} attempts',
                      ),
                  ],
                ),
              ],
              if (data.courses.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                AnalyticsAreaListCard(
                  title: 'Progress by Course',
                  items: [
                    for (final item in data.courses)
                      (
                        name: item.courseName,
                        detail:
                            '${item.averageAccuracy.toStringAsFixed(0)}% · ${item.attempts} tests',
                      ),
                  ],
                ),
              ],
              if (data.papers.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                AnalyticsAreaListCard(
                  title: 'Progress by Paper',
                  items: [
                    for (final item in data.papers)
                      (
                        name: item.paperName,
                        detail:
                            '${item.averageAccuracy.toStringAsFixed(0)}% · ${item.attempts} tests',
                      ),
                  ],
                ),
              ],
              if (data.topics.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                AnalyticsAreaListCard(
                  title: 'Progress by Topic',
                  items: [
                    for (final item in data.topics)
                      (
                        name: item.topicName,
                        detail:
                            '${item.accuracy.toStringAsFixed(0)}% · ${item.attempts} tests',
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              Text('Insights', style: AppTextStyles.titleLarge(context)),
              const SizedBox(height: AppSpacing.lg),
              ProgressInfoCard(
                label: 'Most Practiced Topic',
                value: insights.mostPracticedTopic?.topicName ?? '—',
              ),
              const SizedBox(height: AppSpacing.md),
              ProgressInfoCard(
                label: 'Least Practiced Topic',
                value: insights.leastPracticedTopic?.topicName ?? '—',
              ),
              const SizedBox(height: AppSpacing.md),
              ProgressInfoCard(
                label: 'Most Incorrect Topic',
                value: insights.mostIncorrectTopic?.topicName ?? '—',
              ),
              const SizedBox(height: AppSpacing.md),
              ProgressInfoCard(
                label: 'Best Performing Paper',
                value: insights.bestPerformingPaper?.paperName ?? '—',
              ),
              const SizedBox(height: AppSpacing.md),
              ProgressInfoCard(
                label: 'Lowest Performing Paper',
                value: insights.lowestPerformingPaper?.paperName ?? '—',
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Daily Progress',
                style: AppTextStyles.titleLarge(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (var i = 0; i < data.daily.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                ProgressInfoCard(
                  label: data.daily[i].label,
                  value: data.daily[i].attempts == 0
                      ? 'No attempts'
                      : '${data.daily[i].attempts} · ${data.daily[i].averageAccuracy.toStringAsFixed(0)}%',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsViewData {
  const _AnalyticsViewData({
    required this.summary,
    required this.recent,
    required this.weak,
    required this.strong,
    required this.courses,
    required this.papers,
    required this.topics,
    required this.analytics,
    required this.daily,
  });

  final ProgressSummary summary;
  final List<AttemptHistory> recent;
  final List<WeakTopic> weak;
  final List<StrongTopic> strong;
  final List<CourseStatistics> courses;
  final List<PaperStatistics> papers;
  final List<TopicStatistics> topics;
  final ProgressAnalytics analytics;
  final List<PeriodProgressPoint> daily;
}
