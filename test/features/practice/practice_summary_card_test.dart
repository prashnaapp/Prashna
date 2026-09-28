import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/practice/data/models/practice_models.dart';
import 'package:telangana_prep/features/practice/presentation/screens/practice_session_screen.dart';
import 'package:telangana_prep/features/practice/presentation/widgets/practice_summary_card.dart';

void main() {
  PracticeSessionModel fixture({
    String chapterLabel = 'Chapter 3 — Kakatiyas',
    int questionCount = 12,
    int marks = 12,
    String timeLimitLabel = '12 Minutes',
    String negativeMarking = 'No',
    String difficulty = 'Hard',
  }) {
    return PracticeSessionModel(
      chapterLabel: chapterLabel,
      questionCount: questionCount,
      marks: marks,
      timeLimitLabel: timeLimitLabel,
      negativeMarking: negativeMarking,
      difficulty: difficulty,
    );
  }

  group('PracticeSummaryCard', () {
    testWidgets('does not display Difficulty', (tester) async {
      final session = fixture(difficulty: 'Hard');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PracticeSummaryCard(session: session),
          ),
        ),
      );

      expect(find.text('Difficulty'), findsNothing);
      expect(find.text(session.difficulty), findsNothing);
    });

    testWidgets('still renders other summary metadata', (tester) async {
      final session = fixture(questionCount: 12, marks: 24);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PracticeSummaryCard(session: session),
          ),
        ),
      );

      expect(find.text('Chapter'), findsOneWidget);
      expect(find.text(session.chapterLabel), findsOneWidget);
      expect(find.text('Questions'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Marks'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
      expect(find.text('Time Limit'), findsOneWidget);
      expect(find.text(session.timeLimitLabel), findsOneWidget);
      expect(find.text('Negative Marking'), findsOneWidget);
      expect(find.text(session.negativeMarking), findsOneWidget);
    });
  });

  testWidgets('practice session screen has no visible Difficulty label', (
    tester,
  ) async {
    final session = fixture(difficulty: 'Easy');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PracticeSessionScreen(
            session: session,
            heroTag: 'practice-hero',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Difficulty'), findsNothing);
    expect(find.text('Easy'), findsNothing);
    expect(find.text('Start Quiz'), findsOneWidget);
  });
}
