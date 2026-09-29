import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/data/admin_test_series_question_query.dart';
import 'package:telangana_prep/features/admin/data/models/question_import_models.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_series_question_bank_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/admin/services/admin_question_test_assignment.dart';
import 'package:telangana_prep/features/admin/services/question_import_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_cloud_mapper.dart';
import 'package:telangana_prep/features/question_bank/data/question_content_fingerprint.dart';
import 'package:telangana_prep/features/question_bank/data/question_fingerprint_query.dart';
import 'package:telangana_prep/features/question_bank/data/question_search_text.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
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

  Question sample({
    String id = 'q-1',
    String courseId = 'group-ii',
    String paperId = 'group-ii-paper-i',
    String text = 'Which city is the capital?',
    QuestionItemFormat format = QuestionItemFormat.standardMcq,
    List<String> statements = const [],
    List<String> teluguStatements = const ['ఒకటి'],
    List<String>? englishOptions,
    String firstOption = 'Warangal',
    String? contentFingerprint,
    QuestionPublicationStatus? status = QuestionPublicationStatus.draft,
    QuestionSyllabusAttribution? syllabus,
  }) {
    final now = DateTime(2026, 9, 28);
    final statement = format == QuestionItemFormat.statementMcq;
    final optionTexts =
        englishOptions ?? [firstOption, 'Hyderabad', 'Nizamabad', 'Karimnagar'];
    return Question(
      id: id,
      courseId: courseId,
      paperId: paperId,
      question: text,
      options: optionTexts,
      correctOption: 'B',
      explanation: 'Hyderabad.',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      isActive: false,
      status: status,
      itemFormat: format,
      contentFingerprint: contentFingerprint,
      syllabus: syllabus,
      content: QuestionContent(
        en: QuestionLocalizedContent(
          question: text,
          options: [
            for (final option in optionTexts) QuestionOption(text: option),
          ],
          explanation: 'Hyderabad.',
          statements: statements,
        ),
        te: QuestionLocalizedContent(
          question: 'రాజధాని ఏది?',
          options: statement
              ? const []
              : const [
                  QuestionOption(text: 'వరంగల్'),
                  QuestionOption(text: 'హైదరాబాద్'),
                  QuestionOption(text: 'నిజామాబాద్'),
                  QuestionOption(text: 'కరీంనగర్'),
                ],
          explanation: 'హైదరాబాద్.',
          statements: statement ? teluguStatements : const [],
        ),
      ),
    );
  }

  AdminTestSeriesQuestionQuery queryFor(
    AdminQuestionScope scope, {
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) {
    return AdminTestSeriesQuestionQuery.fromScope(
      scope,
      searchText: searchText,
      cursorDocumentId: cursorDocumentId,
      cursorSearchText: cursorSearchText,
    );
  }

  test('bank pages use a fixed cursor read, not offset or a growing limit', () {
    final first = queryFor(paperScope).cursorPlan;
    final next = queryFor(paperScope, cursorDocumentId: 'q-50').cursorPlan;
    expect(AdminTestSeriesQuestionQuery.pageSize, 50);
    expect(first.limit, 51);
    expect(first.usesOffset, isFalse);
    expect(first.orderBy, ['__name__']);
    expect(first.startAfter, isNull);
    expect(next.limit, 51);
    expect(next.startAfter, ['q-50']);
    expect(next.usesOffset, isFalse);
    for (final scope in [paperScope, grandScope, previousScope]) {
      final plan = queryFor(scope, cursorDocumentId: 'q-1');
      expect(
        plan.equalityFilters.any((filter) => filter.field == 'contentArea'),
        isTrue,
      );
      expect(plan.cursorPlan.orderBy, ['__name__']);
      expect(plan.cursorPlan.limit, 51);
    }
    expect(queryFor(paperScope).equalityFilters.last.value, 'group-ii-paper-i');
    expect(
      queryFor(grandScope).equalityFilters.last.value,
      GrandTestSeries.grandTestII,
    );
    expect(queryFor(previousScope).equalityFilters.last.value, 2024);
  });

  test('search stays inside the bank and paginates by prefix cursor', () {
    final paper = queryFor(paperScope, searchText: '  Capital   City ');
    expect(paper.normalizedSearch, 'capital city');
    expect(paper.searchPrefix, 'city');
    expect(paper.cursorPlan.orderBy, ['__name__']);
    expect(paper.cursorPlan.arrayContains, 'city');
    expect(paper.cursorPlan.startAt, isNull);
    expect(paper.cursorPlan.endAt, isNull);
    expect(paper.cursorPlan.limit, 51);
    expect(paper.cursorPlan.usesOffset, isFalse);
    expect(
      paper.equalityFilters.map((filter) => filter.field),
      containsAll(['contentArea', 'testSeriesCategory', 'courseId', 'paperId']),
    );
    expect(
      paper.equalityFilters.any((filter) => filter.value == 'chapter'),
      isFalse,
    );

    final grand = queryFor(grandScope, searchText: 'capital');
    expect(grand.equalityFilters.last, (
      field: 'seriesId',
      value: GrandTestSeries.grandTestII,
    ));
    final previous = queryFor(previousScope, searchText: 'capital');
    expect(previous.equalityFilters.last, (field: 'year', value: 2024));

    final second = queryFor(
      paperScope,
      searchText: 'capital',
      cursorDocumentId: 'q-2',
      cursorSearchText: 'capital of telangana',
    );
    expect(second.cursorPlan.startAt, isNull);
    expect(second.cursorPlan.arrayContains, 'capital');
    expect(second.cursorPlan.startAfter, ['q-2']);
    final cleared = queryFor(paperScope, searchText: '   ');
    expect(cleared.normalizedSearch, isNull);
    expect(cleared.cursorPlan.orderBy, ['__name__']);
    expect(cleared.cursorPlan.startAfter, isNull);
  });

  test('fingerprint chunks stay bounded and do not scan a bank', () {
    final many = [for (var i = 0; i < 61; i++) 'fp-$i'];
    final groups = QuestionFingerprintQuery.chunks(many);
    expect(groups, hasLength(3));
    expect(groups.every((group) => group.length <= 30), isTrue);
    expect(groups.first, hasLength(30));
  });

  test('manual create and edit persist the shared fingerprint', () async {
    final created = <Map<String, dynamic>>[];
    final updates = <Map<String, dynamic>>[];
    final lookups = <List<({String field, Object value})>>[];
    final repository = QuestionCloudRepository.withHandlers(
      create: ({required questionId, required data}) async {
        created.add(data);
      },
      update: ({required questionId, required data}) async {
        updates.add(data);
      },
      findFingerprints:
          ({required fingerprints, required equalityFilters}) async {
            lookups.add(equalityFilters);
            return {};
          },
    );
    final service = AdminQuestionService(questionRepository: repository);
    final standard = sample(id: '');
    final statement = sample(
      id: '',
      format: QuestionItemFormat.statementMcq,
      statements: const ['Hyderabad is the capital.'],
    );
    final chapter = sample(id: '', paperId: 'group-ii-paper-ii', status: null);

    await service.createQuestion(standard, scope: paperScope);
    await service.createQuestion(statement, scope: paperScope);
    await service.createQuestion(chapter);

    expect(
      created[0]['contentFingerprint'],
      QuestionContentFingerprint.fromQuestion(standard),
    );
    expect(
      created[1]['contentFingerprint'],
      QuestionContentFingerprint.fromQuestion(statement),
    );
    expect(
      created[0]['contentFingerprint'],
      isNot(created[1]['contentFingerprint']),
    );
    expect(
      created[2]['contentFingerprint'],
      QuestionContentFingerprint.fromQuestion(chapter),
    );
    expect(created[2]['contentFingerprint'], contains('group-ii-paper-ii'));
    expect(created.every((row) => row.containsKey('assignedTestId')), isFalse);
    expect(
      created.first[QuestionSearchText.field],
      'which city is the capital?',
    );
    expect(lookups.first.any((filter) => filter.field == 'paperId'), isTrue);
    expect(lookups[2].any((filter) => filter.field == 'seriesId'), isFalse);

    final edited = sample(
      id: 'q-edit',
      text: 'Changed capital question',
      syllabus: const QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        majorStudyAreaId: 'group-ii-paper-i-area-01',
        contentTopicId: 'group-ii-paper-i-area-01-topic-01',
      ),
    );
    final before = QuestionContentFingerprint.fromQuestion(standard);
    final after = QuestionContentFingerprint.fromQuestion(edited);
    expect(after, isNot(before));
    await service.updateQuestion(edited);
    expect(updates.single['contentFingerprint'], after);
    expect(updates.single.containsKey('testId'), isFalse);
  });

  test('exact duplicate blocks create and does not write', () async {
    var writes = 0;
    final question = sample(id: '');
    final fingerprint = QuestionContentFingerprint.fromQuestion(question);
    final repository = QuestionCloudRepository.withHandlers(
      create: ({required questionId, required data}) async {
        writes += 1;
      },
      findFingerprints:
          ({required fingerprints, required equalityFilters}) async {
            expect(fingerprints, [fingerprint]);
            expect(
              fingerprints.single,
              QuestionCloudMapper.toFirestore(
                question,
                documentId: 'generated-on-create',
              )['contentFingerprint'],
            );
            expect(equalityFilters.length, lessThan(8));
            return {fingerprint};
          },
    );
    final service = AdminQuestionService(questionRepository: repository);
    expect(
      () => service.createQuestion(question, scope: paperScope),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('exact duplicate'),
        ),
      ),
    );
    expect(writes, 0);

    final open = QuestionCloudRepository.withHandlers(
      create: ({required questionId, required data}) async {
        writes += 1;
      },
      findFingerprints:
          ({required fingerprints, required equalityFilters}) async => {},
    );
    await AdminQuestionService(
      questionRepository: open,
    ).createQuestion(question, scope: paperScope);
    expect(writes, 1);
  });

  test(
    'import uses the shared fingerprint and rejects a stored duplicate',
    () async {
      final record = QuestionImportRecord(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        question: const QuestionImportLocalizedText(
          en: 'Which city is the capital?',
          te: 'రాజధాని ఏది?',
        ),
        options: const [
          QuestionImportOption(en: 'Warangal', te: 'వరంగల్'),
          QuestionImportOption(en: 'Hyderabad', te: 'హైదరాబాద్'),
          QuestionImportOption(en: 'Nizamabad', te: 'నిజామాబాద్'),
          QuestionImportOption(en: 'Karimnagar', te: 'కరీంనగర్'),
        ],
        correctOption: 'B',
        explanation: const QuestionImportLocalizedText(
          en: 'Hyderabad.',
          te: 'హైదరాబాద్.',
        ),
        testId: 'paper-test',
      );
      final withoutTest = QuestionContentFingerprint.compute(
        courseId: record.courseId,
        paperId: record.paperId,
        itemFormat: record.itemFormat,
        questionEn: record.question.en,
        questionTe: record.question.te,
        correctOption: record.correctOption,
        options: [
          for (final option in record.options) (en: option.en, te: option.te),
        ],
        statements: const [],
      );
      expect(withoutTest, isNotEmpty);

      final created = <Map<String, dynamic>>[];
      final questions = QuestionCloudRepository.withHandlers(
        createBatch: ({required items}) async {
          created.addAll([for (final item in items) item.data]);
        },
        findFingerprints:
            ({required fingerprints, required equalityFilters}) async {
              expect(
                equalityFilters.any((filter) => filter.value == 'testSeries'),
                isTrue,
              );
              expect(fingerprints, contains(withoutTest));
              return {withoutTest};
            },
      );
      final service = QuestionImportService(
        questionRepository: questions,
        scope: paperScope,
      );
      final validation = await service.validateRecords([
        record,
        QuestionImportRecord(
          courseId: record.courseId,
          paperId: record.paperId,
          question: record.question,
          options: record.options,
          correctOption: record.correctOption,
          explanation: record.explanation,
        ),
      ]);
      expect(validation.warnings, isNotEmpty);
      expect(validation.canImport, isFalse);
      expect(
        validation.errors.any((error) => error.field == 'contentFingerprint'),
        isTrue,
      );
      final report = await service.importValidatedBatch(validation);
      expect(report.recordsImported, 0);
      expect(created, isEmpty);
    },
  );

  test('stored question text is normalized for prefix search on write', () {
    final data = QuestionCloudMapper.toFirestore(
      sample(id: 'q-search', text: '  Capital   CITY '),
      includeCreatedAt: true,
      documentId: 'q-search',
    );
    expect(data[QuestionSearchText.field], 'capital city');
  });

  test('manual create and import share one canonical fingerprint', () async {
    final created = <Map<String, dynamic>>[];
    final repository = QuestionCloudRepository.withHandlers(
      create: ({required questionId, required data}) async {
        created.add(data);
      },
      createBatch: ({required items}) async {
        created.addAll([for (final item in items) item.data]);
      },
      findFingerprints:
          ({required fingerprints, required equalityFilters}) async => {},
    );
    final questions = AdminQuestionService(questionRepository: repository);
    final testRepository = TestCloudRepository.withLoader(
      (_) async => const [],
      getById: (id) async {
        if (id != 'paper-test') return null;
        return const TestModel(
          id: 'paper-test',
          examId: 'group-ii',
          category: TestCategoryType.partTests,
          title: 'paper-test',
          questionCount: 0,
          marks: 0,
          durationMinutes: 10,
          negativeMarking: '0',
          difficulty: 'easy',
          questionIds: [],
          paperId: 'group-ii-paper-i',
        );
      },
      update: ({required testId, required data}) async {},
    );
    final imports = QuestionImportService(
      questionRepository: repository,
      scope: paperScope,
      tests: testRepository,
      assignment: AdminQuestionTestAssignment(tests: testRepository),
    );
    final grandImports = QuestionImportService(
      questionRepository: repository,
      scope: grandScope,
    );

    String wrap(List<Map<String, dynamic>> rows) =>
        jsonEncode({'questions': rows});

    Map<String, dynamic> row({
      String? itemFormat,
      List<Map<String, String>>? statements,
      String? testId,
      String? courseId,
      String? paperId,
      String questionEn = 'Which city is the capital?',
    }) {
      return {
        'courseId': ?courseId,
        'paperId': ?paperId,
        'itemFormat': ?itemFormat,
        'testId': ?testId,
        'question': {'en': questionEn, 'te': 'రాజధాని ఏది?'},
        'options': [
          {'en': 'Warangal', 'te': 'వరంగల్'},
          {'en': 'Hyderabad', 'te': 'హైదరాబాద్'},
          {'en': 'Nizamabad', 'te': 'నిజామాబాద్'},
          {'en': 'Karimnagar', 'te': 'కరీంనగర్'},
        ],
        'statements': ?statements,
        'correctOption': 'B',
        'explanation': {'en': 'Hyderabad.', 'te': 'హైదరాబాద్.'},
      };
    }

    await questions.createQuestion(sample(id: ''), scope: paperScope);
    await imports.validateAndImportJson(wrap([row()]));
    await imports.validateAndImportJson(
      wrap([row(courseId: 'group-ii', paperId: 'group-ii-paper-i')]),
    );
    await imports.validateAndImportJson(wrap([row(testId: 'paper-test')]));

    final manualStandard = created[0]['contentFingerprint'];
    expect(created[1]['contentFingerprint'], manualStandard);
    expect(created[2]['contentFingerprint'], manualStandard);
    expect(created[3]['contentFingerprint'], manualStandard);
    expect(created[3].containsKey('assignedTestId'), isFalse);

    final statements = [
      {'en': 'Hyderabad is the capital.', 'te': 'హైదరాబాద్ రాజధాని.'},
    ];
    await questions.createQuestion(
      sample(
        id: '',
        format: QuestionItemFormat.statementMcq,
        statements: const ['Hyderabad is the capital.'],
        teluguStatements: const ['హైదరాబాద్ రాజధాని.'],
        englishOptions: const ['1 only', '2 only', 'Both', 'Neither'],
      ),
      scope: paperScope,
    );
    await imports.validateAndImportJson(
      wrap([
        row(itemFormat: 'statement_mcq', statements: statements)
          ..['options'] = [
            {'en': '1 only'},
            {'en': '2 only'},
            {'en': 'Both'},
            {'en': 'Neither'},
          ],
      ]),
    );
    expect(created[5]['contentFingerprint'], created[4]['contentFingerprint']);

    await questions.createQuestion(
      sample(id: '', paperId: ''),
      scope: grandScope,
    );
    await grandImports.validateAndImportJson(wrap([row()]));
    final grandFingerprint = created[6]['contentFingerprint'] as String;
    expect(created[7]['contentFingerprint'], grandFingerprint);
    expect(grandFingerprint.split('::')[0], 'group-ii');
    expect(grandFingerprint.split('::')[1], isEmpty);
    expect(grandFingerprint.contains(GrandTestSeries.grandTestII), isFalse);

    final original = sample(id: 'q-edit');
    final written = QuestionCloudMapper.toFirestore(
      original,
      documentId: 'q-edit',
      forUpdate: true,
    );
    final resaved = QuestionCloudMapper.toFirestore(
      original,
      documentId: 'q-edit',
      forUpdate: true,
    );
    final textEdited = QuestionCloudMapper.toFirestore(
      sample(id: 'q-edit', text: 'Changed capital question'),
      documentId: 'q-edit',
      forUpdate: true,
    );
    final optionEdited = QuestionCloudMapper.toFirestore(
      sample(id: 'q-edit', firstOption: 'Adilabad'),
      documentId: 'q-edit',
      forUpdate: true,
    );
    final statementEdited = QuestionCloudMapper.toFirestore(
      sample(
        id: 'q-edit',
        format: QuestionItemFormat.statementMcq,
        statements: const ['A different statement.'],
      ),
      documentId: 'q-edit',
      forUpdate: true,
    );
    final stale = QuestionCloudMapper.toFirestore(
      sample(id: 'q-edit', contentFingerprint: 'stale-fingerprint'),
      documentId: 'q-edit',
      forUpdate: true,
    );
    expect(resaved['contentFingerprint'], written['contentFingerprint']);
    expect(
      textEdited['contentFingerprint'],
      isNot(written['contentFingerprint']),
    );
    expect(
      optionEdited['contentFingerprint'],
      isNot(written['contentFingerprint']),
    );
    expect(
      statementEdited['contentFingerprint'],
      isNot(written['contentFingerprint']),
    );
    expect(stale['contentFingerprint'], written['contentFingerprint']);
    expect(stale['contentFingerprint'], isNot('stale-fingerprint'));
  });

  testWidgets('load more keeps rows, then a fresh load starts at page 1', (
    tester,
  ) async {
    final service = _PagingService();
    await tester.pumpWidget(_bank(service));
    await tester.pumpAndSettle();
    expect(find.text('Question 1'), findsOneWidget);
    expect(find.text('Question 2'), findsNothing);
    expect(service.calls.single.cursorDocumentId, isNull);
    expect(service.calls.single.cursorPlan.startAfter, isNull);
    expect(service.calls.single.equalityFilters.last.value, 'group-ii-paper-i');

    await tester.tap(
      find.byKey(const ValueKey('test-series-question-bank-load-more')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Question 1'), findsOneWidget);
    expect(find.text('Question 2'), findsOneWidget);
    expect(service.calls[1].cursorDocumentId, 'q-1');
    expect(service.calls[1].cursorPlan.startAfter, ['q-1']);
    expect(service.calls[1].cursorPlan.usesOffset, isFalse);
    expect(
      find.byKey(const ValueKey('test-series-question-bank-end')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('test-series-question-bank-load-more')),
      findsNothing,
    );

    await tester.pumpWidget(_bank(service, key: UniqueKey()));
    await tester.pumpAndSettle();
    expect(service.calls.last.cursorDocumentId, isNull);
    expect(service.calls.last.cursorPlan.startAfter, isNull);
  });

  testWidgets('a failed next page keeps questions already loaded', (
    tester,
  ) async {
    final service = _PagingService()..failOnPage = 2;
    await tester.pumpWidget(_bank(service));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('test-series-question-bank-load-more')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Question 1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('test-series-question-bank-page-error')),
      findsOneWidget,
    );
  });

  testWidgets('one character does not search and two characters do', (
    tester,
  ) async {
    final service = _PagingService();
    await tester.pumpWidget(_bank(service));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('test-series-question-bank-search')),
      'd',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(service.calls.last.searchPrefix, isNull);
    expect(service.calls.last.cursorPlan.arrayContains, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('test-series-question-bank-search')),
      'da',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(service.calls.last.searchPrefix, 'da');
    expect(service.calls.last.cursorPlan.arrayContains, 'da');

    await tester.enterText(
      find.byKey(const ValueKey('test-series-question-bank-search')),
      '',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(service.calls.last.searchPrefix, isNull);
    expect(service.calls.last.cursorPlan.arrayContains, isNull);
  });

  testWidgets(
    'search is debounced, resets the cursor, and ignores stale text',
    (tester) async {
      final service = _PagingService();
      await tester.pumpWidget(_bank(service));
      await tester.pumpAndSettle();
      final before = service.calls.length;
      await tester.enterText(
        find.byKey(const ValueKey('test-series-question-bank-search')),
        'ca',
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(
        find.byKey(const ValueKey('test-series-question-bank-search')),
        'capital',
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(service.calls.length, before);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(service.calls.length, before + 1);
      expect(service.calls.last.normalizedSearch, 'capital');
      expect(service.calls.last.cursorDocumentId, isNull);
      expect(
        service.calls.last.equalityFilters.any(
          (filter) => filter.value == 'chapter',
        ),
        isFalse,
      );

      await tester.enterText(
        find.byKey(const ValueKey('test-series-question-bank-search')),
        '',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(service.calls.last.normalizedSearch, isNull);
      expect(service.calls.last.cursorPlan.orderBy, ['__name__']);
    },
  );
}

Widget _bank(_PagingService service, {Key? key}) {
  return MaterialApp(
    home: Scaffold(
      body: AdminTestSeriesQuestionBankScreen(
        key: key,
        scope: const AdminQuestionScope(
          contentArea: AdminQuestionScope.contentAreaTestSeries,
          courseId: 'group-ii',
          testSeriesCategory: AdminQuestionScope.categoryPart,
          paperId: 'group-ii-paper-i',
        ),
        service: service,
      ),
    ),
  );
}

class _PagingService extends AdminQuestionService {
  _PagingService() : super();

  final List<AdminTestSeriesQuestionQuery> calls = [];
  int failOnPage = 0;

  @override
  Future<QuestionBankPage> loadTestSeriesQuestionPage(
    AdminQuestionScope scope, {
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) async {
    final query = AdminTestSeriesQuestionQuery.fromScope(
      scope,
      searchText: searchText,
      cursorDocumentId: cursorDocumentId,
      cursorSearchText: cursorSearchText,
    );
    calls.add(query);
    if (failOnPage > 0 && calls.length == failOnPage) {
      throw Exception('page failed');
    }
    if (query.normalizedSearch != null) {
      return const QuestionBankPage(questions: [], hasMore: false);
    }
    if (cursorDocumentId == null) {
      return QuestionBankPage(
        questions: [_question('q-1', 'Question 1')],
        hasMore: true,
        cursorDocumentId: 'q-1',
      );
    }
    return QuestionBankPage(
      questions: [
        _question('q-1', 'Question 1'),
        _question('q-2', 'Question 2'),
      ],
      hasMore: false,
      cursorDocumentId: 'q-2',
    );
  }

  Question _question(String id, String text) {
    final now = DateTime(2026, 9, 28);
    return Question(
      id: id,
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      question: text,
      options: const ['A', 'B', 'C', 'D'],
      correctOption: 'A',
      explanation: 'E',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 30),
      createdAt: now,
      updatedAt: now,
      isActive: false,
      status: QuestionPublicationStatus.draft,
    );
  }
}
