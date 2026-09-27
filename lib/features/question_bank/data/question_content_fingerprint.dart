import 'models/question_models.dart';

/// Canonical normalized content fingerprint.
///
/// This is the same algorithm previously inlined on the import record.
/// `courseId` and `paperId` stay in the fingerprint. `testId` and assignment
/// do not. Do not add a second normalization.
abstract final class QuestionContentFingerprint {
  static String compute({
    required String courseId,
    required String paperId,
    String? itemFormat,
    required String questionEn,
    required String questionTe,
    required String correctOption,
    required List<({String en, String te})> options,
    required List<({String en, String te})> statements,
  }) {
    final optionText = [
      for (final option in options) '${option.en.trim()}|${option.te.trim()}',
    ].join('||');
    final statementText = [
      for (final statement in statements)
        '${statement.en.trim()}|${statement.te.trim()}',
    ].join('||');
    return [
      courseId.trim().toLowerCase(),
      paperId.trim().toLowerCase(),
      (itemFormat ?? 'standard_mcq').trim().toLowerCase(),
      questionEn.trim().toLowerCase(),
      questionTe.trim(),
      correctOption.trim().toUpperCase(),
      optionText.toLowerCase(),
      statementText.toLowerCase(),
    ].join('::');
  }

  static String fromQuestion(Question question) {
    final content = question.content;
    final enOptions = content != null
        ? [for (final option in content.en.options) option.text]
        : question.options;
    final teOptions = content?.te == null
        ? const <String>[]
        : [for (final option in content!.te!.options) option.text];
    final enStatements = content?.en.statements ?? const <String>[];
    final teStatements = content?.te?.statements ?? const <String>[];
    final statementCount = enStatements.length > teStatements.length
        ? enStatements.length
        : teStatements.length;
    return compute(
      courseId: question.courseId,
      paperId: question.paperId,
      itemFormat: _formatValue(question.resolvedItemFormat),
      questionEn: content?.en.question.trim().isNotEmpty == true
          ? content!.en.question
          : question.question,
      questionTe: content?.te?.question ?? '',
      correctOption: question.correctOption,
      options: [
        for (var i = 0; i < enOptions.length; i++)
          (en: enOptions[i], te: i < teOptions.length ? teOptions[i] : ''),
      ],
      statements: [
        for (var i = 0; i < statementCount; i++)
          (
            en: i < enStatements.length ? enStatements[i] : '',
            te: i < teStatements.length ? teStatements[i] : '',
          ),
      ],
    );
  }

  static String _formatValue(QuestionItemFormat format) {
    switch (format) {
      case QuestionItemFormat.standardMcq:
        return 'standard_mcq';
      case QuestionItemFormat.statementMcq:
        return 'statement_mcq';
    }
  }
}
