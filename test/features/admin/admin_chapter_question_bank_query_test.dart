import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_chapter_question_context.dart';
import 'package:telangana_prep/features/admin/data/admin_chapter_question_query.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/data/admin_test_series_question_query.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_list_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_search_text.dart';

const _paperI = AdminChapterQuestionContext(
  courseId: 'group-ii',
  paperId: 'group-ii-paper-i',
  majorStudyAreaId: 'area-current',
  contentTopicId: 'topic-current',
);

const _topic = AdminChapterQuestionContext(
  courseId: 'group-ii',
  paperId: 'group-ii-paper-ii',
  partId: 'part-1',
  topicId: 'topic-1',
  lessonId: 'must-not-be-queried',
);

const _unit = AdminChapterQuestionContext(
  courseId: 'group-iii',
  paperId: 'group-iii-paper-i',
  syllabusUnitId: 'unit-1',
);

const _partUnit = AdminChapterQuestionContext(
  courseId: 'group-iii',
  paperId: 'group-iii-paper-ii',
  partId: 'part-1',
  syllabusUnitId: 'unit-2',
);

Map<String, Object> _filters(AdminChapterQuestionQuery query) {
  return {
    for (final filter in query.equalityFilters) filter.field: filter.value,
  };
}

void main() {
  test(
    'chapter contexts use canonical equality filters and never lessonId',
    () {
      expect(_filters(AdminChapterQuestionQuery.fromContext(_paperI)), {
        'contentArea': 'chapter',
        'courseId': 'group-ii',
        'paperId': 'group-ii-paper-i',
        'majorStudyAreaId': 'area-current',
        'contentTopicId': 'topic-current',
      });
      final topic = AdminChapterQuestionQuery.fromContext(_topic);
      expect(_filters(topic), {
        'contentArea': 'chapter',
        'courseId': 'group-ii',
        'paperId': 'group-ii-paper-ii',
        'partId': 'part-1',
        'topicId': 'topic-1',
      });
      expect(
        topic.equalityFilters.any((filter) => filter.field == 'lessonId'),
        isFalse,
      );
      expect(_filters(AdminChapterQuestionQuery.fromContext(_unit)), {
        'contentArea': 'chapter',
        'courseId': 'group-iii',
        'paperId': 'group-iii-paper-i',
        'syllabusUnitId': 'unit-1',
      });
      expect(_filters(AdminChapterQuestionQuery.fromContext(_partUnit)), {
        'contentArea': 'chapter',
        'courseId': 'group-iii',
        'paperId': 'group-iii-paper-ii',
        'partId': 'part-1',
        'syllabusUnitId': 'unit-2',
      });
    },
  );

  test(
    'unsearched pages order by document id and search is a prefix range',
    () {
      final plain = AdminChapterQuestionQuery.fromContext(_topic);
      expect(plain.cursorPlan.orderBy, ['__name__']);
      expect(plain.cursorPlan.usesOffset, isFalse);
      expect(plain.readLimit, 51);
      expect(plain.cursorPlan.limit, 51);

      final search = AdminChapterQuestionQuery.fromContext(
        _topic,
        searchText: '  Capital   City ',
      );
      expect(search.normalizedSearch, 'capital city');
      expect(
        search.normalizedSearch,
        QuestionSearchText.normalize('  Capital   City '),
      );
      expect(search.searchPrefix, 'city');
      expect(search.cursorPlan.orderBy, ['__name__']);
      expect(search.cursorPlan.arrayContains, 'city');
      expect(search.cursorPlan.startAt, isNull);
      expect(search.cursorPlan.endAt, isNull);

      final next = AdminChapterQuestionQuery.fromContext(
        _topic,
        searchText: 'capital city',
        cursorDocumentId: 'q-9',
        cursorSearchText: 'capital city',
      );
      expect(next.cursorPlan.startAt, isNull);
      expect(next.cursorPlan.arrayContains, 'city');
      expect(next.cursorPlan.startAfter, ['q-9']);
    },
  );

  test('status is a server equality filter and resets with the query', () {
    final filtered = AdminChapterQuestionQuery.fromContext(
      _topic,
      status: QuestionPublicationStatus.published,
    );
    expect(_filters(filtered)['status'], 'published');
    expect(
      AdminChapterQuestionQuery.fromContext(
        _topic,
      ).equalityFilters.any((filter) => filter.field == 'status'),
      isFalse,
    );
  });

  testWidgets(
    'the chapter bank pages on the server and does not load the course',
    (tester) async {
      final service = _ChapterBankService();
      await tester.pumpWidget(_bank(service, _topic));
      await tester.pumpAndSettle();

      expect(service.loadQuestionsCalls, 0);
      expect(service.pages.single.cursorDocumentId, isNull);
      expect(service.counts, hasLength(1));
      expect(find.text('Question 1'), findsOneWidget);
      expect(find.text('Question 2'), findsNothing);
      expect(find.text('1 of 2'), findsOneWidget);
      expect(
        service.pages.single.equalityFilters.any(
          (filter) => filter.field == 'lessonId',
        ),
        isFalse,
      );

      final more = find.byKey(
        const ValueKey('chapter-question-bank-load-more'),
      );
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(find.text('Question 1'), findsOneWidget);
      expect(find.text('Question 2'), findsOneWidget);
      expect(service.pages[1].cursorDocumentId, 'q-1');
      expect(service.pages[1].cursorPlan.startAfter, ['q-1']);
      expect(find.text('2 of 2'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chapter-question-bank-load-more')),
        findsNothing,
      );
    },
  );

  testWidgets('search debounces, resets the cursor, and drops stale text', (
    tester,
  ) async {
    final service = _ChapterBankService();
    await tester.pumpWidget(_bank(service, _topic));
    await tester.pumpAndSettle();
    final before = service.pages.length;

    await tester.enterText(
      find.byKey(const ValueKey('question-list-search')),
      'ca',
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(
      find.byKey(const ValueKey('question-list-search')),
      '  Capital ',
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(service.pages.length, before);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(service.pages.length, before + 1);
    expect(service.pages.last.normalizedSearch, 'capital');
    expect(service.pages.last.cursorDocumentId, isNull);
    expect(service.pages.last.searchPrefix, 'capital');
    expect(service.pages.last.cursorPlan.orderBy, ['__name__']);
    expect(service.pages.last.cursorPlan.arrayContains, 'capital');

    await tester.enterText(
      find.byKey(const ValueKey('question-list-search')),
      '',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(service.pages.last.normalizedSearch, isNull);
    expect(service.pages.last.cursorPlan.orderBy, ['__name__']);
  });

  testWidgets('one character stays a browse query and two characters search', (
    tester,
  ) async {
    final service = _ChapterBankService();
    await tester.pumpWidget(_bank(service, _topic));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('question-list-search')),
      'd',
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(service.pages.length, 1);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(service.pages.last.searchPrefix, isNull);
    expect(service.pages.last.cursorPlan.arrayContains, isNull);
    expect(service.counts.last.searchPrefix, isNull);
    expect(service.counts.last.cursorPlan.arrayContains, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('question-list-search')),
      'da',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(service.pages.last.searchPrefix, 'da');
    expect(service.pages.last.cursorPlan.arrayContains, 'da');
    expect(service.counts.last.cursorPlan.arrayContains, 'da');

    await tester.enterText(
      find.byKey(const ValueKey('question-list-search')),
      '',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(service.pages.last.searchPrefix, isNull);
    expect(service.pages.last.cursorPlan.arrayContains, isNull);
    expect(service.counts.last.cursorPlan.arrayContains, isNull);
  });

  testWidgets('a status change is queried on the server and resets the page', (
    tester,
  ) async {
    final service = _ChapterBankService();
    await tester.pumpWidget(_bank(service, _topic));
    await tester.pumpAndSettle();
    final more = find.byKey(const ValueKey('chapter-question-bank-load-more'));
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();

    final status = find.byKey(const ValueKey('question-list-status'));
    await tester.ensureVisible(status);
    await tester.tap(status);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Published').last);
    await tester.pumpAndSettle();

    expect(service.pages.last.status, QuestionPublicationStatus.published);
    expect(service.pages.last.cursorDocumentId, isNull);
    expect(service.loadQuestionsCalls, 0);
  });
}

Widget _bank(
  _ChapterBankService service,
  AdminChapterQuestionContext location,
) {
  return MaterialApp(
    home: Scaffold(
      body: AdminQuestionListScreen(service: service, chapterContext: location),
    ),
  );
}

class _ChapterBankService extends AdminQuestionService {
  _ChapterBankService() : super();

  final List<AdminChapterQuestionQuery> pages = [];
  final List<AdminChapterQuestionQuery> counts = [];
  int loadQuestionsCalls = 0;

  @override
  Future<List<Course>> loadCourses() async => const [
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
  ];

  @override
  Future<List<Question>> loadQuestions(String courseId) async {
    loadQuestionsCalls += 1;
    return const [];
  }

  @override
  Future<QuestionBankPage> loadChapterQuestionPage(
    AdminChapterQuestionContext location, {
    QuestionPublicationStatus? status,
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) async {
    final query = AdminChapterQuestionQuery.fromContext(
      location,
      status: status,
      searchText: searchText,
      cursorDocumentId: cursorDocumentId,
      cursorSearchText: cursorSearchText,
    );
    pages.add(query);
    if (query.normalizedSearch != null || query.status != null) {
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
      questions: [_question('q-2', 'Question 2')],
      hasMore: false,
      cursorDocumentId: 'q-2',
    );
  }

  @override
  Future<int> countChapterQuestions(
    AdminChapterQuestionContext location, {
    QuestionPublicationStatus? status,
    String? searchText,
  }) async {
    counts.add(
      AdminChapterQuestionQuery.fromContext(
        location,
        status: status,
        searchText: searchText,
      ),
    );
    return 2;
  }
}

Question _question(String id, String text) {
  final now = DateTime(2026, 9, 28);
  return Question(
    id: id,
    courseId: 'group-ii',
    paperId: 'group-ii-paper-ii',
    question: text,
    options: const ['A', 'B', 'C', 'D'],
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
    isActive: true,
    contentArea: AdminQuestionScope.contentAreaChapter,
  );
}
