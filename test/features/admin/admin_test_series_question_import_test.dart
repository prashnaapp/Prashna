import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/data/models/question_import_models.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_chapter_questions_browser_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_import_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_series_question_bank_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/admin/services/admin_question_test_assignment.dart';
import 'package:telangana_prep/features/admin/services/question_import_parser.dart';
import 'package:telangana_prep/features/admin/services/question_import_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_content_fingerprint.dart';
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

  Map<String, dynamic> stem({
    String? itemFormat,
    List<Map<String, String>>? statements,
    String? testId,
    String? courseId,
    String? paperId,
    String? seriesId,
    int? year,
    String? contentArea,
    String? testSeriesCategory,
    String questionEn = 'Which city is the capital?',
  }) {
    return {
      'courseId': ?courseId,
      'paperId': ?paperId,
      'seriesId': ?seriesId,
      'year': ?year,
      'contentArea': ?contentArea,
      'testSeriesCategory': ?testSeriesCategory,
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

  String wrap(List<Map<String, dynamic>> questions) =>
      jsonEncode({'questions': questions});

  TestModel catalogTest({
    required String id,
    required TestCategoryType category,
    String courseId = 'group-ii',
    String? paperId,
    String? seriesId,
    int? year,
    int assigned = 0,
  }) {
    final ids = [for (var i = 0; i < assigned; i++) 'existing-$i'];
    return TestModel(
      id: id,
      examId: courseId,
      category: category,
      title: id,
      questionCount: ids.length,
      marks: ids.length,
      durationMinutes: 10,
      negativeMarking: '0',
      difficulty: 'easy',
      questionIds: ids,
      paperId: paperId,
      seriesId: seriesId,
      year: year,
    );
  }

  QuestionImportService serviceFor({
    required AdminQuestionScope? scope,
    required List<Map<String, dynamic>> created,
    List<TestModel> tests = const [],
    void Function(Map<String, dynamic> data)? onUpdate,
    bool failAssignment = false,
  }) {
    final questions = QuestionCloudRepository.withHandlers(
      createBatch: ({required items}) async {
        created.addAll([for (final item in items) item.data]);
      },
      idGenerator: () => 'q-${created.length + 1}',
    );
    final testRepository = TestCloudRepository.withLoader(
      (_) async => const [],
      getById: (id) async {
        for (final test in tests) {
          if (test.id == id) return test;
        }
        return null;
      },
      update: ({required testId, required data}) async {
        if (failAssignment) throw Exception('assignment rejected');
        onUpdate?.call(data);
      },
    );
    return QuestionImportService(
      questionRepository: questions,
      scope: scope,
      tests: testRepository,
      assignment: AdminQuestionTestAssignment(tests: testRepository),
    );
  }

  test('scoped imports write bank ownership and ignore questionType', () async {
    final created = <Map<String, dynamic>>[];
    final paper = serviceFor(scope: paperScope, created: created);
    final grand = serviceFor(scope: grandScope, created: created);
    final previous = serviceFor(scope: previousScope, created: created);

    final paperResult = await paper.validateAndImportJson(wrap([stem()]));
    final grandResult = await grand.validateAndImportJson(
      wrap([stem(itemFormat: 'standard_mcq')]),
    );
    final previousResult = await previous.validateAndImportJson(wrap([stem()]));

    expect(paperResult.succeeded, isTrue);
    expect(created[0]['contentArea'], 'testSeries');
    expect(created[0]['questionSearchPrefixes'], contains('city'));
    expect(created[0]['testSeriesCategory'], 'part');
    expect(created[0]['courseId'], 'group-ii');
    expect(created[0]['paperId'], 'group-ii-paper-i');
    expect(created[0].containsKey('partId'), isFalse);
    expect(created[0].containsKey('assignedTestId'), isFalse);
    expect(created[0]['questionType'], 'practice');

    expect(grandResult.succeeded, isTrue);
    expect(created[1]['testSeriesCategory'], 'mock');
    expect(created[1]['seriesId'], GrandTestSeries.grandTestII);
    expect(created[1].containsKey('paperId'), isFalse);

    expect(previousResult.succeeded, isTrue);
    expect(created[2]['testSeriesCategory'], 'previousyear');
    expect(created[2]['year'], 2024);
    expect(created[2].containsKey('paperId'), isFalse);
  });

  test(
    'JSON cannot override locked ownership and chapter import stays chapter',
    () async {
      final created = <Map<String, dynamic>>[];
      final scoped = serviceFor(scope: paperScope, created: created);
      final conflict = await scoped.validateJson(
        wrap([stem(paperId: 'group-ii-paper-ii')]),
      );
      expect(conflict.canImport, isFalse);
      expect(conflict.errors.single.field, 'paperId');
      expect(created, isEmpty);

      final chapter = serviceFor(scope: null, created: created);
      final rejected = await chapter.validateJson(
        wrap([
          stem(
            courseId: 'group-ii',
            paperId: 'group-ii-paper-i',
            contentArea: 'testSeries',
            testSeriesCategory: 'part',
          ),
        ]),
      );
      expect(rejected.canImport, isFalse);
      expect(
        rejected.errors.any((error) => error.field == 'contentArea'),
        isTrue,
      );

      final chapterTestId = await chapter.validateJson(
        wrap([
          stem(
              courseId: 'group-ii',
              paperId: 'group-ii-paper-i',
              testId: 'paper-test',
            )
            ..['majorStudyAreaId'] = 'group-ii-paper-i-area-01'
            ..['contentTopicId'] = 'group-ii-paper-i-area-01-topic-01',
        ]),
      );
      expect(chapterTestId.canImport, isFalse);
      expect(chapterTestId.errors.single.field, 'testId');
      expect(created, isEmpty);
    },
  );

  test(
    'standard and statement imports share the canonical question shape',
    () async {
      final created = <Map<String, dynamic>>[];
      final service = serviceFor(scope: paperScope, created: created);
      final statements = [
        {'en': 'Hyderabad is the capital.', 'te': 'హైదరాబాద్ రాజధాని.'},
      ];
      final standard = await service.validateAndImportJson(wrap([stem()]));
      final statement = await service.validateAndImportJson(
        wrap([
          stem(itemFormat: 'statement_mcq', statements: statements)
            ..['options'] = [
              {'en': '1 only'},
              {'en': '2 only'},
              {'en': 'Both'},
              {'en': 'Neither'},
            ],
        ]),
      );
      final invalid = await service.validateJson(
        wrap([stem(itemFormat: 'statement_mcq')]),
      );
      final unsupported = await service.validateJson(
        wrap([stem(itemFormat: 'assertion_reason')]),
      );

      expect(standard.succeeded, isTrue);
      expect(created[0]['itemFormat'], 'standard_mcq');
      expect(statement.succeeded, isTrue);
      expect(created[1]['itemFormat'], 'statement_mcq');
      final content = created[1]['content'] as Map<String, dynamic>;
      expect((content['en'] as Map)['statements'], [
        'Hyderabad is the capital.',
      ]);
      expect(invalid.canImport, isFalse);
      expect(
        invalid.errors.any((error) => error.field == 'statements'),
        isTrue,
      );
      expect(unsupported.canImport, isFalse);
      expect(unsupported.errors.single.field, 'itemFormat');
    },
  );

  test('imported questions persist the import contentFingerprint', () async {
    final created = <Map<String, dynamic>>[];
    final paperTest = catalogTest(
      id: 'paper-test',
      category: TestCategoryType.partTests,
      paperId: 'group-ii-paper-i',
    );
    final service = serviceFor(
      scope: paperScope,
      created: created,
      tests: [paperTest],
    );
    final statementsA = [
      {'en': 'Hyderabad is the capital.', 'te': 'హైదరాబాద్ రాజధాని.'},
    ];
    final statementsB = [
      {'en': 'Warangal is the capital.', 'te': 'వరంగల్ రాజధాని.'},
    ];
    final statementOptions = [
      {'en': '1 only'},
      {'en': '2 only'},
      {'en': 'Both'},
      {'en': 'Neither'},
    ];

    String fingerprintOf(Map<String, dynamic> json) {
      final record = QuestionImportParser.parseJson(wrap([json])).single;
      return QuestionContentFingerprint.compute(
        courseId: paperScope.courseId!,
        paperId: paperScope.paperId!,
        itemFormat: record.itemFormat,
        questionEn: record.question.en,
        questionTe: record.question.te,
        correctOption: record.correctOption,
        options: [
          for (final option in record.options) (en: option.en, te: option.te),
        ],
        statements: [
          for (final statement in record.statements)
            (en: statement.en, te: statement.te),
        ],
      );
    }

    await service.validateAndImportJson(wrap([stem()]));
    await service.validateAndImportJson(
      wrap([
        stem(itemFormat: 'statement_mcq', statements: statementsA)
          ..['options'] = statementOptions,
      ]),
    );
    await service.validateAndImportJson(
      wrap([
        stem(itemFormat: 'statement_mcq', statements: statementsB)
          ..['options'] = statementOptions,
      ]),
    );
    final assigned = await service.validateAndImportJson(
      wrap([stem(questionEn: 'Assigned stem', testId: 'paper-test')]),
    );
    expect(assigned.succeeded, isTrue);

    expect(created[0]['contentFingerprint'], fingerprintOf(stem()));
    expect(
      created[1]['contentFingerprint'],
      fingerprintOf(
        stem(itemFormat: 'statement_mcq', statements: statementsA)
          ..['options'] = statementOptions,
      ),
    );
    expect(
      created[2]['contentFingerprint'],
      fingerprintOf(
        stem(itemFormat: 'statement_mcq', statements: statementsB)
          ..['options'] = statementOptions,
      ),
    );
    expect(
      created[1]['contentFingerprint'],
      isNot(created[2]['contentFingerprint']),
    );
    expect(
      created[3]['contentFingerprint'],
      fingerprintOf(stem(questionEn: 'Assigned stem')),
    );
    expect(
      created[3]['contentFingerprint'],
      fingerprintOf(stem(questionEn: 'Assigned stem', testId: 'paper-test')),
    );

    final failing = serviceFor(
      scope: paperScope,
      created: created,
      tests: [paperTest],
      failAssignment: true,
    );
    final partial = await failing.validateAndImportJson(
      wrap([stem(questionEn: 'Keep fingerprint', testId: 'paper-test')]),
    );
    expect(partial.questionsCreated, isTrue);
    expect(partial.succeeded, isFalse);
    expect(
      created.last['contentFingerprint'],
      fingerprintOf(stem(questionEn: 'Keep fingerprint')),
    );
  });

  test(
    'optional testId assigns only a compatible test and preserves failures',
    () async {
      final created = <Map<String, dynamic>>[];
      final updates = <Map<String, dynamic>>[];
      final paperTest = catalogTest(
        id: 'paper-test',
        category: TestCategoryType.partTests,
        paperId: 'group-ii-paper-i',
      );
      final wrongPaper = catalogTest(
        id: 'wrong-paper',
        category: TestCategoryType.partTests,
        paperId: 'group-ii-paper-ii',
      );
      final service = serviceFor(
        scope: paperScope,
        created: created,
        tests: [paperTest, wrongPaper],
        onUpdate: updates.add,
      );

      final unassigned = await service.validateAndImportJson(wrap([stem()]));
      expect(unassigned.succeeded, isTrue);
      expect(updates, isEmpty);

      final assigned = await service.validateAndImportJson(
        wrap([stem(testId: 'paper-test', questionEn: 'Assigned stem')]),
      );
      expect(assigned.succeeded, isTrue);
      expect(updates.single['questionIds'], ['q-2']);
      expect(updates.single.containsKey('assignedTestId'), isFalse);
      expect(created.last.containsKey('assignedTestId'), isFalse);

      expect(
        (await service.validateJson(wrap([stem(testId: 'missing')]))).canImport,
        isFalse,
      );
      expect(
        (await service.validateJson(
          wrap([stem(testId: 'wrong-paper')]),
        )).canImport,
        isFalse,
      );

      final grand = serviceFor(
        scope: grandScope,
        created: created,
        tests: [
          catalogTest(
            id: 'grand-ii',
            category: TestCategoryType.mockTests,
            seriesId: GrandTestSeries.grandTestII,
            paperId: 'group-ii-paper-iii',
          ),
          catalogTest(
            id: 'grand-i',
            category: TestCategoryType.mockTests,
            seriesId: GrandTestSeries.grandTestI,
            paperId: 'group-ii-paper-iii',
          ),
        ],
      );
      expect(
        (await grand.validateJson(wrap([stem(testId: 'grand-ii')]))).canImport,
        isTrue,
      );
      expect(
        (await grand.validateJson(wrap([stem(testId: 'grand-i')]))).canImport,
        isFalse,
      );

      final previous = serviceFor(
        scope: previousScope,
        created: created,
        tests: [
          catalogTest(
            id: 'year-2024',
            category: TestCategoryType.previousYear,
            year: 2024,
            paperId: 'group-ii-paper-ii',
          ),
          catalogTest(
            id: 'year-2016',
            category: TestCategoryType.previousYear,
            year: 2016,
            paperId: 'group-ii-paper-ii',
          ),
          catalogTest(
            id: 'other-course',
            category: TestCategoryType.previousYear,
            courseId: 'group-iii',
            year: 2024,
            paperId: 'group-iii-paper-i',
          ),
        ],
      );
      expect(
        (await previous.validateJson(
          wrap([stem(testId: 'year-2024')]),
        )).canImport,
        isTrue,
      );
      expect(
        (await previous.validateJson(
          wrap([stem(testId: 'year-2016')]),
        )).canImport,
        isFalse,
      );
      expect(
        (await previous.validateJson(
          wrap([stem(testId: 'other-course')]),
        )).canImport,
        isFalse,
      );

      final failing = serviceFor(
        scope: paperScope,
        created: created,
        tests: [paperTest],
        failAssignment: true,
      );
      final before = created.length;
      final partial = await failing.validateAndImportJson(
        wrap([stem(testId: 'paper-test', questionEn: 'Keep me')]),
      );
      expect(partial.questionsCreated, isTrue);
      expect(partial.succeeded, isFalse);
      expect(partial.assignmentFailureMessage, contains('remain in this bank'));
      expect(created.length, before + 1);
    },
  );

  test(
    'duplicate fingerprint includes statements and excludes testId',
    () async {
      final service = serviceFor(scope: paperScope, created: []);
      final statements = [
        {'en': 'One', 'te': 'ఒకటి'},
      ];
      final otherStatements = [
        {'en': 'Two', 'te': 'రెండు'},
      ];
      final same = await service.validateJson(
        wrap([
          stem(itemFormat: 'statement_mcq', statements: statements),
          stem(itemFormat: 'statement_mcq', statements: statements),
        ]),
      );
      expect(same.warnings, isNotEmpty);
      expect(same.canImport, isTrue);

      final different = await service.validateJson(
        wrap([
          stem(itemFormat: 'statement_mcq', statements: statements),
          stem(itemFormat: 'statement_mcq', statements: otherStatements),
        ]),
      );
      expect(different.warnings, isEmpty);

      final assignmentDoesNotChangeFingerprint = await service.validateJson(
        wrap([
          stem(questionEn: 'Same stem'),
          stem(questionEn: 'Same stem', testId: 'paper-test'),
        ]),
      );
      expect(assignmentDoesNotChangeFingerprint.warnings, isNotEmpty);
    },
  );

  test(
    'import rejects a test that would pass 160 assigned questions',
    () async {
      final full = catalogTest(
        id: 'full',
        category: TestCategoryType.partTests,
        paperId: 'group-ii-paper-i',
        assigned: AdminQuestionTestAssignment.maxAssignedQuestionsPerTest,
      );
      final service = serviceFor(scope: paperScope, created: [], tests: [full]);
      final result = await service.validateJson(
        wrap([
          stem(testId: 'full', questionEn: 'One'),
          stem(testId: 'full', questionEn: 'Two'),
        ]),
      );
      expect(result.canImport, isFalse);
      expect(result.errors.every((error) => error.field == 'testId'), isTrue);
    },
  );

  testWidgets('bank import returns to the same bank and reloads it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var loads = 0;
    final questions = QuestionCloudRepository.withHandlers(
      loadTestSeriesQuestions: (_) async {
        loads += 1;
        return const [];
      },
    );
    final import = _SuccessfulImport();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminTestSeriesQuestionBankScreen(
            scope: paperScope,
            service: AdminQuestionService(questionRepository: questions),
            importService: import,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('test-series-question-bank-import')),
      findsOneWidget,
    );
    expect(loads, 1);

    await tester.tap(
      find.byKey(const ValueKey('test-series-question-bank-import')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('import-locked-ownership')),
      findsOneWidget,
    );
    expect(find.text('Paper-wise'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('validate-import')));
    await tester.tap(find.byKey(const ValueKey('validate-import')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('confirm-import')));
    await tester.tap(find.byKey(const ValueKey('confirm-import')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import drafts'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminTestSeriesQuestionBankScreen), findsOneWidget);
    expect(find.byType(AdminQuestionImportScreen), findsNothing);
    expect(loads, 2);
  });

  testWidgets('sidebar import cannot start a contextless Test Series import', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminQuestionImportEntryScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('import-entry-chapter')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('import-entry-test-series')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('import-json')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('import-entry-chapter')));
    await tester.pumpAndSettle();
    expect(find.byType(AdminChapterQuestionsBrowserScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('import-locked-ownership')), findsNothing);
    expect(find.byKey(const ValueKey('import-json')), findsNothing);
    expect(
      find.byKey(const ValueKey('import-entry-test-series')),
      findsNothing,
    );
  });
}

class _SuccessfulImport extends QuestionImportService {
  _SuccessfulImport() : super();

  @override
  Future<QuestionImportValidationResult> validateJson(String rawJson) async {
    final now = DateTime(2026, 9, 28);
    return QuestionImportValidationResult(
      totalRecords: 1,
      validRecords: 1,
      invalidRecords: 0,
      errors: const [],
      warnings: const [],
      duplicateOrCollisionRecords: const [],
      validatedQuestions: [
        Question(
          id: 'q-imported',
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
          question: 'Imported',
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
          status: QuestionPublicationStatus.draft,
          isActive: false,
        ),
      ],
    );
  }

  @override
  Future<QuestionImportReport> importValidatedBatch(
    QuestionImportValidationResult validation,
  ) async {
    return const QuestionImportReport(
      recordsSubmitted: 1,
      recordsImported: 1,
      recordsRejected: 0,
      createdQuestionIds: ['q-imported'],
      duplicates: [],
      warnings: [],
    );
  }
}
