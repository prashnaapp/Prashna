import '../../question_bank/data/repositories/question_repository.dart';
import 'models/practice_models.dart';

abstract final class PracticeDummyData {
  static const instructions = [
    'Read every question carefully.',
    'You have 60 seconds for each question.',
    'Explanations are shown immediately after submission.',
    'Your progress is automatically saved.',
    'Results will be shown after completing all questions.',
  ];

  static PracticeSessionModel sessionForChapter(int chapterNumber) {
    final count = QuestionRepository.instance
        .loadQuestionsSync()
        .length
        .clamp(10, 35);
    return PracticeSessionModel(
      chapterLabel: 'Chapter $chapterNumber',
      questionCount: count,
      marks: count,
      timeLimitLabel: '$count Minutes',
      negativeMarking: 'No',
      difficulty: 'Medium',
    );
  }
}
