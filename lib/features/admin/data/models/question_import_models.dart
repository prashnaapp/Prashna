import '../../../question_bank/data/models/question_models.dart';

/// One bilingual option pair from a bulk import file.
class QuestionImportOption {
  const QuestionImportOption({required this.en, required this.te});

  final String en;
  final String te;
}

/// One bilingual localized string pair.
class QuestionImportLocalizedText {
  const QuestionImportLocalizedText({required this.en, required this.te});

  final String en;
  final String te;
}

/// Machine-readable import record. Maps 1:1 onto the canonical [Question].
class QuestionImportRecord {
  const QuestionImportRecord({
    this.id,
    required this.courseId,
    required this.paperId,
    this.majorStudyAreaId,
    this.contentTopicId,
    this.partId,
    this.topicId,
    this.lessonId,
    this.syllabusUnitId,
    required this.question,
    required this.options,
    required this.correctOption,
    required this.explanation,
  });

  final String? id;
  final String courseId;
  final String paperId;
  final String? majorStudyAreaId;
  final String? contentTopicId;
  final String? partId;
  final String? topicId;
  final String? lessonId;
  final String? syllabusUnitId;
  final QuestionImportLocalizedText question;
  final List<QuestionImportOption> options;
  final String correctOption;
  final QuestionImportLocalizedText explanation;

  /// Fingerprint used only for within-file content duplicate warnings.
  String get contentFingerprint {
    final optionText = [
      for (final option in options) '${option.en.trim()}|${option.te.trim()}',
    ].join('||');
    return [
      courseId.trim().toLowerCase(),
      paperId.trim().toLowerCase(),
      question.en.trim().toLowerCase(),
      question.te.trim(),
      correctOption.trim().toUpperCase(),
      optionText.toLowerCase(),
    ].join('::');
  }
}

class QuestionImportIssue {
  const QuestionImportIssue({
    required this.recordIndex,
    required this.field,
    required this.message,
    this.isWarning = false,
  });

  /// Zero-based index into the import file.
  final int recordIndex;

  final String field;
  final String message;
  final bool isWarning;

  /// Display index is 1-based for admin readability.
  String get display => 'Record ${recordIndex + 1}\n$field\n$message';
}

class QuestionImportValidationResult {
  const QuestionImportValidationResult({
    required this.totalRecords,
    required this.validRecords,
    required this.invalidRecords,
    required this.errors,
    required this.warnings,
    required this.duplicateOrCollisionRecords,
    required this.validatedQuestions,
  });

  final int totalRecords;
  final int validRecords;
  final int invalidRecords;
  final List<QuestionImportIssue> errors;
  final List<QuestionImportIssue> warnings;
  final List<int> duplicateOrCollisionRecords;
  final List<Question> validatedQuestions;

  bool get canImport =>
      totalRecords > 0 &&
      errors.isEmpty &&
      validatedQuestions.length == totalRecords;
}

class QuestionImportReport {
  const QuestionImportReport({
    required this.recordsSubmitted,
    required this.recordsImported,
    required this.recordsRejected,
    required this.createdQuestionIds,
    required this.duplicates,
    required this.warnings,
    this.failureMessage,
  });

  final int recordsSubmitted;
  final int recordsImported;
  final int recordsRejected;
  final List<String> createdQuestionIds;
  final List<QuestionImportIssue> duplicates;
  final List<QuestionImportIssue> warnings;
  final String? failureMessage;

  bool get succeeded =>
      failureMessage == null &&
      recordsImported == recordsSubmitted &&
      recordsRejected == 0;
}
