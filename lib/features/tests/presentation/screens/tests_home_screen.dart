import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/app_nav_metrics.dart';
import '../../../subscription/service/course_open_guard.dart';
import '../../../syllabus/presentation/available_card_metrics.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';
import '../../../syllabus/presentation/widgets/landing_sheet.dart';
import '../../../syllabus/presentation/widgets/syllabus_course_card.dart';
import '../../data/models/test_models.dart';
import '../../services/test_service.dart';
import '../widgets/tests_hero.dart';
import '../widgets/tests_tip_banner.dart';
import 'exam_test_home_screen.dart';

/// Test Series tab — same compact proportions as Chapters.
///
/// Only the currently-available exams (Group-II / Group-III) are shown.
/// There is no "Launching Soon" section or "Coming Soon" banner.
class TestsHomeScreen extends StatelessWidget {
  const TestsHomeScreen({super.key});

  static const double _bottomNavGap = 10;

  @override
  Widget build(BuildContext context) {
    final available = TestService.instance
        .getExamSummaries()
        .where((e) => e.isEnabled)
        .toList();
    final bottomInset =
        AppNavMetrics.bottomNavigationHeight(context) + _bottomNavGap;

    return Scaffold(
      backgroundColor: SyllabusVisual.page,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final contentHeight = (h - bottomInset).clamp(0.0, h);
          // Slightly taller than the old 0.228 share: the sheet's wave now
          // rides further up the hero, and the title + two-line subtitle must
          // stay clear of it at full size instead of scaling down.
          final heroHeight = (contentHeight * 0.25).clamp(200.0, 250.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroHeight,
                child: TestsHero(height: heroHeight),
              ),
              Positioned(
                top: heroHeight - LandingSheet.heroOverlap,
                left: 0,
                right: 0,
                bottom: bottomInset,
                child: _LandingBody(
                  available: available,
                  contentHeight: contentHeight,
                  onOpenExam: (exam) => _openExam(context, exam),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openExam(BuildContext context, TestExamSummary exam) async {
    await CourseOpenGuard.attemptOpen(
      context: context,
      courseId: exam.examId,
      onAllowed: () {
        final Widget screen = switch (exam.examId) {
          'group-ii' => const GroupIITestHomeScreen(),
          'group-iii' => const GroupIIITestHomeScreen(),
          _ => ExamTestHomeScreen(examId: exam.examId, examTitle: exam.title),
        };

        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}

class _LandingBody extends StatelessWidget {
  const _LandingBody({
    required this.available,
    required this.contentHeight,
    required this.onOpenExam,
  });

  final List<TestExamSummary> available;

  /// Viewport height above the bottom navigation — the basis the shared card
  /// metrics are anchored to, so this tab's cards match the Chapters tab.
  final double contentHeight;
  final ValueChanged<TestExamSummary> onOpenExam;

  // Deliberate, fixed spacing — every value below is accounted for in the
  // budget math so no unclaimed gap can appear before the bottom nav.
  static const double _sectionTitleH = 22;
  static const double _tipToAvailable = 12;
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
            TestsTipBanner.layoutHeight +
            _tipToAvailable +
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
              const TestsTipBanner(),
              const SizedBox(height: _tipToAvailable),
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
                              title: available[i].title,
                              subtitle:
                                  '${available[i].maxMarks.toStringAsFixed(0)} Marks • ${available[i].paperCount} Papers',
                              height: card.height,
                              circleSize: card.circleSize,
                              iconSize: card.iconSize,
                              titleFontSize: card.titleFontSize,
                              subtitleFontSize: card.subtitleFontSize,
                              centerContent: true,
                              titleColor: _availableTitle,
                              boundaryTint: _darkPurple,
                              elevatedShadow: true,
                              accent: _accentFor(available[i].examId),
                              icon: _iconFor(available[i].examId),
                              onTap: () => onOpenExam(available[i]),
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

  Color _accentFor(String examId) {
    return switch (examId) {
      'group-iii' => _darkGreen,
      'group-ii' => _darkPurple,
      _ => AppColors.accent,
    };
  }

  IconData _iconFor(String examId) {
    return switch (examId) {
      'group-iii' => Icons.menu_book_rounded,
      'group-ii' => Icons.school_rounded,
      'police-si' => Icons.badge_rounded,
      'constable' => Icons.local_police_rounded,
      _ => Icons.quiz_rounded,
    };
  }
}
