import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_home_screen.dart';
import 'package:telangana_prep/features/tests/presentation/widgets/tests_tip_banner.dart';

void main() {
  testWidgets('Chapters landing has no RenderFlex overflow on phone size', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(390, 844);
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
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Group-II'), findsOneWidget);
    expect(find.text('Group-III'), findsOneWidget);
    // Launching Soon and Coming Soon have been removed — only the
    // currently-available Group-II/Group-III courses are shown.
    expect(find.text('Coming Soon'), findsNothing);
    expect(find.text('Launching Soon'), findsNothing);
  });

  testWidgets('Practice Smart tip banner has no overflow at layoutHeight', (
    tester,
  ) async {
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
      const MaterialApp(
        home: Scaffold(
          body: Padding(padding: EdgeInsets.all(20), child: TestsTipBanner()),
        ),
      ),
    );
    await tester.pump();

    expect(overflow, isNull, reason: overflow?.exceptionAsString());
    expect(
      tester.getSize(find.byType(TestsTipBanner)).height,
      TestsTipBanner.layoutHeight,
    );
  });
}
