import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/data/admin_test_hierarchy.dart';
import 'package:telangana_prep/features/admin/data/admin_test_series_question_query.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_series_question_bank_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_series_questions_browser_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';
import 'package:telangana_prep/features/tests/data/grand_test_series.dart';
import 'package:telangana_prep/features/tests/data/previous_paper_years.dart';

void main() {
  final syllabus = SyllabusService.instance;

  Question question(String id, String text, {String courseId = 'group-ii'}) {
    final now = DateTime(2026, 9, 27);
    return Question(
      id: id,
      courseId: courseId,
      paperId: '',
      question: text,
      options: const ['A1', 'B1', 'C1', 'D1'],
      correctOption: 'A',
      explanation: '',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      isActive: false,
      status: QuestionPublicationStatus.draft,
    );
  }

  Widget browser({
    required _BankService service,
    String? courseId,
    String? testSeriesCategory,
    String? paperId,
    String? seriesId,
    int? year,
  }) {
    return MaterialApp(
      home: AdminTestSeriesQuestionsBrowserScreen(
        questionService: service,
        courseId: courseId,
        testSeriesCategory: testSeriesCategory,
        paperId: paperId,
        seriesId: seriesId,
        year: year,
      ),
    );
  }

  test('paper-wise, grand, and previous queries constrain server fields', () {
    final paper = AdminTestSeriesQuestionQuery.fromScope(
      const AdminQuestionScope(
        contentArea: AdminQuestionScope.contentAreaTestSeries,
        courseId: 'group-ii',
        testSeriesCategory: AdminQuestionScope.categoryPart,
        paperId: 'group-ii-paper-i',
      ),
    );
    expect(
      {for (final filter in paper.equalityFilters) filter.field: filter.value},
      {
        'contentArea': 'testSeries',
        'testSeriesCategory': 'part',
        'courseId': 'group-ii',
        'paperId': 'group-ii-paper-i',
      },
    );
    expect(paper.seriesId, isNull);
    expect(paper.year, isNull);

    final grand = AdminTestSeriesQuestionQuery.fromScope(
      const AdminQuestionScope(
        contentArea: AdminQuestionScope.contentAreaTestSeries,
        courseId: 'group-iii',
        testSeriesCategory: AdminQuestionScope.categoryMock,
        seriesId: GrandTestSeries.grandTestI,
      ),
    );
    expect(
      {for (final filter in grand.equalityFilters) filter.field: filter.value},
      {
        'contentArea': 'testSeries',
        'testSeriesCategory': 'mock',
        'courseId': 'group-iii',
        'seriesId': GrandTestSeries.grandTestI,
      },
    );
    expect(grand.paperId, isNull);

    final previous = AdminTestSeriesQuestionQuery.fromScope(
      const AdminQuestionScope(
        contentArea: AdminQuestionScope.contentAreaTestSeries,
        courseId: 'group-ii',
        testSeriesCategory: AdminQuestionScope.categoryPreviousYear,
        year: 2016,
      ),
    );
    expect(
      {
        for (final filter in previous.equalityFilters)
          filter.field: filter.value,
      },
      {
        'contentArea': 'testSeries',
        'testSeriesCategory': 'previousyear',
        'courseId': 'group-ii',
        'year': 2016,
      },
    );
    expect(AdminTestSeriesQuestionQuery.pageSize, 50);
  });

  test('service asks the repository for the bounded context query', () async {
    AdminTestSeriesQuestionQuery? captured;
    var courseReads = 0;
    final repository = QuestionCloudRepository.withHandlers(
      loadQuestions: (_) async {
        courseReads += 1;
        return const [];
      },
      loadTestSeriesQuestions: (query) async {
        captured = query;
        return const [];
      },
    );
    final service = AdminQuestionService(questionRepository: repository);
    await service.loadTestSeriesQuestions(
      const AdminQuestionScope(
        contentArea: AdminQuestionScope.contentAreaTestSeries,
        courseId: 'group-ii',
        testSeriesCategory: AdminQuestionScope.categoryPart,
        paperId: 'group-ii-paper-ii',
      ),
    );
    expect(courseReads, 0);
    expect(captured, isNotNull);
    expect(captured!.equalityFilters.map((filter) => filter.field).toList(), [
      'contentArea',
      'testSeriesCategory',
      'courseId',
      'paperId',
    ]);
    expect(captured!.equalityFilters.last.value, 'group-ii-paper-ii');
  });

  testWidgets('Group-II and Group-III Paper-wise list canonical papers only', (
    tester,
  ) async {
    final service = _BankService();
    for (final courseId in ['group-ii', 'group-iii']) {
      await tester.pumpWidget(
        browser(
          service: service,
          courseId: courseId,
          testSeriesCategory: AdminQuestionScope.categoryPart,
        ),
      );
      await tester.pumpAndSettle();
      final course = syllabus.getCourseById(courseId)!;
      for (final paper in course.papers) {
        expect(find.text(AdminTestHierarchy.paperLabel(paper)), findsOneWidget);
      }
      for (final paper in course.papers) {
        for (final part in paper.parts) {
          expect(find.text(part.displayName), findsNothing);
        }
      }
      expect(find.text('Create Question'), findsNothing);
      expect(service.loadQuestionsCalls, 0);
      expect(service.queries, isEmpty);
    }
  });

  testWidgets('Paper-I opens a paper-wise bank without a part', (tester) async {
    final service = _BankService(
      seeds: [
        _Seed(
          question: question('q-paper-i', 'Paper I capital question'),
          contentArea: 'testSeries',
          testSeriesCategory: 'part',
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
        ),
      ],
    );
    await tester.pumpWidget(
      browser(
        service: service,
        courseId: 'group-ii',
        testSeriesCategory: AdminQuestionScope.categoryPart,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('test-series-questions-paper-group-ii-paper-i'),
      ),
    );
    await tester.pumpAndSettle();

    final screen = tester.widget<AdminTestSeriesQuestionsBrowserScreen>(
      find.byType(AdminTestSeriesQuestionsBrowserScreen).last,
    );
    expect(screen.scope.contentArea, 'testSeries');
    expect(screen.scope.testSeriesCategory, 'part');
    expect(screen.scope.courseId, 'group-ii');
    expect(screen.scope.paperId, 'group-ii-paper-i');
    expect(screen.scope.isQuestionBank, isTrue);
    expect(service.queries.single.paperId, 'group-ii-paper-i');
    expect(
      service.queries.single.equalityFilters.any((f) => f.field == 'partId'),
      isFalse,
    );
    expect(find.text('Paper I capital question'), findsOneWidget);
    expect(find.text('Create Question'), findsOneWidget);
    expect(find.text('Import Questions'), findsNothing);
    expect(find.text('Assign'), findsNothing);
    expect(service.loadQuestionsCalls, 0);
  });

  testWidgets('Grand Tests lists the four containers and no papers', (
    tester,
  ) async {
    final service = _BankService();
    await tester.pumpWidget(
      browser(
        service: service,
        courseId: 'group-ii',
        testSeriesCategory: AdminQuestionScope.categoryMock,
      ),
    );
    await tester.pumpAndSettle();
    expect(GrandTestSeries.ids, [
      'Grand Test - I',
      'Grand Test - II',
      'Grand Test - III',
      'Old Grand Tests',
    ]);
    for (final seriesId in GrandTestSeries.ids) {
      expect(find.text(seriesId), findsOneWidget);
    }
    final papers = syllabus.getCourseById('group-ii')!.papers;
    for (final paper in papers) {
      expect(find.text(AdminTestHierarchy.paperLabel(paper)), findsNothing);
    }
    expect(service.loadQuestionsCalls, 0);
  });

  testWidgets('each Grand container carries its seriesId', (tester) async {
    final service = _BankService();
    await tester.pumpWidget(
      browser(
        service: service,
        courseId: 'group-iii',
        testSeriesCategory: AdminQuestionScope.categoryMock,
      ),
    );
    await tester.pumpAndSettle();
    for (final seriesId in GrandTestSeries.ids) {
      await tester.tap(find.text(seriesId));
      await tester.pumpAndSettle();
      final screen = tester.widget<AdminTestSeriesQuestionsBrowserScreen>(
        find.byType(AdminTestSeriesQuestionsBrowserScreen).last,
      );
      expect(screen.scope.courseId, 'group-iii');
      expect(screen.scope.testSeriesCategory, 'mock');
      expect(screen.scope.seriesId, seriesId);
      expect(screen.scope.paperId, isNull);
      expect(service.queries.last.seriesId, seriesId);
      expect(
        service.queries.last.equalityFilters.map((f) => f.field),
        isNot(contains('paperId')),
      );
      Navigator.of(
        tester.element(find.byType(AdminTestSeriesQuestionsBrowserScreen).last),
      ).pop();
      await tester.pumpAndSettle();
    }
    expect(service.loadQuestionsCalls, 0);
  });

  testWidgets('Previous Papers use the locked years and no paper folder', (
    tester,
  ) async {
    final service = _BankService();
    Future<void> expectYears(String courseId, List<int> years) async {
      await tester.pumpWidget(
        browser(
          service: service,
          courseId: courseId,
          testSeriesCategory: AdminQuestionScope.categoryPreviousYear,
        ),
      );
      await tester.pumpAndSettle();
      expect(PreviousPaperYears.forExam(courseId), years);
      for (final year in years) {
        expect(find.text('$year'), findsOneWidget);
      }
      final papers = syllabus.getCourseById(courseId)!.papers;
      for (final paper in papers) {
        expect(find.text(AdminTestHierarchy.paperLabel(paper)), findsNothing);
      }
    }

    await expectYears('group-ii', const [2016, 2024]);
    await expectYears('group-iii', const [2018, 2024]);
    expect(service.loadQuestionsCalls, 0);
  });

  testWidgets('Previous year selection carries courseId and integer year', (
    tester,
  ) async {
    final service = _BankService();
    await tester.pumpWidget(
      browser(
        service: service,
        courseId: 'group-iii',
        testSeriesCategory: AdminQuestionScope.categoryPreviousYear,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('test-series-questions-year-2018')),
    );
    await tester.pumpAndSettle();
    final screen = tester.widget<AdminTestSeriesQuestionsBrowserScreen>(
      find.byType(AdminTestSeriesQuestionsBrowserScreen).last,
    );
    expect(screen.scope.courseId, 'group-iii');
    expect(screen.scope.testSeriesCategory, 'previousyear');
    expect(screen.scope.year, 2018);
    expect(screen.scope.paperId, isNull);
    expect(service.queries.single.year, 2018);
    expect(service.queries.single.equalityFilters.last.value, 2018);
    expect(service.loadQuestionsCalls, 0);
  });

  testWidgets('bank shows only the matching Test Series context', (
    tester,
  ) async {
    final service = _BankService(
      seeds: [
        _Seed(
          question: question('q-match', 'Matching paper question'),
          contentArea: 'testSeries',
          testSeriesCategory: 'part',
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
        ),
        _Seed(
          question: question('q-other-paper', 'Other paper question'),
          contentArea: 'testSeries',
          testSeriesCategory: 'part',
          courseId: 'group-ii',
          paperId: 'group-ii-paper-ii',
        ),
        _Seed(
          question: question('q-grand', 'Grand question'),
          contentArea: 'testSeries',
          testSeriesCategory: 'mock',
          courseId: 'group-ii',
          seriesId: GrandTestSeries.grandTestI,
        ),
        _Seed(
          question: question('q-year', 'Year question'),
          contentArea: 'testSeries',
          testSeriesCategory: 'previousyear',
          courseId: 'group-ii',
          year: 2016,
        ),
        _Seed(
          question: question(
            'q-other-course',
            'Other course question',
            courseId: 'group-iii',
          ),
          contentArea: 'testSeries',
          testSeriesCategory: 'part',
          courseId: 'group-iii',
          paperId: 'group-ii-paper-i',
        ),
        _Seed(
          question: question('q-legacy', 'Legacy chapter question'),
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestSeriesQuestionBankScreen(
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
    await tester.pumpAndSettle();
    expect(find.text('Matching paper question'), findsOneWidget);
    expect(find.text('Other paper question'), findsNothing);
    expect(find.text('Grand question'), findsNothing);
    expect(find.text('Year question'), findsNothing);
    expect(find.text('Other course question'), findsNothing);
    expect(find.text('Legacy chapter question'), findsNothing);
    expect(service.loadQuestionsCalls, 0);
    expect(service.queries.single.testSeriesCategory, 'part');
    expect(service.queries.single.paperId, 'group-ii-paper-i');
  });

  testWidgets('empty matching bank shows an empty state', (tester) async {
    final service = _BankService();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestSeriesQuestionBankScreen(
          scope: const AdminQuestionScope(
            contentArea: AdminQuestionScope.contentAreaTestSeries,
            courseId: 'group-ii',
            testSeriesCategory: AdminQuestionScope.categoryMock,
            seriesId: GrandTestSeries.oldGrandTests,
          ),
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('test-series-question-bank-empty')),
      findsOneWidget,
    );
    expect(find.text('No questions in this bank yet.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('test-series-question-bank-create')),
      findsOneWidget,
    );
    expect(service.loadQuestionsCalls, 0);
  });
}

class _Seed {
  const _Seed({
    required this.question,
    this.contentArea,
    this.testSeriesCategory,
    this.courseId,
    this.paperId,
    this.seriesId,
    this.year,
  });

  final Question question;
  final String? contentArea;
  final String? testSeriesCategory;
  final String? courseId;
  final String? paperId;
  final String? seriesId;
  final int? year;
}

class _BankService extends AdminQuestionService {
  _BankService({this.seeds = const []}) : super();

  final List<_Seed> seeds;
  final List<AdminTestSeriesQuestionQuery> queries = [];
  int loadQuestionsCalls = 0;

  @override
  Future<List<Question>> loadQuestions(String courseId) async {
    loadQuestionsCalls += 1;
    return [for (final seed in seeds) seed.question];
  }

  @override
  Future<List<Question>> loadTestSeriesQuestions(
    AdminQuestionScope scope,
  ) async {
    final query = AdminTestSeriesQuestionQuery.fromScope(scope);
    queries.add(query);
    return [
      for (final seed in seeds)
        if (_matches(seed, query)) seed.question,
    ];
  }

  bool _matches(_Seed seed, AdminTestSeriesQuestionQuery query) {
    if (seed.contentArea != AdminQuestionScope.contentAreaTestSeries) {
      return false;
    }
    if (seed.testSeriesCategory != query.testSeriesCategory) return false;
    if (seed.courseId != query.courseId) return false;
    for (final filter in query.equalityFilters) {
      final actual = switch (filter.field) {
        'paperId' => seed.paperId,
        'seriesId' => seed.seriesId,
        'year' => seed.year,
        'contentArea' => seed.contentArea,
        'testSeriesCategory' => seed.testSeriesCategory,
        'courseId' => seed.courseId,
        _ => null,
      };
      if (actual != filter.value) return false;
    }
    return true;
  }
}
