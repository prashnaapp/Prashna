import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../navigation/app_nav_metrics.dart';
import '../../../course_dashboard/presentation/screens/course_dashboard_screen.dart';
import '../../../subscription/service/course_open_guard.dart';
import '../../services/home_service.dart';
import '../home_visual.dart';
import '../widgets/continue_learning_card.dart';
import '../widgets/home_courses_section.dart';
import '../widgets/home_entrance.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_quick_access_section.dart';
import '../widgets/today_goal_card.dart';

/// Home dashboard reconstructed to the approved reference visual.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = HomeService.instance;
    final continueLearning = home.getContinueLearning();
    final todayGoal = home.getTodayGoal();
    final media = MediaQuery.of(context);
    // Edge-to-edge Android versions can expose the status inset through
    // `padding`, while other configurations expose it through `viewPadding`.
    // Use the larger physical inset so hero content is never clipped.
    final topInset = media.viewPadding.top > media.padding.top
        ? media.viewPadding.top
        : media.padding.top;
    final expandedHero = topInset + HomeVisual.heroBodyHeight;
    final collapsedHero = topInset + HomeVisual.heroCollapsedBodyHeight;
    final collapseRange = (expandedHero - collapsedHero).clamp(1.0, 500.0);
    final bottomInset = AppNavMetrics.bottomNavigationHeight(context) + 32;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: ColoredBox(
        color: HomeVisual.page,
        child: Stack(
          children: [
            // BACK — one backdrop (gradient + decorations). No branding.
            ListenableBuilder(
              listenable: _scroll,
              builder: (context, _) {
                final metrics = _collapseMetrics(
                  expandedHero: expandedHero,
                  collapsedHero: collapsedHero,
                  collapseRange: collapseRange,
                );
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: metrics.backdropHeight,
                  child: HomeHeroBackdrop(
                    collapseProgress: metrics.progress,
                  ),
                );
              },
            ),

            // MIDDLE — scroll content. Preparation paints above the backdrop
            // overlap band via the top spacer. Not rebuilt on every scroll tick.
            Positioned.fill(
              child: CustomScrollView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: expandedHero - HomeVisual.overlap,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        HomeVisual.pagePadding,
                        0,
                        HomeVisual.pagePadding,
                        bottomInset + 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TodayGoalCard(goal: todayGoal),
                          HomeEntrance(
                            index: 1,
                            topSpacing: HomeVisual.sectionGap,
                            child: ContinueLearningCard(
                              data: continueLearning,
                              onContinue: () {
                                CourseOpenGuard.attemptOpen(
                                  context: context,
                                  courseId: continueLearning.courseId,
                                  onAllowed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => CourseDashboardScreen(
                                          courseId: continueLearning.courseId,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const HomeEntrance(
                            index: 2,
                            topSpacing: HomeVisual.sectionGap,
                            child: HomeQuickAccessSection(),
                          ),
                          const HomeEntrance(
                            index: 3,
                            topSpacing: HomeVisual.sectionGap,
                            child: HomeCoursesSection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FRONT — one chrome layer (Prashna + greeting). Never a second
            // full hero, so branding cannot duplicate.
            ListenableBuilder(
              listenable: _scroll,
              builder: (context, _) {
                final metrics = _collapseMetrics(
                  expandedHero: expandedHero,
                  collapsedHero: collapsedHero,
                  collapseRange: collapseRange,
                );
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: metrics.chromeHeight,
                  child: HomeHeroChrome(
                    topInset: topInset,
                    collapseProgress: metrics.progress,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  _HeroCollapseMetrics _collapseMetrics({
    required double expandedHero,
    required double collapsedHero,
    required double collapseRange,
  }) {
    final rawOffset = _scroll.hasClients ? _scroll.offset : 0.0;
    final offset = rawOffset < 0 ? 0.0 : rawOffset;
    final pull = rawOffset < 0 ? -rawOffset : 0.0;
    final progress = (offset / collapseRange).clamp(0.0, 1.0);
    return _HeroCollapseMetrics(
      progress: progress,
      backdropHeight:
          lerpDouble(expandedHero, collapsedHero, progress)! + pull,
      chromeHeight: lerpDouble(
            expandedHero - HomeVisual.overlap,
            collapsedHero,
            progress,
          )! +
          pull,
    );
  }
}

class _HeroCollapseMetrics {
  const _HeroCollapseMetrics({
    required this.progress,
    required this.backdropHeight,
    required this.chromeHeight,
  });

  final double progress;
  final double backdropHeight;
  final double chromeHeight;
}
