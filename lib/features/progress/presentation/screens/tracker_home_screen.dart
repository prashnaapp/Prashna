import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../data/models/attempt_analytics_models.dart';
import '../../services/progress_service.dart';
import '../widgets/attempt_analytics_section.dart';
import '../widgets/course_progress_section.dart';
import '../widgets/revision_center_card.dart';

/// Progress tab — same composition pattern as Home.
///
/// Scaffold → AppBar → SafeArea → AppResponsivePadding → TabScrollView → sections
class TrackerHomeScreen extends StatefulWidget {
  const TrackerHomeScreen({super.key});

  @override
  State<TrackerHomeScreen> createState() => _TrackerHomeScreenState();
}

class _TrackerHomeScreenState extends State<TrackerHomeScreen> {
  late Future<ProgressSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = ProgressService.instance.generateSummary();
  }

  void _refreshSummary() {
    if (!mounted) return;
    setState(() {
      _summaryFuture = ProgressService.instance.generateSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final summaries = ProgressService.instance.getExamSummaries();
    final enabled = summaries.where((item) => item.isEnabled).toList();
    final comingSoon = summaries.where((item) => !item.isEnabled).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Progress')),
      body: SafeArea(
        bottom: false,
        child: AppResponsivePadding(
          child: TabScrollView(
            // Horizontal inset from AppResponsivePadding only (Home/Test Series parity).
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            children: [
              Text(
                'Track your syllabus progress.',
                style: AppTextStyles.bodyMedium(context),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const RevisionCenterCard(),
              const SizedBox(height: AppSpacing.xxl),
              AttemptAnalyticsSection(
                summaryFuture: _summaryFuture,
                onAnalyticsClosed: _refreshSummary,
              ),
              if (enabled.isNotEmpty || comingSoon.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                CourseProgressSection(
                  enabled: enabled,
                  comingSoon: comingSoon,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
