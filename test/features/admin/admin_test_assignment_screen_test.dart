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
    expect(find.text('First assigned Question'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('remove-question-q-missing')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('remove-question-q-one')), findsOneWidget);
  });

  testWidgets('add stages locally and Save writes the ordered IDs once', (
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
    await _scrollTo(tester, questionFinder);
    tester.widget<CheckboxListTile>(questionFinder).onChanged!.call(true);
    await tester.pump();
    final assignFinder = find.byKey(
      const ValueKey('assign-selected-questions'),
    );
    tester.widget<FilledButton>(assignFinder).onPressed!.call();
    await tester.pumpAndSettle();
    await _scrollToTop(tester);

    expect(service.updateCalls, 0);
    expect(service.updatedIds, isNull);
    expect(find.text('3 / 160 assigned'), findsOneWidget);
    expect(find.text('Pending changes are not saved yet.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-assignment-changes')));
    await tester.pumpAndSettle();

    expect(service.updateCalls, 1);
    expect(service.updatedIds, const ['q-missing', 'q-one', 'q-two']);
  });

  testWidgets('owner-only record is presented as a conflict, not membership', (
    tester,
  ) async {
    final service = _FakeAdminTestService(
      test: chapterTest,
      assigned: [_question('q-one', 'First assigned Question')],
      available: [_question('q-orphan', 'Owner-only Question')],
      owners: const {'q-one': 'test-1', 'q-orphan': 'test-1'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestAssignmentScreen(test: chapterTest, service: service),
      ),
    );
    await tester.pumpAndSettle();

    final orphan = find.byKey(const ValueKey('assignable-question-q-orphan'));
    await _scrollTo(tester, orphan);
    final checkbox = tester.widget<CheckboxListTile>(orphan);
    expect(checkbox.onChanged, isNull);
    expect(find.text('Ownership record conflict'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('remove-question-q-orphan')),
      findsNothing,
    );
    await _scrollToTop(tester);
    expect(find.text('2 / 160 assigned'), findsOneWidget);
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

    final other = find.byKey(const ValueKey('assignable-question-q-other'));
    await _scrollTo(tester, other);
    final checkbox = tester.widget<CheckboxListTile>(other);
    expect(checkbox.onChanged, isNull);
    expect(find.text('Assigned to another Test'), findsOneWidget);
    final legacy = find.byKey(const ValueKey('assignable-question-q-legacy'));
    await _scrollTo(tester, legacy);
    final legacyCheckbox = tester.widget<CheckboxListTile>(legacy);
    expect(legacyCheckbox.onChanged, isNull);
    expect(find.text('Legacy Test reference not verified'), findsWidgets);
  });

  testWidgets('remove stays staged until Save', (tester) async {
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

    expect(service.updateCalls, 0);
    expect(service.updatedIds, isNull);
    expect(find.text('1 / 160 assigned'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-assignment-changes')));
    await tester.pumpAndSettle();

    expect(service.updateCalls, 1);
    expect(service.updatedIds, const ['q-missing']);
  });

  testWidgets('draft inactive released Question can be staged and saved', (
    tester,
  ) async {
    final released = _question(
      'q-released',
      'Released draft Question',
      isActive: false,
      status: QuestionPublicationStatus.draft,
    );
    final published = _test(
      questionIds: const ['q-one'],
      status: TestPublicationStatus.published,
    );
    final service = _FakeAdminTestService(
      test: published,
      assigned: [_question('q-one', 'Assigned')],
      available: [released],
      owners: const {'q-one': 'test-1'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestAssignmentScreen(test: published, service: service),
      ),
    );
    await tester.pumpAndSettle();

    final releasedFinder = find.byKey(
      const ValueKey('assignable-question-q-released'),
    );
    await _scrollTo(tester, releasedFinder);
    final checkbox = tester.widget<CheckboxListTile>(releasedFinder);
    expect(checkbox.onChanged, isNotNull);
    checkbox.onChanged!(true);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('assign-selected-questions')));
    await tester.pump();
    expect(service.updateCalls, 0);

    await tester.tap(find.byKey(const ValueKey('save-assignment-changes')));
    await tester.pumpAndSettle();

    expect(service.updateCalls, 1);
    expect(service.updatedIds, ['q-one', 'q-released']);
  });

  testWidgets('archived Question is unavailable', (tester) async {
    final service = _FakeAdminTestService(
      test: _test(questionIds: const []),
      assigned: const [],
      available: [
        _question(
          'q-archived',
          'Archived',
          isActive: false,
          status: QuestionPublicationStatus.archived,
        ),
      ],
      owners: const {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestAssignmentScreen(test: service.test, service: service),
      ),
    );
    await tester.pumpAndSettle();

    final archivedFinder = find.byKey(
      const ValueKey('assignable-question-q-archived'),
    );
    await _scrollTo(tester, archivedFinder);
    final checkbox = tester.widget<CheckboxListTile>(archivedFinder);
    expect(checkbox.onChanged, isNull);
    expect(find.text('Archived Question cannot be assigned'), findsOneWidget);
  });

  testWidgets('back with no changes exits without a write', (tester) async {
    final service = _FakeAdminTestService(
      test: _test(questionIds: const ['q-one']),
      assigned: [_question('q-one', 'Assigned')],
      available: const [],
      owners: const {'q-one': 'test-1'},
    );
    bool? result;
    await _pumpRouteHarness(tester, service, (value) => result = value);

    await tester.tap(find.byKey(const ValueKey('open-manage')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(service.updateCalls, 0);
  });

  testWidgets('back with staged changes requires discard and writes nothing', (
    tester,
  ) async {
    final service = _FakeAdminTestService(
      test: _test(questionIds: const ['q-one']),
      assigned: [_question('q-one', 'Assigned')],
      available: const [],
      owners: const {'q-one': 'test-1'},
    );
    bool? result;
    await _pumpRouteHarness(tester, service, (value) => result = value);

    await tester.tap(find.byKey(const ValueKey('open-manage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('remove-question-q-one')));
    await tester.pump();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard unsaved Question changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 160 assigned'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cancel-assignment-changes')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(service.updateCalls, 0);
    expect(service.test.questionIds, ['q-one']);
  });

  testWidgets('failed Save retains staged membership for retry', (
    tester,
  ) async {
    final service = _FakeAdminTestService(
      test: _test(questionIds: const ['q-one']),
      assigned: [_question('q-one', 'Assigned')],
      available: [_question('q-two', 'New Question')],
      owners: const {'q-one': 'test-1'},
      updateError: const FormatException('Authoritative save rejected.'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestAssignmentScreen(test: service.test, service: service),
      ),
    );
    await tester.pumpAndSettle();

    final questionFinder = find.byKey(
      const ValueKey('assignable-question-q-two'),
    );
    await _scrollTo(tester, questionFinder);
    tester.widget<CheckboxListTile>(questionFinder).onChanged!(true);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('assign-selected-questions')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-assignment-changes')));
    await tester.pumpAndSettle();
    await _scrollToTop(tester);

    expect(service.updateCalls, 1);
    expect(find.text('Authoritative save rejected.'), findsOneWidget);
    expect(find.text('2 / 160 assigned'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('save-assignment-changes')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('manual IDs normalize duplicates and stage without writing', (
    tester,
  ) async {
    final service = _FakeAdminTestService(
      test: _test(questionIds: const []),
      assigned: const [],
      available: [
        _question(
          'q-draft',
          'Draft manual Question',
          isActive: false,
          status: QuestionPublicationStatus.draft,
        ),
      ],
      owners: const {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestAssignmentScreen(test: service.test, service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('managed-question-ids')),
      'q-draft, q-draft\n',
    );
    await tester.tap(find.byKey(const ValueKey('stage-manual-question-ids')));
    await tester.pumpAndSettle();

    expect(find.text('1 / 160 assigned'), findsOneWidget);
    expect(find.text('Draft manual Question'), findsOneWidget);
    expect(service.updateCalls, 0);
  });

  testWidgets('manual ID validation reports the exact missing ID', (
    tester,
  ) async {
    final service = _FakeAdminTestService(
      test: _test(questionIds: const []),
      assigned: const [],
      available: const [],
      owners: const {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestAssignmentScreen(test: service.test, service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('managed-question-ids')),
      'missing-id',
    );
    await tester.tap(find.byKey(const ValueKey('stage-manual-question-ids')));
    await tester.pumpAndSettle();

    expect(find.text('Question "missing-id" does not exist.'), findsOneWidget);
    expect(service.updateCalls, 0);
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
      scrollable: find.byType(Scrollable).first,
    );
    final checkbox = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('assignable-question-q-extra')),
    );
    expect(checkbox.onChanged, isNull);
  });

  test(
    'published Test accepts a draft inactive Question in client preflight',
    () async {
      final published = _test(
        questionIds: const [],
        status: TestPublicationStatus.published,
      );
      Map<String, dynamic>? written;
      final service = AdminTestService(
        testRepository: TestCloudRepository.withLoader(
          (_) async => const [],
          getById: (_) async => published,
          update: ({required testId, required data}) async => written = data,
        ),
        questionRepository: QuestionCloudRepository.withHandlers(
          getByIds: (_) async => [
            _question(
              'q-draft',
              'Draft inactive',
              isActive: false,
              status: QuestionPublicationStatus.draft,
            ),
          ],
        ),
      );

      await service.updateTest(
        _test(
          questionIds: const ['q-draft'],
          status: TestPublicationStatus.published,
        ),
      );

      expect(written?['questionIds'], ['q-draft']);
    },
  );

  test(
    'client preflight rejects newly added archived but preserves existing',
    () async {
      var current = _test(questionIds: const []);
      var writes = 0;
      final archived = _question(
        'q-archived',
        'Archived',
        isActive: false,
        status: QuestionPublicationStatus.archived,
      );
      final service = AdminTestService(
        testRepository: TestCloudRepository.withLoader(
          (_) async => const [],
          getById: (_) async => current,
          update: ({required testId, required data}) async => writes++,
        ),
        questionRepository: QuestionCloudRepository.withHandlers(
          getByIds: (_) async => [archived],
        ),
      );

      await expectLater(
        service.updateTest(_test(questionIds: const ['q-archived'])),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Archived Question "q-archived" cannot be assigned.'),
          ),
        ),
      );
      expect(writes, 0);

      current = _test(
        questionIds: const ['q-archived'],
        status: TestPublicationStatus.archived,
      );
      await service.updateTest(current, preserveAssignments: true);
      expect(writes, 1);
    },
  );

  test(
    'manual validation allows draft inactive and rejects archived or owned',
    () async {
      final test = _test(questionIds: const []);
      final questions = [
        _question(
          'q-draft',
          'Draft inactive',
          isActive: false,
          status: QuestionPublicationStatus.draft,
        ),
        _question(
          'q-archived',
          'Archived',
          isActive: false,
          status: QuestionPublicationStatus.archived,
        ),
        _question('q-owned', 'Owned'),
        _question('q-orphan', 'Orphan owner'),
      ];
      final service = _StateBackedAdminTestService(
        questions: questions,
        owners: const {'q-owned': 'another-test', 'q-orphan': 'test-1'},
      );

      expect(
        await service.normalizeManagedQuestionIds(test, const [], const [
          'q-draft, q-draft',
        ]),
        ['q-draft'],
      );
      await expectLater(
        service.normalizeManagedQuestionIds(test, const [], const [
          'q-archived',
        ]),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Archived Question "q-archived" cannot be assigned.',
          ),
        ),
      );
      await expectLater(
        service.normalizeManagedQuestionIds(test, const [], const ['q-owned']),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Question "q-owned" is already assigned to another Test.',
          ),
        ),
      );
      await expectLater(
        service.normalizeManagedQuestionIds(test, const [], const ['q-orphan']),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Question "q-orphan" has an ownership record conflict.',
          ),
        ),
      );
    },
  );

  test(
    'manual validation enforces staged duplicates and the 160 cap',
    () async {
      final service = AdminTestService();
      final test = _test(questionIds: const []);

      await expectLater(
        service.normalizeManagedQuestionIds(
          test,
          const ['q-existing'],
          const ['q-existing'],
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Question "q-existing" is already staged for this Test.',
          ),
        ),
      );
      await expectLater(
        service.normalizeManagedQuestionIds(
          test,
          [for (var i = 0; i < 160; i++) 'q-$i'],
          const ['q-extra'],
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'A Test can assign at most 160 Questions.',
          ),
        ),
      );
    },
  );

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
    this.updateError,
  }) : super();

  TestModel test;
  final List<Question> assigned;
  final List<Question> available;
  final Map<String, String> owners;
  final Map<String, List<String>> legacyTestIds;
  final Object? updateError;
  List<String>? updatedIds;
  int updateCalls = 0;

  @override
  Future<TestModel?> getTest(String testId) async => test;

  @override
  Future<List<Question>> loadQuestionsByIds(List<String> ids) async {
    final all = <String, Question>{
      for (final question in assigned) question.id: question,
      for (final question in available) question.id: question,
    };
    return [
      for (final id in ids)
        if (all[id] != null) all[id]!,
    ];
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
  Future<List<String>> normalizeManagedQuestionIds(
    TestModel test,
    List<String> stagedIds,
    Iterable<String> rawIds,
  ) async {
    final ids = AdminTestService.dedupeQuestionIds(rawIds);
    final all = <String, Question>{
      for (final question in assigned) question.id: question,
      for (final question in available) question.id: question,
    };
    for (final id in ids) {
      if (stagedIds.contains(id)) {
        throw FormatException(
          'Question "$id" is already staged for this Test.',
        );
      }
      final question = all[id];
      if (question == null) {
        throw FormatException('Question "$id" does not exist.');
      }
      if (question.status == QuestionPublicationStatus.archived) {
        throw FormatException('Archived Question "$id" cannot be assigned.');
      }
      final owner = owners[id];
      if (owner != null && owner != test.id) {
        throw FormatException(
          'Question "$id" is already assigned to another Test.',
        );
      }
      if (owner == test.id && !test.questionIds.contains(id)) {
        throw FormatException(
          'Question "$id" has an ownership record conflict.',
        );
      }
    }
    if (stagedIds.length + ids.length > 160) {
      throw const FormatException('A Test can assign at most 160 Questions.');
    }
    return ids;
  }

  @override
  Future<void> updateTest(
    TestModel test, {
    bool preserveAssignments = false,
  }) async {
    updateCalls++;
    if (updateError != null) throw updateError!;
    updatedIds = test.questionIds;
    this.test = _test(
      questionIds: test.questionIds,
      category: test.category,
      paperId: test.paperId,
      seriesId: test.seriesId,
      year: test.year,
      status: test.status,
    );
  }
}

class _StateBackedAdminTestService extends AdminTestService {
  _StateBackedAdminTestService({
    required this.questions,
    this.owners = const {},
  });

  final List<Question> questions;
  final Map<String, String> owners;

  @override
  Future<List<Question>> loadQuestionsByIds(List<String> ids) async => [
    for (final question in questions)
      if (ids.contains(question.id)) question,
  ];

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

Future<void> _scrollTo(WidgetTester tester, Finder finder) {
  return tester.scrollUntilVisible(
    finder,
    400,
    scrollable: find.byType(Scrollable).first,
  );
}

Future<void> _scrollToTop(WidgetTester tester) async {
  final scrollable = tester.state<ScrollableState>(
    find.byType(Scrollable).first,
  );
  scrollable.position.jumpTo(0);
  await tester.pump();
}

Future<void> _pumpRouteHarness(
  WidgetTester tester,
  _FakeAdminTestService service,
  ValueChanged<bool?> onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const ValueKey('open-manage'),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AdminTestAssignmentScreen(
                    test: service.test,
                    service: service,
                  ),
                ),
              );
              onResult(result);
            },
            child: const Text('Open Manage'),
          ),
        ),
      ),
    ),
  );
}

Question _question(
  String id,
  String text, {
  bool isActive = true,
  QuestionPublicationStatus? status,
}) {
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
    isActive: isActive,
    status: status,
    contentArea: 'chapter',
  );
}

TestModel _test({
  required List<String> questionIds,
  TestCategoryType category = TestCategoryType.chapterTests,
  String? paperId,
  String? seriesId,
  int? year,
  TestPublicationStatus status = TestPublicationStatus.draft,
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
    status: status,
    paperId: paperId,
    seriesId: seriesId,
    year: year,
  );
}
