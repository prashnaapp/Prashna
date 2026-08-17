import 'package:flutter/material.dart';

import '../../../../navigation/tab_scroll_view.dart';
import '../../../syllabus/presentation/widgets/landing_sheet.dart';
import '../../data/models/attempt_analytics_models.dart';
import '../../data/models/progress_models.dart';
import '../../services/progress_service.dart';
import '../progress_visual.dart';
import '../widgets/attempt_analytics_section.dart';
import '../widgets/course_progress_section.dart';
import '../widgets/progress_hero.dart';
import '../widgets/revision_center_card.dart';

/// Progress tab — purple hero waving into a light, scrolling content sheet,
/// matching the Chapters and Test Series landings.
///
/// The hero is fixed and the sheet scrolls beneath its wave, so the header
/// stays legible while the sections below can exceed one screen.
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
    final available = ProgressService.instance
        .getExamSummaries()
        .where((item) => item.isEnabled)
        .toList();

    return Scaffold(
      backgroundColor: ProgressVisual.page,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final heroHeight = (constraints.maxHeight * 0.24).clamp(196.0, 236.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroHeight,
                child: ProgressHero(height: heroHeight),
              ),
              Positioned(
                top: heroHeight - LandingSheet.heroOverlap,
                left: 0,
                right: 0,
                bottom: 0,
                child: LandingSheet(
                  expand: true,
                  padding: EdgeInsets.zero,
                  child: _ProgressBody(
                    available: available,
                    summaryFuture: _summaryFuture,
                    onAnalyticsClosed: _refreshSummary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({
    required this.available,
    required this.summaryFuture,
    required this.onAnalyticsClosed,
  });

  final List<ExamProgressSummary> available;
  final Future<ProgressSummary> summaryFuture;
  final VoidCallback onAnalyticsClosed;

  /// Breathing room between the major sections.
  static const double _sectionGap = 20;

  @override
  Widget build(BuildContext context) {
    return TabScrollView(
      // TabScrollView adds the bottom-navigation inset, so content always
      // clears the floating bar.
      padding: const EdgeInsets.fromLTRB(
        ProgressVisual.pagePadding,
        LandingSheet.topPad,
        ProgressVisual.pagePadding,
        0,
      ),
      children: [
        const RevisionCenterCard(),
        const SizedBox(height: _sectionGap),
        AttemptAnalyticsSection(
          summaryFuture: summaryFuture,
          onAnalyticsClosed: onAnalyticsClosed,
        ),
        if (available.isNotEmpty) ...[
          const SizedBox(height: _sectionGap),
          CourseProgressSection(available: available),
        ],
      ],
    );
  }
}
