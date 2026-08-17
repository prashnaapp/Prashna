import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telangana_prep/features/tests/presentation/widgets/tests_tip_banner.dart';

void main() {
  testWidgets('TestsTipBanner fits layoutHeight without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 360, child: TestsTipBanner())),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(TestsTipBanner));
    expect(size.height, TestsTipBanner.layoutHeight);
    expect(find.text('Practice Smart. Score Higher.'), findsOneWidget);
    expect(
      find.text('Choose a test series to begin your preparation.'),
      findsOneWidget,
    );
  });
}
