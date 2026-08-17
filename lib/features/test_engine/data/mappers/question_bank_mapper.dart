import '../../../question_bank/data/models/question_models.dart';
import '../models/test_engine_models.dart';

/// Maps Question Bank entities into Test Engine attempt models.
abstract final class QuestionBankMapper {
  static const _labels = ['A', 'B', 'C', 'D', 'E'];

  static TestQuestion toTestQuestion(Question question) {
    final englishOptions = question.options.isNotEmpty
        ? question.options
        : question.content?.en.options.map((option) => option.text).toList() ??
              const <String>[];
    final teluguOptions = question.content?.te?.options;
    return TestQuestion(
      id: question.id,
      text: question.question.isNotEmpty
          ? question.question
          : question.content?.en.question ?? '',
      options: [
        for (var i = 0; i < englishOptions.length; i++)
          TestOption(
            label: _labels[i.clamp(0, _labels.length - 1)],
            text: englishOptions[i],
            teluguText: teluguOptions != null && i < teluguOptions.length
                ? teluguOptions[i].text
                : null,
          ),
      ],
      correctOption: question.correctOption,
      explanation: question.explanation.isNotEmpty
          ? question.explanation
          : question.content?.en.explanation ?? '',
      paperId: question.paperId,
      sectionId: question.sectionId,
      topicId: question.topicId,
      content: question.content,
      syllabus: question.syllabus,
    );
  }

  static List<TestQuestion> toTestQuestions(List<Question> questions) {
    return [for (final question in questions) toTestQuestion(question)];
  }

  static QuestionType? questionTypeForMode(TestMode mode) {
    switch (mode) {
      case TestMode.practice:
      case TestMode.topic:
      case TestMode.section:
      case TestMode.paper:
        return QuestionType.practice;
      case TestMode.previousYear:
        return QuestionType.previousYear;
      case TestMode.mock:
      case TestMode.grand:
        return QuestionType.mock;
    }
  }
}
