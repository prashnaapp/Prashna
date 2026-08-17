import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telangana_prep/features/tests/presentation/screens/exam_test_home_screen.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_list_screen.dart';
import 'package:telangana_prep/features/tests/presentation/widgets/exam_category_hero.dart';
import 'package:telangana_prep/features/tests/presentation/widgets/exam_category_tile.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';

TestService _catalog() {
  return TestService(
    cloudRepository: TestCloudRepository.withLoader((_) async => const []),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpIgnoringFonts(WidgetTester tester, Widget widget) async {
    final old = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('GoogleFonts')) return;
      old?.call(details);
    };
    addTearDown(() => FlutterError.onError = old);
    await tester.pumpWidget(widget);
    await tester.pump();
    while (tester.takeException() != null) {}
  }

  testWidgets('ExamCategoryHero shows title, subtitle, back, and bell', (
    tester,
  ) async {
    var popped = false;
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: Scaffold(
          body: ExamCategoryHero(
            title: 'Group-II',
            height: 220,
            onBack: () => popped = true,
          ),
        ),
      ),
    );

    expect(find.text('Group-II'), findsOneWidget);
    expect(find.text('Choose a category to begin.'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    expect(popped, isTrue);
  });

  testWidgets('ExamCategoryTile is tappable with chevron', (tester) async {
    var taps = 0;
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: Scaffold(
          body: ExamCategoryTile(
            title: 'Paper-wise Tests',
            subtitle: 'View available tests',
            icon: Icons.description_rounded,
            accent: const Color(0xFF4C8DFF),
            height: 108,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('Paper-wise Tests'), findsOneWidget);
    expect(find.text('View available tests'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    await tester.tap(find.byType(ExamCategoryTile));
    expect(taps, 1);
  });

  testWidgets('Group-II category screen shows three cards and no overflow', (
    tester,
  ) async {
    for (final size in [
      const Size(360, 740),
      const Size(390, 844),
      const Size(412, 915),
    ]) {
      final view = tester.view;
      view.physicalSize = size;
      view.devicePixelRatio = 1.0;

      FlutterErrorDetails? overflow;
      final old = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          overflow ??= details;
        }
        if (details.exceptionAsString().contains('GoogleFonts')) return;
        old?.call(details);
      };

      await tester.pumpWidget(
        MaterialApp(
          home: ExamTestHomeScreen(
            examId: 'group-ii',
            examTitle: 'Group-II',
            testService: _catalog(),
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
      expect(find.text('Group-II'), findsOneWidget);
      expect(find.text('Choose a category to begin.'), findsOneWidget);
      expect(find.text('Paper-wise Tests'), findsOneWidget);
      expect(find.text('Grand Tests'), findsOneWidget);
      expect(find.text('Previous Papers'), findsOneWidget);
      expect(find.text('Chapter Tests'), findsNothing);
      expect(find.text('Mock Tests'), findsNothing);
      expect(find.byType(ExamCategoryTile), findsNWidgets(3));

      final tiles = find.byType(ExamCategoryTile).evaluate().toList();
      final first = tester.getSize(find.byType(ExamCategoryTile).first);
      final second = tester.getSize(find.byWidget(tiles[1].widget));
      final third = tester.getSize(find.byWidget(tiles[2].widget));
      expect(first.height, closeTo(second.height, 0.5));
      expect(second.height, closeTo(third.height, 0.5));
      expect(first.width, closeTo(second.width, 0.5));
      expect(first.height, lessThan(90));
      expect(first.height, greaterThan(70));
      expect(first.width, greaterThan(size.width * 0.80));
      FlutterError.onError = old;
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('Group-III category screen uses Group-III title', (tester) async {
    final old = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('GoogleFonts')) return;
      old?.call(details);
    };
    addTearDown(() => FlutterError.onError = old);

    await tester.pumpWidget(
      MaterialApp(
        home: ExamTestHomeScreen(
          examId: 'group-iii',
          examTitle: 'Group-III',
          testService: _catalog(),
        ),
      ),
    );
    await tester.pump();
    while (tester.takeException() != null) {}

    expect(find.text('Group-III'), findsOneWidget);
    expect(find.text('Paper-wise Tests'), findsOneWidget);
    expect(find.text('Grand Tests'), findsOneWidget);
    expect(find.text('Previous Papers'), findsOneWidget);
  });

  testWidgets('Paper-wise Tests opens the existing category destination', (
    tester,
  ) async {
    final old = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('GoogleFonts')) return;
      old?.call(details);
    };
    addTearDown(() => FlutterError.onError = old);

    await tester.pumpWidget(
      MaterialApp(
        home: ExamTestHomeScreen(
          examId: 'group-ii',
          examTitle: 'Group-II',
          testService: _catalog(),
        ),
      ),
    );
    await tester.pump();
    while (tester.takeException() != null) {}

    await tester.tap(find.text('Paper-wise Tests'));
    await tester.pumpAndSettle();
    expect(find.byType(TestListScreen), findsOneWidget);
  });
}
