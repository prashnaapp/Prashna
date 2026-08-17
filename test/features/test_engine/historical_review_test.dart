import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_attempt_history.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_attempt_history_detail.dart';
import 'package:telangana_prep/features/test_engine/data/test_attempt_cloud_mapper.dart';
import 'package:telangana_prep/features/test_engine/presentation/screens/test_attempt_historical_review_screen.dart';
import 'package:telangana_prep/features/test_engine/presentation/screens/test_attempt_history_detail_screen.dart';

void main() {
  final now = DateTime(2026, 8, 15, 12);

  TestAttemptHistoryItem summary({
    required String attemptId,
    int? snapshotSchemaVersion = 1,
  }) {
    return TestAttemptHistoryItem(
      attemptId: attemptId,
      testId: 'test-1',
      courseId: 'group-iii',
      mode: 'topic',
      status: 'submitted',
      score: 1,
      percentage: 50,
      accuracy: 50,
      correct: 1,
      wrong: 1,
      skipped: 0,
      totalQuestions: 2,
      timeSpentSeconds: 30,
      startedAt: now,
      submittedAt: now.add(const Duration(seconds: 30)),
      passed: false,
      uid: 'student-a',
      authority: 'server_verified',
      snapshotSchemaVersion: snapshotSchemaVersion,
      testTitle: 'Unit Test',
      courseTitle: 'Group-III',
    );
  }

  Map<String, dynamic> snapshotDoc({
    required String questionId,
    required String text,
    required String correctOption,
    String explanation = 'Frozen explanation',
    int position = 0,
  }) {
    return {
      'questionId': questionId,
      'position': position,
      'text': text,
      'correctOption': correctOption,
      'explanation': explanation,
      'options': [
        {'label': 'A', 'text': 'one'},
        {'label': 'B', 'text': 'two'},
        {'label': 'C', 'text': 'three'},
        {'label': 'D', 'text': 'four'},
      ],
    };
  }

  test('P1-4.21/24/25 mapper builds snapshot-backed reviews', () {
    final detail = TestAttemptCloudMapper.detailFromFirestore('attempt-1', {
      'id': 'attempt-1',
      'uid': 'student-a',
      'testId': 'test-1',
      'courseId': 'group-iii',
      'status': 'submitted',
      'score': 1,
      'percentage': 50,
      'accuracy': 50,
      'correct': 1,
      'wrong': 1,
      'skipped': 0,
      'totalQuestions': 2,
      'timeSpentSeconds': 30,
      'passed': false,
      'authority': 'server_verified',
      'snapshotSchemaVersion': 1,
      'questionSnapshots': [
        snapshotDoc(
          questionId: 'q1',
          text: 'Frozen Q1',
          correctOption: 'A',
          position: 0,
        ),
        snapshotDoc(
          questionId: 'q2',
          text: 'Frozen Q2',
          correctOption: 'B',
          position: 1,
        ),
      ],
      'answers': [
        {'questionId': 'q1', 'selectedOption': 'B', 'answered': true},
        {'questionId': 'q2', 'selectedOption': 'B', 'answered': true},
      ],
    });

    expect(detail, isNotNull);
    expect(detail!.hasImmutableQuestionReview, isTrue);
    final reviews = detail.buildQuestionReviews();
    expect(reviews, hasLength(2));
    expect(reviews[0].snapshot.text, 'Frozen Q1');
    expect(reviews[0].snapshot.correctOption, 'A');
    expect(reviews[0].selectedOption, 'B');
    expect(reviews[0].isCorrect, isFalse);
    expect(reviews[1].isCorrect, isTrue);
  });

  test('P1-4.22/23 current question mutation / deletion does not affect review', () {
    final detail = TestAttemptHistoryDetail(
      summary: summary(attemptId: 'attempt-1'),
      questionSnapshots: [
        HistoricalQuestionSnapshot(
          questionId: 'deleted-q',
          text: 'Still reviewable',
          options: const [
            HistoricalQuestionOption(label: 'A', text: 'one'),
            HistoricalQuestionOption(label: 'B', text: 'two'),
          ],
          correctOption: 'A',
          explanation: 'Frozen',
          position: 0,
        ),
      ],
      answers: const [
        HistoricalAnswerRecord(
          questionId: 'deleted-q',
          selectedOption: 'A',
          answered: true,
        ),
      ],
    );

    final reviews = detail.buildQuestionReviews();
    expect(reviews.single.snapshot.text, 'Still reviewable');
    expect(reviews.single.snapshot.correctOption, 'A');
    expect(reviews.single.isCorrect, isTrue);
  });

  test('P1-4.26 legacy attempt remains supported without review', () {
    final detail = TestAttemptCloudMapper.detailFromFirestore('legacy-1', {
      'id': 'legacy-1',
      'uid': 'student-a',
      'testId': 'test-1',
      'courseId': 'group-ii',
      'status': 'submitted',
      'score': 1,
      'percentage': 100,
      'accuracy': 100,
      'correct': 1,
      'wrong': 0,
      'skipped': 0,
      'totalQuestions': 1,
      'timeSpentSeconds': 10,
      'passed': true,
    });
    expect(detail, isNotNull);
    expect(detail!.summary.hasImmutableSnapshot, isFalse);
    expect(detail.hasImmutableQuestionReview, isFalse);
    expect(detail.buildQuestionReviews(), isEmpty);
  });

  testWidgets('P1-4 history detail opens snapshot review', (tester) async {
    final detail = TestAttemptHistoryDetail(
      summary: summary(attemptId: 'attempt-ui'),
      questionSnapshots: [
        HistoricalQuestionSnapshot(
          questionId: 'q1',
          text: 'Immutable question body',
          options: const [
            HistoricalQuestionOption(label: 'A', text: 'one'),
            HistoricalQuestionOption(label: 'B', text: 'two'),
          ],
          correctOption: 'A',
          explanation: 'Because A',
          position: 0,
        ),
      ],
      answers: const [
        HistoricalAnswerRecord(
          questionId: 'q1',
          selectedOption: 'B',
          answered: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TestAttemptHistoryDetailScreen(
          item: detail.summary,
          preloadedDetail: detail,
        ),
      ),
    );
    await tester.pump();

    final reviewButton = find.text('Question Review');
    expect(reviewButton, findsOneWidget);
    await tester.ensureVisible(reviewButton);
    await tester.pump();
    await tester.tap(reviewButton);
    await tester.pump();
    await tester.pump();

    expect(find.byType(TestAttemptHistoricalReviewScreen), findsOneWidget);
    expect(find.text('Immutable question body'), findsOneWidget);
    expect(find.text('Correct answer: A'), findsOneWidget);
    expect(find.text('Your answer: B'), findsOneWidget);
    expect(find.text('Because A'), findsOneWidget);
  });

  testWidgets('P1-4 legacy detail shows legacy message', (tester) async {
    final item = summary(attemptId: 'legacy-ui', snapshotSchemaVersion: null);

    await tester.pumpWidget(
      MaterialApp(
        home: TestAttemptHistoryDetailScreen(
          item: item,
          preloadedDetail: TestAttemptHistoryDetail(summary: item),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining('Legacy attempt'),
      findsOneWidget,
    );
    expect(find.text('Question Review'), findsNothing);
  });
}
