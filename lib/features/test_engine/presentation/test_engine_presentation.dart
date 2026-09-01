/// Presentation-only labels for the live attempt and result screens.
///
/// Values are always supplied by the existing controller/result objects.
abstract final class TestEnginePresentation {
  static String questionProgressLabel({
    required int questionNumber,
    required int totalQuestions,
  }) {
    return 'Question $questionNumber of $totalQuestions';
  }

  static String timeTakenLabel(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
