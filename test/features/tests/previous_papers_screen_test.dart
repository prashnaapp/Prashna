import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_header_band.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_paper_progress_banner.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_wave_footer.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/data/previous_paper_years.dart';
import 'package:telangana_prep/features/tests/data/test_series_browser_groups.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_instructions_screen.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_series_browser_screen.dart';
import 'package:telangana_prep/features/tests/presentation/widgets/test_series_row_card.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';

TestModel published({
  required String id,
  required String examId,
  required String title,
  required int year,
  String? paperId,
  int questionCount = 10,
  int marks = 10,
}) {
  return TestModel(
    id: id,
    examId: examId,
    category: TestCategoryType.previousYear,
    title: title,
    questionCount: questionCount,
    marks: marks,
    durationMinutes: 15,
    negativeMarking: '0',
    difficulty: 'Medium',
    status: TestPublicationStatus.published,
    paperId: paperId,
    year: year,
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

  test('PreviousPaperYears are fixed product values per exam', () {
    expect(PreviousPaperYears.forExam('group-ii'), [2016, 2024]);
    expect(PreviousPaperYears.forExam('group-iii'), [2018, 2024]);
    expect(PreviousPaperYears.initialYear('group-ii'), 2016);
    expect(PreviousPaperYears.initialYear('group-iii'), 2018);
    expect(PreviousPaperYears.forExam('group-ii'), isNot(contains(2018)));
    expect(PreviousPaperYears.forExam('group-iii'), isNot(contains(2016)));
  });

  test('forYear keeps only matching years and skips null year', () {
    final tests = [
      published(
        id: 'a',
        examId: 'group-ii',
        title: '2016 A',
        year: 2016,
        paperId: 'group-ii-paper-i',
      ),
      published(
        id: 'b',
        examId: 'group-ii',
        title: '2024 B',
        year: 2024,
        paperId: 'group-ii-paper-i',
      ),
      const TestModel(
        id: 'c',
        examId: 'group-ii',
        category: TestCategoryType.previousYear,
        title: 'No year',
        questionCount: 1,
        marks: 1,
        durationMinutes: 1,
        negativeMarking: '0',
        difficulty: 'Medium',
        status: TestPublicationStatus.published,
        paperId: 'group-ii-paper-i',
      ),
    ];
    expect(
      TestSeriesBrowserGroups.forYear(tests: tests, year: 2016).map((t) => t.id),
      ['a'],
    );
    expect(
      TestSeriesBrowserGroups.forYear(tests: tests, year: 2024).map((t) => t.id),
      ['b'],
    );
  });

  testWidgets('Group-II always shows fixed 2016 and 2024 with empty catalog', (
    tester,
  ) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: TestSeriesBrowserScreen(
          examId: 'group-ii',
          mode: TestSeriesBrowserMode.previousPapers,
          testService: catalog(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Previous Papers'), findsOneWidget);
    expect(find.text('2016'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
    expect(find.text('2018'), findsNothing);
    expect(
      find.text('There are no published previous papers for 2016 yet.'),
      findsOneWidget,
    );
    expect(find.byType(SyllabusHeaderBand), findsNothing);
    expect(find.byType(SyllabusWaveFooter), findsNothing);
    expect(find.byType(SyllabusPaperProgressBanner), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
  });

  testWidgets('Group-III always shows fixed 2018 and 2024 with empty catalog', (
    tester,
  ) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: TestSeriesBrowserScreen(
          examId: 'group-iii',
          mode: TestSeriesBrowserMode.previousPapers,
          testService: catalog(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2018'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
    expect(find.text('2016'), findsNothing);
    expect(
      find.text('There are no published previous papers for 2018 yet.'),
      findsOneWidget,
    );
  });

  testWidgets('Group-II filters by year and Start opens Instructions', (
    tester,
  ) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: TestSeriesBrowserScreen(
          examId: 'group-ii',
          mode: TestSeriesBrowserMode.previousPapers,
          testService: catalog([
            published(
              id: 'y2016',
              examId: 'group-ii',
              title: '2016 Real Title',
              year: 2016,
              paperId: 'group-ii-paper-i',
              questionCount: 150,
              marks: 150,
            ),
            published(
              id: 'y2024',
              examId: 'group-ii',
              title: '2024 Real Title',
              year: 2024,
              paperId: 'group-ii-paper-ii',
              questionCount: 120,
              marks: 120,
            ),
            const TestModel(
              id: 'noyear',
              examId: 'group-ii',
              category: TestCategoryType.previousYear,
              title: 'Missing Year Title',
              questionCount: 1,
              marks: 1,
              durationMinutes: 1,
              negativeMarking: '0',
              difficulty: 'Medium',
              status: TestPublicationStatus.published,
              paperId: 'group-ii-paper-i',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2016 Real Title'), findsOneWidget);
    expect(find.text('150 Questions • 150 Marks'), findsOneWidget);
    expect(find.text('2024 Real Title'), findsNothing);
    expect(find.text('Missing Year Title'), findsNothing);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.byType(TestInstructionsScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('2024'));
    await tester.pumpAndSettle();
    expect(find.text('2024 Real Title'), findsOneWidget);
    expect(find.text('120 Questions • 120 Marks'), findsOneWidget);
    expect(find.text('2016 Real Title'), findsNothing);
    expect(find.text('Missing Year Title'), findsNothing);
    expect(find.byType(TestSeriesRowCard), findsOneWidget);
  });

  testWidgets('Group-III filters 2018 and 2024 independently', (tester) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: TestSeriesBrowserScreen(
          examId: 'group-iii',
          mode: TestSeriesBrowserMode.previousPapers,
          testService: catalog([
            published(
              id: 'g3-2018',
              examId: 'group-iii',
              title: 'G3 2018 Paper',
              year: 2018,
              paperId: 'group-iii-paper-i',
            ),
            published(
              id: 'g3-2024',
              examId: 'group-iii',
              title: 'G3 2024 Paper',
              year: 2024,
              paperId: 'group-iii-paper-ii',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('G3 2018 Paper'), findsOneWidget);
    expect(find.text('G3 2024 Paper'), findsNothing);

    await tester.tap(find.text('2024'));
    await tester.pumpAndSettle();
    expect(find.text('G3 2024 Paper'), findsOneWidget);
    expect(find.text('G3 2018 Paper'), findsNothing);
  });

  testWidgets('empty selected year keeps year pills visible', (tester) async {
    await pumpIgnoringFonts(
      tester,
      MaterialApp(
        home: TestSeriesBrowserScreen(
          examId: 'group-ii',
          mode: TestSeriesBrowserMode.previousPapers,
          testService: catalog([
            published(
              id: 'only-2024',
              examId: 'group-ii',
              title: 'Only 2024',
              year: 2024,
              paperId: 'group-ii-paper-i',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2016'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
    expect(
      find.text('There are no published previous papers for 2016 yet.'),
      findsOneWidget,
    );
    expect(find.text('Only 2024'), findsNothing);

    await tester.tap(find.text('2024'));
    await tester.pumpAndSettle();
    expect(find.text('Only 2024'), findsOneWidget);
    expect(find.text('2016'), findsOneWidget);
  });

  testWidgets('Previous Papers has no overflow at common widths', (
    tester,
  ) async {
    final service = catalog([
      published(
        id: 'wide',
        examId: 'group-ii',
        title: 'A reasonably long previous paper title for layout',
        year: 2016,
        paperId: 'group-ii-paper-i',
        questionCount: 150,
        marks: 150,
      ),
    ]);

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
          home: TestSeriesBrowserScreen(
            examId: 'group-ii',
            mode: TestSeriesBrowserMode.previousPapers,
            testService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}

      expect(overflow, isNull, reason: '$size ${overflow?.exceptionAsString()}');
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('2016'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      FlutterError.onError = old;
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
