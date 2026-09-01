import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/data/tests_dummy_data.dart';
import 'package:telangana_prep/features/tests/presentation/screens/test_instructions_screen.dart';
import 'package:telangana_prep/features/tests/presentation/test_instructions_presentation.dart';

void main() {
  TestModel fixture({
    String title = 'Ancient Telangana Practice',
    int questionCount = 17,
    int marks = 17,
    int durationMinutes = 30,
    String negativeMarking = '0.25',
    String difficulty = 'Medium',
    String? paperId,
    String? partId,
    String? syllabusUnitId,
  }) {
    return TestModel(
      id: 'fixture-test-id',
      examId: 'group-ii',
      category: TestCategoryType.chapterTests,
      title: title,
      questionCount: questionCount,
      marks: marks,
      durationMinutes: durationMinutes,
      negativeMarking: negativeMarking,
      difficulty: difficulty,
      status: TestPublicationStatus.published,
      paperId: paperId,
      partId: partId,
      syllabusUnitId: syllabusUnitId,
    );
  }

  Future<void> pumpInstructions(
    WidgetTester tester, {
    required TestModel test,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: TestInstructionsScreen(test: test)),
    );
    await tester.pump();
  }

  test('duration label uses the supplied minutes with singular/plural', () {
    expect(TestInstructionsPresentation.durationLabel(1), '1 Minute');
    expect(TestInstructionsPresentation.durationLabel(30), '30 Minutes');
    expect(TestInstructionsPresentation.durationLabel(0), '0 Minutes');
  });

  testWidgets('renders fixture-driven title and metadata', (tester) async {
    final test = fixture();
    await pumpInstructions(tester, test: test);

    expect(find.text('Test Instructions'), findsOneWidget);
    expect(find.text(test.title), findsOneWidget);
    expect(find.text('Questions'), findsOneWidget);
    expect(find.text('${test.questionCount}'), findsWidgets);
    expect(find.text('Marks'), findsOneWidget);
    expect(find.text('${test.marks}'), findsWidgets);
    expect(find.text('Duration'), findsOneWidget);
    expect(
      find.text(
        TestInstructionsPresentation.durationLabel(test.durationMinutes),
      ),
      findsOneWidget,
    );
    expect(find.text('Negative Marking'), findsOneWidget);
    expect(find.text(test.negativeMarking), findsOneWidget);
    expect(find.text('Difficulty'), findsOneWidget);
    expect(find.text(test.difficulty), findsOneWidget);
    expect(find.text('Instructions'), findsOneWidget);
    for (final line in TestsDummyData.instructions) {
      expect(find.text(line), findsOneWidget);
    }
    expect(find.text('Start Test'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-test')), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('omits context pill when paper/part/unit are absent', (
    tester,
  ) async {
    await pumpInstructions(tester, test: fixture());
    expect(TestInstructionsPresentation.contextLabel(fixture()), isNull);
    expect(find.textContaining(' • '), findsNothing);
  });

  testWidgets('shows context pill from existing paper/part/unit ids', (
    tester,
  ) async {
    final test = fixture(
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-01',
      syllabusUnitId: 'group-ii-paper-ii-part-01-topic-01',
    );
    final label = TestInstructionsPresentation.contextLabel(test);
    expect(label, isNotNull);
    await pumpInstructions(tester, test: test);
    expect(find.text(label!), findsOneWidget);
  });

  testWidgets('question count, marks, and negative marking stay dynamic', (
    tester,
  ) async {
    final test = fixture(
      questionCount: 1,
      marks: 4,
      negativeMarking: '0',
      difficulty: 'Easy',
    );
    await pumpInstructions(tester, test: test);

    expect(find.text('1'), findsWidgets);
    expect(find.text('4'), findsWidgets);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('20'), findsNothing);
    expect(find.text('0.25'), findsNothing);
    expect(find.text('Medium'), findsNothing);
  });

  testWidgets('duration presentation is 1 Minute not 1 Minutes', (
    tester,
  ) async {
    await pumpInstructions(tester, test: fixture(durationMinutes: 1));
    expect(find.text('1 Minute'), findsOneWidget);
    expect(find.text('1 Minutes'), findsNothing);
    expect(find.text('1Minutes'), findsNothing);
  });

  testWidgets('long title wraps without inventing a replacement', (
    tester,
  ) async {
    const title =
        'Group-II Paper II Part I — Ancient and Medieval Telangana Practice Set';
    await pumpInstructions(
      tester,
      test: fixture(title: title),
      size: const Size(360, 740),
    );
    expect(find.text(title), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('back remains available when the screen can pop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TestInstructionsScreen(test: fixture()),
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
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(find.byType(TestInstructionsScreen), findsNothing);
  });

  testWidgets('no overflow at 360/390/430', (tester) async {
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

      await pumpInstructions(
        tester,
        test: fixture(
          title: 'A reasonably long catalog title for layout wrapping',
          questionCount: 150,
          marks: 150,
          durationMinutes: 180,
          negativeMarking: '0.25',
        ),
        size: size,
      );
      expect(
        overflow,
        isNull,
        reason: '${size.width}: ${overflow?.exceptionAsString()}',
      );
      expect(find.text('Negative Marking'), findsOneWidget);
      expect(find.text('Start Test'), findsOneWidget);
    }
  });
}
