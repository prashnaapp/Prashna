import '../../course_enrollment/model/course.dart';
import '../../course_enrollment/service/course_catalog_service.dart';
import '../../question_bank/data/models/question_models.dart';
import '../../question_bank/repository/question_cloud_repository.dart';
import '../../tests/data/models/test_models.dart';
import '../../tests/data/test_cloud_mapper.dart';
import '../../tests/repository/test_cloud_repository.dart';
import '../../syllabus/data/models/syllabus_models.dart';
import '../../syllabus/services/syllabus_service.dart';

/// Admin-only orchestration for Test Series definitions.
///
/// Student-facing catalog [TestService] remains read-only. All writes reach
/// Firestore through [TestCloudRepository] and are authorized by the Firebase
/// Auth `admin` custom claim in Firestore rules.
class AdminTestService {
  AdminTestService({
    TestCloudRepository? testRepository,
    QuestionCloudRepository? questionRepository,
    CourseCatalogService? courseCatalogService,
  }) : _tests = testRepository ?? TestCloudRepository(),
       _questions = questionRepository ?? QuestionCloudRepository(),
       _courses = courseCatalogService;

  static final AdminTestService instance = AdminTestService();

  final TestCloudRepository _tests;
  final QuestionCloudRepository _questions;
  final CourseCatalogService? _courses;

  Future<List<Course>> loadCourses() {
    return (_courses ?? CourseCatalogService()).loadPublishedCourses();
  }

  Future<List<TestModel>> loadTests(String courseId) {
    final id = courseId.trim();
    if (id.isEmpty) {
      throw const FormatException('Select a course before loading tests.');
    }
    return _tests.loadAdminTests(id);
  }

  Future<TestModel?> getTest(String testId) {
    return _tests.getAdminTestById(testId);
  }

  List<String> validate(TestModel test, {String? documentId}) {
    final errors = TestCloudMapper.validateForWrite(
      test,
      documentId: documentId,
    );
    errors.addAll(_validateSyllabusLocation(test));
    return errors;
  }

  Future<String> createTest(TestModel test) async {
    final draft = TestModel(
      id: test.id,
      examId: test.examId,
      category: test.category,
      title: test.title,
      description: test.description,
      questionCount: test.questionCount,
      marks: test.marks,
      durationMinutes: test.durationMinutes,
      negativeMarking: test.negativeMarking,
      difficulty: test.difficulty,
      questionIds: test.questionIds,
      status: TestPublicationStatus.draft,
      paperId: test.paperId,
      partId: test.partId,
      syllabusUnitId: test.syllabusUnitId,
      year: test.year,
      seriesId: test.seriesId,
    );
    final errors = validate(draft, documentId: 'generated-on-create');
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }
    await _validateAssignedQuestions(draft);
    return _tests.createTest(draft);
  }

  Future<void> updateTest(TestModel test) async {
    final errors = validate(test, documentId: test.id);
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }
    await _validateAssignedQuestions(test);
    await _tests.updateTest(test);
  }

  Future<void> publishTest(String testId) async {
    final id = testId.trim();
    if (id.isEmpty) {
      throw const FormatException('Test ID is required.');
    }

    // Never trust the model that was rendered in the list. Re-read the
    // authoritative admin document immediately before changing visibility.
    final current = await _tests.getAdminTestById(id);
    if (current == null) {
      throw const FormatException('Test was not found.');
    }
    if (current.status == TestPublicationStatus.archived) {
      throw const FormatException('Archived tests cannot be published.');
    }

    final errors = TestCloudMapper.validateForPublication(
      current,
      documentId: id,
    );
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }

    await _tests.setTestStatus(id, TestPublicationStatus.published);
  }

  Future<void> unpublishTest(String testId) {
    return _tests.setTestStatus(testId, TestPublicationStatus.draft);
  }

  Future<void> archiveTest(String testId) {
    return _tests.setTestStatus(testId, TestPublicationStatus.archived);
  }

  Future<void> setStatus(String testId, TestPublicationStatus status) async {
    if (status == TestPublicationStatus.published) {
      await publishTest(testId);
      return;
    }
    await _tests.setTestStatus(testId, status);
  }

  /// Filter-based question ID selection for building fixed tests.
  Future<List<String>> findQuestionIds({
    required String courseId,
    String? paperId,
    String? partId,
    String? topicId,
    String? lessonId,
    String? syllabusUnitId,
    String? majorStudyAreaId,
    String? contentTopicId,
  }) async {
    final questions = await _questions.loadQuestions(
      filter: QuestionFilter(
        courseId: courseId,
        paperId: paperId,
        partId: partId,
        topicId: topicId,
        lessonId: lessonId,
        syllabusUnitId: syllabusUnitId,
        majorStudyAreaId: majorStudyAreaId,
        contentTopicId: contentTopicId,
        activeOnly: true,
      ),
    );
    return [for (final question in questions) question.id];
  }

  /// Published questions whose canonical chapter/topic equals [syllabusUnitId].
  ///
  /// Group-II Paper I stores that identity on `majorStudyAreaId`. Group-II
  /// Papers II–IV store it on `topicId`. Group-III stores `syllabusUnitId`.
  /// Matching uses [Question.canonicalScope], never titles.
  Future<List<String>> findQuestionIdsForChapterTest({
    required String courseId,
    required String paperId,
    String? partId,
    required String syllabusUnitId,
  }) async {
    final unitId = syllabusUnitId.trim();
    if (unitId.isEmpty) return const [];
    final questions = await _questions.loadQuestions(
      filter: QuestionFilter(
        courseId: courseId,
        paperId: paperId,
        partId: partId,
        activeOnly: true,
      ),
    );
    return [
      for (final question in questions)
        if (questionMatchesChapterUnit(question, unitId)) question.id,
    ];
  }

  /// Canonical Chapter/Topic identity for assignment. Not raw Firestore
  /// `syllabusUnitId`, which Group-II questions are forbidden from storing.
  static bool questionMatchesChapterUnit(Question question, String unitId) {
    return question.canonicalScope?.syllabusUnitId == unitId;
  }

  List<String> _validateSyllabusLocation(TestModel test) {
    final errors = <String>[];
    final courseId = test.examId.trim();
    final paperId = test.paperId?.trim();
    final partId = test.partId?.trim();
    final unitId = test.syllabusUnitId?.trim();
    final seriesId = test.seriesId?.trim();

    if (courseId.isEmpty) return errors;
    if (SyllabusService.instance.getCourseById(courseId) == null) {
      errors.add('Course "$courseId" is not in the syllabus catalog.');
      return errors;
    }

    switch (test.category) {
      case TestCategoryType.partTests:
        return _validatePaperAndOptionalPart(
          courseId: courseId,
          paperId: paperId,
          partId: partId,
          unitId: unitId,
          paperRequired: true,
          partRequiredIfPaperHasParts: true,
          unitRequired: false,
        );
      case TestCategoryType.mockTests:
        if (seriesId == null || seriesId.isEmpty) {
          errors.add('Grand Test group is required.');
        }
        errors.addAll(
          _validatePaperAndOptionalPart(
            courseId: courseId,
            paperId: paperId,
            partId: partId,
            unitId: unitId,
            paperRequired: true,
            partRequiredIfPaperHasParts: false,
            unitRequired: false,
          ),
        );
        return errors;
      case TestCategoryType.previousYear:
        final year = test.year;
        if (year == null || year < 1900 || year > 2100) {
          errors.add('A valid exam year is required.');
        }
        errors.addAll(
          _validatePaperAndOptionalPart(
            courseId: courseId,
            paperId: paperId,
            partId: partId,
            unitId: unitId,
            paperRequired: true,
            partRequiredIfPaperHasParts: false,
            unitRequired: false,
          ),
        );
        return errors;
      case TestCategoryType.chapterTests:
      case TestCategoryType.paperTests:
        break;
    }

    final hasLocation = [
      paperId,
      partId,
      unitId,
    ].any((value) => value != null && value.isNotEmpty);
    if (!hasLocation) return errors; // Legacy tests remain valid.

    errors.addAll(
      _validatePaperAndOptionalPart(
        courseId: courseId,
        paperId: paperId,
        partId: partId,
        unitId: unitId,
        paperRequired: true,
        partRequiredIfPaperHasParts: true,
        unitRequired: true,
      ),
    );
    return errors;
  }

  List<String> _validatePaperAndOptionalPart({
    required String courseId,
    required String? paperId,
    required String? partId,
    required String? unitId,
    required bool paperRequired,
    required bool partRequiredIfPaperHasParts,
    required bool unitRequired,
  }) {
    final errors = <String>[];
    if (paperId == null || paperId.isEmpty) {
      if (paperRequired) {
        errors.add('Paper is required when a syllabus location is specified.');
      }
      return errors;
    }
    final paper = SyllabusService.instance.getPaper(
      courseId: courseId,
      paperId: paperId,
    );
    if (paper == null) {
      errors.add('Paper "$paperId" does not belong to course "$courseId".');
      return errors;
    }

    final usesParts = paper.parts.isNotEmpty;
    if (partRequiredIfPaperHasParts &&
        usesParts &&
        (partId == null || partId.isEmpty)) {
      errors.add('Part is required for paper "$paperId".');
      return errors;
    }
    if (!usesParts && partId != null && partId.isNotEmpty) {
      errors.add('Paper "$paperId" does not have Parts.');
    }

    SyllabusPart? part;
    if (partId != null && partId.isNotEmpty) {
      part = SyllabusService.instance.getPart(
        courseId: courseId,
        paperId: paperId,
        partId: partId,
      );
      if (part == null) {
        errors.add('Part "$partId" does not belong to paper "$paperId".');
      }
    }

    if (unitId == null || unitId.isEmpty) {
      if (unitRequired) {
        errors.add('Syllabus Unit is required when a location is specified.');
      }
      return errors;
    }

    final validUnit = part != null
        ? part.syllabusUnits.any((unit) => unit.id == unitId)
        : paper.syllabusUnits.any((unit) => unit.id == unitId);
    if (!validUnit) {
      errors.add(
        'Syllabus Unit "$unitId" does not belong to the selected '
        '${part == null ? 'Paper' : 'Part'}.',
      );
    }
    return errors;
  }

  Future<void> _validateAssignedQuestions(TestModel test) async {
    if (test.questionIds.isEmpty) return;

    final questions = await _questions.getByIds(test.questionIds);
    final byId = {for (final question in questions) question.id: question};
    final errors = <String>[];
    for (final id in test.questionIds) {
      final question = byId[id];
      if (question == null) {
        errors.add('Question "$id" does not exist.');
        continue;
      }
      if (!question.isActive) {
        errors.add('Question "$id" is inactive.');
      }
      if (question.courseId != test.examId) {
        errors.add('Question "$id" belongs to another course.');
      }
      if (test.paperId != null &&
          test.paperId!.isNotEmpty &&
          question.paperId != test.paperId) {
        errors.add('Question "$id" does not match the test paper.');
      }
      if (test.partId != null &&
          test.partId!.isNotEmpty &&
          question.partId != test.partId) {
        errors.add('Question "$id" does not match the test part.');
      }
      if (test.syllabusUnitId != null && test.syllabusUnitId!.isNotEmpty) {
        if (!questionMatchesChapterUnit(question, test.syllabusUnitId!)) {
          errors.add(
            'This question belongs to another Chapter/Topic and cannot be '
            'added to this test. (Question "$id")',
          );
        }
      }
    }
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }
  }
}
