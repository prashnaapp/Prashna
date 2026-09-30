import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_content_callable_client.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/data/admin_test_scope.dart';
import 'package:telangana_prep/features/admin/data/admin_test_series_question_query.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_test_form.dart';
import 'package:telangana_prep/features/admin/services/admin_question_test_assignment.dart';
import 'package:telangana_prep/features/admin/services/admin_test_service.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';

void main() {
  test(
    'manual IDs dedupe and reject missing, incompatible, and owned IDs',
    () async {
      final service = _RecordingService(
        questions: [
          _seriesQuestion(
            'part-free',
            category: 'part',
            paperId: 'group-ii-paper-i',
          ),
          _seriesQuestion(
            'part-ok',
            category: 'part',
            paperId: 'group-ii-paper-i',
          ),
          _chapterQuestion('chapter-q'),
        ],
        owners: const {'part-ok': 'other-test'},
      );

      expect(
        await service.normalizeInitialQuestionIds(paperTest(), const [
          'part-free',
          'part-free',
        ]),
        ['part-free'],
      );

      expect(
        () =>
            service.normalizeInitialQuestionIds(paperTest(), const ['missing']),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Question "missing" does not exist.',
          ),
        ),
      );
      expect(
        () => service.normalizeInitialQuestionIds(paperTest(), const [
          'chapter-q',
        ]),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Question "chapter-q" is not compatible with this Test.',
          ),
        ),
      );
      expect(
        () =>
            service.normalizeInitialQuestionIds(paperTest(), const ['part-ok']),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Question "part-ok" is already assigned to another Test.',
          ),
        ),
      );
    },
  );

  test('manual selection keeps first-seen order and enforces 160', () async {
    final service = _RecordingService(
      questions: [
        _seriesQuestion('b', category: 'part', paperId: 'group-ii-paper-i'),
        _seriesQuestion('a', category: 'part', paperId: 'group-ii-paper-i'),
      ],
    );

    expect(
      await service.normalizeInitialQuestionIds(paperTest(), const [
        'b',
        'a',
        'b',
      ]),
      ['b', 'a'],
    );
    expect(
      () => service.normalizeInitialQuestionIds(paperTest(), [
        for (var i = 0; i < 161; i++) 'q-$i',
      ]),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'A Test can assign at most 160 Questions.',
        ),
      ),
    );
    expect(AdminQuestionTestAssignment.maxAssignedQuestionsPerTest, 160);
  });

  test(
    'paper-wise available questions exclude chapter and owned questions',
    () async {
      final queries = <AdminTestSeriesQuestionQuery>[];
      final questions = [
        for (var i = 0; i < 10; i++)
          _seriesQuestion(
            'part-$i',
            category: AdminQuestionScope.categoryPart,
            paperId: 'group-ii-paper-i',
          ),
        _chapterQuestion('chapter-leak'),
      ];
      final service = _AvailableService(
        questions: QuestionCloudRepository.withHandlers(
          loadTestSeriesQuestionPage: (query) async {
            queries.add(query);
            return QuestionBankPage(questions: questions, hasMore: false);
          },
        ),
        owners: const {
          'part-0': 'other',
          'part-1': 'other',
          'part-2': 'other',
          'part-3': 'other',
          'part-4': 'other',
        },
      );

      final page = await service.loadAvailableInitialQuestionPage(paperTest());

      expect(
        queries.single.testSeriesCategory,
        AdminQuestionScope.categoryPart,
      );
      expect(queries.single.courseId, 'group-ii');
      expect(queries.single.paperId, 'group-ii-paper-i');
      expect(
        queries.single.equalityFilters,
        contains((
          field: 'contentArea',
          value: AdminQuestionScope.contentAreaTestSeries,
        )),
      );
      expect(page.questions.map((question) => question.id), [
        'part-5',
        'part-6',
        'part-7',
        'part-8',
        'part-9',
      ]);
    },
  );

  test('grand and previous available questions stay in their banks', () async {
    final queries = <AdminTestSeriesQuestionQuery>[];
    final service = _AvailableService(
      questions: QuestionCloudRepository.withHandlers(
        loadTestSeriesQuestionPage: (query) async {
          queries.add(query);
          return QuestionBankPage(
            questions: [
              _seriesQuestion(
                'mock-ok',
                category: AdminQuestionScope.categoryMock,
                seriesId: 'Grand Test - I',
              ),
              _seriesQuestion(
                'year-ok',
                category: AdminQuestionScope.categoryPreviousYear,
                year: 2016,
              ),
              _chapterQuestion('chapter-leak'),
            ],
            hasMore: false,
          );
        },
      ),
    );

    final grand = await service.loadAvailableInitialQuestionPage(
      paperTest(
        category: TestCategoryType.mockTests,
        seriesId: 'Grand Test - I',
        paperId: null,
      ),
    );
    final previous = await service.loadAvailableInitialQuestionPage(
      paperTest(
        category: TestCategoryType.previousYear,
        year: 2016,
        paperId: null,
      ),
    );

    expect(queries[0].seriesId, 'Grand Test - I');
    expect(queries[0].testSeriesCategory, AdminQuestionScope.categoryMock);
    expect(grand.questions.map((question) => question.id), ['mock-ok']);
    expect(queries[1].year, 2016);
    expect(
      queries[1].testSeriesCategory,
      AdminQuestionScope.categoryPreviousYear,
    );
    expect(previous.questions.map((question) => question.id), ['year-ok']);
  });

  test('chapter available questions stay in the chapter bank', () async {
    final service = _AvailableService(
      questions: QuestionCloudRepository.withHandlers(
        loadQuestions: (_) async => [
          _chapterQuestion(
            'chapter-ok',
            majorStudyAreaId: 'group-ii-paper-i-area-01',
          ),
          _chapterQuestion(
            'other-unit',
            majorStudyAreaId: 'group-ii-paper-i-area-02',
          ),
          _seriesQuestion(
            'series-leak',
            category: AdminQuestionScope.categoryPart,
            paperId: 'group-ii-paper-i',
          ),
        ],
      ),
    );

    final page = await service.loadAvailableInitialQuestionPage(
      paperTest(
        category: TestCategoryType.chapterTests,
        syllabusUnitId: 'group-ii-paper-i-area-01',
      ),
    );

    expect(page.questions.map((question) => question.id), ['chapter-ok']);
  });

  test(
    'initial questions assign through update and empty drafts do not',
    () async {
      Map<String, dynamic>? created;
      Map<String, dynamic>? updated;
      TestModel? stored;
      final questions = [
        _seriesQuestion('b', category: 'part', paperId: 'group-ii-paper-i'),
        _seriesQuestion('a', category: 'part', paperId: 'group-ii-paper-i'),
      ];
      final tests = TestCloudRepository.withLoader(
        (_) async => const [],
        idGenerator: () => 'draft-1',
        getById: (_) async => stored,
        create: ({required testId, required data}) async {
          created = data;
          stored = paperTest(id: testId, questionIds: const []);
        },
        update: ({required testId, required data}) async {
          updated = data;
        },
      );
      final service = _RecordingService(
        testRepository: tests,
        questionRepository: QuestionCloudRepository.withHandlers(
          getByIds: (ids) async => [
            for (final question in questions)
              if (ids.contains(question.id)) question,
          ],
        ),
        questions: questions,
      );

      await service.createDraftWithInitialQuestions(
        paperTest(id: '', questionCount: 10),
        initialQuestionIds: const ['b', 'a', 'b'],
      );

      expect(created?['questionIds'], isEmpty);
      expect(created?['questionCount'], 10);
      expect(updated?['questionIds'], ['b', 'a']);
      expect(service.lastPreserveAssignments, isFalse);

      created = null;
      updated = null;
      await service.createDraftWithInitialQuestions(
        paperTest(id: '', questionCount: 10),
      );
      expect(created?['questionIds'], isEmpty);
      expect(updated, isNull);
    },
  );

  test('assignment failure preserves the draft and reports it', () async {
    TestModel? stored;
    var questionWrites = 0;
    final questions = [
      _seriesQuestion('q-1', category: 'part', paperId: 'group-ii-paper-i'),
    ];
    final tests = TestCloudRepository.withLoader(
      (_) async => const [],
      idGenerator: () => 'draft-1',
      getById: (_) async => stored,
      create: ({required testId, required data}) async {
        stored = paperTest(id: testId, questionIds: const []);
      },
      update: ({required testId, required data}) async {
        throw Exception('assignment transaction failed');
      },
    );
    final service = _RecordingService(
      testRepository: tests,
      questionRepository: QuestionCloudRepository.withHandlers(
        getByIds: (_) async => questions,
        update:
            ({
              required String questionId,
              required Map<String, dynamic> data,
            }) async {
              questionWrites++;
            },
      ),
      questions: questions,
    );

    await expectLater(
      service.createDraftWithInitialQuestions(
        paperTest(id: ''),
        initialQuestionIds: const ['q-1'],
      ),
      throwsA(
        isA<InitialQuestionAssignmentException>()
            .having((error) => error.testId, 'testId', 'draft-1')
            .having(
              (error) => error.toString(),
              'message',
              InitialQuestionAssignmentException.message,
            ),
      ),
    );
    expect(stored, isNotNull);
    expect(stored!.questionIds, isEmpty);
    expect(questionWrites, 0);
  });

  testWidgets('create form loads compatible questions and submits manual IDs', (
    tester,
  ) async {
    List<String>? submittedIds;
    TestModel? submitted;
    final service = _RecordingService(
      questions: [
        _seriesQuestion(
          'visible-q',
          category: 'part',
          paperId: 'group-ii-paper-i',
          text: 'Visible paper question',
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminTestForm(
            courses: const [_course],
            service: service,
            scope: const AdminTestScope(
              category: TestCategoryType.partTests,
              courseId: 'group-ii',
              paperId: 'group-ii-paper-i',
            ),
            onSubmit: (_) async {},
            onCreateDraft: (test, ids) async {
              submitted = test;
              submittedIds = ids;
            },
          ),
        ),
      ),
    );

    expect(find.text('Initial Questions (Optional)'), findsOneWidget);
    expect(find.text('Manual Question IDs'), findsOneWidget);
    expect(find.text('Paper ID'), findsNothing);
    expect(find.text('Part ID'), findsNothing);
    expect(find.text('Topic ID'), findsNothing);
    expect(find.text('Lesson ID'), findsNothing);
    expect(find.text('Syllabus Unit ID'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'Seeded Test');
    await tester.enterText(
      find.byKey(const ValueKey('initial-question-ids')),
      'visible-q, visible-q',
    );
    final load = find.byKey(const ValueKey('load-available-questions'));
    await tester.ensureVisible(load);
    await tester.tap(load);
    await tester.pumpAndSettle();

    expect(find.text('Visible paper question'), findsOneWidget);
    expect(find.text('visible-q'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('initial-question-visible-q')));
    await tester.pump();

    final submit = find.byKey(const ValueKey('submit-test'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.questionIds, isEmpty);
    expect(submitted!.questionCount, 10);
    expect(submittedIds, ['visible-q']);
  });
}

const _course = Course(
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
);

class _RecordingService extends AdminTestService {
  _RecordingService({
    super.testRepository,
    super.questionRepository,
    required this.questions,
    this.owners = const {},
  });

  final List<Question> questions;
  final Map<String, String> owners;
  bool? lastPreserveAssignments;

  @override
  Future<void> updateTest(
    TestModel test, {
    bool preserveAssignments = false,
  }) async {
    lastPreserveAssignments = preserveAssignments;
    await super.updateTest(test, preserveAssignments: preserveAssignments);
  }

  @override
  Future<List<Question>> loadQuestionsByIds(List<String> ids) async {
    return [
      for (final question in questions)
        if (ids.contains(question.id)) question,
    ];
  }

  @override
  Future<QuestionBankPage> loadAvailableInitialQuestionPage(
    TestModel test, {
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) async {
    return QuestionBankPage(
      questions: [
        for (final question in questions)
          if (AdminTestService.questionIsCompatibleWithTest(question, test) &&
              !owners.containsKey(question.id))
            question,
      ],
      hasMore: false,
    );
  }

  @override
  Future<AdminQuestionAssignmentState> loadQuestionAssignmentState(
    List<String> ids,
  ) async {
    return AdminQuestionAssignmentState(
      owners: {
        for (final id in ids)
          if (owners[id] != null) id: owners[id]!,
      },
      legacyTestIds: const {},
    );
  }
}

class _AvailableService extends AdminTestService {
  _AvailableService({
    required QuestionCloudRepository questions,
    this.owners = const {},
  }) : super(
         questionRepository: questions,
         testRepository: TestCloudRepository.withLoader((_) async => const []),
       );

  final Map<String, String> owners;

  @override
  Future<AdminQuestionAssignmentState> loadQuestionAssignmentState(
    List<String> ids,
  ) async {
    return AdminQuestionAssignmentState(
      owners: {
        for (final id in ids)
          if (owners[id] != null) id: owners[id]!,
      },
      legacyTestIds: const {},
    );
  }
}

TestModel paperTest({
  String id = 'draft',
  TestCategoryType category = TestCategoryType.partTests,
  String? paperId = 'group-ii-paper-i',
  String? seriesId,
  int? year,
  String? syllabusUnitId,
  List<String> questionIds = const [],
  int questionCount = 10,
}) {
  return TestModel(
    id: id,
    examId: 'group-ii',
    category: category,
    title: 'Scoped Test',
    questionCount: questionCount,
    marks: 10,
    durationMinutes: 30,
    negativeMarking: '0',
    difficulty: 'Medium',
    questionIds: questionIds,
    paperId: paperId,
    seriesId: seriesId,
    year: year,
    syllabusUnitId: syllabusUnitId,
  );
}

Question _seriesQuestion(
  String id, {
  required String category,
  String paperId = 'group-ii-paper-i',
  String? seriesId,
  int? year,
  String text = 'Series question',
}) {
  final now = DateTime(2026, 9, 29);
  return Question(
    id: id,
    courseId: 'group-ii',
    paperId: paperId,
    question: text,
    options: const ['A', 'B'],
    correctOption: 'A',
    explanation: '',
    difficulty: QuestionDifficulty.medium,
    questionType: QuestionType.practice,
    marks: 1,
    negativeMarks: 0,
    tags: const [],
    estimatedTime: const Duration(seconds: 30),
    createdAt: now,
    updatedAt: now,
    year: year,
    contentArea: AdminQuestionScope.contentAreaTestSeries,
    testSeriesCategory: category,
    seriesId: seriesId,
  );
}

Question _chapterQuestion(String id, {String? majorStudyAreaId}) {
  final now = DateTime(2026, 9, 29);
  return Question(
    id: id,
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    question: 'Chapter question',
    options: const ['A', 'B'],
    correctOption: 'A',
    explanation: '',
    difficulty: QuestionDifficulty.medium,
    questionType: QuestionType.practice,
    marks: 1,
    negativeMarks: 0,
    tags: const [],
    estimatedTime: const Duration(seconds: 30),
    createdAt: now,
    updatedAt: now,
    contentArea: AdminQuestionScope.contentAreaChapter,
    syllabus: majorStudyAreaId == null
        ? null
        : QuestionSyllabusAttribution(
            courseId: 'group-ii',
            paperId: 'group-ii-paper-i',
            majorStudyAreaId: majorStudyAreaId,
          ),
  );
}
