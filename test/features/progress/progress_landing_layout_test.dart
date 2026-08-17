import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telangana_prep/features/progress/presentation/screens/tracker_home_screen.dart';
import 'package:telangana_prep/features/progress/presentation/widgets/analytics_stat_grid.dart';
import 'package:telangana_prep/features/progress/presentation/widgets/exam_tracker_card.dart';
import 'package:telangana_prep/features/progress/presentation/widgets/progress_hero.dart';
import 'package:telangana_prep/features/progress/presentation/widgets/revision_center_card.dart';
import 'package:telangana_prep/navigation/app_nav_metrics.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Progress landing renders without overflow on phone sizes', (
    tester,
  ) async {
    for (final size in [
      const Size(360, 740),
      const Size(390, 844),
      const Size(412, 915),
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

      await tester.pumpWidget(const MaterialApp(home: TrackerHomeScreen()));
      await tester.pump();
      while (tester.takeException() != null) {}

      expect(
        overflow,
        isNull,
        reason: '$size ${overflow?.exceptionAsString()}',
      );
      FlutterError.onError = old;

      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Track your syllabus progress.'), findsOneWidget);
      expect(find.byType(RevisionCenterCard), findsOneWidget);
      expect(find.text('Attempt Analytics'), findsOneWidget);
      expect(find.text('View Full Analytics'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Group-II'), findsOneWidget);
      expect(find.text('Group-III'), findsOneWidget);
      expect(find.text('Launching Soon'), findsNothing);

      // Six equal statistic tiles.
      expect(find.byType(AnalyticsStatGrid), findsOneWidget);
      for (final label in [
        'Tests',
        'Questions',
        'Avg Score',
        'Accuracy',
        'Avg Time',
        'Streak',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      final cards = find.byType(ExamTrackerCard).evaluate().toList();
      expect(cards.length, 2);
      final first = tester.getSize(find.byWidget(cards.first.widget));
      final second = tester.getSize(find.byWidget(cards[1].widget));
      expect(first.height, closeTo(second.height, 0.5));
      expect(first.width, closeTo(second.width, 0.5));
      expect(first.height, lessThan(96));

      // Content must start below the hero's wave, never on the gradient.
      final heroBottom = tester.getBottomLeft(find.byType(ProgressHero)).dy;
      final cardTop = tester.getTopLeft(find.byType(RevisionCenterCard)).dy;
      expect(cardTop, greaterThan(heroBottom - 6));

      // Scrolling to the end must lift the last card clear of the floating
      // bottom navigation instead of leaving it behind the bar.
      await tester.fling(
        find.byType(ExamTrackerCard).first,
        const Offset(0, -600),
        1200,
      );
      await tester.pumpAndSettle();
      final lastBottom = tester
          .getBottomLeft(find.byType(ExamTrackerCard).last)
          .dy;
      expect(lastBottom, lessThan(size.height - AppNavMetrics.barHeight));
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
