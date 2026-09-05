import 'package:flutter/material.dart';

import '../../../../navigation/tab_scroll_view.dart';
import '../../../syllabus/presentation/widgets/landing_sheet.dart';
import '../../data/models/attempt_analytics_models.dart';
import '../../services/progress_service.dart';
import '../progress_visual.dart';
import '../widgets/attempt_analytics_section.dart';
import '../widgets/progress_hero.dart';
import '../widgets/revision_center_card.dart';

/// Progress tab — purple hero waving into a light, scrolling content sheet,
/// matching the Chapters and Test Series landings.
///
/// The hero is fixed and the sheet scrolls beneath its wave, so the header
/// stays legible while the sections below can exceed one screen.
class TrackerHomeScreen extends StatefulWidget {
  const TrackerHomeScreen({
    super.key,
    this.isActive = true,
    @visibleForTesting this.debugLoadSummary,
  });

  /// When the Progress tab becomes selected in the shell [IndexedStack],
  /// Attempt Analytics re-fetches submitted `test_attempts`.
  final bool isActive;

  /// Test seam for activation/refresh lifecycle only.
  @visibleForTesting
  final Future<ProgressSummary> Function()? debugLoadSummary;

  @override
  State<TrackerHomeScreen> createState() => _TrackerHomeScreenState();
}

class _TrackerHomeScreenState extends State<TrackerHomeScreen>
    with WidgetsBindingObserver {
  late Future<ProgressSummary> _summaryFuture;

  Future<ProgressSummary> _loadSummary() {
    final loader = widget.debugLoadSummary;
    if (loader != null) return loader();
    return ProgressService.instance.generateSummary();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _summaryFuture = _loadSummary();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TrackerHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _refreshSummary();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _refreshSummary();
    }
  }

  void _refreshSummary() {
    if (!mounted) return;
    setState(() {
      _summaryFuture = _loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
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
    required this.summaryFuture,
    required this.onAnalyticsClosed,
  });

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
      ],
    );
  }
}
