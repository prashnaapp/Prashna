import '../../question_bank/repository/question_cloud_repository.dart';
import '../../syllabus/services/syllabus_service.dart';
import '../data/models/question_import_models.dart';
import 'question_import_parser.dart';
import 'question_import_validator.dart';

/// Admin bulk-import orchestration.
///
/// Validate never writes. Import writes only after a fully valid batch and
/// always creates draft/inactive questions through [QuestionCloudRepository].
class QuestionImportService {
  QuestionImportService({
    QuestionCloudRepository? questionRepository,
    SyllabusService? syllabusService,
    QuestionImportValidator? validator,
  }) : this._(
         questionRepository ?? QuestionCloudRepository(),
         syllabusService,
         validator,
       );

  QuestionImportService._(
    QuestionCloudRepository questions,
    SyllabusService? syllabusService,
    QuestionImportValidator? validator,
  ) : _questions = questions,
      _validator =
          validator ??
          QuestionImportValidator(
            questionRepository: questions,
            syllabusService: syllabusService,
          );

  final QuestionCloudRepository _questions;
  final QuestionImportValidator _validator;

  /// Parses JSON and validates without writing Firestore.
  Future<QuestionImportValidationResult> validateJson(String rawJson) async {
    final records = QuestionImportParser.parseJson(rawJson);
    return _validator.validate(records);
  }

  Future<QuestionImportValidationResult> validateRecords(
    List<QuestionImportRecord> records,
  ) {
    return _validator.validate(records);
  }

  /// Imports only when the entire batch is valid. Never auto-publishes.
  Future<QuestionImportReport> importValidatedBatch(
    QuestionImportValidationResult validation,
  ) async {
    if (!validation.canImport) {
      return QuestionImportReport(
        recordsSubmitted: validation.totalRecords,
        recordsImported: 0,
        recordsRejected: validation.totalRecords,
        createdQuestionIds: const [],
        duplicates: [
          for (final index in validation.duplicateOrCollisionRecords)
            QuestionImportIssue(
              recordIndex: index,
              field: 'id',
              message: 'Duplicate or collision blocked import.',
            ),
        ],
        warnings: validation.warnings,
        failureMessage:
            'Import blocked: fix validation errors before importing.',
      );
    }

    try {
      final createdIds = await _questions.createQuestionsBatch(
        validation.validatedQuestions,
      );
      if (createdIds.length != validation.validatedQuestions.length) {
        return QuestionImportReport(
          recordsSubmitted: validation.totalRecords,
          recordsImported: 0,
          recordsRejected: validation.totalRecords,
          createdQuestionIds: const [],
          duplicates: const [],
          warnings: validation.warnings,
          failureMessage:
              'Import failed: batch write did not create every question.',
        );
      }
      return QuestionImportReport(
        recordsSubmitted: validation.totalRecords,
        recordsImported: createdIds.length,
        recordsRejected: 0,
        createdQuestionIds: createdIds,
        duplicates: const [],
        warnings: validation.warnings,
      );
    } catch (error) {
      return QuestionImportReport(
        recordsSubmitted: validation.totalRecords,
        recordsImported: 0,
        recordsRejected: validation.totalRecords,
        createdQuestionIds: const [],
        duplicates: const [],
        warnings: validation.warnings,
        failureMessage: 'Import failed: $error',
      );
    }
  }

  /// Convenience path: validate JSON then import only if fully valid.
  Future<QuestionImportReport> validateAndImportJson(String rawJson) async {
    final validation = await validateJson(rawJson);
    return importValidatedBatch(validation);
  }
}
