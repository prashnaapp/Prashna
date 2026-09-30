import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/admin_routes.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_tests_home_screen.dart';
import 'package:telangana_prep/features/admin/presentation/shell/admin_nav_destination.dart';

void main() {
  testWidgets('Tests landing shows Chapter Tests and Test Series cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminTestsHomeScreen(embeddedInShell: true)),
    );

    expect(find.text('Tests'), findsOneWidget);
    expect(find.text('Manage chapter tests and test series'), findsOneWidget);
    expect(find.text('Chapter Tests'), findsOneWidget);
    expect(find.text('Test Series'), findsOneWidget);
    expect(find.byKey(const ValueKey('tests-choice-chapter')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tests-choice-test-series')),
      findsOneWidget,
    );
  });

  testWidgets('Chapter Tests card opens the Chapters browser', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AdminRoutes.chapters: (_) =>
              const Scaffold(body: Text('Chapters flow')),
        },
        home: const AdminTestsHomeScreen(embeddedInShell: true),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('tests-choice-chapter')));
    await tester.pumpAndSettle();

    expect(find.text('Chapters flow'), findsOneWidget);
  });

  testWidgets('Test Series card opens the Test Series browser', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AdminRoutes.testSeries: (_) =>
              const Scaffold(body: Text('Test Series flow')),
        },
        home: const AdminTestsHomeScreen(embeddedInShell: true),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('tests-choice-test-series')));
    await tester.pumpAndSettle();

    expect(find.text('Test Series flow'), findsOneWidget);
  });

  test('sidebar Tests route maps nested chapter and series destinations', () {
    expect(
      AdminNavDestinationX.fromRouteName(AdminRoutes.tests),
      AdminNavDestination.tests,
    );
    expect(
      AdminNavDestinationX.fromRouteName(AdminRoutes.chapters),
      AdminNavDestination.tests,
    );
    expect(
      AdminNavDestinationX.fromRouteName(AdminRoutes.testSeries),
      AdminNavDestination.tests,
    );
    expect(
      AdminNavDestinationX.fromRouteName(AdminRoutes.testCreate),
      AdminNavDestination.tests,
    );
    expect(
      AdminNavDestinationX.fromRouteName(AdminRoutes.testEdit),
      AdminNavDestination.tests,
    );
    expect(
      AdminNavDestinationX.fromRouteName(AdminRoutes.testAssignments),
      AdminNavDestination.tests,
    );
  });

  test('Questions and Import Questions sidebar mapping is unchanged', () {
    expect(
      AdminNavDestinationX.fromRouteName(AdminRoutes.questions),
      AdminNavDestination.questions,
    );
    expect(
      AdminNavDestinationX.fromRouteName(AdminRoutes.chapterQuestions),
      AdminNavDestination.questions,
    );
    expect(
      AdminNavDestinationX.fromRouteName(AdminRoutes.questionImport),
      AdminNavDestination.importQuestions,
    );
  });

  test('AdminNavDestination labels exclude legacy Chapters sidebar entry', () {
    final labels = AdminNavDestination.values
        .map((item) => item.label)
        .toList();
    expect(labels, contains('Tests'));
    expect(labels, isNot(contains('Chapters')));
    expect(labels.where((label) => label == 'Test Series'), isEmpty);
  });
}
