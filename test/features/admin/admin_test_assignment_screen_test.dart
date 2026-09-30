import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_content_callable_client.dart';
import 'package:telangana_prep/features/admin/data/admin_test_series_question_query.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_assignment_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_test_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';

void main() {
  final chapterTest = _test(questionIds: const ['q-missing', 'q-one']);

  testWidgets('shows ordered assigned Questions and safe missing references', (
    tester,
  ) async {
    final service = _FakeAdminTestService(
      test: chapterTest,
      assigned: [_question('q-one', 'First assigned Question')],
      available: [_question('q-one', 'First assigned Question')],
      owners: const {'q-one': 'test-1'},
      legacyTestIds: const {
        'q-missing': ['legacy-test'],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestAssignmentScreen(test: chapterTest, service: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Missing Question reference: q-missing'), findsOneWidget);
    expect(
      find.text(
        'Legacy Test reference not verified; the reference was not removed '
        'automatically.',
      ),
      findsOneWidget,
    );
    expect(find.text('First assigned Question'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('remove-question-q-missing')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('remove-question-q-one')), findsOneWidget);
  });

  testWidgets('selects and appends through the authoritative Test update', (
    tester,
  ) async {
    final service = _FakeAdminTestService(
      test: chapterTest,
      assigned: [_question('q-one', 'First assigned Question')],
      available: [
        _question('q-one', 'First assigned Question'),
        _question('q-two', 'New compatible Question'),
      ],
      owners: const {'q-one': 'test-1'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestAssignmentScreen(test: chapterTest, service: service),
      ),
    );
    await tester.pumpAndSettle();

    final questionFinder = find.byKey(
      const ValueKey('assignable-question-q-two'),
    );
    tester.widget<CheckboxListTile>(questionFinder).onChanged!.call(true);
    await tester.pump();
    final assignFinder = find.byKey(
      const ValueKey('assign-selected-questions'),
    );
    tester.widget<FilledButton>(assignFinder).onPressed!.call();
    await tester.pumpAndSettle();

    expect(service.updatedIds, const ['q-missing', 'q-one', 'q-two']);
  });

  testWidgets('does not allow a Question assigned to another Test', (
    tester,
  ) async {
    final service = _FakeAdminTestService(
      test: chapterTest,
      assigned: const [],
      available: [
        _question('q-other', 'Owned elsewhere'),
        _question('q-legacy', 'Legacy ownership'),
      ],
      owners: const {'q-other': 'test-2'},
      legacyTestIds: const {
        'q-legacy': ['legacy-test'],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestAssignmentScreen(test: chapterTest, service: service),
      ),
    );
    await tester.pumpAndSettle();

    final checkbox = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('assignable-question-q-other')),
    );
    expect(checkbox.onChanged, isNull);
    expect(find.text('Assigned to another Test'), findsOneWidget);
    final legacyCheckbox = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('assignable-question-q-legacy')),
    );
    expect(legacyCheckbox.onChanged, isNull);
    expect(find.text('Legacy Test reference not verified'), findsWidgets);
  });

  testWidgets('remove updates only the ordered Test IDs', (tester) async {
    final service = _FakeAdminTestService(
      test: chapterTest,
      assigned: [_question('q-one', 'First assigned Question')],
      available: const [],
      owners: const {'q-one': 'test-1'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestAssignmentScreen(test: chapterTest, service: service),
      ),
    );
    await tester.pumpAndSettle();

    tester
        .widget<IconButton>(find.byKey(const ValueKey('remove-question-q-one')))
        .onPressed!
        .call();
    await tester.pump();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(service.updatedIds, const ['q-missing']);
  });

  testWidgets('disables selection at the 160 Question limit', (tester) async {
    final fullTest = _test(questionIds: [for (var i = 0; i < 160; i++) 'q-$i']);
    final service = _FakeAdminTestService(
      test: fullTest,
      assigned: const [],
      available: [_question('q-extra', 'Over capacity')],
      owners: const {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestAssignmentScreen(test: fullTest, service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('assignable-question-q-extra')),
      500,
    );
    final checkbox = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('assignable-question-q-extra')),
    );
    expect(checkbox.onChanged, isNull);
  });

  test('Test Series compatibility keeps the bank discriminators', () async {
    final queries = <AdminTestSeriesQuestionQuery>[];
    final questions = QuestionCloudRepository.withHandlers(
      loadTestSeriesQuestionPage: (query) async {
        queries.add(query);
        return const QuestionBankPage(questions: [], hasMore: false);
      },
    );
    final service = AdminTestService(
      questionRepository: questions,
      testRepository: TestCloudRepository(),
    );

    await service.loadCompatibleQuestionPage(
      _test(
        questionIds: const [],
        category: TestCategoryType.partTests,
        paperId: 'group-ii-paper-i',
      ),
    );
    await service.loadCompatibleQuestionPage(
      _test(
        questionIds: const [],
        category: TestCategoryType.mockTests,
        seriesId: 'Grand Test - I',
      ),
    );
    await service.loadCompatibleQuestionPage(
      _test(
        questionIds: const [],
        category: TestCategoryType.previousYear,
        year: 2024,
      ),
    );

    expect(queries, hasLength(3));
    expect(
      queries[0].equalityFilters.map(
        (filter) => '${filter.field}=${filter.value}',
      ),
      [
        'contentArea=testSeries',
        'testSeriesCategory=part',
        'courseId=group-ii',
        'paperId=group-ii-paper-i',
      ],
    );
    expect(
      queries[1].equalityFilters.map(
        (filter) => '${filter.field}=${filter.value}',
      ),
      [
        'contentArea=testSeries',
        'testSeriesCategory=mock',
        'courseId=group-ii',
        'seriesId=Grand Test - I',
      ],
    );
    expect(
      queries[2].equalityFilters.map(
        (filter) => '${filter.field}=${filter.value}',
      ),
      [
        'contentArea=testSeries',
        'testSeriesCategory=previousyear',
        'courseId=group-ii',
        'year=2024',
      ],
    );
  });

  test('Chapter compatibility excludes Test-Series Questions', () async {
    final questions = QuestionCloudRepository.withHandlers(
      loadQuestions: (_) async => [
        _question('chapter', 'Chapter Question'),
        Question(
          id: 'series',
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
          question: 'Test-Series Question',
          options: const ['A', 'B'],
          correctOption: 'A',
          explanation: '',
          difficulty: QuestionDifficulty.medium,
          questionType: QuestionType.practice,
          marks: 1,
          negativeMarks: 0,
          tags: const [],
          estimatedTime: const Duration(seconds: 60),
          createdAt: DateTime(2026, 9, 28),
          updatedAt: DateTime(2026, 9, 28),
          isActive: true,
          contentArea: 'testSeries',
          testSeriesCategory: 'part',
        ),
      ],
    );
    final service = AdminTestService(
      questionRepository: questions,
      testRepository: TestCloudRepository(),
    );

    final page = await service.loadCompatibleQuestionPage(chapterTest);
    expect(page.questions.map((question) => question.id), ['chapter']);
  });
}

class _FakeAdminTestService extends AdminTestService {
  _FakeAdminTestService({
    required this.test,
    required this.assigned,
    required this.available,
    required this.owners,
    this.legacyTestIds = const {},
  }) : super();

  final TestModel test;
  final List<Question> assigned;
  final List<Question> available;
  final Map<String, String> owners;
  final Map<String, List<String>> legacyTestIds;
  List<String>? updatedIds;

  @override
  Future<TestModel?> getTest(String testId) async => test;

  @override
  Future<List<Question>> loadQuestionsByIds(List<String> ids) async => assigned;

  @override
  Future<AdminQuestionAssignmentState> loadQuestionAssignmentState(
    List<String> ids,
  ) async {
    return AdminQuestionAssignmentState(
      owners: {
        for (final id in ids)
          if (owners[id] != null) id: owners[id]!,
      },
      legacyTestIds: {
        for (final id in ids)
          if (legacyTestIds[id] != null) id: legacyTestIds[id]!,
      },
    );
  }

  @override
  Future<QuestionBankPage> loadCompatibleQuestionPage(
    TestModel test, {
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) async {
    return QuestionBankPage(questions: available, hasMore: false);
  }

  @override
  Future<void> updateTest(
    TestModel test, {
    bool preserveAssignments = false,
  }) async {
    updatedIds = test.questionIds;
  }
}

Question _question(String id, String text) {
  final now = DateTime(2026, 9, 28);
  return Question(
    id: id,
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    question: text,
    options: const ['A', 'B'],
    correctOption: 'A',
    explanation: '',
    difficulty: QuestionDifficulty.medium,
    questionType: QuestionType.practice,
    marks: 1,
    negativeMarks: 0,
    tags: const [],
    estimatedTime: const Duration(seconds: 60),
    createdAt: now,
    updatedAt: now,
    isActive: true,
  );
}

TestModel _test({
  required List<String> questionIds,
  TestCategoryType category = TestCategoryType.chapterTests,
  String? paperId,
  String? seriesId,
  int? year,
}) {
  return TestModel(
    id: 'test-1',
    examId: 'group-ii',
    category: category,
    title: 'Chapter Test',
    questionCount: questionIds.length,
    marks: questionIds.length,
    durationMinutes: questionIds.length,
    negativeMarking: '0',
    difficulty: 'Medium',
    questionIds: questionIds,
    status: TestPublicationStatus.draft,
    paperId: paperId,
    seriesId: seriesId,
    year: year,
  );
}
