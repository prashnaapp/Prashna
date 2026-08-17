import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_home_screen.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/chapters_hero.dart';
import 'package:telangana_prep/features/syllabus/presentation/widgets/syllabus_course_card.dart';

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
      const Size(360, 740), // small Android phone
      const Size(390, 844), // common modern phone
      const Size(412, 915), // large Android phone
    ]) {
      await pumpAt(tester, size);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Group-II'), findsOneWidget);
      expect(find.text('Group-III'), findsOneWidget);
      expect(find.text('Launching Soon'), findsNothing);
      expect(find.text('Coming Soon'), findsNothing);
      expect(find.text('Police SI'), findsNothing);
      expect(find.text('Constable'), findsNothing);

      final cards = find.byType(SyllabusCourseCard);
      expect(cards, findsNWidgets(2));
      final cardSize = tester.getSize(cards.first);
      // ignore: avoid_print
      print('size=$size cardSize=$cardSize');

      // Two side-by-side cards flush with the page margins (reference
      // proportion), never a single tall full-row panel.
      expect(cardSize.width, lessThan(size.width * 0.46));
      expect(cardSize.width, greaterThan(size.width * 0.38));
      expect(cardSize.height, lessThan(280));
      expect(cardSize.height, greaterThan(120));

      // The two cards stay side-by-side, equal size, on the same row.
      final bothCards = cards.evaluate().toList();
      final firstTop = tester.getTopLeft(cards.first).dy;
      final secondTop = tester.getTopLeft(cards.last).dy;
      expect(secondTop, firstTop);
      expect(bothCards.length, 2);

      // The "Available" label must clear the wave trough, i.e. sit below
      // the deepest point of the sheet's curved top edge, so it can never
      // render on top of the purple hero.
      final labelTop = tester.getTopLeft(find.text('Available')).dy;
      final heroBottom = tester.getBottomLeft(find.byType(ChaptersHero)).dy;
      expect(labelTop, greaterThan(heroBottom - 6));
      // ignore: avoid_print
      print('size=$size labelTop=$labelTop heroBottom=$heroBottom');
    }
  });
}
