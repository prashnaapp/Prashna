import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_browser_screen.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_unit_tests_screen.dart';
import 'package:telangana_prep/features/syllabus/presentation/syllabus_browser_sequence.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_browser_pill.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_unit_row_card.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';

void main() {
  Future<void> pumpBrowser(
    WidgetTester tester, {
    required String courseId,
    String? paperId,
    String? partId,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: SyllabusBrowserScreen(
          key: UniqueKey(),
          courseId: courseId,
          initialPaperId: paperId,
          initialPartId: partId,
        ),
      ),
    );
    await tester.pump();
  }

  bool pillSelected(WidgetTester tester, String key) {
    return tester
        .widget<SyllabusBrowserPill>(find.byKey(ValueKey(key)))
        .selected;
  }

  Future<void> dragContent(WidgetTester tester, Offset offset) async {
    final card = find.byType(SyllabusUnitRowCard).first;
    await tester.drag(card, offset);
    await tester.pumpAndSettle();
  }

  test('sequence is derived from existing Group-II and Group-III data', () {
    final groupIi = SyllabusService.instance.getCourseById('group-ii')!;
    final iiStops = SyllabusBrowserSequence.fromPapers(groupIi.papers);

    expect(iiStops.first.paperId, groupIi.papers.first.id);
    expect(iiStops.first.partId, isNull);

    final paperIi = groupIi.papers[1];
    expect(paperIi.hasPartSyllabusUnits, isTrue);
    expect(iiStops[1].paperId, paperIi.id);
    expect(iiStops[1].partId, paperIi.parts.first.id);
    expect(iiStops[2].partId, paperIi.parts[1].id);
    expect(iiStops[3].partId, paperIi.parts[2].id);
    expect(iiStops[4].paperId, groupIi.papers[2].id);
    expect(iiStops[4].partId, groupIi.papers[2].parts.first.id);

    var expected = 0;
    for (final paper in groupIi.papers) {
      expected += paper.hasPartSyllabusUnits ? paper.parts.length : 1;
    }
    expect(iiStops.length, expected);

    final groupIii = SyllabusService.instance.getCourseById('group-iii')!;
    final iiiStops = SyllabusBrowserSequence.fromPapers(groupIii.papers);
    expect(iiiStops.first.paperId, groupIii.papers.first.id);
    expect(iiiStops.first.partId, isNull);
    expect(iiiStops[1].paperId, groupIii.papers[1].id);
    expect(iiiStops[1].partId, groupIii.papers[1].parts.first.id);
  });

  testWidgets('Group-II swipe left walks Paper I → Paper II parts → Paper III', (
    tester,
  ) async {
    await pumpBrowser(tester, courseId: 'group-ii');

    expect(
      pillSelected(tester, 'syllabus-paper-group-ii-paper-i'),
      isTrue,
    );
    expect(find.text('Current Affairs'), findsOneWidget);
    expect(find.text('Select Part'), findsNothing);

    await dragContent(tester, const Offset(-80, 0));
    expect(
      pillSelected(tester, 'syllabus-paper-group-ii-paper-ii'),
      isTrue,
    );
    expect(find.text('Select Part'), findsOneWidget);
    expect(
      pillSelected(tester, 'syllabus-part-group-ii-paper-ii-part-01'),
      isTrue,
    );
    expect(find.text('Ancient and Medieval Telangana'), findsOneWidget);

    await dragContent(tester, const Offset(-80, 0));
    expect(
      pillSelected(tester, 'syllabus-part-group-ii-paper-ii-part-02'),
      isTrue,
    );
    expect(
      pillSelected(tester, 'syllabus-paper-group-ii-paper-ii'),
      isTrue,
    );

    await dragContent(tester, const Offset(-80, 0));
    expect(
      pillSelected(tester, 'syllabus-part-group-ii-paper-ii-part-03'),
      isTrue,
    );

    await dragContent(tester, const Offset(-80, 0));
    expect(
      pillSelected(tester, 'syllabus-paper-group-ii-paper-iii'),
      isTrue,
    );
    expect(
      pillSelected(tester, 'syllabus-part-group-ii-paper-iii-part-01'),
      isTrue,
    );
    expect(find.text('Demography'), findsOneWidget);

    await dragContent(tester, const Offset(80, 0));
    expect(
      pillSelected(tester, 'syllabus-paper-group-ii-paper-ii'),
      isTrue,
    );
    expect(
      pillSelected(tester, 'syllabus-part-group-ii-paper-ii-part-03'),
      isTrue,
    );
  });

  testWidgets('boundaries do not wrap', (tester) async {
    await pumpBrowser(tester, courseId: 'group-ii');
    expect(find.text('Current Affairs'), findsOneWidget);
    expect(find.text('Select Part'), findsNothing);

    await dragContent(tester, const Offset(80, 0));
    expect(find.text('Current Affairs'), findsOneWidget);
    expect(find.text('Select Part'), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('syllabus-paper-group-ii-paper-i')),
    );
    expect(
      pillSelected(tester, 'syllabus-paper-group-ii-paper-i'),
      isTrue,
    );

    final course = SyllabusService.instance.getCourseById('group-ii')!;
    final last = SyllabusBrowserSequence.fromPapers(course.papers).last;
    await pumpBrowser(
      tester,
      courseId: 'group-ii',
      paperId: last.paperId,
      partId: last.partId,
    );
    final lastPaper = course.papers.singleWhere((p) => p.id == last.paperId);
    expect(find.text(lastPaper.title), findsWidgets);
    await tester.ensureVisible(
      find.byKey(ValueKey('syllabus-paper-${last.paperId}')),
    );
    expect(pillSelected(tester, 'syllabus-paper-${last.paperId}'), isTrue);
    if (last.partId != null) {
      await tester.ensureVisible(
        find.byKey(ValueKey('syllabus-part-${last.partId}')),
      );
      expect(pillSelected(tester, 'syllabus-part-${last.partId}'), isTrue);
    }

    await dragContent(tester, const Offset(-80, 0));
    await tester.ensureVisible(
      find.byKey(ValueKey('syllabus-paper-${last.paperId}')),
    );
    expect(pillSelected(tester, 'syllabus-paper-${last.paperId}'), isTrue);
    if (last.partId != null) {
      expect(pillSelected(tester, 'syllabus-part-${last.partId}'), isTrue);
    }
    expect(find.text(lastPaper.title), findsWidgets);
  });

  testWidgets('Group-III swipe uses the same sequence mechanism', (
    tester,
  ) async {
    await pumpBrowser(tester, courseId: 'group-iii');
    expect(
      pillSelected(tester, 'syllabus-paper-group-iii-paper-i'),
      isTrue,
    );
    expect(find.text('Current Affairs'), findsOneWidget);

    await dragContent(tester, const Offset(-80, 0));
    expect(
      pillSelected(tester, 'syllabus-paper-group-iii-paper-ii'),
      isTrue,
    );
    expect(find.text('Select Part'), findsOneWidget);
    expect(
      pillSelected(tester, 'syllabus-part-group-iii-paper-ii-part-i'),
      isTrue,
    );

    await dragContent(tester, const Offset(80, 0));
    expect(
      pillSelected(tester, 'syllabus-paper-group-iii-paper-i'),
      isTrue,
    );
    expect(find.text('Select Part'), findsNothing);
  });

  testWidgets('vertical, small, and diagonal drags do not change destination', (
    tester,
  ) async {
    await pumpBrowser(tester, courseId: 'group-ii');
    await dragContent(tester, const Offset(0, -80));
    expect(find.text('Select Part'), findsNothing);
    expect(find.text('Ancient and Medieval Telangana'), findsNothing);

    await pumpBrowser(tester, courseId: 'group-ii');
    await dragContent(tester, const Offset(-30, 0));
    expect(find.text('Select Part'), findsNothing);
    expect(find.text('Current Affairs'), findsOneWidget);

    await pumpBrowser(tester, courseId: 'group-ii');
    await dragContent(tester, const Offset(-70, 80));
    expect(find.text('Select Part'), findsNothing);
    expect(find.text('Ancient and Medieval Telangana'), findsNothing);
    expect(find.text('Current Affairs'), findsOneWidget);
  });

  testWidgets('paper and part pills still change the same selection', (
    tester,
  ) async {
    await pumpBrowser(tester, courseId: 'group-ii');

    await tester.tap(
      find.byKey(const ValueKey('syllabus-paper-group-ii-paper-ii')),
    );
    await tester.pumpAndSettle();
    expect(
      pillSelected(tester, 'syllabus-paper-group-ii-paper-ii'),
      isTrue,
    );
    expect(
      pillSelected(tester, 'syllabus-part-group-ii-paper-ii-part-01'),
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey('syllabus-part-group-ii-paper-ii-part-02')),
    );
    await tester.pumpAndSettle();
    expect(
      pillSelected(tester, 'syllabus-part-group-ii-paper-ii-part-02'),
      isTrue,
    );
  });

  testWidgets('unit card and back navigation still work after swipe wiring', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const SyllabusBrowserScreen(courseId: 'group-ii'),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Current Affairs'));
    await tester.pumpAndSettle();
    expect(find.byType(SyllabusUnitTestsScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(SyllabusBrowserScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('swipe layouts do not overflow at 360/390/430', (tester) async {
    for (final size in [
      const Size(360, 740),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      FlutterErrorDetails? overflow;
      final old = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          overflow ??= details;
        }
        old?.call(details);
      };
      addTearDown(() => FlutterError.onError = old);

      await pumpBrowser(tester, courseId: 'group-ii', size: size);
      expect(overflow, isNull, reason: '${size.width}: ${overflow?.exceptionAsString()}');
      await dragContent(tester, const Offset(-80, 0));
      expect(overflow, isNull, reason: '${size.width} after swipe');
      expect(
        pillSelected(tester, 'syllabus-paper-group-ii-paper-ii'),
        isTrue,
      );
    }
  });
}
