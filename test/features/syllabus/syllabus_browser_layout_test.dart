import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_browser_screen.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_unit_tests_screen.dart';
import 'package:telangana_prep/features/syllabus/presentation/syllabus_visual.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_browser_pill.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_unit_row_card.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_unit_visual.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Size size, {
    required String courseId,
  }) async {
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
      old?.call(details);
    };
    addTearDown(() => FlutterError.onError = old);

    await tester.pumpWidget(
      MaterialApp(home: SyllabusBrowserScreen(courseId: courseId)),
    );
    await tester.pump();
    expect(overflow, isNull, reason: overflow?.exceptionAsString());
  }

  testWidgets('Group-II browser renders papers and Paper I subjects', (
    tester,
  ) async {
    for (final size in [
      const Size(360, 740),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      await pumpAt(tester, size, courseId: 'group-ii');

      expect(find.text('Group-II'), findsOneWidget);
      expect(find.byType(SyllabusBrowserPill), findsNWidgets(4));
      expect(find.text('Paper I'), findsWidgets);
      expect(find.text('Paper II'), findsOneWidget);
      expect(find.text('Paper III'), findsOneWidget);
      expect(find.text('Paper IV'), findsOneWidget);
      expect(find.text('Current Affairs'), findsOneWidget);
      expect(find.text('International Relations'), findsOneWidget);
      expect(find.text('General Science and Technology'), findsOneWidget);
      expect(find.text('Environment and Disaster Management'), findsOneWidget);
      expect(find.text('Indian History and Heritage'), findsOneWidget);
      expect(find.text('Telangana Society and Culture'), findsOneWidget);
      expect(find.text('Questions'), findsNothing);
      expect(find.text('Explore your syllabus'), findsNothing);
      expect(find.text('Not Started'), findsNothing);

      final cards = find.byType(SyllabusUnitRowCard);
      expect(cards, findsWidgets);
      final first = tester.getSize(cards.first);
      expect(first.height, lessThan(110));
      expect(first.height, greaterThan(56));

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        SyllabusVisual.page,
      );
    }
  });

  testWidgets('Group-II paper selection still shows parts and units', (
    tester,
  ) async {
    await pumpAt(tester, const Size(390, 844), courseId: 'group-ii');

    await tester.tap(
      find.byKey(const ValueKey('syllabus-paper-group-ii-paper-ii')),
    );
    await tester.pump();

    expect(find.text('Select Part'), findsOneWidget);
    expect(find.text('Part - I'), findsOneWidget);
    expect(find.text('Ancient and Medieval Telangana'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('syllabus-paper-group-ii-paper-iii')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('syllabus-paper-group-ii-paper-iv')),
      findsOneWidget,
    );
  });

  testWidgets('Group-III browser adapts to three papers and short Paper-I labels', (
    tester,
  ) async {
    for (final size in [
      const Size(360, 740),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      await pumpAt(tester, size, courseId: 'group-iii');

      expect(find.text('Group-III'), findsOneWidget);
      expect(find.byType(SyllabusBrowserPill), findsNWidgets(3));
      expect(find.text('Paper-I'), findsWidgets);
      expect(find.text('Paper-II'), findsOneWidget);
      expect(find.text('Paper-III'), findsOneWidget);
      expect(find.text('Current Affairs'), findsOneWidget);
      expect(find.text('International Relations'), findsOneWidget);
      expect(find.text('General Science and Technology'), findsOneWidget);
      expect(find.text('Environment and Disaster Management'), findsOneWidget);
      expect(find.text('Geography'), findsOneWidget);
      expect(find.text('Indian History and Heritage'), findsOneWidget);
      expect(find.text('Telangana Society and Culture'), findsOneWidget);
      expect(
        find.text('Current Affairs – Regional, National & International'),
        findsNothing,
      );
      expect(
        find.text(
          'Environmental Issues; Disaster Management- Prevention and Mitigation Strategies',
        ),
        findsNothing,
      );
      expect(find.text('Questions'), findsNothing);
    }

    await tester.tap(
      find.byKey(const ValueKey('syllabus-paper-group-iii-paper-ii')),
    );
    await tester.pump();
    expect(find.text('Select Part'), findsOneWidget);
    expect(find.text('Part - I'), findsOneWidget);
  });

  testWidgets('subject tap still opens the existing unit tests screen', (
    tester,
  ) async {
    await pumpAt(tester, const Size(390, 844), courseId: 'group-ii');

    await tester.tap(find.text('Current Affairs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SyllabusUnitTestsScreen), findsOneWidget);
  });

  testWidgets('back navigation remains available', (tester) async {
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
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(SyllabusBrowserScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(SyllabusBrowserScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('Group-II Paper III parts keep names and remain selectable', (
    tester,
  ) async {
    await pumpAt(tester, const Size(430, 932), courseId: 'group-ii');

    await tester.ensureVisible(
      find.byKey(const ValueKey('syllabus-paper-group-ii-paper-iii')),
    );
    await tester.tap(
      find.byKey(const ValueKey('syllabus-paper-group-ii-paper-iii')),
    );
    await tester.pump();

    expect(find.text('Select Part'), findsOneWidget);
    expect(find.text('Demography'), findsOneWidget);
    expect(find.text('National Income'), findsOneWidget);
    expect(find.text('Primary and Secondary Sectors'), findsOneWidget);
    expect(find.text('Industry and Services'), findsOneWidget);
    expect(find.text('Planning and Public Finance'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('syllabus-part-group-ii-paper-iii-part-02')),
    );
    await tester.pump();
    expect(find.text('Telangana Economy Structure and Growth'), findsOneWidget);
    expect(find.text('Telangana Demography and HRD'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('syllabus-part-group-ii-paper-iii-part-03')),
    );
    await tester.pump();
    expect(find.text('Growth and Development'), findsOneWidget);
    expect(find.text('Poverty and Unemployment'), findsOneWidget);
    expect(find.text('Environment and Sustainable Development'), findsOneWidget);
  });

  test('Group-II Paper III icons are unique within each part', () {
    final paper = SyllabusService.instance
        .getCourseById('group-ii')!
        .papers
        .singleWhere((p) => p.id == 'group-ii-paper-iii');
    for (final part in paper.parts) {
      final icons = <IconData>{};
      for (var i = 0; i < part.syllabusUnits.length; i++) {
        final unit = part.syllabusUnits[i];
        icons.add(
          SyllabusUnitVisualCatalog.resolve(
            unitId: unit.id,
            displayName: unit.displayName,
            index: i,
          ).icon,
        );
      }
      expect(
        icons.length,
        part.syllabusUnits.length,
        reason: '${part.id} has repeated icons',
      );
      expect(icons.contains(Icons.trending_up_rounded), isFalse);
    }
  });

  test('Group-III Paper-I display aliases are ID-based and data is unchanged', () {
    final paper = SyllabusService.instance
        .getCourseById('group-iii')!
        .papers
        .singleWhere((p) => p.id == 'group-iii-paper-i');
    expect(
      paper.syllabusUnits[0].displayName,
      'Current Affairs – Regional, National & International',
    );
    expect(paper.syllabusUnits[0].id, 'group-iii-paper-i-unit-01');

    final aliases = {
      'group-iii-paper-i-unit-01': 'Current Affairs',
      'group-iii-paper-i-unit-02': 'International Relations',
      'group-iii-paper-i-unit-03': 'General Science and Technology',
      'group-iii-paper-i-unit-04': 'Environment and Disaster Management',
      'group-iii-paper-i-unit-05': 'Geography',
      'group-iii-paper-i-unit-06': 'Indian History and Heritage',
      'group-iii-paper-i-unit-07': 'Telangana Society and Culture',
    };
    for (var i = 0; i < paper.syllabusUnits.length; i++) {
      final unit = paper.syllabusUnits[i];
      final visual = SyllabusUnitVisualCatalog.resolve(
        unitId: unit.id,
        displayName: unit.displayName,
        index: i,
      );
      final expected = aliases[unit.id];
      if (expected != null) {
        expect(visual.cardTitle, expected);
      } else {
        expect(visual.cardTitle, isNull);
      }
    }

    final groupIiPaperI = SyllabusService.instance
        .getCourseById('group-ii')!
        .papers
        .first
        .syllabusUnits
        .first;
    expect(groupIiPaperI.displayName, 'Current Affairs');
    expect(
      SyllabusUnitVisualCatalog.resolve(
        unitId: groupIiPaperI.id,
        displayName: groupIiPaperI.displayName,
        index: 0,
      ).cardTitle,
      isNull,
    );
  });

  test('Paper I subject icons are unique by name', () {
    final paper = SyllabusService.instance
        .getCourseById('group-ii')!
        .papers
        .first;
    final icons = <IconData>{};
    for (var i = 0; i < paper.syllabusUnits.length; i++) {
      final unit = paper.syllabusUnits[i];
      final visual = SyllabusUnitVisualCatalog.resolve(
        unitId: unit.id,
        displayName: unit.displayName,
        index: i,
      );
      icons.add(visual.icon);
    }
    expect(icons.length, paper.syllabusUnits.length);
  });

  test('open-unit destination remains SyllabusUnitTestsScreen', () {
    final source = File(
      'lib/features/syllabus/presentation/screens/syllabus_browser_screen.dart',
    ).readAsStringSync();
    expect(source, contains('SyllabusUnitTestsScreen('));
    expect(source, contains('courseId: _courseId'));
    expect(source, contains('paperId: _paper!.id'));
    expect(source, contains('unitId: unit.id'));
    expect(source, contains('CourseOpenGuard.attemptOpen'));
  });
}
