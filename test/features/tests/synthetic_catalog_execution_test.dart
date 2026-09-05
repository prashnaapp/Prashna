import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/data/tests_dummy_data.dart';
import 'package:telangana_prep/features/tests/presentation/mock_test_navigation.dart';
import 'package:telangana_prep/features/tests/presentation/paper_wise_navigation.dart';
import 'package:telangana_prep/features/tests/presentation/previous_papers_navigation.dart';
import 'package:telangana_prep/features/tests/presentation/screens/grand_tests_screen.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_list_screen.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_series_browser_screen.dart';
import 'package:telangana_prep/features/tests/presentation/test_quiz_navigation.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';

void main() {
  TestModel published({
    required String id,
    required String examId,
    required TestCategoryType category,
    String title = 'Published Catalog Test',
  }) {
    return TestModel(
      id: id,
      examId: examId,
      category: category,
      title: title,
      questionCount: 2,
      marks: 2,
      durationMinutes: 10,
      negativeMarking: '0',
      difficulty: 'Medium',
      status: TestPublicationStatus.published,
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

  test('dummy helpers are synthetic and unpublished', () {
    final dummy = TestsDummyData.mockPaperTest(
      examId: 'group-ii',
      mock: const MockTestEntry(id: 'mock-1', title: 'Mock Test 1'),
      paper: const PaperWisePaper(
        id: 'paper-i',
        title: 'Paper I',
        subtitle: 'General Studies',
      ),
    );
    expect(TestsDummyData.isSyntheticCatalogTest(dummy), isTrue);
    expect(dummy.isAvailableForNewAttempts, isFalse);
    expect(
      TestsDummyData.isSyntheticCatalogTest(
        published(
          id: 'test-group-ii-001',
          examId: 'group-ii',
          category: TestCategoryType.chapterTests,
        ),
      ),
      isFalse,
    );
  });

  testWidgets(
    'A: synthetic category routes do not start nonexistent server tests',
    (tester) async {
      var started = 0;
      final empty = catalog(const []);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () => openMockPaperTest(
                      context: context,
                      examId: 'group-ii',
                      mock: const MockTestEntry(
                        id: 'mock-1',
                        title: 'Mock Test 1',
                      ),
                      paper: const PaperWisePaper(
                        id: 'paper-i',
                        title: 'Paper I',
                        subtitle: 'General Studies',
                      ),
                      testService: empty,
                    ),
                    child: const Text('open-mock'),
                  ),
                  TextButton(
                    onPressed: () => openPaperWisePartTest(
                      context: context,
                      part: TestsDummyData.paperWisePartsFor(
                        examId: 'group-iii',
                        paperId: 'paper-i',
                      ).first,
                      testService: empty,
                    ),
                    child: const Text('open-part'),
                  ),
                  TextButton(
                    onPressed: () => openPreviousPaperTest(
                      context: context,
                      examId: 'group-ii',
                      year: const PreviousPaperYear(year: 2016),
                      paper: const PaperWisePaper(
                        id: 'paper-i',
                        title: 'Paper I',
                        subtitle: 'General Studies',
                      ),
                      testService: empty,
                    ),
                    child: const Text('open-previous'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open-mock'));
      await tester.pumpAndSettle();
      expect(find.byType(TestListScreen), findsOneWidget);
      expect(find.text('No tests available'), findsOneWidget);
      Navigator.of(tester.element(find.byType(TestListScreen))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-part'));
      await tester.pumpAndSettle();
      expect(find.text('No tests available'), findsOneWidget);
      Navigator.of(tester.element(find.byType(TestListScreen))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-previous'));
      await tester.pumpAndSettle();
      expect(find.text('No tests available'), findsOneWidget);
      expect(started, 0);
    },
  );

  testWidgets('dummy TestModel never calls startAttempt', (tester) async {
    var started = 0;
    final dummy = TestsDummyData.previousPaperTest(
      examId: 'group-iii',
      year: const PreviousPaperYear(year: 2018),
      paper: const PaperWisePaper(
        id: 'paper-ii',
        title: 'Paper II',
        subtitle: 'History',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => openTestPracticeSession(
                  context,
                  dummy,
                  startAttempt: ({required testId, required startRequestId}) async {
                    started += 1;
                    return <String, dynamic>{};
                  },
                ),
                child: const Text('start-dummy'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('start-dummy'));
    await tester.pumpAndSettle();
    expect(started, 0);
    expect(
      find.text('This test is not available for new attempts.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'B: empty category shows empty state for Group-II and Group-III',
    (tester) async {
      final empty = catalog(const []);
      for (final examId in ['group-ii', 'group-iii']) {
        await tester.pumpWidget(
          MaterialApp(
            home: TestListScreen(
              examId: examId,
              category: TestCategoryType.mockTests,
              title: 'Mock Tests',
              testService: empty,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No tests available'), findsOneWidget);
        expect(
          find.text('There are no published tests in this category yet.'),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets('C/J/K: published Firestore tests still start for both groups', (
    tester,
  ) async {
    final started = <String>[];
    for (final examId in ['group-ii', 'group-iii']) {
      final test = published(
        id: 'test-$examId-001',
        examId: examId,
        category: TestCategoryType.chapterTests,
        title: '$examId published',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => openTestPracticeSession(
                    context,
                    test,
                    startAttempt: ({required testId, required startRequestId}) async {
                      started.add(testId);
                      throw StateError('stop-after-start');
                    },
                  ),
                  child: const Text('start-real'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('start-real'));
      await tester.pumpAndSettle();
    }
    expect(started, ['test-group-ii-001', 'test-group-iii-001']);
  });

  testWidgets('dashboard categories open published lists, not dummy IDs', (
    tester,
  ) async {
    final empty = catalog(const []);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => openTestCategory(
                context: context,
                examId: 'group-ii',
                category: const TestCategoryModel(
                  type: TestCategoryType.mockTests,
                  title: 'Mock Tests',
                  subtitle: 'View available tests',
                ),
                testService: empty,
              ),
              child: const Text('open-category'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open-category'));
    await tester.pumpAndSettle();
    expect(find.byType(GrandTestsScreen), findsOneWidget);
    expect(find.byType(TestSeriesBrowserScreen), findsNothing);
    expect(find.byType(TestListScreen), findsNothing);
    expect(find.text('No tests available'), findsNothing);
    expect(find.text('Grand Test - I'), findsOneWidget);
    expect(find.text('Grand Test - II'), findsOneWidget);
    expect(find.text('Grand Test - III'), findsOneWidget);
    expect(find.text('Old Grand Tests'), findsOneWidget);
    expect(find.text('Mock Test 1'), findsNothing);
  });

  testWidgets('published category list shows the real test card', (
    tester,
  ) async {
    final service = catalog([
      published(
        id: 'test-group-iii-unit-1',
        examId: 'group-iii',
        category: TestCategoryType.partTests,
        title: 'Group-III Part Test',
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: TestListScreen(
          examId: 'group-iii',
          category: TestCategoryType.partTests,
          title: 'Paper-wise Tests',
          testService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Group-III Part Test'), findsOneWidget);
    expect(find.text('No tests available'), findsNothing);
  });
}
