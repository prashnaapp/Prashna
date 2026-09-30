import '../../course_enrollment/model/course.dart';
import '../../course_enrollment/service/course_catalog_service.dart';
import '../../question_bank/data/models/question_models.dart';
import '../../question_bank/repository/question_cloud_repository.dart';
import '../../tests/data/models/test_models.dart';
import '../../tests/data/test_cloud_mapper.dart';
import '../../tests/repository/test_cloud_repository.dart';
import '../../syllabus/data/models/canonical_scope.dart';
import '../../syllabus/data/models/syllabus_models.dart';
import '../../syllabus/services/syllabus_service.dart';
import '../data/admin_chapter_question_query.dart';
import '../data/admin_content_callable_client.dart';
import '../debug/admin_perf_trace.dart';
import '../data/admin_question_scope.dart';
import '../data/admin_test_series_question_query.dart';
import 'admin_question_test_assignment.dart';

/// Draft creation succeeded, then the Manage Questions assignment update failed.
///
/// The draft is left in place. Questions are not deleted.
class InitialQuestionAssignmentException implements Exception {
  const InitialQuestionAssignmentException(this.testId);

  final String testId;

  static const message =
      'Draft created, but initial Question assignment failed.';

  @override
  String toString() => message;
}

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
  List<Course>? _coursesCache;
  final Map<String, List<TestModel>> _testsCache = {};

  Future<List<Course>> loadCourses() {
    return AdminPerfTrace.span('hierarchy.courses', () async {
      if (_coursesCache != null) return _coursesCache!;
      final courses = await (_courses ?? CourseCatalogService())
          .loadPublishedCourses();
      _coursesCache = courses;
      return courses;
    });
  }

  Future<List<TestModel>> loadTests(String courseId) {
    return AdminPerfTrace.span('hierarchy.tests', () async {
      final id = courseId.trim();
      if (id.isEmpty) {
        throw const FormatException('Select a course before loading tests.');
      }
      if (_testsCache.containsKey(id)) return _testsCache[id]!;
      final tests = await _tests.loadAdminTests(id);
      _testsCache[id] = tests;
      return tests;
    });
  }

  /// Course catalog and one course's tests are independent reads.
  Future<({List<Course> courses, List<TestModel> tests})> loadHierarchy({
    String? courseId,
  }) {
    return AdminPerfTrace.span('hierarchy.navigation', () async {
      final id = courseId?.trim();
      if (id == null || id.isEmpty) {
        return (
          courses: await loadCourses(),
          tests: const <TestModel>[],
        );
      }
      final results = await Future.wait([
        loadCourses(),
        loadTests(id),
      ]);
      return (
        courses: results[0] as List<Course>,
        tests: results[1] as List<TestModel>,
      );
    });
  }

  void _invalidateTestLists() => _testsCache.clear();

  Future<TestModel?> getTest(String testId) {
    return _tests.getAdminTestById(testId);
  }

  Future<List<Question>> loadQuestionsByIds(List<String> ids) {
    return _questions.getAdminByIds(ids);
  }

  Future<Map<String, String>> loadQuestionAssignmentOwners(List<String> ids) {
    return _questions.getQuestionAssignmentOwners(ids);
  }

  Future<AdminQuestionAssignmentState> loadQuestionAssignmentState(
    List<String> ids,
  ) {
    return _questions.getQuestionAssignmentState(ids);
  }

  /// Compatible, unassigned Questions for optional seeding on Test create.
  ///
  /// Uses the same bank query as Manage Questions, then drops Questions that
  /// are already owned by another Test. Chapter and Test Series banks stay
  /// separate.
  Future<QuestionBankPage> loadAvailableInitialQuestionPage(
    TestModel test, {
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) async {
    final page = await loadCompatibleQuestionPage(
      test,
      searchText: searchText,
      cursorDocumentId: cursorDocumentId,
      cursorSearchText: cursorSearchText,
    );
    final state = await loadQuestionAssignmentState([
      for (final question in page.questions) question.id,
    ]);
    return QuestionBankPage(
      questions: [
        for (final question in page.questions)
          if (_isAssignableQuestion(question) &&
              questionIsCompatibleWithTest(question, test) &&
              !questionIsOwnedElsewhere(state, question.id))
            question,
      ],
      hasMore: page.hasMore,
      cursorDocumentId: page.cursorDocumentId,
      cursorSearchText: page.cursorSearchText,
    );
  }

  /// Validates and orders optional initial Question IDs for one draft.
  ///
  /// Duplicates collapse to the first occurrence. An incompatible, missing,
  /// or already-owned ID fails the whole selection.
  Future<List<String>> normalizeInitialQuestionIds(
    TestModel test,
    List<String> rawIds,
  ) async {
    final ids = dedupeQuestionIds(rawIds);
    if (ids.length > AdminQuestionTestAssignment.maxAssignedQuestionsPerTest) {
      throw const FormatException('A Test can assign at most 160 Questions.');
    }
    if (ids.isEmpty) return const [];

    final questions = await loadQuestionsByIds(ids);
    final byId = {for (final question in questions) question.id: question};
    final state = await loadQuestionAssignmentState(ids);
    for (final id in ids) {
      final question = byId[id];
      if (question == null) {
        throw FormatException('Question "$id" does not exist.');
      }
      if (!_isAssignableQuestion(question)) {
        throw FormatException('Archived Question "$id" cannot be assigned.');
      }
      if (!questionIsCompatibleWithTest(question, test)) {
        throw FormatException(
          'Question "$id" is not compatible with this Test.',
        );
      }
      if (questionIsOwnedElsewhere(state, id)) {
        throw FormatException(
          'Question "$id" is already assigned to another Test.',
        );
      }
    }
    return ids;
  }

  /// Validates manual Question IDs before adding them to an existing Test's
  /// staged membership. This is read-only; the authoritative write still
  /// happens once through [updateTest] when the Admin saves the final order.
  Future<List<String>> normalizeManagedQuestionIds(
    TestModel test,
    List<String> stagedIds,
    Iterable<String> rawIds,
  ) async {
    final ids = dedupeQuestionIds(rawIds);
    if (ids.isEmpty) {
      throw const FormatException('Enter at least one Question ID.');
    }
    final staged = stagedIds.toSet();
    for (final id in ids) {
      if (staged.contains(id)) {
        throw FormatException(
          'Question "$id" is already staged for this Test.',
        );
      }
    }
    if (staged.length + ids.length >
        AdminQuestionTestAssignment.maxAssignedQuestionsPerTest) {
      throw const FormatException('A Test can assign at most 160 Questions.');
    }

    final questions = await loadQuestionsByIds(ids);
    final byId = {for (final question in questions) question.id: question};
    final state = await loadQuestionAssignmentState(ids);
    final original = test.questionIds.toSet();
    for (final id in ids) {
      final question = byId[id];
      if (question == null) {
        throw FormatException('Question "$id" does not exist.');
      }
      if (!_isAssignableQuestion(question)) {
        throw FormatException('Archived Question "$id" cannot be assigned.');
      }
      if (!questionIsCompatibleWithTest(question, test)) {
        throw FormatException(
          'Question "$id" is not compatible with this Test.',
        );
      }

      final owner = state.owners[id]?.trim();
      if (owner != null && owner.isNotEmpty) {
        final validOriginalOwner = owner == test.id && original.contains(id);
        if (!validOriginalOwner) {
          if (owner == test.id) {
            throw FormatException(
              'Question "$id" has an ownership record conflict.',
            );
          }
          throw FormatException(
            'Question "$id" is already assigned to another Test.',
          );
        }
      }

      final references = state.legacyTestIds[id] ?? const <String>[];
      final conflictingReferences = references.where(
        (testId) => testId != test.id || !original.contains(id),
      );
      if (conflictingReferences.isNotEmpty) {
        throw FormatException(
          'Question "$id" is already referenced by another Test.',
        );
      }
    }
    return ids;
  }

  /// Creates a draft with no Questions, then assigns [initialQuestionIds]
  /// through [updateTest] — the same callable transaction as Manage Questions.
  Future<String> createDraftWithInitialQuestions(
    TestModel test, {
    List<String> initialQuestionIds = const [],
  }) async {
    final ids = await normalizeInitialQuestionIds(test, initialQuestionIds);
    final createdId = await createTest(_withoutQuestionIds(test));
    if (ids.isEmpty) return createdId;
    try {
      final created = await getTest(createdId);
      if (created == null) {
        throw const FormatException('Test was not found.');
      }
      await updateTest(_withQuestionIds(created, ids));
    } catch (error) {
      if (error is InitialQuestionAssignmentException) rethrow;
      throw InitialQuestionAssignmentException(createdId);
    }
    return createdId;
  }

  static List<String> dedupeQuestionIds(Iterable<String> rawIds) {
    final ids = <String>[];
    final seen = <String>{};
    for (final raw in rawIds) {
      for (final part in raw.split(RegExp(r'[\n,]'))) {
        final id = part.trim();
        if (id.isEmpty || !seen.add(id)) continue;
        ids.add(id);
      }
    }
    return ids;
  }

  static bool questionIsOwnedElsewhere(
    AdminQuestionAssignmentState state,
    String questionId,
  ) {
    final owner = state.owners[questionId]?.trim();
    if (owner != null && owner.isNotEmpty) return true;
    return state.legacyTestIds[questionId]?.isNotEmpty ?? false;
  }

  static bool questionIsCompatibleWithTest(Question question, TestModel test) {
    if (question.courseId.trim() != test.examId.trim()) return false;
    switch (test.category) {
      case TestCategoryType.partTests:
        return question.contentArea ==
                AdminQuestionScope.contentAreaTestSeries &&
            question.testSeriesCategory == AdminQuestionScope.categoryPart &&
            question.paperId == test.paperId;
      case TestCategoryType.mockTests:
        return question.contentArea ==
                AdminQuestionScope.contentAreaTestSeries &&
            question.testSeriesCategory == AdminQuestionScope.categoryMock &&
            question.seriesId == test.seriesId;
      case TestCategoryType.previousYear:
        return question.contentArea ==
                AdminQuestionScope.contentAreaTestSeries &&
            question.testSeriesCategory ==
                AdminQuestionScope.categoryPreviousYear &&
            question.year == test.year;
      case TestCategoryType.chapterTests:
      case TestCategoryType.paperTests:
        return question.contentArea == AdminQuestionScope.contentAreaChapter &&
            questionMatchesChapterTest(question, test);
    }
  }

  static bool _isAssignableQuestion(Question question) {
    return question.status != QuestionPublicationStatus.archived;
  }

  static TestModel _withoutQuestionIds(TestModel test) {
    return TestModel(
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
      questionIds: const [],
      status: TestPublicationStatus.draft,
      paperId: test.paperId,
      partId: test.partId,
      syllabusUnitId: test.syllabusUnitId,
      majorStudyAreaId: test.majorStudyAreaId,
      contentTopicId: test.contentTopicId,
      canonicalTopicId: test.canonicalTopicId,
      lessonId: test.lessonId,
      scopeShape: test.scopeShape,
      year: test.year,
      seriesId: test.seriesId,
    );
  }

  static TestModel _withQuestionIds(TestModel test, List<String> ids) {
    return TestModel(
      id: test.id,
      examId: test.examId,
      category: test.category,
      title: test.title,
      description: test.description,
      questionCount: ids.length,
      marks: test.marks,
      durationMinutes: test.durationMinutes,
      negativeMarking: test.negativeMarking,
      difficulty: test.difficulty,
      questionIds: ids,
      status: test.status,
      paperId: test.paperId,
      partId: test.partId,
      syllabusUnitId: test.syllabusUnitId,
      majorStudyAreaId: test.majorStudyAreaId,
      contentTopicId: test.contentTopicId,
      canonicalTopicId: test.canonicalTopicId,
      lessonId: test.lessonId,
      scopeShape: test.scopeShape,
      year: test.year,
      seriesId: test.seriesId,
    );
  }

  Future<QuestionBankPage> loadCompatibleQuestionPage(
    TestModel test, {
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) async {
    final scope = _questionScopeForTest(test);
    if (scope.isTestSeries) {
      if (!scope.isQuestionBank) {
        throw const FormatException(
          'Test Series ownership is incomplete for this Test.',
        );
      }
      final page = await _questions.loadTestSeriesQuestionPage(
        AdminTestSeriesQuestionQuery.fromScope(
          scope,
          searchText: searchText,
          cursorDocumentId: cursorDocumentId,
          cursorSearchText: cursorSearchText,
        ),
      );
      return QuestionBankPage(
        questions: [
          for (final question in page.questions)
            if (_isAssignableQuestion(question)) question,
        ],
        hasMore: page.hasMore,
        cursorDocumentId: page.cursorDocumentId,
        cursorSearchText: page.cursorSearchText,
      );
    }

    final chapterQuery = _chapterQueryForTest(
      test,
      searchText: searchText,
      cursorDocumentId: cursorDocumentId,
      cursorSearchText: cursorSearchText,
    );
    if (chapterQuery != null) {
      final page = await _questions.loadChapterQuestionPage(chapterQuery);
      return QuestionBankPage(
        questions: [
          for (final question in page.questions)
            if (_isAssignableQuestion(question) &&
                questionMatchesChapterTest(question, test))
              question,
        ],
        hasMore: page.hasMore,
        cursorDocumentId: page.cursorDocumentId,
        cursorSearchText: page.cursorSearchText,
      );
    }

    final questions = await _questions.loadQuestions(
      filter: QuestionFilter(
        courseId: test.examId,
        paperId: test.paperId,
        partId: test.partId,
        activeOnly: false,
      ),
    );
    final normalizedSearch = searchText?.trim().toLowerCase() ?? '';
    final compatible = [
      for (final question in questions)
        if ((question.contentArea == null ||
                question.contentArea ==
                    AdminQuestionScope.contentAreaChapter) &&
            _isAssignableQuestion(question) &&
            questionMatchesChapterTest(question, test) &&
            (normalizedSearch.isEmpty ||
                _questionSearchText(question).contains(normalizedSearch)))
          question,
    ];
    return QuestionBankPage(
      questions: compatible,
      hasMore: false,
      cursorDocumentId: compatible.isEmpty ? null : compatible.last.id,
    );
  }

  /// Scoped Chapter bank when the Test's canonical location matches an
  /// existing Chapter Question query. Incomplete locations keep the paper scan.
  static AdminChapterQuestionQuery? _chapterQueryForTest(
    TestModel test, {
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) {
    if (test.category != TestCategoryType.chapterTests &&
        test.category != TestCategoryType.paperTests) {
      return null;
    }
    final scope = test.canonicalScope;
    if (scope == null) return null;
    switch (scope.shape) {
      case CanonicalScopeShape.groupIiiPaperUnit:
      case CanonicalScopeShape.groupIiiPartUnit:
        return AdminChapterQuestionQuery(
          courseId: scope.courseId,
          paperId: scope.paperId,
          partId: scope.partId,
          syllabusUnitId: scope.syllabusUnitId,
          searchText: searchText,
          cursorDocumentId: cursorDocumentId,
          cursorSearchText: cursorSearchText,
        );
      case CanonicalScopeShape.groupIiPartUnit:
        final partId = scope.partId;
        if (partId == null) return null;
        return AdminChapterQuestionQuery(
          courseId: scope.courseId,
          paperId: scope.paperId,
          partId: partId,
          topicId: scope.canonicalTopicId ?? scope.syllabusUnitId,
          searchText: searchText,
          cursorDocumentId: cursorDocumentId,
          cursorSearchText: cursorSearchText,
        );
      case CanonicalScopeShape.groupIiPaperI:
        final areaId = scope.majorStudyAreaId;
        final contentTopicId = scope.contentTopicId;
        if (areaId == null || contentTopicId == null) return null;
        return AdminChapterQuestionQuery(
          courseId: scope.courseId,
          paperId: scope.paperId,
          majorStudyAreaId: areaId,
          contentTopicId: contentTopicId,
          searchText: searchText,
          cursorDocumentId: cursorDocumentId,
          cursorSearchText: cursorSearchText,
        );
    }
  }

  static AdminQuestionScope _questionScopeForTest(TestModel test) {
    switch (test.category) {
      case TestCategoryType.partTests:
        return AdminQuestionScope(
          contentArea: AdminQuestionScope.contentAreaTestSeries,
          courseId: test.examId,
          testSeriesCategory: AdminQuestionScope.categoryPart,
          paperId: test.paperId,
        );
      case TestCategoryType.mockTests:
        return AdminQuestionScope(
          contentArea: AdminQuestionScope.contentAreaTestSeries,
          courseId: test.examId,
          testSeriesCategory: AdminQuestionScope.categoryMock,
          seriesId: test.seriesId,
        );
      case TestCategoryType.previousYear:
        return AdminQuestionScope(
          contentArea: AdminQuestionScope.contentAreaTestSeries,
          courseId: test.examId,
          testSeriesCategory: AdminQuestionScope.categoryPreviousYear,
          year: test.year,
        );
      case TestCategoryType.chapterTests:
      case TestCategoryType.paperTests:
        return AdminQuestionScope(
          contentArea: AdminQuestionScope.contentAreaChapter,
          courseId: test.examId,
        );
    }
  }

  static bool questionMatchesChapterTest(Question question, TestModel test) {
    final unitId = test.syllabusUnitId?.trim();
    if (unitId == null || unitId.isEmpty) {
      return true;
    }
    return questionMatchesChapterUnit(question, unitId);
  }

  static String _questionSearchText(Question question) {
    final topLevel = question.question.trim();
    if (topLevel.isNotEmpty) return topLevel.toLowerCase();
    return question.content?.en.question.trim().toLowerCase() ?? '';
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
    final id = await _tests.createTest(draft);
    _invalidateTestLists();
    return id;
  }

  Future<void> updateTest(
    TestModel test, {
    bool preserveAssignments = false,
  }) async {
    // Re-read for current client-side validation. The preserve intent is also
    // sent to the callable, which re-reads membership inside its transaction;
    // this client snapshot is not the concurrency boundary.
    final current = await _tests.getAdminTestById(test.id);
    if (current == null) {
      throw const FormatException('Test was not found.');
    }
    final effective = preserveAssignments
        ? _withServerAssignments(test, current)
        : test;
    final errors = validate(effective, documentId: effective.id);
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }
    await _validateAssignedQuestions(
      effective,
      existingIds: current.questionIds.toSet(),
    );

    if (effective.status == TestPublicationStatus.published &&
        current.status != TestPublicationStatus.published) {
      if (current.status == TestPublicationStatus.archived) {
        throw const FormatException('Archived tests cannot be published.');
      }
      final publicationErrors = TestCloudMapper.validateForPublication(
        effective,
        documentId: effective.id,
      );
      if (publicationErrors.isNotEmpty) {
        throw FormatException(publicationErrors.join(' '));
      }
    }

    await _tests.updateTest(
      effective,
      preserveQuestionAssignments: preserveAssignments,
    );
    _invalidateTestLists();
  }

  /// Metadata edits keep the assignment set that is already stored.
  ///
  /// [questionIds] always come from [current]. When that set is non-empty,
  /// question count, marks, and duration are the assignment transaction's
  /// values, not the form copy captured when Edit Test opened.
  static TestModel _withServerAssignments(TestModel form, TestModel current) {
    final ids = List<String>.unmodifiable(current.questionIds);
    final assigned = ids.isNotEmpty;
    return TestModel(
      id: form.id,
      examId: form.examId,
      category: form.category,
      title: form.title,
      description: form.description,
      questionCount: assigned ? ids.length : form.questionCount,
      marks: assigned ? current.marks : form.marks,
      durationMinutes: assigned
          ? current.durationMinutes
          : form.durationMinutes,
      negativeMarking: form.negativeMarking,
      difficulty: form.difficulty,
      questionIds: ids,
      status: form.status,
      paperId: form.paperId,
      partId: form.partId,
      syllabusUnitId: form.syllabusUnitId,
      majorStudyAreaId: form.majorStudyAreaId ?? current.majorStudyAreaId,
      contentTopicId: form.contentTopicId ?? current.contentTopicId,
      canonicalTopicId: form.canonicalTopicId ?? current.canonicalTopicId,
      lessonId: form.lessonId ?? current.lessonId,
      scopeShape: form.scopeShape ?? current.scopeShape,
      year: form.year,
      seriesId: form.seriesId,
    );
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
    _invalidateTestLists();
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
    _invalidateTestLists();
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
          partRequiredIfPaperHasParts: false,
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
            paperRequired: false,
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
            paperRequired: false,
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

  Future<void> _validateAssignedQuestions(
    TestModel test, {
    Set<String> existingIds = const {},
  }) async {
    if (test.questionIds.isEmpty) return;

    final questions = await _questions.getAdminByIds(test.questionIds);
    final byId = {for (final question in questions) question.id: question};
    final errors = <String>[];
    for (final id in test.questionIds) {
      final question = byId[id];
      if (question == null) {
        errors.add('Question "$id" does not exist.');
        continue;
      }
      if (question.status == QuestionPublicationStatus.archived &&
          !existingIds.contains(id)) {
        errors.add('Archived Question "$id" cannot be assigned.');
      }
      if (question.courseId != test.examId) {
        errors.add('Question "$id" belongs to another course.');
      }
      if (test.paperId != null &&
          test.paperId!.isNotEmpty &&
          question.paperId.isNotEmpty &&
          question.paperId != test.paperId &&
          (test.category == TestCategoryType.chapterTests ||
              test.category == TestCategoryType.paperTests ||
              test.category == TestCategoryType.partTests)) {
        errors.add('Question "$id" does not match the test paper.');
      }
      if (test.partId != null &&
          test.partId!.isNotEmpty &&
          question.partId != null &&
          question.partId!.isNotEmpty &&
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
