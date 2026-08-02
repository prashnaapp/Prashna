class OptionModel {
  const OptionModel({
    required this.label,
    required this.text,
  });

  final String label;
  final String text;
}

class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOption,
    required this.explanation,
  });

  final String id;
  final String question;
  final List<OptionModel> options;
  final String correctOption;
  final String explanation;

  OptionModel? optionByLabel(String label) {
    for (final option in options) {
      if (option.label == label) return option;
    }
    return null;
  }

  String get correctAnswerText =>
      optionByLabel(correctOption)?.text ?? correctOption;
}
