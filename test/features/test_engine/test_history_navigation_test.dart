import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/profile/presentation/profile_navigation.dart';
import 'package:telangana_prep/features/profile/presentation/screens/profile_screen.dart';
import 'package:telangana_prep/features/profile/services/profile_service.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_attempt_history.dart';
import 'package:telangana_prep/features/test_engine/presentation/screens/test_attempt_history_detail_screen.dart';
import 'package:telangana_prep/features/test_engine/presentation/screens/test_attempt_history_screen.dart';
import 'package:telangana_prep/features/test_engine/repository/test_attempt_cloud_repository.dart';

void main() {
  TestAttemptHistoryItem item({
    required String attemptId,
    required String uid,
    String testTitle = 'Group-II Practice Test 1',
    String courseId = 'group-ii',
    double score = 8,
    double percentage = 80,
  }) {
    return TestAttemptHistoryItem(
      attemptId: attemptId,
      testId: 'test-$courseId-001',
      courseId: courseId,
      mode: 'topic',
      status: 'submitted',
      score: score,
      percentage: percentage,
      accuracy: percentage,
      correct: 8,
      wrong: 2,
      skipped: 0,
      totalQuestions: 10,
      timeSpentSeconds: 120,
      startedAt: DateTime(2026, 8, 15, 10),
      submittedAt: DateTime(2026, 8, 15, 10, 2),
      passed: percentage >= 40,
      uid: uid,
      testTitle: testTitle,
      courseTitle: courseId == 'group-ii' ? 'Group-II' : 'Group-III',
    );
  }

  setUp(() {
    ProfileService.skipAuthLookup = true;
  });

  tearDown(() {
    ProfileService.skipAuthLookup = false;
  });

  testWidgets('11: Test History appears in student Account navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    expect(find.text('Test History'), findsOneWidget);
    expect(find.byKey(const ValueKey('test-history-tile')), findsOneWidget);
    expect(find.text('View your completed test attempts'), findsOneWidget);
  });

  testWidgets('13: empty history shows a clean empty state', (tester) async {
    final repo = TestAttemptCloudRepository.withHandlers(
      currentUid: () => 'user-1',
      loader: ({courseId}) async => const [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => openTestHistory(context, repository: repo),
              child: const Text('open-history'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open-history'));
    await tester.pumpAndSettle();
    expect(find.byType(TestAttemptHistoryScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('history-empty')), findsOneWidget);
    expect(find.text('No attempts yet'), findsOneWidget);
  });

  testWidgets('12/14: history is user-scoped and opens existing detail', (
    tester,
  ) async {
    final repo = TestAttemptCloudRepository.withHandlers(
      currentUid: () => 'user-1',
      loader: ({courseId}) async => [item(attemptId: 'mine', uid: 'user-1')],
    );
    await tester.pumpWidget(
      MaterialApp(home: TestAttemptHistoryScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Group-II Practice Test 1'), findsOneWidget);
    expect(find.textContaining('Score 8'), findsOneWidget);
    expect(find.textContaining('80'), findsOneWidget);
    expect(find.text('submitted'), findsOneWidget);
    expect(find.text('someone-else-test'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('history-item-mine')));
    await tester.pumpAndSettle();
    expect(find.byType(TestAttemptHistoryDetailScreen), findsOneWidget);
    expect(find.text('Attempt Details'), findsOneWidget);
    expect(find.text('Group-II Practice Test 1'), findsOneWidget);
    expect(find.text('submitted'), findsOneWidget);
  });
}
