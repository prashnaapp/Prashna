import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telangana_prep/core/theme/app_theme.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_course_card.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/presentation/screens/tests_home_screen.dart';
import 'package:telangana_prep/features/tests/presentation/widgets/tests_hero.dart';
import 'package:telangana_prep/features/tests/presentation/widgets/tests_tip_banner.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';
import 'package:telangana_prep/navigation/custom_bottom_navigation.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    final view = tester.view;
    view.physicalSize = size;
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    FlutterErrorDetails? overflow;
    final old = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflow ??= details;
      }
      if (details.exceptionAsString().contains('GoogleFonts')) return;
      old?.call(details);
    };
    addTearDown(() => FlutterError.onError = old);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const TestsHomeScreen(),
      ),
    );
    await tester.pump();
    while (tester.takeException() != null) {}
    expect(overflow, isNull, reason: overflow?.exceptionAsString());
  }

  testWidgets(
    'Test Series landing keeps title, Available groups, and dynamic stats',
    (tester) async {
      for (final size in [
        const Size(360, 740),
        const Size(390, 844),
        const Size(430, 932),
      ]) {
        await pumpAt(tester, size);

        expect(find.text('Test Series'), findsOneWidget);
        expect(find.byType(TestsHero), findsOneWidget);
        expect(
          find.text('Practice with full-length and topic tests.'),
          findsNothing,
        );
        expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
        expect(find.text('Practice Smart. Score Higher.'), findsNothing);
        expect(
          find.text('Choose a test series to begin your preparation.'),
          findsNothing,
        );
        expect(find.byType(TestsTipBanner), findsNothing);

        expect(find.text('Available'), findsOneWidget);
        expect(find.text('Group-II'), findsOneWidget);
        expect(find.text('Group-III'), findsOneWidget);
        expect(find.text('600 Marks'), findsOneWidget);
        expect(find.text('4 Papers'), findsOneWidget);
        expect(find.text('450 Marks'), findsOneWidget);
        expect(find.text('3 Papers'), findsOneWidget);
        expect(find.textContaining('Marks •'), findsNothing);

        final cards = find.byType(SyllabusCourseCard);
        expect(cards, findsNWidgets(2));
        final firstTop = tester.getTopLeft(cards.first).dy;
        final secondTop = tester.getTopLeft(cards.last).dy;
        expect(secondTop, firstTop);

        final firstSize = tester.getSize(cards.first);
        expect(firstSize.width, lessThan(size.width * 0.48));
        expect(firstSize.width, greaterThan(size.width * 0.36));

        final materials = tester
            .widgetList<Material>(
              find.descendant(of: cards, matching: find.byType(Material)),
            )
            .toList();
        expect(materials, isNotEmpty);
        expect(
          materials.every(
            (material) =>
                material.clipBehavior == Clip.antiAlias &&
                material.shape is RoundedRectangleBorder,
          ),
          isTrue,
        );
      }
    },
  );

  testWidgets('bottom navigation remains beside Test Series landing', (
    tester,
  ) async {
    await pumpAt(tester, const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Stack(
          fit: StackFit.expand,
          children: [
            const TestsHomeScreen(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavigation(
                currentIndex: 2,
                onDestinationSelected: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    while (tester.takeException() != null) {}

    expect(find.byType(CustomBottomNavigation), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Chapters'), findsOneWidget);
    expect(find.text('Test Series'), findsWidgets);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  test('available Test Series catalog is unchanged', () {
    final available = TestService.instance
        .getExamSummaries()
        .where((exam) => exam.isEnabled)
        .toList();
    expect(available.map((e) => e.examId), ['group-ii', 'group-iii']);
    expect(available[0].title, 'Group-II');
    expect(available[0].maxMarks, 600);
    expect(available[0].paperCount, 4);
    expect(available[1].title, 'Group-III');
    expect(available[1].maxMarks, 450);
    expect(available[1].paperCount, 3);
    expect(available, isA<List<TestExamSummary>>());
  });

  test('Group-II / Group-III open destinations are unchanged', () {
    final source = File(
      'lib/features/tests/presentation/screens/tests_home_screen.dart',
    ).readAsStringSync();
    expect(source, contains('CourseOpenGuard.attemptOpen'));
    expect(source, contains('courseId: exam.examId'));
    expect(source, contains("const GroupIITestHomeScreen()"));
    expect(source, contains("const GroupIIITestHomeScreen()"));
    expect(source, contains('Navigator.push'));
    expect(source, contains("exam.examId"));
  });

  test('shell still hosts Test Series tab and bottom navigation', () {
    final source = File(
      'lib/navigation/main_navigation_screen.dart',
    ).readAsStringSync();
    expect(source, contains('const TestsScreen()'));
    expect(source, contains('CustomBottomNavigation('));
  });
}
