import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telangana_prep/features/progress/data/models/attempt_analytics_models.dart';
import 'package:telangana_prep/features/progress/presentation/screens/tracker_home_screen.dart';
import 'package:telangana_prep/features/progress/presentation/widgets/analytics_stat_grid.dart';
import 'package:telangana_prep/features/progress/presentation/widgets/progress_hero.dart';
import 'package:telangana_prep/features/progress/presentation/widgets/revision_center_card.dart';
import 'package:telangana_prep/navigation/app_nav_item.dart';
import 'package:telangana_prep/navigation/app_nav_metrics.dart';
import 'package:telangana_prep/navigation/custom_bottom_navigation.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Progress landing renders without overflow on phone sizes', (
    tester,
  ) async {
    for (final size in [
      const Size(360, 740),
      const Size(390, 844),
      const Size(412, 915),
      const Size(430, 932),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      // Fresh tree per size: otherwise the previous iteration's scroll offset
      // is restored and the position assertions below measure a scrolled sheet.
      await tester.pumpWidget(const SizedBox.shrink());

      FlutterErrorDetails? overflow;
      final old = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('overflowed')) overflow ??= details;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackerHomeScreen(
              debugLoadSummary: () async => const ProgressSummary(
                totalTests: 3,
                totalQuestions: 42,
                averageScore: 12.5,
                averageAccuracy: 80.0,
                averageTime: Duration(minutes: 2),
                highestScore: 20,
                lowestScore: 5,
                currentStreak: 4,
                longestStreak: 7,
              ),
            ),
            bottomNavigationBar: CustomBottomNavigation(
              currentIndex: AppNavItems.indexOf(AppTab.progress),
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      while (tester.takeException() != null) {}

      expect(
        overflow,
        isNull,
        reason: '$size ${overflow?.exceptionAsString()}',
      );
      FlutterError.onError = old;

      expect(find.text('Progress'), findsWidgets);
      expect(find.text('Track your syllabus progress.'), findsOneWidget);
      expect(find.byType(RevisionCenterCard), findsOneWidget);
      expect(find.text('Attempt Analytics'), findsOneWidget);
      expect(find.text('View Full Analytics'), findsOneWidget);

      // H2.8B: decorative bell and Available syllabus entry points removed.
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
      expect(find.text('Available'), findsNothing);
      expect(find.text('Group-II'), findsNothing);
      expect(find.text('Group-III'), findsNothing);
      expect(find.text('Launching Soon'), findsNothing);

      expect(find.byType(AnalyticsStatGrid), findsOneWidget);
      final labels = [
        'Tests',
        'Questions',
        'Avg Score',
        'Accuracy',
        'Avg Time',
        'Streak',
      ];
      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }

      // Dynamic values from ProgressSummary (not hardcoded UI strings).
      expect(find.text('3'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('12.5'), findsOneWidget);
      expect(find.text('80.0%'), findsOneWidget);
      expect(find.text('2m'), findsOneWidget);
      expect(find.text('4d'), findsOneWidget);

      // 2 columns × 3 rows geometry.
      final tests = tester.getCenter(find.text('Tests'));
      final questions = tester.getCenter(find.text('Questions'));
      final avgScore = tester.getCenter(find.text('Avg Score'));
      final accuracy = tester.getCenter(find.text('Accuracy'));
      final avgTime = tester.getCenter(find.text('Avg Time'));
      final streak = tester.getCenter(find.text('Streak'));

      expect(tests.dy, closeTo(questions.dy, 1), reason: '$size row 1');
      expect(avgScore.dy, closeTo(accuracy.dy, 1), reason: '$size row 2');
      expect(avgTime.dy, closeTo(streak.dy, 1), reason: '$size row 3');
      expect(questions.dx, greaterThan(tests.dx));
      expect(accuracy.dx, greaterThan(avgScore.dx));
      expect(streak.dx, greaterThan(avgTime.dx));
      expect(avgScore.dy, greaterThan(tests.dy + 20));
      expect(avgTime.dy, greaterThan(avgScore.dy + 20));

      final grid = tester.widget<AnalyticsStatGrid>(
        find.byType(AnalyticsStatGrid),
      );
      expect(grid.columns, 2);

      // Content must start below the hero's wave, never on the gradient.
      final heroBottom = tester.getBottomLeft(find.byType(ProgressHero)).dy;
      final cardTop = tester.getTopLeft(find.byType(RevisionCenterCard)).dy;
      expect(cardTop, greaterThan(heroBottom - 6));

      // Scrolling to the end must lift analytics clear of the floating
      // bottom navigation instead of leaving it behind the bar.
      await tester.fling(
        find.byType(AnalyticsStatGrid),
        const Offset(0, -600),
        1200,
      );
      await tester.pumpAndSettle();
      final analyticsBottom = tester
          .getBottomLeft(find.byType(AnalyticsStatGrid))
          .dy;
      expect(analyticsBottom, lessThan(size.height - AppNavMetrics.barHeight));

      // Bottom Progress destination remains in the shell navigation.
      expect(
        find.descendant(
          of: find.byType(CustomBottomNavigation),
          matching: find.text('Progress'),
        ),
        findsOneWidget,
      );
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
