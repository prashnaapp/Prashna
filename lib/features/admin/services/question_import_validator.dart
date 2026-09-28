import '../../question_bank/data/models/question_models.dart';
import '../../question_bank/data/question_content_fingerprint.dart';
import '../../question_bank/repository/question_cloud_repository.dart';
import '../../syllabus/data/models/syllabus_models.dart';
import '../../syllabus/services/syllabus_service.dart';
import '../../tests/data/models/test_models.dart';
import '../data/admin_chapter_question_context.dart';
import '../data/admin_compatible_test_query.dart';
import '../data/admin_question_scope.dart';
import '../data/admin_test_series_question_query.dart';
import '../data/models/question_import_models.dart';
import 'admin_question_test_assignment.dart';

/// Pure validation for bulk question import. Performs no Firestore writes.
class QuestionImportValidator {
  QuestionImportValidator({
    QuestionCloudRepository? questionRepository,
    SyllabusService? syllabusService,
    this.scope,
    this.chapterContext,
    this.loadTest,
  }) : _questions = questionRepository,
       _syllabus = syllabusService ?? SyllabusService.instance;

  final QuestionCloudRepository? _questions;
  final SyllabusService _syllabus;
  final AdminQuestionScope? scope;
  final AdminChapterQuestionContext? chapterContext;
  final Future<TestModel?> Function(String testId)? loadTest;

  bool get _lockedBank => scope?.isQuestionBank ?? false;

  Future<QuestionImportValidationResult> validate(
    List<QuestionImportRecord> records,
  ) async {
    final errors = <QuestionImportIssue>[];
    final warnings = <QuestionImportIssue>[];
    final duplicateOrCollision = <int>{};
    final validated = <Question>[];
    final assignTestIds = <String?>[];
    final sourceIndexes = <int>[];
    final seenIds = <String, int>{};
    final seenFingerprints = <String, int>{};

    final suppliedIds = <String>[
      for (final record in records)
        if (record.id != null && record.id!.trim().isNotEmpty)
          record.id!.trim(),
    ];
    final existingById = await _loadExistingIds(suppliedIds);

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      final recordErrors = <QuestionImportIssue>[];

      _validateContent(record, i, recordErrors);
      final chapterRecord = _lockedBank
          ? record
          : _lockChapterContext(record, i, recordErrors);
      if (_lockedBank) {
        _validateLockedOwnership(record, i, recordErrors);
      } else {
        _validateChapterOwnership(chapterRecord, i, recordErrors);
        _validateSyllabus(chapterRecord, i, recordErrors);
      }

      final id = record.id?.trim();
      if (id != null && id.isNotEmpty) {
        final previous = seenIds[id];
        if (previous != null) {
          recordErrors.add(
            QuestionImportIssue(
              recordIndex: i,
              field: 'id',
              message:
                  'Duplicate ID "$id" also used by Record ${previous + 1}.',
            ),
          );
          duplicateOrCollision.add(i);
          duplicateOrCollision.add(previous);
        } else {
          seenIds[id] = i;
        }
        if (existingById.contains(id)) {
          recordErrors.add(
            QuestionImportIssue(
              recordIndex: i,
              field: 'id',
              message: 'Collides with an existing question ID.',
            ),
          );
          duplicateOrCollision.add(i);
        }
      }

      final question = _toQuestion(chapterRecord);
      final fingerprint = QuestionContentFingerprint.fromQuestion(question);
      final previousFingerprint = seenFingerprints[fingerprint];
      if (previousFingerprint != null) {
        warnings.add(
          QuestionImportIssue(
            recordIndex: i,
            field: 'question',
            message: 'Content duplicate of Record ${previousFingerprint + 1}.',
            isWarning: true,
          ),
        );
        duplicateOrCollision.add(i);
        duplicateOrCollision.add(previousFingerprint);
      } else {
        seenFingerprints[fingerprint] = i;
      }

      if (recordErrors.isEmpty) {
        validated.add(question);
        assignTestIds.add(_lockedBank ? record.testId?.trim() : null);
        sourceIndexes.add(i);
      } else {
        errors.addAll(recordErrors);
      }
    }

    if (_lockedBank) {
      await _rejectExistingFingerprints(
        errors,
        validated,
        assignTestIds,
        sourceIndexes,
      );
      await _validateTestAssignments(
        errors,
        validated,
        assignTestIds,
        sourceIndexes,
      );
    } else {
      await _rejectExistingFingerprints(
        errors,
        validated,
        assignTestIds,
        sourceIndexes,
      );
    }

    final invalidCount = records.length - validated.length;
    return QuestionImportValidationResult(
      totalRecords: records.length,
      validRecords: validated.length,
      invalidRecords: invalidCount,
      errors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
      duplicateOrCollisionRecords: duplicateOrCollision.toList(growable: false)
        ..sort(),
      validatedQuestions: List.unmodifiable(validated),
      assignTestIds: List.unmodifiable(assignTestIds),
    );
  }

  Future<Set<String>> _loadExistingIds(List<String> ids) async {
    final repo = _questions;
    if (repo == null || ids.isEmpty) return const {};
    final unique = ids.toSet().toList(growable: false);
    final existing = await repo.getByIds(unique);
    return {for (final question in existing) question.id};
  }

  void _validateContent(
    QuestionImportRecord record,
    int index,
    List<QuestionImportIssue> errors,
  ) {
    if (record.question.en.trim().isEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'question.en',
          message: 'Missing English question',
        ),
      );
    }
    if (record.question.te.trim().isEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'question.te',
          message: 'Missing Telugu question',
        ),
      );
    }
    if (record.options.length != 4) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'options',
          message: 'Exactly four option pairs are required.',
        ),
      );
    }
    for (var i = 0; i < record.options.length; i++) {
      final option = record.options[i];
      if (option.en.trim().isEmpty) {
        errors.add(
          QuestionImportIssue(
            recordIndex: index,
            field: 'options[$i].en',
            message: 'Missing English option',
          ),
        );
      }
      final requireTelugu =
          !record.isStatementMcq || _statementHasTeluguOptions(record);
      if (requireTelugu && option.te.trim().isEmpty) {
        errors.add(
          QuestionImportIssue(
            recordIndex: index,
            field: 'options[$i].te',
            message: 'Missing Telugu option',
          ),
        );
      }
    }
    final format = record.itemFormat ?? 'standard_mcq';
    if (format != 'standard_mcq' && format != 'statement_mcq') {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'itemFormat',
          message: 'Unsupported question format "$format".',
        ),
      );
    }
    if (record.isStatementMcq) {
      if (record.statements.isEmpty) {
        errors.add(
          QuestionImportIssue(
            recordIndex: index,
            field: 'statements',
            message:
                'Statement-based questions require at least one statement.',
          ),
        );
      }
      for (var i = 0; i < record.statements.length; i++) {
        final statement = record.statements[i];
        if (statement.en.trim().isEmpty || statement.te.trim().isEmpty) {
          errors.add(
            QuestionImportIssue(
              recordIndex: index,
              field: 'statements[$i]',
              message:
                  'English and Telugu text are required for every statement.',
            ),
          );
        }
      }
    }
    final correct = record.correctOption.trim().toUpperCase();
    if (!const ['A', 'B', 'C', 'D'].contains(correct)) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'correctOption',
          message: 'Invalid correct answer. Must be A, B, C, or D.',
        ),
      );
    }
    if (record.explanation.en.trim().isEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'explanation.en',
          message: 'Missing English explanation',
        ),
      );
    }
    if (record.explanation.te.trim().isEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'explanation.te',
          message: 'Missing Telugu explanation',
        ),
      );
    }
  }

  void _validateSyllabus(
    QuestionImportRecord record,
    int index,
    List<QuestionImportIssue> errors,
  ) {
    final courseId = record.courseId.trim();
    final paperId = record.paperId.trim();
    if (courseId.isEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'courseId',
          message: 'Course is required.',
        ),
      );
      return;
    }
    if (paperId.isEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'paperId',
          message: 'Paper is required.',
        ),
      );
      return;
    }

    final course = _syllabus.getCourseById(courseId);
    if (course == null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'courseId',
          message: 'Unknown course "$courseId".',
        ),
      );
      return;
    }
    final paper = _syllabus.getPaper(courseId: courseId, paperId: paperId);
    if (paper == null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'paperId',
          message: 'Unknown paper "$paperId" for course "$courseId".',
        ),
      );
      return;
    }

    if (courseId == 'group-iii') {
      _validateGroupIii(record, paper, index, errors);
    } else if (paper.hasCanonicalPaperIContent) {
      _validatePaperI(record, paper, index, errors);
    } else if (paper.hasCanonicalParts) {
      _validatePartBased(record, paper, index, errors);
    } else {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'paperId',
          message: 'Paper has no canonical syllabus mapping.',
        ),
      );
    }
  }

  void _validateGroupIii(
    QuestionImportRecord record,
    SyllabusPaper paper,
    int index,
    List<QuestionImportIssue> errors,
  ) {
    if (record.majorStudyAreaId != null ||
        record.contentTopicId != null ||
        record.topicId != null ||
        record.lessonId != null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'syllabusUnitId',
          message:
              'Group-III forbids Topic/Lesson/Major Study Area fields; '
              'use Paper / Part / Syllabus Unit.',
        ),
      );
    }

    final unitId = record.syllabusUnitId?.trim();
    if (unitId == null || unitId.isEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'syllabusUnitId',
          message: 'Syllabus Unit is required for Group-III.',
        ),
      );
      return;
    }

    if (paper.hasDirectSyllabusUnits) {
      if (record.partId != null && record.partId!.trim().isNotEmpty) {
        errors.add(
          QuestionImportIssue(
            recordIndex: index,
            field: 'partId',
            message: 'Group-III Paper-I forbids partId.',
          ),
        );
      }
      final known = paper.syllabusUnits.any((unit) => unit.id == unitId);
      if (!known) {
        errors.add(
          QuestionImportIssue(
            recordIndex: index,
            field: 'syllabusUnitId',
            message: 'Unknown Syllabus Unit "$unitId".',
          ),
        );
      }
      return;
    }

    if (paper.hasPartSyllabusUnits) {
      final partId = record.partId?.trim();
      if (partId == null || partId.isEmpty) {
        errors.add(
          QuestionImportIssue(
            recordIndex: index,
            field: 'partId',
            message: 'Part is required for this Group-III paper.',
          ),
        );
        return;
      }
      SyllabusPart? part;
      for (final candidate in paper.parts) {
        if (candidate.id == partId) {
          part = candidate;
          break;
        }
      }
      if (part == null) {
        errors.add(
          QuestionImportIssue(
            recordIndex: index,
            field: 'partId',
            message: 'Unknown Part "$partId".',
          ),
        );
        return;
      }
      final known = part.syllabusUnits.any((unit) => unit.id == unitId);
      if (!known) {
        errors.add(
          QuestionImportIssue(
            recordIndex: index,
            field: 'syllabusUnitId',
            message: 'Unknown Syllabus Unit "$unitId".',
          ),
        );
      }
      return;
    }

    errors.add(
      QuestionImportIssue(
        recordIndex: index,
        field: 'paperId',
        message: 'Paper has no Group-III syllabus units.',
      ),
    );
  }

  void _validatePaperI(
    QuestionImportRecord record,
    SyllabusPaper paper,
    int index,
    List<QuestionImportIssue> errors,
  ) {
    if (record.partId != null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'partId',
          message: 'Paper I forbids partId.',
        ),
      );
    }
    if (record.lessonId != null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'lessonId',
          message: 'Paper I forbids lessonId.',
        ),
      );
    }
    if (record.topicId != null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'topicId',
          message: 'Paper I forbids part-based topicId.',
        ),
      );
    }
    if (record.syllabusUnitId != null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'syllabusUnitId',
          message: 'Group-II Paper I forbids syllabusUnitId.',
        ),
      );
    }
    final areaId = record.majorStudyAreaId?.trim();
    final topicId = record.contentTopicId?.trim();
    if (areaId == null || areaId.isEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'majorStudyAreaId',
          message: 'Major Study Area is required for Paper I.',
        ),
      );
      return;
    }
    if (topicId == null || topicId.isEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'contentTopicId',
          message: 'Content Topic is required for Paper I.',
        ),
      );
      return;
    }
    SyllabusMajorStudyArea? area;
    for (final candidate in paper.majorStudyAreas) {
      if (candidate.id == areaId) {
        area = candidate;
        break;
      }
    }
    if (area == null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'majorStudyAreaId',
          message: 'Unknown Major Study Area "$areaId".',
        ),
      );
      return;
    }
    final topicExists = area.contentTopics.any((topic) => topic.id == topicId);
    if (!topicExists) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'contentTopicId',
          message: 'Unknown Content Topic "$topicId".',
        ),
      );
    }
  }

  void _validatePartBased(
    QuestionImportRecord record,
    SyllabusPaper paper,
    int index,
    List<QuestionImportIssue> errors,
  ) {
    if (record.syllabusUnitId != null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'syllabusUnitId',
          message: 'Group-II Papers II–IV forbid syllabusUnitId.',
        ),
      );
    }
    if (record.majorStudyAreaId != null || record.contentTopicId != null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'majorStudyAreaId',
          message: 'Papers II–IV forbid Paper I majorStudyArea/contentTopic.',
        ),
      );
    }
    final partId = record.partId?.trim();
    final topicId = record.topicId?.trim();
    final lessonId = record.lessonId?.trim();
    if (partId == null || partId.isEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'partId',
          message: 'Part is required for Papers II–IV.',
        ),
      );
      return;
    }
    if (topicId == null || topicId.isEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'topicId',
          message: 'Topic is required for Papers II–IV.',
        ),
      );
      return;
    }
    SyllabusPart? part;
    for (final candidate in paper.parts) {
      if (candidate.id == partId) {
        part = candidate;
        break;
      }
    }
    if (part == null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'partId',
          message: 'Unknown Part "$partId".',
        ),
      );
      return;
    }
    SyllabusTopic? topic;
    for (final candidate in part.topics) {
      if (candidate.id == topicId) {
        topic = candidate;
        break;
      }
    }
    if (topic == null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'topicId',
          message: 'Unknown Topic "$topicId".',
        ),
      );
      return;
    }
    if (lessonId != null && lessonId.isNotEmpty) {
      if (topic.lessons.isEmpty) {
        errors.add(
          QuestionImportIssue(
            recordIndex: index,
            field: 'lessonId',
            message: 'Lesson is not applicable for this Topic.',
          ),
        );
      } else {
        final lessonExists = topic.lessons.any(
          (lesson) => lesson.id == lessonId,
        );

        if (!lessonExists) {
          errors.add(
            QuestionImportIssue(
              recordIndex: index,
              field: 'lessonId',
              message: 'Unknown Lesson "$lessonId".',
            ),
          );
        }
      }
    }
  }

  bool _statementHasTeluguOptions(QuestionImportRecord record) {
    return record.options.any((option) => option.te.trim().isNotEmpty);
  }

  QuestionImportRecord _lockChapterContext(
    QuestionImportRecord record,
    int index,
    List<QuestionImportIssue> errors,
  ) {
    final chapter = chapterContext;
    if (chapter == null) return record;

    void conflict(String field) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: field,
          message: 'JSON cannot override the selected chapter.',
        ),
      );
    }

    String lockedText(String supplied, String? selected, String field) {
      final value = supplied.trim();
      final locked = selected?.trim() ?? '';
      if (value.isNotEmpty && locked.isNotEmpty && value != locked) {
        conflict(field);
      }
      return locked.isNotEmpty ? locked : value;
    }

    String? lockedOptional(String? supplied, String? selected, String field) {
      final value = supplied?.trim() ?? '';
      final locked = selected?.trim() ?? '';
      if (value.isNotEmpty && locked.isNotEmpty && value != locked) {
        conflict(field);
      }
      if (locked.isNotEmpty) return locked;
      return value.isEmpty ? null : value;
    }

    return QuestionImportRecord(
      id: record.id,
      courseId: lockedText(record.courseId, chapter.courseId, 'courseId'),
      paperId: lockedText(record.paperId, chapter.paperId, 'paperId'),
      majorStudyAreaId: lockedOptional(
        record.majorStudyAreaId,
        chapter.majorStudyAreaId,
        'majorStudyAreaId',
      ),
      contentTopicId: lockedOptional(
        record.contentTopicId,
        chapter.contentTopicId,
        'contentTopicId',
      ),
      partId: lockedOptional(record.partId, chapter.partId, 'partId'),
      topicId: lockedOptional(record.topicId, chapter.topicId, 'topicId'),
      lessonId: record.lessonId,
      syllabusUnitId: lockedOptional(
        record.syllabusUnitId,
        chapter.syllabusUnitId,
        'syllabusUnitId',
      ),
      question: record.question,
      options: record.options,
      correctOption: record.correctOption,
      explanation: record.explanation,
      itemFormat: record.itemFormat,
      statements: record.statements,
      testId: record.testId,
      contentArea: record.contentArea,
      testSeriesCategory: record.testSeriesCategory,
      seriesId: record.seriesId,
      year: record.year,
    );
  }

  void _validateChapterOwnership(
    QuestionImportRecord record,
    int index,
    List<QuestionImportIssue> errors,
  ) {
    if (record.contentArea != null ||
        record.testSeriesCategory != null ||
        record.seriesId != null ||
        record.year != null) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'contentArea',
          message:
              'Test Series ownership is only allowed from a Test Series question bank.',
        ),
      );
    }
    if (record.testId != null && record.testId!.trim().isNotEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'testId',
          message:
              'testId assignment is supported only from a Test Series question bank.',
        ),
      );
    }
  }

  void _validateLockedOwnership(
    QuestionImportRecord record,
    int index,
    List<QuestionImportIssue> errors,
  ) {
    final bank = scope!;
    void conflict(String field, String message) {
      errors.add(
        QuestionImportIssue(recordIndex: index, field: field, message: message),
      );
    }

    if (record.contentArea != null &&
        record.contentArea != AdminQuestionScope.contentAreaTestSeries) {
      conflict(
        'contentArea',
        'JSON cannot override the selected question bank.',
      );
    }
    if (record.testSeriesCategory != null &&
        record.testSeriesCategory != bank.testSeriesCategory) {
      conflict(
        'testSeriesCategory',
        'JSON cannot override the selected question bank.',
      );
    }
    if (record.courseId.trim().isNotEmpty &&
        record.courseId.trim() != bank.courseId) {
      conflict('courseId', 'JSON cannot override the selected question bank.');
    }
    switch (bank.testSeriesCategory) {
      case AdminQuestionScope.categoryPart:
        if (record.paperId.trim().isNotEmpty &&
            record.paperId.trim() != bank.paperId) {
          conflict(
            'paperId',
            'JSON cannot override the selected question bank.',
          );
        }
        if (record.seriesId != null || record.year != null) {
          conflict(
            'seriesId',
            'JSON cannot override the selected question bank.',
          );
        }
      case AdminQuestionScope.categoryMock:
        if (record.paperId.trim().isNotEmpty || record.year != null) {
          conflict(
            'paperId',
            'JSON cannot override the selected question bank.',
          );
        }
        if (record.seriesId != null && record.seriesId != bank.seriesId) {
          conflict(
            'seriesId',
            'JSON cannot override the selected question bank.',
          );
        }
      case AdminQuestionScope.categoryPreviousYear:
        if (record.paperId.trim().isNotEmpty || record.seriesId != null) {
          conflict(
            'paperId',
            'JSON cannot override the selected question bank.',
          );
        }
        if (record.year != null && record.year != bank.year) {
          conflict('year', 'JSON cannot override the selected question bank.');
        }
    }
  }

  Future<void> _rejectExistingFingerprints(
    List<QuestionImportIssue> errors,
    List<Question> validated,
    List<String?> assignTestIds,
    List<int> sourceIndexes,
  ) async {
    final repository = _questions;
    if (repository == null || validated.isEmpty) return;
    final drop = <int>{};
    if (_lockedBank) {
      final found = await repository.findExistingContentFingerprints(
        fingerprints: [
          for (final question in validated)
            QuestionContentFingerprint.fromQuestion(question),
        ],
        equalityFilters: AdminTestSeriesQuestionQuery.fromScope(
          scope!,
        ).equalityFilters,
      );
      for (var i = 0; i < validated.length; i++) {
        final fingerprint = QuestionContentFingerprint.fromQuestion(
          validated[i],
        );
        if (!found.contains(fingerprint)) continue;
        errors.add(
          QuestionImportIssue(
            recordIndex: sourceIndexes[i],
            field: 'contentFingerprint',
            message: 'Exact duplicate already exists in this bank.',
          ),
        );
        drop.add(i);
      }
    } else {
      final groups = <String, List<int>>{};
      for (var i = 0; i < validated.length; i++) {
        final question = validated[i];
        final key = '${question.courseId}\u0000${question.paperId}';
        groups.putIfAbsent(key, () => []).add(i);
      }
      for (final indexes in groups.values) {
        final sample = validated[indexes.first];
        final found = await repository.findExistingContentFingerprints(
          fingerprints: [
            for (final index in indexes)
              QuestionContentFingerprint.fromQuestion(validated[index]),
          ],
          equalityFilters: [
            (field: 'courseId', value: sample.courseId),
            (field: 'paperId', value: sample.paperId),
          ],
        );
        for (final index in indexes) {
          final fingerprint = QuestionContentFingerprint.fromQuestion(
            validated[index],
          );
          if (!found.contains(fingerprint)) continue;
          errors.add(
            QuestionImportIssue(
              recordIndex: sourceIndexes[index],
              field: 'contentFingerprint',
              message: 'Exact duplicate already exists in this bank.',
            ),
          );
          drop.add(index);
        }
      }
    }
    if (drop.isEmpty) return;
    final keptQuestions = <Question>[];
    final keptIds = <String?>[];
    final keptSources = <int>[];
    for (var i = 0; i < validated.length; i++) {
      if (drop.contains(i)) continue;
      keptQuestions.add(validated[i]);
      keptIds.add(assignTestIds[i]);
      keptSources.add(sourceIndexes[i]);
    }
    validated
      ..clear()
      ..addAll(keptQuestions);
    assignTestIds
      ..clear()
      ..addAll(keptIds);
    sourceIndexes
      ..clear()
      ..addAll(keptSources);
  }

  Future<void> _validateTestAssignments(
    List<QuestionImportIssue> errors,
    List<Question> validated,
    List<String?> assignTestIds,
    List<int> sourceIndexes,
  ) async {
    final query = AdminCompatibleTestQuery.fromScope(scope!);
    final grouped = <String, List<int>>{};
    for (var i = 0; i < assignTestIds.length; i++) {
      final testId = assignTestIds[i]?.trim() ?? '';
      if (testId.isEmpty) {
        assignTestIds[i] = null;
        continue;
      }
      grouped.putIfAbsent(testId, () => []).add(i);
    }
    final drop = <int>{};
    for (final entry in grouped.entries) {
      final test = await loadTest?.call(entry.key);
      if (test == null) {
        for (final slot in entry.value) {
          errors.add(
            QuestionImportIssue(
              recordIndex: sourceIndexes[slot],
              field: 'testId',
              message: 'Unknown test "${entry.key}".',
            ),
          );
          drop.add(slot);
        }
        continue;
      }
      if (!query.matches(test)) {
        for (final slot in entry.value) {
          errors.add(
            QuestionImportIssue(
              recordIndex: sourceIndexes[slot],
              field: 'testId',
              message: 'Test "${entry.key}" is not compatible with this bank.',
            ),
          );
          drop.add(slot);
        }
        continue;
      }
      final room =
          AdminQuestionTestAssignment.maxAssignedQuestionsPerTest -
          test.questionIds.length;
      if (entry.value.length > room) {
        final overflow = entry.value.skip(room < 0 ? 0 : room);
        for (final slot in overflow) {
          errors.add(
            QuestionImportIssue(
              recordIndex: sourceIndexes[slot],
              field: 'testId',
              message:
                  'Test "${entry.key}" can assign at most '
                  '${AdminQuestionTestAssignment.maxAssignedQuestionsPerTest} questions.',
            ),
          );
          drop.add(slot);
        }
      }
    }
    if (drop.isEmpty) return;
    final keptQuestions = <Question>[];
    final keptIds = <String?>[];
    for (var i = 0; i < validated.length; i++) {
      if (drop.contains(i)) continue;
      keptQuestions.add(validated[i]);
      keptIds.add(assignTestIds[i]);
    }
    validated
      ..clear()
      ..addAll(keptQuestions);
    assignTestIds
      ..clear()
      ..addAll(keptIds);
  }

  Question _toQuestion(QuestionImportRecord record) {
    final now = DateTime.now();
    final correct = record.correctOption.trim().toUpperCase();
    final englishOptions = [
      for (final option in record.options) option.en.trim(),
    ];
    final statement = record.isStatementMcq;
    final omitTeluguOptions = statement && !_statementHasTeluguOptions(record);
    final bank = _lockedBank ? scope! : null;
    final courseId = bank?.courseId?.trim().isNotEmpty == true
        ? bank!.courseId!.trim()
        : record.courseId.trim();
    final paperId = bank == null
        ? record.paperId.trim()
        : (bank.testSeriesCategory == AdminQuestionScope.categoryPart
              ? (bank.paperId ?? '')
              : '');
    final content = QuestionContent(
      en: QuestionLocalizedContent(
        question: record.question.en.trim(),
        options: [
          for (final option in record.options)
            QuestionOption(text: option.en.trim()),
        ],
        explanation: record.explanation.en.trim(),
        statements: statement
            ? [for (final item in record.statements) item.en.trim()]
            : const [],
      ),
      te: QuestionLocalizedContent(
        question: record.question.te.trim(),
        options: omitTeluguOptions
            ? const []
            : [
                for (final option in record.options)
                  QuestionOption(text: option.te.trim()),
              ],
        explanation: record.explanation.te.trim(),
        statements: statement
            ? [for (final item in record.statements) item.te.trim()]
            : const [],
      ),
    );
    final paper = _syllabus.getPaper(courseId: courseId, paperId: paperId);
    final isGroupIii = courseId == 'group-iii';
    final isPaperI = !isGroupIii && paper?.hasCanonicalPaperIContent == true;
    return Question(
      id: record.id?.trim() ?? '',
      courseId: courseId,
      paperId: paperId,
      question: record.question.en.trim(),
      options: englishOptions,
      correctOption: correct,
      explanation: record.explanation.en.trim(),
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      language: 'en',
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      isActive: false,
      status: QuestionPublicationStatus.draft,
      year: bank?.testSeriesCategory == AdminQuestionScope.categoryPreviousYear
          ? bank!.year
          : null,
      itemFormat: statement
          ? QuestionItemFormat.statementMcq
          : QuestionItemFormat.standardMcq,
      content: content,
      syllabus: bank != null
          ? null
          : QuestionSyllabusAttribution(
              courseId: courseId,
              paperId: paperId,
              majorStudyAreaId: isPaperI
                  ? record.majorStudyAreaId?.trim()
                  : null,
              contentTopicId: isPaperI ? record.contentTopicId?.trim() : null,
              partId:
                  isPaperI ||
                      (isGroupIii && paper?.hasDirectSyllabusUnits == true)
                  ? null
                  : record.partId?.trim(),
              topicId: isPaperI || isGroupIii ? null : record.topicId?.trim(),
              lessonId: isPaperI || isGroupIii ? null : record.lessonId?.trim(),
              syllabusUnitId: isGroupIii ? record.syllabusUnitId?.trim() : null,
            ),
    );
  }
}
