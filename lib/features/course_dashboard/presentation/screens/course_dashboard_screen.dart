import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../../syllabus/presentation/screens/syllabus_papers_screen.dart';
import '../../../tests/presentation/screens/exam_test_home_screen.dart';
import '../../models/course_dashboard_models.dart';
import '../../services/course_dashboard_service.dart';
import '../widgets/continue_learning_section.dart';
import '../widgets/course_header_section.dart';
import '../widgets/paper_progress_section.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/weak_topics_section.dart';

/// Course study home — Progress Engine backed.
class CourseDashboardScreen extends StatefulWidget {
  const CourseDashboardScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseDashboardScreen> createState() => _CourseDashboardScreenState();
}

class _CourseDashboardScreenState extends State<CourseDashboardScreen> {
  late Future<CourseDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = CourseDashboardService.instance.loadDashboard(widget.courseId);
  }

  void _reload() {
    setState(() {
      _future =
          CourseDashboardService.instance.loadDashboard(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CourseDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(data?.title ?? 'Course'),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {},
                icon: const Icon(Icons.notifications_rounded),
              ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: AppCircularProgress())
              : SafeArea(
                  bottom: false,
                  child: AppResponsivePadding(
                    child: TabScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl,
                      ),
                      children: [
                        CourseHeaderSection(data: data!),
                        const SizedBox(height: AppSpacing.xxxl),
                        ContinueLearningSection(data: data.continueLearning),
                        const SizedBox(height: AppSpacing.xxxl),
                        QuickActionsSection(
                          onPracticeBits: () => _openPracticeBits(context),
                          onTestSeries: () =>
                              _openTestSeries(context, data.title),
                          onRevision: () => _soon(context),
                          onBookmarks: () => _soon(context),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        PaperProgressSection(papers: data.papers),
                        const SizedBox(height: AppSpacing.xxxl),
                        RecentActivitySection(activity: data.recentActivity),
                        const SizedBox(height: AppSpacing.xxxl),
                        WeakTopicsSection(topics: data.weakTopics),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _openPracticeBits(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SyllabusPapersScreen(courseId: widget.courseId),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _openTestSeries(BuildContext context, String title) async {
    final Widget screen = switch (widget.courseId) {
      'group-ii' => const GroupIITestHomeScreen(),
      'group-iii' => const GroupIIITestHomeScreen(),
      _ => ExamTestHomeScreen(examId: widget.courseId, examTitle: title),
    };

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) _reload();
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming Soon')),
    );
  }
}
