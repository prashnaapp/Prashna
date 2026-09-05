import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/data/test_series_browser_groups.dart';
import 'package:telangana_prep/features/tests/presentation/screens/grand_test_papers_screen.dart';
import 'package:telangana_prep/features/tests/presentation/screens/grand_tests_screen.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_instructions_screen.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_series_browser_screen.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_selector_pill.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_header_band.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_paper_progress_banner.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_wave_footer.dart';
import 'package:telangana_prep/features/tests/presentation/widgets/test_series_row_card.dart';

TestModel published({
  required String id,
  required String examId,
  required TestCategoryType category,
  required String title,
  String? paperId,
  String? partId,
  int? year,
  String? seriesId,
}) {
  return TestModel(
    id: id,
    examId: examId,
    category: category,
    title: title,
    questionCount: 10,
    marks: 10,
    durationMinutes: 15,
    negativeMarking: '0',
    difficulty: 'Medium',
    status: TestPublicationStatus.published,
    paperId: paperId,
    partId: partId,
    year: year,
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

  group('TestSeriesBrowserGroups', () {
    test('paper-wise tabs come from syllabus papers, not hardcoded titles', () {
      final papers = SyllabusService.instance.getCourseById('group-ii')!.papers;
      final tests = [
        published(
          id: 'p2-part-1',
          examId: 'group-ii',
          category: TestCategoryType.partTests,
          title: 'Ancient India Part Test',
          paperId: 'group-ii-paper-ii',
          partId: 'group-ii-paper-ii-part-01',
        ),
        published(
          id: 'p2-part-2',
          examId: 'group-ii',
          category: TestCategoryType.partTests,
          title: 'Medieval India Part Test',
          paperId: 'group-ii-paper-ii',
          partId: 'group-ii-paper-ii-part-02',
        ),
      ];

      final tabs = TestSeriesBrowserGroups.paperWise(
        papers: papers,
        tests: tests,
      );

      expect(tabs.map((tab) => tab.id).toList(), [
        'group-ii-paper-i',
        'group-ii-paper-ii',
        'group-ii-paper-iii',
        'group-ii-paper-iv',
      ]);
      expect(tabs.map((tab) => tab.label).toList(), [
        'Paper I',
        'Paper II',
        'Paper III',
        'Paper IV',
      ]);
      expect(tabs[0].tests, isEmpty);
      expect(tabs[1].tests.map((test) => test.title), [
        'Ancient India Part Test',
        'Medieval India Part Test',
      ]);
    });

    test('Group-III paper-wise has three paper tabs from syllabus data', () {
      final papers = SyllabusService.instance.getCourseById('group-iii')!.papers;
      final tabs = TestSeriesBrowserGroups.paperWise(
        papers: papers,
        tests: const [],
      );
      expect(tabs, hasLength(3));
      expect(tabs.map((tab) => tab.id).toList(), [
        'group-iii-paper-i',
        'group-iii-paper-ii',
        'group-iii-paper-iii',
      ]);
      expect(tabs.map((tab) => tab.label).toList(), [
        'Paper I',
        'Paper II',
        'Paper III',
      ]);
    });

    test('grand tests group by seriesId without reading titles', () {
      final tabs = TestSeriesBrowserGroups.grandTests([
        published(
          id: 'g1-p1',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'Paper I Grand Test',
          paperId: 'group-ii-paper-i',
          seriesId: 'set-a',
        ),
        published(
          id: 'g1-p2',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'Paper II Grand Test',
          paperId: 'group-ii-paper-ii',
          seriesId: 'set-a',
        ),
        published(
          id: 'g2-p1',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'Paper I Grand Test B',
          paperId: 'group-ii-paper-i',
          seriesId: 'set-b',
        ),
      ]);

      expect(tabs.map((tab) => tab.label).toList(), ['set-a', 'set-b']);
      expect(tabs.first.tests, hasLength(2));
      expect(tabs.last.tests, hasLength(1));
    });

    test('papersForSeries keeps one test per syllabus paper in paper order', () {
      final papers = SyllabusService.instance.getCourseById('group-ii')!.papers;
      final tests = [
        published(
          id: 'later-p1',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'Second Paper I',
          paperId: 'group-ii-paper-i',
          seriesId: 'Grand Test - I',
        ),
        published(
          id: 'p4',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'Paper IV Grand',
          paperId: 'group-ii-paper-iv',
          seriesId: 'Grand Test - I',
        ),
        published(
          id: 'p1',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'First Paper I',
          paperId: 'group-ii-paper-i',
          seriesId: 'Grand Test - I',
        ),
      ];

      final ordered = TestSeriesBrowserGroups.papersForSeries(
        papers: papers,
        seriesTests: tests,
      );
      expect(ordered.map((test) => test.id).toList(), ['later-p1', 'p4']);
    });

    test('grand tests without seriesId do not invent tabs', () {
      final tabs = TestSeriesBrowserGroups.grandTests([
        published(
          id: 'a-p1',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'Paper I Grand Test',
          paperId: 'group-ii-paper-i',
        ),
      ]);
      expect(tabs, isEmpty);
    });

    test('previous papers tabs come from year metadata', () {
      final tabs = TestSeriesBrowserGroups.previousPapers([
        published(
          id: 'py-2016-i',
          examId: 'group-ii',
          category: TestCategoryType.previousYear,
          title: 'Paper I',
          paperId: 'group-ii-paper-i',
          year: 2016,
        ),
        published(
          id: 'py-2024-i',
          examId: 'group-ii',
          category: TestCategoryType.previousYear,
          title: 'Paper I',
          paperId: 'group-ii-paper-i',
          year: 2024,
        ),
      ]);

      expect(tabs.map((tab) => tab.label).toList(), ['2016', '2024']);
      expect(tabs.first.tests.single.id, 'py-2016-i');
    });

    test('previous papers without year do not fall back to paper tabs', () {
      final tabs = TestSeriesBrowserGroups.previousPapers([
        published(
          id: 'py-no-year',
          examId: 'group-ii',
          category: TestCategoryType.previousYear,
          title: 'Paper I',
          paperId: 'group-ii-paper-i',
        ),
      ]);
      expect(tabs, isEmpty);
    });
  });

  group('TestSeriesBrowserScreen', () {
    testWidgets('Group-II paper-wise shows paper pills and selected-paper cards', (
      tester,
    ) async {
      final service = catalog([
        published(
          id: 'p1',
          examId: 'group-ii',
          category: TestCategoryType.partTests,
          title: 'Paper I Practice',
          paperId: 'group-ii-paper-i',
        ),
        published(
          id: 'p2-a',
          examId: 'group-ii',
          category: TestCategoryType.partTests,
          title: 'Part I Test',
          paperId: 'group-ii-paper-ii',
          partId: 'part-1',
        ),
        published(
          id: 'p2-b',
          examId: 'group-ii',
          category: TestCategoryType.partTests,
          title: 'Part II Test',
          paperId: 'group-ii-paper-ii',
          partId: 'part-2',
        ),
      ]);

      await pumpIgnoringFonts(
        tester,
        MaterialApp(
          home: TestSeriesBrowserScreen(
            examId: 'group-ii',
            mode: TestSeriesBrowserMode.paperWise,
            testService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paper-wise Tests'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
      expect(find.byType(SyllabusHeaderBand), findsNothing);
      expect(find.byType(SyllabusSelectorPill), findsNWidgets(4));
      expect(find.text('Paper I'), findsOneWidget);
      expect(find.text('Paper II'), findsOneWidget);
      expect(find.text('Paper III'), findsOneWidget);
      expect(find.text('Paper IV'), findsOneWidget);
      expect(find.text('Paper I Practice'), findsOneWidget);
      expect(find.text('10 Questions • 10 Marks'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
      expect(find.text('0% complete'), findsNothing);
      expect(find.textContaining('Your Progress'), findsNothing);
      expect(find.byType(SyllabusPaperProgressBanner), findsNothing);
      expect(find.byType(SyllabusWaveFooter), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Part I Test'), findsNothing);

      await tester.tap(find.text('Paper II'));
      await tester.pumpAndSettle();

      expect(find.text('Paper I Practice'), findsNothing);
      expect(find.text('Part I Test'), findsOneWidget);
      expect(find.text('Part II Test'), findsOneWidget);
      expect(find.byType(TestSeriesRowCard), findsNWidgets(2));
    });

    testWidgets('Group-III paper-wise shows three paper pills', (tester) async {
      await pumpIgnoringFonts(
        tester,
        MaterialApp(
          home: TestSeriesBrowserScreen(
            examId: 'group-iii',
            mode: TestSeriesBrowserMode.paperWise,
            testService: catalog(const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paper-wise Tests'), findsOneWidget);
      expect(find.byType(SyllabusSelectorPill), findsNWidgets(3));
      expect(find.text('Paper I'), findsOneWidget);
      expect(find.text('Paper II'), findsOneWidget);
      expect(find.text('Paper III'), findsOneWidget);
    });

    testWidgets('grand tests list series cards then paper tests', (
      tester,
    ) async {
      final service = catalog([
        published(
          id: 's1-p1',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'Paper I Grand Test',
          paperId: 'group-ii-paper-i',
          seriesId: 'Grand Test - I',
        ),
        published(
          id: 's1-p2',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'Paper II Grand Test',
          paperId: 'group-ii-paper-ii',
          seriesId: 'Grand Test - I',
        ),
        published(
          id: 's2-p1',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'Paper I Grand Test Two',
          paperId: 'group-ii-paper-i',
          seriesId: 'Grand Test - II',
        ),
      ]);

      await pumpIgnoringFonts(
        tester,
        MaterialApp(
          home: GrandTestsScreen(examId: 'group-ii', testService: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grand Tests'), findsOneWidget);
      expect(find.text('Grand Test - I'), findsOneWidget);
      expect(find.text('Grand Test - II'), findsOneWidget);
      expect(find.text('Grand Test - III'), findsOneWidget);
      expect(find.text('Old Grand Tests'), findsOneWidget);
      expect(find.text('set-1'), findsNothing);
      expect(find.text('Paper I'), findsNothing);
      expect(find.text('Paper I Grand Test Two'), findsNothing);

      await tester.tap(find.text('Grand Test - II'));
      await tester.pumpAndSettle();
      expect(find.byType(GrandTestPapersScreen), findsOneWidget);
      expect(find.text('Paper I'), findsOneWidget);
      expect(find.text('Paper II'), findsNothing);
    });

    testWidgets('previous papers change cards when a year tab is selected', (
      tester,
    ) async {
      final service = catalog([
        published(
          id: 'y2016-i',
          examId: 'group-ii',
          category: TestCategoryType.previousYear,
          title: '2016 Paper I',
          paperId: 'group-ii-paper-i',
          year: 2016,
        ),
        published(
          id: 'y2024-i',
          examId: 'group-ii',
          category: TestCategoryType.previousYear,
          title: '2024 Paper I',
          paperId: 'group-ii-paper-i',
          year: 2024,
        ),
      ]);

      await pumpIgnoringFonts(
        tester,
        MaterialApp(
          home: TestSeriesBrowserScreen(
            examId: 'group-ii',
            mode: TestSeriesBrowserMode.previousPapers,
            testService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Previous Papers'), findsOneWidget);
      expect(find.text('2016'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('2016 Paper I'), findsOneWidget);
      expect(find.text('2024 Paper I'), findsNothing);

      await tester.tap(find.text('2024'));
      await tester.pumpAndSettle();
      expect(find.text('2024 Paper I'), findsOneWidget);
      expect(find.text('2016 Paper I'), findsNothing);
    });

    testWidgets('paper-wise layout has no overflow at 360/390/430', (
      tester,
    ) async {
      final service = catalog([
        published(
          id: 'p1',
          examId: 'group-ii',
          category: TestCategoryType.partTests,
          title: 'A reasonably long Paper I practice title',
          paperId: 'group-ii-paper-i',
        ),
      ]);

      for (final size in [
        const Size(360, 740),
        const Size(390, 844),
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
            home: TestSeriesBrowserScreen(
              examId: 'group-ii',
              mode: TestSeriesBrowserMode.paperWise,
              testService: service,
            ),
          ),
        );
        await tester.pumpAndSettle();
        while (tester.takeException() != null) {}

        expect(
          overflow,
          isNull,
          reason: '$size ${overflow?.exceptionAsString()}',
        );
        expect(find.text('Paper-wise Tests'), findsOneWidget);
        expect(find.text('Start'), findsOneWidget);
        FlutterError.onError = old;
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('tapping a test card opens the existing instructions screen', (
      tester,
    ) async {
      final service = catalog([
        published(
          id: 'start-1',
          examId: 'group-ii',
          category: TestCategoryType.partTests,
          title: 'Startable Paper Test',
          paperId: 'group-ii-paper-i',
        ),
      ]);

      await pumpIgnoringFonts(
        tester,
        MaterialApp(
          home: TestSeriesBrowserScreen(
            examId: 'group-ii',
            mode: TestSeriesBrowserMode.paperWise,
            testService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Startable Paper Test'));
      await tester.pumpAndSettle();
      expect(find.byType(TestInstructionsScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.byType(TestInstructionsScreen), findsOneWidget);
    });

    testWidgets('paper-wise back button pops', (tester) async {
      await pumpIgnoringFonts(
        tester,
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => TestSeriesBrowserScreen(
                        examId: 'group-ii',
                        mode: TestSeriesBrowserMode.paperWise,
                        testService: catalog(const []),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Paper-wise Tests'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Paper-wise Tests'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
