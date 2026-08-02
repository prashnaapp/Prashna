import '../../question_bank/data/models/question_models.dart' as bank;
import '../../question_bank/data/repositories/question_repository.dart';
import 'models/question_models.dart';

/// Legacy practice quiz adapter — Question Bank is the only question source.
abstract final class DummyQuestions {
  static const int timerSeconds = 60;

  static List<QuestionModel>? _cache;

  static int get totalCount => all.length;

  static List<QuestionModel> get all {
    _cache ??= _mapFromBank();
    return _cache!;
  }

  static QuestionModel at(int index) => all[index.clamp(0, all.length - 1)];

  static List<QuestionModel> _mapFromBank() {
    final questions = QuestionRepository.instance.loadQuestionsSync(
      filter: const bank.QuestionFilter(
        questionType: bank.QuestionType.practice,
      ),
    );

    const labels = ['A', 'B', 'C', 'D', 'E'];
    return [
      for (final q in questions)
        QuestionModel(
          id: q.id,
          question: q.question,
          options: [
            for (var i = 0; i < q.options.length; i++)
              OptionModel(
                label: labels[i.clamp(0, labels.length - 1)],
                text: q.options[i],
              ),
          ],
          correctOption: q.correctOption,
          explanation: q.explanation,
        ),
    ];
  }
}
