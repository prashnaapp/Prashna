import '../../question_bank/data/models/question_models.dart';
import '../../question_bank/repository/question_cloud_repository.dart';
import '../../syllabus/data/models/syllabus_models.dart';
import '../../syllabus/services/syllabus_service.dart';
import '../data/models/question_import_models.dart';

/// Pure validation for bulk question import. Performs no Firestore writes.
class QuestionImportValidator {
  QuestionImportValidator({
    QuestionCloudRepository? questionRepository,
    SyllabusService? syllabusService,
  }) : _questions = questionRepository,
       _syllabus = syllabusService ?? SyllabusService.instance;

  final QuestionCloudRepository? _questions;
  final SyllabusService _syllabus;

  Future<QuestionImportValidationResult> validate(
    List<QuestionImportRecord> records,
  ) async {
    final errors = <QuestionImportIssue>[];
    final warnings = <QuestionImportIssue>[];
    final duplicateOrCollision = <int>{};
    final validated = <Question>[];
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
      _validateSyllabus(record, i, recordErrors);

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

      final fingerprint = record.contentFingerprint;
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
        validated.add(_toQuestion(record));
      } else {
        errors.addAll(recordErrors);
      }
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
      if (option.te.trim().isEmpty) {
        errors.add(
          QuestionImportIssue(
            recordIndex: index,
            field: 'options[$i].te',
            message: 'Missing Telugu option',
          ),
        );
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
    if (topic.lessons.isNotEmpty) {
      if (lessonId == null || lessonId.isEmpty) {
        errors.add(
          QuestionImportIssue(
            recordIndex: index,
            field: 'lessonId',
            message: 'Lesson is required for this Topic.',
          ),
        );
        return;
      }
      final lessonExists = topic.lessons.any((lesson) => lesson.id == lessonId);
      if (!lessonExists) {
        errors.add(
          QuestionImportIssue(
            recordIndex: index,
            field: 'lessonId',
            message: 'Unknown Lesson "$lessonId".',
          ),
        );
      }
    } else if (lessonId != null && lessonId.isNotEmpty) {
      errors.add(
        QuestionImportIssue(
          recordIndex: index,
          field: 'lessonId',
          message: 'Lesson is not applicable for this Topic.',
        ),
      );
    }
  }

  Question _toQuestion(QuestionImportRecord record) {
    final now = DateTime.now();
    final correct = record.correctOption.trim().toUpperCase();
    final englishOptions = [
      for (final option in record.options) option.en.trim(),
    ];
    final content = QuestionContent(
      en: QuestionLocalizedContent(
        question: record.question.en.trim(),
        options: [
          for (final option in record.options)
            QuestionOption(text: option.en.trim()),
        ],
        explanation: record.explanation.en.trim(),
      ),
      te: QuestionLocalizedContent(
        question: record.question.te.trim(),
        options: [
          for (final option in record.options)
            QuestionOption(text: option.te.trim()),
        ],
        explanation: record.explanation.te.trim(),
      ),
    );
    final paper = _syllabus.getPaper(
      courseId: record.courseId.trim(),
      paperId: record.paperId.trim(),
    );
    final isGroupIii = record.courseId.trim() == 'group-iii';
    final isPaperI = !isGroupIii && paper?.hasCanonicalPaperIContent == true;
    return Question(
      id: record.id?.trim() ?? '',
      courseId: record.courseId.trim(),
      paperId: record.paperId.trim(),
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
      content: content,
      syllabus: QuestionSyllabusAttribution(
        courseId: record.courseId.trim(),
        paperId: record.paperId.trim(),
        majorStudyAreaId: isPaperI ? record.majorStudyAreaId?.trim() : null,
        contentTopicId: isPaperI ? record.contentTopicId?.trim() : null,
        partId: isPaperI || (isGroupIii && paper?.hasDirectSyllabusUnits == true)
            ? null
            : record.partId?.trim(),
        topicId: isPaperI || isGroupIii ? null : record.topicId?.trim(),
        lessonId: isPaperI || isGroupIii ? null : record.lessonId?.trim(),
        syllabusUnitId: isGroupIii ? record.syllabusUnitId?.trim() : null,
      ),
    );
  }
}
