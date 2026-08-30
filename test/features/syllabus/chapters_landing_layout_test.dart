import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/syllabus/data/syllabus_dummy_data.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_home_screen.dart';
import 'package:telangana_prep/features/syllabus/presentation/syllabus_visual.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/chapters_course_card.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/chapters_hero.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';
import 'package:telangana_prep/navigation/custom_bottom_navigation.dart';

void main() {
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
      old?.call(details);
    };
    addTearDown(() => FlutterError.onError = old);

    await tester.pumpWidget(const MaterialApp(home: SyllabusHomeScreen()));
    await tester.pump();
    expect(overflow, isNull, reason: overflow?.exceptionAsString());
  }

  testWidgets('Chapters landing has no overflow and compact Available cards on '
      'common phone sizes', (tester) async {
    for (final size in [
      const Size(360, 740),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      await pumpAt(tester, size);
      expect(find.text('Chapters'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Group-II'), findsOneWidget);
      expect(find.text('Group-III'), findsOneWidget);
      expect(find.text('600 Marks'), findsOneWidget);
      expect(find.text('4 Papers'), findsOneWidget);
      expect(find.text('450 Marks'), findsOneWidget);
      expect(find.text('3 Papers'), findsOneWidget);
      expect(find.text('Launching Soon'), findsNothing);
      expect(find.text('Coming Soon'), findsNothing);
      expect(find.text('Explore your syllabus'), findsNothing);
      expect(find.text('Police SI'), findsNothing);
      expect(find.text('Constable'), findsNothing);

      final cards = find.byType(ChaptersCourseCard);
      expect(cards, findsNWidgets(2));
      final cardSize = tester.getSize(cards.first);

      expect(cardSize.width, lessThan(size.width * 0.48));
      expect(cardSize.width, greaterThan(size.width * 0.36));
      // ~70% of the previous tall Available cards, without becoming tiny.
      expect(cardSize.height, lessThan(200));
      expect(cardSize.height, greaterThan(140));

      final bothCards = cards.evaluate().toList();
      final firstTop = tester.getTopLeft(cards.first).dy;
      final secondTop = tester.getTopLeft(cards.last).dy;
      expect(secondTop, firstTop);
      expect(bothCards.length, 2);

      final labelTop = tester.getTopLeft(find.text('Available')).dy;
      final heroBottom = tester.getBottomLeft(find.byType(ChaptersHero)).dy;
      expect(labelTop, greaterThan(heroBottom - 2));

      expect(find.byType(CustomBottomNavigation), findsNothing);
      expect(tester.widget<InkWell>(find.byType(InkWell).first).onTap, isNotNull);

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        SyllabusVisual.page,
      );
      final cardMaterials = tester
          .widgetList<Material>(
            find.descendant(
              of: cards,
              matching: find.byType(Material),
            ),
          )
          .toList();
      expect(cardMaterials, isNotEmpty);
      expect(
        cardMaterials.every(
          (material) =>
              material.clipBehavior == Clip.antiAlias &&
              material.color == SyllabusVisual.surface,
        ),
        isTrue,
      );
    }
  });

  test('available syllabus catalog is unchanged', () {
    final available = SyllabusService.instance
        .getAllCourses()
        .where((course) => course.isAvailable)
        .toList();
    expect(available.map((c) => c.id), ['group-ii', 'group-iii']);
    expect(available[0].name, 'Group-II');
    expect(available[0].totalMarks, 600);
    expect(available[0].totalPapers, 4);
    expect(available[1].name, 'Group-III');
    expect(available[1].totalMarks, 450);
    expect(available[1].totalPapers, 3);
    expect(SyllabusDummyData.all.length, greaterThanOrEqualTo(2));
  });

  test('course open destination remains CourseOpenGuard + SyllabusBrowserScreen', () {
    final source = File(
      'lib/features/syllabus/presentation/screens/syllabus_home_screen.dart',
    ).readAsStringSync();
    expect(source, contains('CourseOpenGuard.attemptOpen'));
    expect(source, contains('courseId: course.id'));
    expect(source, contains('SyllabusBrowserScreen(courseId: course.id)'));
    expect(source, contains('Navigator.push'));
  });
}
