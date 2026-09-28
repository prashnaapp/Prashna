import '../../question_bank/repository/question_cloud_repository.dart';
import '../../syllabus/services/syllabus_service.dart';
import '../../tests/repository/test_cloud_repository.dart';
import '../data/admin_chapter_question_context.dart';
import '../data/admin_question_scope.dart';
import '../data/models/question_import_models.dart';
import 'admin_question_test_assignment.dart';
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
    AdminQuestionScope? scope,
    AdminChapterQuestionContext? chapterContext,
    TestCloudRepository? tests,
    AdminQuestionTestAssignment? assignment,
  }) : this._(
         questionRepository ?? QuestionCloudRepository(),
         syllabusService,
         validator,
         scope,
         chapterContext,
         tests,
         assignment,
       );

  QuestionImportService._(
    QuestionCloudRepository questions,
    SyllabusService? syllabusService,
    QuestionImportValidator? validator,
    this.scope,
    this.chapterContext,
    TestCloudRepository? tests,
    AdminQuestionTestAssignment? assignment,
  ) : _questions = questions,
      _assignment = assignment ?? AdminQuestionTestAssignment(tests: tests),
      _validator =
          validator ??
          QuestionImportValidator(
            questionRepository: questions,
            syllabusService: syllabusService,
            scope: scope,
            chapterContext: chapterContext,
            loadTest:
                (tests ??
                        (scope?.isQuestionBank == true
                            ? TestCloudRepository()
                            : null))
                    ?.getAdminTestById,
          );

  final QuestionCloudRepository _questions;
  final QuestionImportValidator _validator;
  final AdminQuestionScope? scope;
  final AdminChapterQuestionContext? chapterContext;
  final AdminQuestionTestAssignment _assignment;

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
        ownership: scope,
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
      final assignmentFailure = await _assignCreatedQuestions(
        createdIds,
        validation.assignTestIds,
      );
      return QuestionImportReport(
        recordsSubmitted: validation.totalRecords,
        recordsImported: createdIds.length,
        recordsRejected: 0,
        createdQuestionIds: createdIds,
        duplicates: const [],
        warnings: validation.warnings,
        assignmentFailureMessage: assignmentFailure,
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

  /// Assigns in file order, one Test update at a time. A failure keeps every
  /// Question already created.
  Future<String?> _assignCreatedQuestions(
    List<String> createdIds,
    List<String?> testIds,
  ) async {
    final bank = scope;
    if (bank == null || !bank.isQuestionBank || testIds.isEmpty) return null;
    final failures = <String>[];
    for (var i = 0; i < createdIds.length && i < testIds.length; i++) {
      final testId = testIds[i]?.trim() ?? '';
      if (testId.isEmpty) continue;
      try {
        await _assignment.assignCreatedQuestion(
          scope: bank,
          testId: testId,
          questionId: createdIds[i],
        );
      } catch (error) {
        failures.add(createdIds[i]);
      }
    }
    if (failures.isEmpty) return null;
    return 'Question import succeeded, but assignment failed for '
        '${failures.join(', ')}. Those questions remain in this bank and are '
        'not assigned.';
  }
}
