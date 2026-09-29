import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_chapter_question_context.dart';
import 'package:telangana_prep/features/admin/data/admin_chapter_question_query.dart';
import 'package:telangana_prep/features/admin/data/admin_compatible_test_query.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/data/admin_test_hierarchy.dart';
import 'package:telangana_prep/features/admin/data/question_create_outcome.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_form_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_series_question_bank_screen.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_question_form.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/admin/services/admin_question_test_assignment.dart';
import 'package:telangana_prep/features/admin/services/admin_test_series_question_create.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';
import 'package:telangana_prep/features/tests/data/grand_test_series.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';

void main() {
  const paperScope = AdminQuestionScope(
    contentArea: AdminQuestionScope.contentAreaTestSeries,
    courseId: 'group-ii',
    testSeriesCategory: AdminQuestionScope.categoryPart,
    paperId: 'group-ii-paper-i',
  );
  const grandScope = AdminQuestionScope(
    contentArea: AdminQuestionScope.contentAreaTestSeries,
    courseId: 'group-ii',
    testSeriesCategory: AdminQuestionScope.categoryMock,
    seriesId: GrandTestSeries.grandTestII,
  );
  const previousScope = AdminQuestionScope(
    contentArea: AdminQuestionScope.contentAreaTestSeries,
    courseId: 'group-ii',
    testSeriesCategory: AdminQuestionScope.categoryPreviousYear,
    year: 2024,
  );

  Question draft({
    QuestionType questionType = QuestionType.practice,
    String? partId,
    int? year,
    bool paperI = false,
  }) {
    final now = DateTime(2026, 9, 28);
    final paperId = paperI ? 'group-ii-paper-i' : 'group-ii-paper-ii';
    return Question(
      id: '',
      courseId: 'group-ii',
      paperId: paperId,
      question: 'Which city is the capital?',
      options: const ['Warangal', 'Hyderabad', 'Nizamabad', 'Karimnagar'],
      correctOption: 'B',
      explanation: 'Hyderabad is the capital.',
      difficulty: QuestionDifficulty.medium,
      questionType: questionType,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      isActive: false,
      status: QuestionPublicationStatus.draft,
      year: year,
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: 'Which city is the capital?',
          options: [
            QuestionOption(text: 'Warangal'),
            QuestionOption(text: 'Hyderabad'),
            QuestionOption(text: 'Nizamabad'),
            QuestionOption(text: 'Karimnagar'),
          ],
          explanation: 'Hyderabad is the capital.',
        ),
        te: QuestionLocalizedContent(
          question: 'రాజధాని నగరం ఏది?',
          options: [
            QuestionOption(text: 'వరంగల్'),
            QuestionOption(text: 'హైదరాబాద్'),
            QuestionOption(text: 'నిజామాబాద్'),
            QuestionOption(text: 'కరీంనగర్'),
          ],
          explanation: 'హైదరాబాద్ రాజధాని.',
        ),
      ),
      syllabus: paperI
          ? const QuestionSyllabusAttribution(
              courseId: 'group-ii',
              paperId: 'group-ii-paper-i',
              majorStudyAreaId: 'group-ii-paper-i-area-1',
              contentTopicId: 'group-ii-paper-i-area-1-topic-1',
            )
          : QuestionSyllabusAttribution(
              courseId: 'group-ii',
              paperId: 'group-ii-paper-ii',
              partId: partId,
              topicId: 'group-ii-paper-ii-part-1-topic-1',
              lessonId: 'should-not-be-required',
            ),
    );
  }

  TestModel catalogTest({
    required String id,
    required TestCategoryType category,
    String courseId = 'group-ii',
    String? paperId,
    String? partId,
    String? seriesId,
    int? year,
    List<String> questionIds = const ['existing-q'],
  }) {
    return TestModel(
      id: id,
      examId: courseId,
      category: category,
      title: id,
      questionCount: questionIds.length,
      marks: questionIds.length,
      durationMinutes: 30,
      negativeMarking: '0',
      difficulty: 'easy',
      questionIds: questionIds,
      status: TestPublicationStatus.draft,
      paperId: paperId,
      partId: partId,
      seriesId: seriesId,
      year: year,
    );
  }

  Map<String, dynamic> ownershipOf(Map<String, dynamic> data) {
    return {
      'contentArea': data['contentArea'],
      'testSeriesCategory': data['testSeriesCategory'],
      'courseId': data['courseId'],
      'paperId': data['paperId'],
      'seriesId': data['seriesId'],
      'year': data['year'],
      'partId': data['partId'],
    };
  }

  test(
    'ownership payloads follow the selected bank and ignore questionType',
    () async {
      final captured = <Map<String, dynamic>>[];
      final recording = QuestionCloudRepository.withHandlers(
        create: ({required questionId, required data}) async {
          captured.add(data);
        },
        idGenerator: () => 'q-created',
      );
      final recordingService = AdminQuestionService(
        questionRepository: recording,
      );

      await recordingService.createQuestion(draft(), scope: paperScope);
      await recordingService.createQuestion(
        draft(
          questionType: QuestionType.mock,
          partId: 'group-ii-paper-ii-part-1',
        ),
        scope: paperScope,
      );
      await recordingService.createQuestion(draft(), scope: grandScope);
      await recordingService.createQuestion(
        draft(questionType: QuestionType.previousYear, year: 1999),
        scope: previousScope,
      );
      await recordingService.createQuestion(draft(paperI: true));

      expect(ownershipOf(captured[0]), {
        'contentArea': 'testSeries',
        'testSeriesCategory': 'part',
        'courseId': 'group-ii',
        'paperId': 'group-ii-paper-i',
        'seriesId': null,
        'year': null,
        'partId': null,
      });
      expect(captured[0].containsKey('partId'), isFalse);
      expect(captured[0].containsKey('lessonId'), isFalse);
      expect(captured[0].containsKey('assignedTestId'), isFalse);
      expect(captured[0]['questionType'], 'practice');
      expect(ownershipOf(captured[1]), ownershipOf(captured[0]));
      expect(captured[1]['questionType'], 'mock');
      expect(ownershipOf(captured[2]), {
        'contentArea': 'testSeries',
        'testSeriesCategory': 'mock',
        'courseId': 'group-ii',
        'paperId': null,
        'seriesId': GrandTestSeries.grandTestII,
        'year': null,
        'partId': null,
      });
      expect(captured[2].containsKey('paperId'), isFalse);
      expect(ownershipOf(captured[3]), {
        'contentArea': 'testSeries',
        'testSeriesCategory': 'previousyear',
        'courseId': 'group-ii',
        'paperId': null,
        'seriesId': null,
        'year': 2024,
        'partId': null,
      });
      expect(captured[3]['year'], 2024);
      expect(captured[3]['questionType'], 'previousYear');
      expect(captured[4]['contentArea'], 'chapter');
      expect(captured[4].containsKey('testSeriesCategory'), isFalse);
    },
  );

  test('chapter Papers II–IV still require part and topic, not lesson', () {
    final service = AdminQuestionService();
    final withoutLesson = Question(
      id: 'q-chapter',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      question: 'Which city is the capital?',
      options: const ['Warangal', 'Hyderabad', 'Nizamabad', 'Karimnagar'],
      correctOption: 'B',
      explanation: 'Hyderabad is the capital.',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: DateTime(2026, 9, 28),
      updatedAt: DateTime(2026, 9, 28),
      status: QuestionPublicationStatus.draft,
      content: draft().content,
      syllabus: const QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-ii',
        partId: 'group-ii-paper-ii-part-1',
        topicId: 'group-ii-paper-ii-part-1-topic-1',
      ),
    );
    expect(service.validate(withoutLesson, documentId: 'q-chapter'), isEmpty);

    final missingPart = Question(
      id: withoutLesson.id,
      courseId: withoutLesson.courseId,
      paperId: withoutLesson.paperId,
      question: withoutLesson.question,
      options: withoutLesson.options,
      correctOption: withoutLesson.correctOption,
      explanation: withoutLesson.explanation,
      difficulty: withoutLesson.difficulty,
      questionType: withoutLesson.questionType,
      marks: withoutLesson.marks,
      negativeMarks: withoutLesson.negativeMarks,
      tags: withoutLesson.tags,
      estimatedTime: withoutLesson.estimatedTime,
      createdAt: withoutLesson.createdAt,
      updatedAt: withoutLesson.updatedAt,
      status: withoutLesson.status,
      content: withoutLesson.content,
      syllabus: const QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-ii',
        topicId: 'group-ii-paper-ii-part-1-topic-1',
      ),
    );
    expect(
      service
          .validate(missingPart, documentId: 'q-chapter')
          .any((error) => error.contains('Part')),
      isTrue,
    );
  });

  test(
    'compatible test queries exclude the wrong context and ignore partId',
    () {
      final paper = AdminCompatibleTestQuery.fromScope(paperScope);
      expect(
        {
          for (final filter in paper.equalityFilters)
            filter.field: filter.value,
        },
        {
          'courseId': 'group-ii',
          'category': 'part',
          'paperId': 'group-ii-paper-i',
        },
      );
      expect(
        paper.equalityFilters.any((filter) => filter.field == 'partId'),
        isFalse,
      );
      expect(
        paper.matches(
          catalogTest(
            id: 'same-paper-with-part',
            category: TestCategoryType.partTests,
            paperId: 'group-ii-paper-i',
            partId: 'group-ii-paper-i-part-1',
          ),
        ),
        isTrue,
      );
      expect(
        paper.matches(
          catalogTest(
            id: 'wrong-paper',
            category: TestCategoryType.partTests,
            paperId: 'group-ii-paper-ii',
          ),
        ),
        isFalse,
      );
      expect(
        paper.matches(
          catalogTest(
            id: 'wrong-category',
            category: TestCategoryType.mockTests,
            paperId: 'group-ii-paper-i',
            seriesId: GrandTestSeries.grandTestII,
          ),
        ),
        isFalse,
      );
      expect(
        paper.matches(
          catalogTest(
            id: 'wrong-course',
            category: TestCategoryType.partTests,
            courseId: 'group-iii',
            paperId: 'group-ii-paper-i',
          ),
        ),
        isFalse,
      );

      final grand = AdminCompatibleTestQuery.fromScope(grandScope);
      expect(
        {
          for (final filter in grand.equalityFilters)
            filter.field: filter.value,
        },
        {
          'courseId': 'group-ii',
          'category': 'mock',
          'seriesId': GrandTestSeries.grandTestII,
        },
      );
      expect(
        grand.equalityFilters.any((filter) => filter.field == 'paperId'),
        isFalse,
      );
      expect(
        grand.matches(
          catalogTest(
            id: 'grand-ii',
            category: TestCategoryType.mockTests,
            seriesId: GrandTestSeries.grandTestII,
            paperId: 'group-ii-paper-iii',
          ),
        ),
        isTrue,
      );
      expect(
        grand.matches(
          catalogTest(
            id: 'grand-i',
            category: TestCategoryType.mockTests,
            seriesId: GrandTestSeries.grandTestI,
            paperId: 'group-ii-paper-iii',
          ),
        ),
        isFalse,
      );

      final previous = AdminCompatibleTestQuery.fromScope(previousScope);
      expect(previous.equalityFilters.last.value, 2024);
      expect(
        previous.matches(
          catalogTest(
            id: 'year-2024',
            category: TestCategoryType.previousYear,
            year: 2024,
            paperId: 'group-ii-paper-ii',
          ),
        ),
        isTrue,
      );
      expect(
        previous.matches(
          catalogTest(
            id: 'year-2016',
            category: TestCategoryType.previousYear,
            year: 2016,
            paperId: 'group-ii-paper-ii',
          ),
        ),
        isFalse,
      );
    },
  );

  test(
    'optional assignment uses the test update callable and keeps a failed question',
    () async {
      final created = <Map<String, dynamic>>[];
      final questions = QuestionCloudRepository.withHandlers(
        create: ({required questionId, required data}) async {
          created.add(data);
        },
        idGenerator: () => 'q-new',
      );
      final service = AdminQuestionService(questionRepository: questions);
      final updates = <Map<String, dynamic>>[];
      var failUpdate = false;
      final compatible = catalogTest(
        id: 'paper-test',
        category: TestCategoryType.partTests,
        paperId: 'group-ii-paper-i',
        partId: 'some-part',
      );
      final tests = TestCloudRepository.withLoader(
        (_) async => const [],
        getById: (id) async => id == compatible.id ? compatible : null,
        update: ({required testId, required data}) async {
          if (failUpdate) throw Exception('assignment rejected');
          updates.add(data);
        },
      );
      final assignment = AdminQuestionTestAssignment(tests: tests);

      final unassigned = await createTestSeriesQuestion(
        questions: service,
        assignment: assignment,
        scope: paperScope,
        question: draft(),
      );
      expect(unassigned.assignmentFailed, isFalse);
      expect(updates, isEmpty);
      expect(created, hasLength(1));
      expect(created.single.containsKey('assignedTestId'), isFalse);

      final assigned = await createTestSeriesQuestion(
        questions: service,
        assignment: assignment,
        scope: paperScope,
        question: draft(),
        assignToTestId: compatible.id,
      );
      expect(assigned.assignmentFailed, isFalse);
      expect(updates.single['questionIds'], ['existing-q', 'q-new']);
      expect(updates.single.containsKey('assignedTestId'), isFalse);
      expect(updates.single['status'], 'draft');
      expect(created.last['status'], 'draft');
      expect(created, hasLength(2));

      failUpdate = true;
      await expectLater(
        createTestSeriesQuestion(
          questions: service,
          assignment: assignment,
          scope: paperScope,
          question: draft(),
          assignToTestId: compatible.id,
        ),
        throwsA(
          isA<QuestionAssignmentFailed>().having(
            (error) => error.outcome.message,
            'message',
            contains('Question was created'),
          ),
        ),
      );
      expect(created, hasLength(3));
    },
  );

  testWidgets('bank create locks ownership, writes it, and reloads the bank', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final created = <Map<String, dynamic>>[];
    var loads = 0;
    final questions = QuestionCloudRepository.withHandlers(
      loadTestSeriesQuestions: (_) async {
        loads += 1;
        return const [];
      },
      create: ({required questionId, required data}) async {
        created.add(data);
      },
      idGenerator: () => 'q-from-form',
    );
    final service = AdminQuestionService(questionRepository: questions);
    final updates = <Map<String, dynamic>>[];
    final compatible = catalogTest(
      id: 'paper-test',
      category: TestCategoryType.partTests,
      paperId: 'group-ii-paper-i',
    );
    final tests = TestCloudRepository.withLoader(
      (_) async => const [],
      getById: (id) async => compatible,
      update: ({required testId, required data}) async {
        updates.add(data);
      },
      loadCompatibleTests: (_) async => [
        compatible,
        catalogTest(
          id: 'wrong-paper',
          category: TestCategoryType.partTests,
          paperId: 'group-ii-paper-ii',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminTestSeriesQuestionBankScreen(
            scope: paperScope,
            service: service,
            assignment: AdminQuestionTestAssignment(tests: tests),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('test-series-question-bank-create')),
      findsOneWidget,
    );
    expect(loads, 1);

    await tester.tap(
      find.byKey(const ValueKey('test-series-question-bank-create')),
    );
    await tester.pumpAndSettle();

    final paper = SyllabusService.instance.getPaper(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
    )!;
    expect(
      find.byKey(const ValueKey('test-series-ownership-context')),
      findsOneWidget,
    );
    expect(find.text('Group-II'), findsWidgets);
    expect(find.text('Paper-wise'), findsWidgets);
    expect(find.text(AdminTestHierarchy.paperLabel(paper)), findsWidgets);
    expect(find.byKey(const ValueKey('question-course')), findsNothing);
    expect(
      find.byKey(const ValueKey('group-ii-question-syllabus')),
      findsNothing,
    );
    expect(find.text('wrong-paper'), findsNothing);
    expect(find.text('Do not assign'), findsOneWidget);
    expect(find.byKey(const ValueKey('question-difficulty')), findsNothing);
    expect(find.text('Difficulty'), findsNothing);

    Future<void> enter(String key, String value) async {
      final field = find.byKey(ValueKey(key));
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }

    await enter('question-en', 'Which city is the capital?');
    await enter('question-te', 'రాజధాని నగరం ఏది?');
    await enter('option-en-A', 'Warangal');
    await enter('option-te-A', 'వరంగల్');
    await enter('option-en-B', 'Hyderabad');
    await enter('option-te-B', 'హైదరాబాద్');
    await enter('option-en-C', 'Nizamabad');
    await enter('option-te-C', 'నిజామాబాద్');
    await enter('option-en-D', 'Karimnagar');
    await enter('option-te-D', 'కరీంనగర్');
    await enter('explanation-en', 'Hyderabad is the capital.');
    await enter('explanation-te', 'హైదరాబాద్ రాజధాని.');
    await tester.ensureVisible(find.byKey(const ValueKey('submit-question')));
    await tester.tap(find.byKey(const ValueKey('submit-question')));
    await tester.pumpAndSettle();

    expect(find.byType(AdminQuestionFormScreen), findsNothing);
    expect(find.byType(AdminTestSeriesQuestionBankScreen), findsOneWidget);
    expect(loads, 2);
    expect(updates, isEmpty);
    expect(created.single['contentArea'], 'testSeries');
    expect(created.single['testSeriesCategory'], 'part');
    expect(created.single['courseId'], 'group-ii');
    expect(created.single['paperId'], 'group-ii-paper-i');
    expect(created.single['difficulty'], 'medium');
    expect(created.single.containsKey('partId'), isFalse);
    expect(created.single.containsKey('assignedTestId'), isFalse);
  });

  testWidgets('grand and previous forms keep ownership read-only', (
    tester,
  ) async {
    Future<void> open(AdminQuestionScope scope) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminQuestionForm(
              courses: const [
                Course(
                  courseId: 'group-ii',
                  title: 'Group-II',
                  shortTitle: 'G-II',
                  description: '',
                  thumbnail: null,
                  icon: null,
                  color: null,
                  isFree: false,
                  isPublished: true,
                  price: 0,
                  sortOrder: 1,
                  createdAt: null,
                  updatedAt: null,
                ),
              ],
              lockedScope: scope,
              onSubmit: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open(grandScope);
    expect(find.text('Grand Tests'), findsOneWidget);
    expect(find.text(GrandTestSeries.grandTestII), findsOneWidget);
    expect(find.byKey(const ValueKey('question-difficulty')), findsNothing);
    expect(find.byKey(const ValueKey('question-course')), findsNothing);
    expect(
      find.byKey(const ValueKey('group-ii-question-syllabus')),
      findsNothing,
    );

    await open(previousScope);
    expect(find.text('Previous Papers'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
    expect(find.byKey(const ValueKey('question-course')), findsNothing);
  });

  testWidgets('chapter create still shows the editable syllabus form', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminQuestionForm(
            courses: const [
              Course(
                courseId: 'group-ii',
                title: 'Group-II',
                shortTitle: 'G-II',
                description: '',
                thumbnail: null,
                icon: null,
                color: null,
                isFree: false,
                isPublished: true,
                price: 0,
                sortOrder: 1,
                createdAt: null,
                updatedAt: null,
              ),
            ],
            onSubmit: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('question-course')), findsOneWidget);
    expect(find.byKey(const ValueKey('question-difficulty')), findsNothing);
    expect(
      find.byKey(const ValueKey('test-series-ownership-context')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('test-series-assign-test')), findsNothing);
  });

  test('chapter creates persist contentArea=chapter for every bank', () async {
    final captured = <Map<String, dynamic>>[];
    final service = AdminQuestionService(
      questionRepository: QuestionCloudRepository.withHandlers(
        create: ({required questionId, required data}) async {
          captured.add(data);
        },
        idGenerator: () => 'q-created',
      ),
    );
    final now = DateTime(2026, 9, 28);
    final groupIii = Question(
      id: '',
      courseId: 'group-iii',
      paperId: 'group-iii-paper-i',
      question: 'Which city is the capital?',
      options: const ['Warangal', 'Hyderabad', 'Nizamabad', 'Karimnagar'],
      correctOption: 'B',
      explanation: 'Hyderabad is the capital.',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      isActive: false,
      status: QuestionPublicationStatus.draft,
      content: draft(paperI: true).content,
      syllabus: const QuestionSyllabusAttribution(
        courseId: 'group-iii',
        paperId: 'group-iii-paper-i',
        syllabusUnitId: 'group-iii-paper-i-unit-01',
      ),
    );

    await service.createQuestion(draft(paperI: true));
    await service.createQuestion(
      draft(partId: 'group-ii-paper-ii-part-01'),
    );
    await service.createQuestion(groupIii);

    expect(captured[0]['contentArea'], 'chapter');
    expect(captured[1]['contentArea'], 'chapter');
    expect(captured[2]['contentArea'], 'chapter');
    expect(captured[0].containsKey('testSeriesCategory'), isFalse);
    _expectChapterQuery(captured[0], const AdminChapterQuestionContext(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      majorStudyAreaId: 'group-ii-paper-i-area-1',
      contentTopicId: 'group-ii-paper-i-area-1-topic-1',
    ));
    _expectChapterQuery(captured[1], const AdminChapterQuestionContext(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-01',
      topicId: 'group-ii-paper-ii-part-1-topic-1',
    ));
    _expectChapterQuery(captured[2], const AdminChapterQuestionContext(
      courseId: 'group-iii',
      paperId: 'group-iii-paper-i',
      syllabusUnitId: 'group-iii-paper-i-unit-01',
    ));
  });

  test('editing a legacy chapter question writes contentArea=chapter', () async {
    Map<String, dynamic>? written;
    final service = AdminQuestionService(
      questionRepository: QuestionCloudRepository.withHandlers(
        update: ({required questionId, required data}) async {
          written = data;
        },
      ),
    );
    final legacy = draft(paperI: true).copyWithId('q-legacy');
    await service.updateQuestion(legacy);
    expect(legacy.contentArea, isNull);
    expect(written?['contentArea'], 'chapter');
    expect(written?.containsKey('testSeriesCategory'), isFalse);
  });

  test('editing a test series question keeps contentArea=testSeries', () async {
    Map<String, dynamic>? written;
    final service = AdminQuestionService(
      questionRepository: QuestionCloudRepository.withHandlers(
        update: ({required questionId, required data}) async {
          written = data;
        },
      ),
    );
    final existing = Question(
      id: 'q-series',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      question: 'Which city is the capital?',
      options: const ['Warangal', 'Hyderabad', 'Nizamabad', 'Karimnagar'],
      correctOption: 'B',
      explanation: 'Hyderabad is the capital.',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: DateTime(2026, 9, 28),
      updatedAt: DateTime(2026, 9, 28),
      isActive: false,
      status: QuestionPublicationStatus.draft,
      content: draft(paperI: true).content,
      syllabus: draft(paperI: true).syllabus,
      contentArea: AdminQuestionScope.contentAreaTestSeries,
      testSeriesCategory: AdminQuestionScope.categoryPart,
    );
    await service.updateQuestion(existing);
    expect(written?['contentArea'], 'testSeries');
  });
}

void _expectChapterQuery(
  Map<String, dynamic> data,
  AdminChapterQuestionContext location,
) {
  final query = AdminChapterQuestionQuery.fromContext(location);
  for (final filter in query.equalityFilters) {
    expect(data[filter.field], filter.value, reason: filter.field);
  }
}

extension on Question {
  Question copyWithId(String id) {
    return Question(
      id: id,
      courseId: courseId,
      paperId: paperId,
      question: question,
      options: options,
      correctOption: correctOption,
      explanation: explanation,
      difficulty: difficulty,
      questionType: questionType,
      marks: marks,
      negativeMarks: negativeMarks,
      tags: tags,
      estimatedTime: estimatedTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      status: status,
      content: content,
      syllabus: syllabus,
    );
  }
}
