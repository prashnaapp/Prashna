import '../../course_enrollment/model/course.dart';
import '../../course_enrollment/service/course_catalog_service.dart';
import '../../question_bank/data/models/question_models.dart';
import '../../question_bank/data/question_cloud_mapper.dart';
import '../../question_bank/repository/question_cloud_repository.dart';
import '../../syllabus/services/syllabus_service.dart';

/// Admin-only orchestration for Question Bank content.
///
/// Student-facing [QuestionService] remains read/preparation-only. All writes
/// still reach Firestore through the existing QuestionCloudRepository and are
/// authorized by the Firebase Auth `admin` custom claim in Firestore rules.
class AdminQuestionService {
  AdminQuestionService({
    QuestionCloudRepository? questionRepository,
    CourseCatalogService? courseCatalogService,
  }) : _questions = questionRepository ?? QuestionCloudRepository(),
       _courses = courseCatalogService;

  static final AdminQuestionService instance = AdminQuestionService();

  final QuestionCloudRepository _questions;
  final CourseCatalogService? _courses;

  Future<List<Course>> loadCourses() {
    return (_courses ?? CourseCatalogService()).loadPublishedCourses();
  }

  Future<List<Question>> loadQuestions(String courseId) {
    final id = courseId.trim();
    if (id.isEmpty) {
      throw const FormatException('Select a course before loading questions.');
    }
    return _questions.loadQuestions(
      filter: QuestionFilter(courseId: id, activeOnly: false),
    );
  }

  Future<Question?> getQuestion(String questionId) {
    return _questions.getQuestionById(questionId);
  }

  List<String> validate(Question question, {String? documentId}) {
    final errors = QuestionCloudMapper.validateForWrite(
      question,
      documentId: documentId,
    );
    if (question.status != null) {
      errors.addAll(_validateCanonicalAdminQuestion(question));
    }
    return errors;
  }

  Future<String> createQuestion(Question question) {
    // The repository generates the ID. A non-empty sentinel validates all
    // content without allowing a client-provided ID to drift.
    final errors = validate(question, documentId: 'generated-on-create');
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }
    return _questions.createQuestion(question);
  }

  Future<void> updateQuestion(Question question) {
    final errors = validate(question, documentId: question.id);
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }
    return _questions.updateQuestion(question);
  }

  Future<void> deactivateQuestion(String questionId) {
    return _questions.setQuestionActive(questionId, isActive: false);
  }

  Future<void> reactivateQuestion(String questionId) {
    return _questions.setQuestionActive(questionId, isActive: true);
  }

  Future<void> setStatus(String questionId, QuestionPublicationStatus status) {
    return _questions.setQuestionStatus(questionId, status);
  }

  List<String> _validateCanonicalAdminQuestion(Question question) {
    final errors = <String>[];
    final content = question.content;
    final syllabus = question.syllabus;
    if (content == null) {
      errors.add('Bilingual content is required.');
      return errors;
    }
    if (content.en.question.trim().isEmpty) {
      errors.add('English question is required.');
    }
    if (content.te?.question.trim().isEmpty != false) {
      errors.add('Telugu question is required.');
    }
    final isStatement =
        question.resolvedItemFormat == QuestionItemFormat.statementMcq;
    if (content.en.options.length != 4) {
      errors.add('Exactly four English options are required.');
    }
    if (content.en.options.any((option) => option.text.trim().isEmpty)) {
      errors.add('English options cannot be empty.');
    }
    if (!isStatement) {
      if (content.te?.options.length != 4) {
        errors.add('Exactly four Telugu options are required.');
      }
      if (content.te?.options.any((option) => option.text.trim().isEmpty) !=
          false) {
        errors.add('Telugu options cannot be empty.');
      }
    }
    if (isStatement) {
      final englishStatements = content.en.statements;
      final teluguStatements = content.te?.statements ?? const <String>[];
      if (englishStatements.isEmpty) {
        errors.add('At least one statement is required.');
      }
      if (englishStatements.any((statement) => statement.trim().isEmpty)) {
        errors.add('English text is required for every statement.');
      }
      if (teluguStatements.length != englishStatements.length) {
        errors.add('English and Telugu statement counts must match.');
      }
      if (teluguStatements.any((statement) => statement.trim().isEmpty)) {
        errors.add('Telugu text is required for every statement.');
      }
    }
    if (content.en.explanation.trim().isEmpty) {
      errors.add('English explanation is required.');
    }
    if (content.te?.explanation.trim().isEmpty != false) {
      errors.add('Telugu explanation is required.');
    }
    if (!const ['A', 'B', 'C', 'D'].contains(question.correctOption)) {
      errors.add('Correct answer must be A, B, C, or D.');
    }
    if (syllabus == null) {
      errors.add('Canonical syllabus attribution is required.');
      return errors;
    }
    if (question.courseId.trim() == 'group-iii') {
      errors.addAll(_validateGroupIiiSyllabus(syllabus));
      return errors;
    }
    if (syllabus.paperId == 'group-ii-paper-i') {
      if (syllabus.majorStudyAreaId == null ||
          syllabus.contentTopicId == null ||
          syllabus.partId != null ||
          syllabus.lessonId != null ||
          syllabus.syllabusUnitId != null) {
        errors.add('Paper I requires Major Study Area and Content Topic only.');
      }
    } else if (syllabus.partId == null || syllabus.topicId == null) {
      errors.add('Papers II–IV require Part and Topic attribution.');
    } else if (syllabus.syllabusUnitId != null) {
      errors.add('Group-II questions must not use syllabusUnitId.');
    }
    return errors;
  }

  List<String> _validateGroupIiiSyllabus(QuestionSyllabusAttribution syllabus) {
    final errors = <String>[];
    final paperId = syllabus.paperId.trim();
    if (paperId.isEmpty) {
      errors.add('Paper is required.');
      return errors;
    }
    if (syllabus.majorStudyAreaId != null ||
        syllabus.contentTopicId != null ||
        syllabus.topicId != null ||
        syllabus.lessonId != null) {
      errors.add(
        'Group-III questions use Paper / Part / Syllabus Unit only '
        '(no Topic or Lesson).',
      );
    }

    final paper = SyllabusService.instance.getPaper(
      courseId: 'group-iii',
      paperId: paperId,
    );
    if (paper == null) {
      errors.add('Unknown Group-III paper "$paperId".');
      return errors;
    }

    final unitId = syllabus.syllabusUnitId?.trim();
    if (unitId == null || unitId.isEmpty) {
      errors.add('Syllabus Unit is required for Group-III.');
      return errors;
    }

    if (paper.hasDirectSyllabusUnits) {
      if (syllabus.partId != null && syllabus.partId!.trim().isNotEmpty) {
        errors.add('Group-III Paper-I must not include partId.');
      }
      final known = paper.syllabusUnits.any((unit) => unit.id == unitId);
      if (!known) {
        errors.add('Unknown Syllabus Unit "$unitId" for Paper-I.');
      }
      return errors;
    }

    if (paper.hasPartSyllabusUnits) {
      final partId = syllabus.partId?.trim();
      if (partId == null || partId.isEmpty) {
        errors.add('Part is required for this Group-III paper.');
        return errors;
      }
      final part = SyllabusService.instance.getPart(
        courseId: 'group-iii',
        paperId: paperId,
        partId: partId,
      );
      if (part == null) {
        errors.add('Unknown Part "$partId".');
        return errors;
      }
      final known = part.syllabusUnits.any((unit) => unit.id == unitId);
      if (!known) {
        errors.add('Unknown Syllabus Unit "$unitId" for the selected Part.');
      }
      return errors;
    }

    errors.add('Paper has no Group-III syllabus units.');
    return errors;
  }
}
