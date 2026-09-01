import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/repositories/test_repository.dart';
import 'package:telangana_prep/features/test_engine/presentation/controllers/test_engine_controller.dart';
import 'package:telangana_prep/features/test_engine/presentation/screens/test_result_screen.dart';
import 'package:telangana_prep/features/test_engine/presentation/test_engine_presentation.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

void main() {
  Test fixtureTest({
    String title = 'Result Layout Drill',
    int totalQuestions = 23,
    int totalMarks = 23,
  }) {
    return Test(
      id: 'result-layout',
      title: title,
      courseId: 'group-ii',
      duration: const Duration(minutes: 30),
      totalQuestions: totalQuestions,
      totalMarks: totalMarks,
      negativeMarks: 0,
      instructions: const [],
      mode: TestMode.topic,
      questions: [
        TestQuestion(
          id: 'q1',
          text: 'Fixture question',
          options: const [
            TestOption(label: 'A', text: 'A'),
            TestOption(label: 'B', text: 'B'),
            TestOption(label: 'C', text: 'C'),
            TestOption(label: 'D', text: 'D'),
          ],
          correctOption: 'A',
          explanation: '',
        ),
      ],
    );
  }

  TestResult fixtureResult({
    int correct = 9,
    int wrong = 3,
    int skipped = 11,
    double score = 9,
    double accuracy = 75,
    double percentage = 39.1,
    Duration timeTaken = const Duration(minutes: 12, seconds: 17),
    bool passed = false,
  }) {
    return TestResult(
      totalQuestions: correct + wrong + skipped,
      attempted: correct + wrong,
      correct: correct,
      wrong: wrong,
      skipped: skipped,
      score: score,
      accuracy: accuracy,
      percentage: percentage,
      timeTaken: timeTaken,
      passed: passed,
    );
  }

  Future<void> pumpResult(
    WidgetTester tester, {
    required Test test,
    required TestResult result,
    Size size = const Size(390, 844),
    VoidCallback? onViewAnalysis,
    VoidCallback? onGoHome,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TestEngineController(
      test: test,
      service: TestService(repository: TestRepository()),
    )..result = result;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: TestResultScreen(
          controller: controller,
          onViewAnalysis: onViewAnalysis ?? () {},
          onGoHome: onGoHome ?? () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('time-taken label uses the supplied duration', () {
    expect(
      TestEnginePresentation.timeTakenLabel(
        const Duration(minutes: 12, seconds: 17),
      ),
      '12m 17s',
    );
    expect(TestEnginePresentation.timeTakenLabel(Duration.zero), '0m 0s');
  });

  testWidgets('renders fixture-driven score, stats, and actions', (
    tester,
  ) async {
    final test = fixtureTest(totalMarks: 23);
    final result = fixtureResult();
    var openedAnalysis = false;
    var wentHome = false;
    await pumpResult(
      tester,
      test: test,
      result: result,
      onViewAnalysis: () => openedAnalysis = true,
      onGoHome: () => wentHome = true,
    );

    expect(find.text('Result'), findsOneWidget);
    expect(find.text('TEST COMPLETED!'), findsOneWidget);
    expect(find.text('Keep Practicing'), findsOneWidget);
    expect(
      find.text('${result.score.toStringAsFixed(0)} / ${test.totalMarks}'),
      findsOneWidget,
    );
    expect(find.text('${result.percentage}%'), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('${result.correct}'), findsOneWidget);
    expect(find.text('Wrong'), findsOneWidget);
    expect(find.text('${result.wrong}'), findsOneWidget);
    expect(find.text('Skipped'), findsOneWidget);
    expect(find.text('${result.skipped}'), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);
    expect(find.text('${result.accuracy}%'), findsOneWidget);
    expect(find.text('Time Taken'), findsOneWidget);
    expect(
      find.text(TestEnginePresentation.timeTakenLabel(result.timeTaken)),
      findsOneWidget,
    );
    expect(find.text('Review Answers'), findsOneWidget);
    expect(find.text('Back to Unit'), findsOneWidget);

    await tester.tap(find.text('Review Answers'));
    await tester.pump();
    expect(openedAnalysis, isTrue);

    await tester.tap(find.text('Back to Unit'));
    await tester.pump();
    expect(wentHome, isTrue);
  });

  testWidgets('passed result keeps existing motivational logic', (
    tester,
  ) async {
    final test = fixtureTest(totalMarks: 10);
    final result = fixtureResult(
      correct: 8,
      wrong: 1,
      skipped: 1,
      score: 8,
      accuracy: 88.9,
      percentage: 80,
      passed: true,
    );
    await pumpResult(tester, test: test, result: result);
    expect(find.text('Passed'), findsOneWidget);
    expect(find.text('Keep Practicing'), findsNothing);
    expect(find.text('8 / ${test.totalMarks}'), findsOneWidget);
    expect(find.text('${result.percentage}%'), findsOneWidget);
  });

  testWidgets('no overflow at 360/390/430', (tester) async {
    final test = fixtureTest(totalMarks: 150);
    final result = fixtureResult(
      correct: 120,
      wrong: 18,
      skipped: 12,
      score: 118.5,
      accuracy: 86.96,
      percentage: 79.0,
      timeTaken: const Duration(minutes: 179, seconds: 59),
      passed: true,
    );

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
          return;
        }
        old?.call(details);
      };
      addTearDown(() => FlutterError.onError = old);

      await pumpResult(tester, test: test, result: result, size: size);
      expect(
        overflow,
        isNull,
        reason: '${size.width}: ${overflow?.exceptionAsString()}',
      );
      expect(find.text('Review Answers'), findsOneWidget);
      final back = find.text('Back to Unit');
      await tester.scrollUntilVisible(back, 80);
      expect(back, findsOneWidget);
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('Time Taken'), findsOneWidget);
    }
  });
}
