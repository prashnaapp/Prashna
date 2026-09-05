import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_header_band.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_wave_footer.dart';
import 'package:telangana_prep/features/tests/data/grand_test_series.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/presentation/paper_wise_navigation.dart';
import 'package:telangana_prep/features/tests/presentation/screens/exam_test_home_screen.dart';
import 'package:telangana_prep/features/tests/presentation/screens/grand_test_papers_screen.dart';
import 'package:telangana_prep/features/tests/presentation/screens/grand_tests_screen.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_instructions_screen.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_list_screen.dart';
import 'package:telangana_prep/features/tests/presentation/widgets/test_series_row_card.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';

TestModel published({
  required String id,
  required String examId,
  required String title,
  required String paperId,
  required String seriesId,
  int questionCount = 30,
  int marks = 30,
}) {
  return TestModel(
    id: id,
    examId: examId,
    category: TestCategoryType.mockTests,
    title: title,
    questionCount: questionCount,
    marks: marks,
    durationMinutes: 30,
    negativeMarking: '0',
    difficulty: 'Medium',
    status: TestPublicationStatus.published,
    paperId: paperId,
    seriesId: seriesId,
  );
}

TestService catalog(List<TestModel> tests) {
  return TestService(
    cloudRepository: TestCloudRepository.withLoader((courseId) async {
      return [
        for (final test in tests)
          if (test.examId == courseId) test,
      ];
    }),
  );
}

List<TestModel> groupIiSeries() {
  return [
    for (final series in GrandTestSeries.ids.take(3))
      for (final paper in [
        ('group-ii-paper-i', 'Paper I catalog'),
        ('group-ii-paper-ii', 'Paper II catalog'),
        ('group-ii-paper-iii', 'Paper III catalog'),
        ('group-ii-paper-iv', 'Paper IV catalog'),
      ])
        published(
          id: '$series-${paper.$1}',
          examId: 'group-ii',
          title: paper.$2,
          paperId: paper.$1,
          seriesId: series,
        ),
  ];
}

List<TestModel> groupIiiSeries() {
  return [
    for (final series in GrandTestSeries.ids.take(3))
      for (final paper in [
        ('group-iii-paper-i', 'G3 Paper I catalog'),
        ('group-iii-paper-ii', 'G3 Paper II catalog'),
        ('group-iii-paper-iii', 'G3 Paper III catalog'),
      ])
        published(
          id: '$series-${paper.$1}',
          examId: 'group-iii',
          title: paper.$2,
          paperId: paper.$1,
          seriesId: series,
        ),
  ];
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

  test('approved Grand Test seriesIds are the four product containers', () {
    expect(GrandTestSeries.ids, [
      'Grand Test - I',
      'Grand Test - II',
      'Grand Test - III',
      'Old Grand Tests',
    ]);
    expect(GrandTestSeries.isApproved('Grand Test 1'), isFalse);
    expect(GrandTestSeries.isApproved('Grand Test-I'), isFalse);
    expect(
      GrandTestSeries.selectorValues(existing: 'Grand Test 1'),
      contains('Grand Test 1'),
    );
    expect(GrandTestSeries.selectorValues(), GrandTestSeries.ids);
  });

  testWidgets('empty catalog still shows exactly four Grand Test containers', (
    tester,
  ) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: GrandTestsScreen(
          examId: 'group-ii',
          testService: catalog(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Grand Tests'), findsOneWidget);
    expect(find.text(GrandTestSeries.grandTestI), findsOneWidget);
    expect(find.text(GrandTestSeries.grandTestII), findsOneWidget);
    expect(find.text(GrandTestSeries.grandTestIII), findsOneWidget);
    expect(find.text(GrandTestSeries.oldGrandTests), findsOneWidget);
    expect(find.text('Grand Test - IV'), findsNothing);
    expect(find.text('Grand Test 1'), findsNothing);
    expect(find.text('No tests available'), findsNothing);
    expect(find.byType(TestSeriesRowCard), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    expect(find.byType(SyllabusHeaderBand), findsNothing);
    expect(find.byType(SyllabusWaveFooter), findsNothing);
  });

  testWidgets('each of the four containers opens the matching series', (
    tester,
  ) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: GrandTestsScreen(
          examId: 'group-ii',
          testService: catalog(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final seriesId in GrandTestSeries.ids) {
      await tester.tap(find.text(seriesId));
      await tester.pumpAndSettle();
      expect(find.byType(GrandTestPapersScreen), findsOneWidget);
      expect(find.text(seriesId), findsWidgets);
      expect(
        find.text('There are no published papers in this Grand Test yet.'),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(GrandTestsScreen), findsOneWidget);
    }
  });

  testWidgets('Grand Test I with Paper-I only shows Paper I', (tester) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: GrandTestsScreen(
          examId: 'group-ii',
          testService: catalog([
            published(
              id: 'gt1-p1',
              examId: 'group-ii',
              title: 'Paper I catalog',
              paperId: 'group-ii-paper-i',
              seriesId: GrandTestSeries.grandTestI,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(GrandTestSeries.grandTestI));
    await tester.pumpAndSettle();

    expect(find.text('Paper I'), findsOneWidget);
    expect(find.text('Paper II'), findsNothing);
    expect(find.byType(TestSeriesRowCard), findsOneWidget);
    expect(find.byType(TestListScreen), findsNothing);
  });

  testWidgets('Grand Test I with Paper-I and Paper-II shows both', (
    tester,
  ) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: GrandTestsScreen(
          examId: 'group-ii',
          testService: catalog([
            published(
              id: 'gt1-p1',
              examId: 'group-ii',
              title: 'Paper I catalog',
              paperId: 'group-ii-paper-i',
              seriesId: GrandTestSeries.grandTestI,
            ),
            published(
              id: 'gt1-p2',
              examId: 'group-ii',
              title: 'Paper II catalog',
              paperId: 'group-ii-paper-ii',
              seriesId: GrandTestSeries.grandTestI,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(GrandTestSeries.grandTestI));
    await tester.pumpAndSettle();

    expect(find.text('Paper I'), findsOneWidget);
    expect(find.text('Paper II'), findsOneWidget);
    expect(find.text('Paper III'), findsNothing);
    expect(find.byType(TestSeriesRowCard), findsNWidgets(2));
  });

  testWidgets('Group-II Grand Test I opens four paper tests', (tester) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: GrandTestsScreen(
          examId: 'group-ii',
          testService: catalog(groupIiSeries()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(GrandTestSeries.grandTestI));
    await tester.pumpAndSettle();

    expect(find.byType(GrandTestPapersScreen), findsOneWidget);
    expect(find.text(GrandTestSeries.grandTestI), findsOneWidget);
    expect(find.text('Paper I'), findsOneWidget);
    expect(find.text('Paper II'), findsOneWidget);
    expect(find.text('Paper III'), findsOneWidget);
    expect(find.text('Paper IV'), findsOneWidget);
    expect(find.byType(TestSeriesRowCard), findsNWidgets(4));
    expect(find.text('Start'), findsNWidgets(4));
    expect(find.text('0%'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(TestListScreen), findsNothing);

    for (final paper in ['Paper I', 'Paper II', 'Paper III', 'Paper IV']) {
      await tester.tap(find.text(paper));
      await tester.pumpAndSettle();
      expect(find.byType(TestInstructionsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(GrandTestsScreen), findsOneWidget);
    expect(find.byType(GrandTestPapersScreen), findsNothing);
  });

  testWidgets('Group-III Grand Test I opens three papers and not Paper IV', (
    tester,
  ) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: GrandTestsScreen(
          examId: 'group-iii',
          testService: catalog(groupIiiSeries()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(GrandTestSeries.grandTestI));
    await tester.pumpAndSettle();

    expect(find.text('Paper-I'), findsOneWidget);
    expect(find.text('Paper-II'), findsOneWidget);
    expect(find.text('Paper-III'), findsOneWidget);
    expect(find.text('Paper-IV'), findsNothing);
    expect(find.text('Paper IV'), findsNothing);
    expect(find.byType(TestSeriesRowCard), findsNWidgets(3));

    await tester.tap(find.text('Paper-I'));
    await tester.pumpAndSettle();
    expect(find.byType(TestInstructionsScreen), findsOneWidget);
  });

  testWidgets('Old Grand Tests shows matching published papers', (tester) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: GrandTestsScreen(
          examId: 'group-ii',
          testService: catalog([
            published(
              id: 'old-p1',
              examId: 'group-ii',
              title: 'Old Paper I catalog',
              paperId: 'group-ii-paper-i',
              seriesId: GrandTestSeries.oldGrandTests,
            ),
            published(
              id: 'old-p3',
              examId: 'group-ii',
              title: 'Old Paper III catalog',
              paperId: 'group-ii-paper-iii',
              seriesId: GrandTestSeries.oldGrandTests,
            ),
            published(
              id: 'current-p2',
              examId: 'group-ii',
              title: 'Current Paper II catalog',
              paperId: 'group-ii-paper-ii',
              seriesId: GrandTestSeries.grandTestI,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(GrandTestSeries.oldGrandTests));
    await tester.pumpAndSettle();

    expect(find.text('Paper I'), findsOneWidget);
    expect(find.text('Paper III'), findsOneWidget);
    expect(find.text('Paper II'), findsNothing);
    expect(find.byType(TestSeriesRowCard), findsNWidgets(2));
    expect(find.byType(TestListScreen), findsNothing);

    await tester.tap(find.text('Paper I'));
    await tester.pumpAndSettle();
    expect(find.byType(TestInstructionsScreen), findsOneWidget);
  });

  testWidgets('category Grand Tests returns on back', (tester) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: ExamTestHomeScreen(
          examId: 'group-ii',
          examTitle: 'Group-II',
          testService: catalog(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grand Tests'));
    await tester.pumpAndSettle();
    expect(find.byType(GrandTestsScreen), findsOneWidget);
    expect(find.text(GrandTestSeries.oldGrandTests), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ExamTestHomeScreen), findsOneWidget);
    expect(find.text('Group-II'), findsOneWidget);
  });

  testWidgets('openTestCategory routes mock tests to GrandTestsScreen', (
    tester,
  ) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => openTestCategory(
                context: context,
                examId: 'group-ii',
                category: const TestCategoryModel(
                  type: TestCategoryType.mockTests,
                  title: 'Grand Tests',
                  subtitle: 'View available tests',
                ),
                testService: catalog(const []),
              ),
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(GrandTestsScreen), findsOneWidget);
    expect(find.byType(TestListScreen), findsNothing);
    expect(find.text('No tests available'), findsNothing);
  });

  testWidgets('Grand Tests has no overflow at common widths', (tester) async {
    final service = catalog(groupIiSeries());
    for (final size in [
      const Size(360, 740),
      const Size(390, 844),
      const Size(412, 915),
      const Size(430, 932),
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
          home: GrandTestsScreen(examId: 'group-ii', testService: service),
        ),
      );
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
      expect(overflow, isNull, reason: 'list $size ${overflow?.exceptionAsString()}');

      await tester.tap(find.text(GrandTestSeries.grandTestI));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
      expect(
        overflow,
        isNull,
        reason: 'papers $size ${overflow?.exceptionAsString()}',
      );

      FlutterError.onError = old;
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
