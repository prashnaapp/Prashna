import 'test_attempt_history.dart';

/// Immutable question content revealed after submit for historical review.
class HistoricalQuestionSnapshot {
  const HistoricalQuestionSnapshot({
    required this.questionId,
    required this.text,
    required this.options,
    required this.correctOption,
    this.explanation,
    this.position,
  });

  final String questionId;
  final String text;
  final List<HistoricalQuestionOption> options;
  final String correctOption;
  final String? explanation;
  final int? position;
}

class HistoricalQuestionOption {
  const HistoricalQuestionOption({
    required this.label,
    required this.text,
  });

  final String label;
  final String text;
}

class HistoricalAnswerRecord {
  const HistoricalAnswerRecord({
    required this.questionId,
    this.selectedOption,
    this.answered = false,
  });

  final String questionId;
  final String? selectedOption;
  final bool answered;
}

/// One frozen question + the student's recorded answer for history review.
class HistoricalQuestionReviewItem {
  const HistoricalQuestionReviewItem({
    required this.snapshot,
    required this.selectedOption,
    required this.answered,
    required this.isCorrect,
    required this.isSkipped,
  });

  final HistoricalQuestionSnapshot snapshot;
  final String? selectedOption;
  final bool answered;
  final bool isCorrect;
  final bool isSkipped;
}

/// Full attempt payload for history detail / question review.
class TestAttemptHistoryDetail {
  const TestAttemptHistoryDetail({
    required this.summary,
    this.questionSnapshots = const [],
    this.answers = const [],
  });

  final TestAttemptHistoryItem summary;
  final List<HistoricalQuestionSnapshot> questionSnapshots;
  final List<HistoricalAnswerRecord> answers;

  bool get hasImmutableQuestionReview =>
      summary.hasImmutableSnapshot && questionSnapshots.isNotEmpty;

  List<HistoricalQuestionReviewItem> buildQuestionReviews() {
    if (!hasImmutableQuestionReview) return const [];
    final byId = {
      for (final answer in answers) answer.questionId: answer,
    };
    final ordered = [...questionSnapshots]
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

    return [
      for (final snapshot in ordered)
        _reviewFor(snapshot, byId[snapshot.questionId]),
    ];
  }

  HistoricalQuestionReviewItem _reviewFor(
    HistoricalQuestionSnapshot snapshot,
    HistoricalAnswerRecord? answer,
  ) {
    final selected = answer?.selectedOption?.trim();
    final answered =
        answer?.answered == true ||
        (selected != null && selected.isNotEmpty);
    final isSkipped = !answered;
    final isCorrect =
        answered &&
        selected != null &&
        selected.toUpperCase() == snapshot.correctOption.toUpperCase();
    return HistoricalQuestionReviewItem(
      snapshot: snapshot,
      selectedOption: selected,
      answered: answered,
      isCorrect: isCorrect,
      isSkipped: isSkipped,
    );
  }
}
