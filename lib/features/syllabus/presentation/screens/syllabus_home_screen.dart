import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/app_nav_metrics.dart';
import '../../../subscription/service/course_open_guard.dart';
import '../../data/models/syllabus_models.dart';
import '../../services/syllabus_service.dart';
import '../available_card_metrics.dart';
import '../syllabus_visual.dart';
import '../widgets/chapters_hero.dart';
import '../widgets/landing_sheet.dart';
import '../widgets/syllabus_course_card.dart';
import 'syllabus_browser_screen.dart';

/// Chapters tab root — fixed single-viewport landing (no scroll).
///
/// Only the currently-available courses (Group-II / Group-III) are shown.
/// There is no "Launching Soon" section or "Coming Soon" banner.
class SyllabusHomeScreen extends StatelessWidget {
  const SyllabusHomeScreen({super.key});

  static const double _bottomNavGap = 10;

  @override
  Widget build(BuildContext context) {
    final available = SyllabusService.instance
        .getAllCourses()
        .where((c) => c.isAvailable)
        .toList();
    final bottomInset =
        AppNavMetrics.bottomNavigationHeight(context) + _bottomNavGap;

    return Scaffold(
      backgroundColor: SyllabusVisual.page,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final contentHeight = (h - bottomInset).clamp(0.0, h);
          // Hero takes a deliberate share of the screen (reference proportion)
          // so the body below never inherits an oversized leftover budget.
          final heroHeight = (contentHeight * 0.33).clamp(224.0, 290.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroHeight,
                child: ChaptersHero(height: heroHeight),
              ),
              Positioned(
                top: heroHeight - LandingSheet.heroOverlap,
                left: 0,
                right: 0,
                bottom: bottomInset,
                child: _LandingBody(
                  available: available,
                  contentHeight: contentHeight,
                  onOpenCourse: (course) => _openCourse(context, course),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCourse(BuildContext context, SyllabusCourse course) async {
    await CourseOpenGuard.attemptOpen(
      context: context,
      courseId: course.id,
      onAllowed: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => SyllabusBrowserScreen(courseId: course.id),
          ),
        );
      },
    );
  }
}

class _LandingBody extends StatelessWidget {
  const _LandingBody({
    required this.available,
    required this.contentHeight,
    required this.onOpenCourse,
  });

  final List<SyllabusCourse> available;

  /// Viewport height above the bottom navigation — the basis the shared card
  /// metrics are anchored to.
  final double contentHeight;
  final ValueChanged<SyllabusCourse> onOpenCourse;

  // Deliberate, fixed spacing — every value below is accounted for in the
  // budget math so no unclaimed gap can appear before the bottom nav.
  static const double _sectionTitleH = 22;
  static const double _availableToCards = 14;
  static const double _bottomBreathBase = 16;

  // Darker, more prominent tones for the Available (Group-II/III) cards.
  static const Color _darkPurple = Color(0xFF4A3AB0);
  static const Color _darkGreen = Color(0xFF167A63);
  static const Color _availableTitle = Color(0xFF130F2B);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyH = constraints.maxHeight;
        final contentWidth =
            constraints.maxWidth - (2 * SyllabusVisual.pagePadding);

        final chromeBeforeCards =
            LandingSheet.topPad +
            (available.isNotEmpty ? _sectionTitleH + _availableToCards : 0);

        final cardArea = (bodyH - chromeBeforeCards - _bottomBreathBase).clamp(
          0.0,
          bodyH,
        );

        final card = AvailableCardMetrics.forViewport(
          contentWidth: contentWidth,
          contentHeight: contentHeight,
          maxHeight: cardArea,
        );
        final leftover = (cardArea - card.height).clamp(0.0, cardArea);
        final bottomBreath = _bottomBreathBase + leftover;

        return LandingSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (available.isNotEmpty) ...[
                SizedBox(
                  height: _sectionTitleH,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Available',
                      style: AppTextStyles.titleMedium(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: SyllabusVisual.ink,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: _availableToCards),
                SizedBox(
                  height: card.height,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < available.length; i++) ...[
                          if (i > 0)
                            const SizedBox(width: AvailableCardMetrics.gap),
                          SizedBox(
                            width: card.width,
                            child: SyllabusCourseCard(
                              title: available[i].name,
                              subtitle:
                                  '${available[i].totalMarks} Marks • ${available[i].totalPapers} Papers',
                              height: card.height,
                              circleSize: card.circleSize,
                              iconSize: card.iconSize,
                              titleFontSize: card.titleFontSize,
                              subtitleFontSize: card.subtitleFontSize,
                              centerContent: true,
                              titleColor: _availableTitle,
                              boundaryTint: _darkPurple,
                              elevatedShadow: true,
                              accent: _accentFor(available[i].id),
                              icon: _iconFor(available[i].icon),
                              onTap: () => onOpenCourse(available[i]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: bottomBreath),
            ],
          ),
        );
      },
    );
  }

  Color _accentFor(String courseId) {
    return switch (courseId) {
      'group-iii' => _darkGreen,
      'group-ii' => _darkPurple,
      _ => AppColors.accent,
    };
  }

  IconData _iconFor(String key) {
    return switch (key) {
      'school' => Icons.school_rounded,
      'menu_book' => Icons.menu_book_rounded,
      'badge' => Icons.badge_rounded,
      'local_police' => Icons.local_police_rounded,
      _ => Icons.auto_stories_rounded,
    };
  }
}
