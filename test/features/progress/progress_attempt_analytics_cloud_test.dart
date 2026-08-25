import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/progress/data/repositories/progress_repository.dart';
import 'package:telangana_prep/features/progress/services/progress_service.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_attempt_history.dart';
import 'package:telangana_prep/features/test_engine/repository/test_attempt_cloud_repository.dart';

void main() {
  TestAttemptHistoryItem submitted({
    required String attemptId,
    String status = 'submitted',
    double score = 1,
    double percentage = 100,
    double accuracy = 100,
    int correct = 1,
    int wrong = 0,
    int skipped = 0,
    int totalQuestions = 1,
    int timeSpentSeconds = 42,
  }) {
    return TestAttemptHistoryItem(
      attemptId: attemptId,
      testId: 'test-group-ii-001',
      courseId: 'group-ii',
      mode: 'topic',
      status: status,
      score: score,
      percentage: percentage,
      accuracy: accuracy,
      correct: correct,
      wrong: wrong,
      skipped: skipped,
      totalQuestions: totalQuestions,
      timeSpentSeconds: timeSpentSeconds,
      startedAt: DateTime(2026, 8, 22, 10),
      submittedAt: DateTime(2026, 8, 22, 10, 1),
      passed: true,
      uid: 'user-1',
      testTitle: 'Group-II Practice Test 1',
      courseTitle: 'Group-II',
    );
  }

  test(
    'Attempt Analytics uses submitted test_attempts, ignores in_progress',
    () async {
      final service = ProgressService.debug(
        repository: ProgressRepository(seed: false),
        attemptCloudRepository: TestAttemptCloudRepository.withHandlers(
          currentUid: () => 'user-1',
          loader: ({courseId}) async => [
            submitted(attemptId: 'a-submitted'),
            submitted(attemptId: 'a-open', status: 'in_progress'),
          ],
        ),
      );

      final summary = await service.generateSummary();

      expect(summary.totalTests, 1);
      expect(summary.totalQuestions, 1);
      expect(summary.averageScore, 1.0);
      expect(summary.averageAccuracy, 100.0);
      expect(summary.averageTime, const Duration(seconds: 42));
      expect(summary.currentStreak, greaterThanOrEqualTo(0));
    },
  );

  test('empty submitted history yields zero Attempt Analytics', () async {
    final service = ProgressService.debug(
      repository: ProgressRepository(seed: false),
      attemptCloudRepository: TestAttemptCloudRepository.withHandlers(
        currentUid: () => 'user-1',
        loader: ({courseId}) async => const [],
      ),
    );

    final summary = await service.generateSummary();
    expect(summary.totalTests, 0);
    expect(summary.totalQuestions, 0);
    expect(summary.averageScore, 0);
    expect(summary.averageAccuracy, 0);
    expect(summary.averageTime, Duration.zero);
    expect(summary.currentStreak, 0);
  });
}
