import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/admin_routes.dart';
import 'package:telangana_prep/features/admin/data/admin_chapter_question_context.dart';
import 'package:telangana_prep/features/admin/data/admin_chapter_question_query.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/data/admin_test_series_question_query.dart';
import 'package:telangana_prep/features/question_bank/data/question_search_text.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_chapter_questions_browser_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_form_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_import_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_list_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_series_questions_browser_screen.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_question_form.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/admin/services/question_import_parser.dart';
import 'package:telangana_prep/features/admin/services/question_import_service.dart';
import 'package:telangana_prep/features/admin/services/question_import_validator.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/syllabus/data/models/syllabus_models.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';

const _groupIi = Course(
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

const _groupIii = Course(
  courseId: 'group-iii',
  title: 'Group-III',
  shortTitle: 'G-III',
  description: '',
  thumbnail: null,
  icon: null,
  color: null,
  isFree: false,
  isPublished: true,
  price: 0,
  sortOrder: 2,
  createdAt: null,
  updatedAt: null,
);

Question _question({
  required String id,
  required String courseId,
  required String paperId,
  String text = 'Scoped chapter question',
  String? majorStudyAreaId,
  String? contentTopicId,
  String? partId,
  String? topicId,
  String? lessonId,
  String? syllabusUnitId,
  QuestionContent? content,
}) {
  final now = DateTime(2026, 9, 28);
  return Question(
    id: id,
    courseId: courseId,
    paperId: paperId,
    question: text,
    options: const ['A', 'B', 'C', 'D'],
    correctOption: 'A',
    explanation: 'Explanation',
    difficulty: QuestionDifficulty.medium,
    questionType: QuestionType.practice,
    marks: 1,
    negativeMarks: 0,
    tags: const [],
    estimatedTime: const Duration(seconds: 30),
    createdAt: now,
    updatedAt: now,
    isActive: true,
    content: content,
    contentArea: AdminQuestionScope.contentAreaChapter,
    syllabus: QuestionSyllabusAttribution(
      courseId: courseId,
      paperId: paperId,
      majorStudyAreaId: majorStudyAreaId,
      contentTopicId: contentTopicId,
      partId: partId,
      topicId: topicId,
      lessonId: lessonId,
      syllabusUnitId: syllabusUnitId,
    ),
  );
}

Map<String, dynamic> _importRecord({
  String? courseId,
  String? topicId,
  String? lessonId,
}) {
  return {
    'courseId': ?courseId,
    'topicId': ?topicId,
    'lessonId': ?lessonId,
    'question': {'en': 'Imported chapter question', 'te': 'దిగుమతి ప్రశ్న'},
    'options': [
      {'en': 'One', 'te': 'ఒకటి'},
      {'en': 'Two', 'te': 'రెండు'},
      {'en': 'Three', 'te': 'మూడు'},
      {'en': 'Four', 'te': 'నాలుగు'},
    ],
    'correctOption': 'A',
    'explanation': {'en': 'Because', 'te': 'ఎందుకంటే'},
  };
}

class _FakeQuestions extends AdminQuestionService {
  _FakeQuestions(this.questions);

  final List<Question> questions;
  String? loadedCourseId;

  @override
  Future<List<Course>> loadCourses() async => const [_groupIi, _groupIii];

  int loadQuestionsCalls = 0;

  @override
  Future<List<Question>> loadQuestions(String courseId) async {
    loadQuestionsCalls += 1;
    loadedCourseId = courseId;
    return questions;
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
    loadedCourseId = query.courseId;
    final matched =
        questions.where((question) => _matches(question, query)).toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final start = cursorDocumentId == null
        ? 0
        : matched.indexWhere((question) => question.id == cursorDocumentId) + 1;
    final slice = matched.skip(start < 0 ? 0 : start);
    final page = slice.take(AdminTestSeriesQuestionQuery.pageSize).toList();
    return QuestionBankPage(
      questions: page,
      hasMore: slice.length > AdminTestSeriesQuestionQuery.pageSize,
      cursorDocumentId: page.isEmpty ? null : page.last.id,
    );
  }

  @override
  Future<int> countChapterQuestions(
    AdminChapterQuestionContext location, {
    QuestionPublicationStatus? status,
    String? searchText,
  }) async {
    final query = AdminChapterQuestionQuery.fromContext(
      location,
      status: status,
      searchText: searchText,
    );
    return questions.where((question) => _matches(question, query)).length;
  }

  bool _matches(Question question, AdminChapterQuestionQuery query) {
    for (final filter in query.equalityFilters) {
      if (_value(question, filter.field) != filter.value) return false;
    }
    final search = query.normalizedSearch;
    if (search == null) return true;
    return QuestionSearchText.normalize(question.question).startsWith(search);
  }

  Object? _value(Question question, String field) {
    switch (field) {
      case 'contentArea':
        return question.contentArea;
      case 'courseId':
        return question.courseId;
      case 'paperId':
        return question.paperId;
      case 'majorStudyAreaId':
        return question.majorStudyAreaId;
      case 'contentTopicId':
        return question.contentTopicId;
      case 'partId':
        return question.partId;
      case 'topicId':
        return question.syllabus?.topicId;
      case 'syllabusUnitId':
        return question.syllabusUnitId;
      case 'status':
        return question.status?.name;
      default:
        return null;
    }
  }
}

void main() {
  final syllabus = SyllabusService.instance;

  Future<void> tapKey(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Widget browser(_FakeQuestions service) {
    return MaterialApp(
      home: Scaffold(
        body: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => AdminChapterQuestionsBrowserScreen(
              questionService: service,
              embeddedInShell: true,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('landing separates Group-II and Group-III', (tester) async {
    await tester.pumpWidget(browser(_FakeQuestions(const [])));
    await tester.pumpAndSettle();

    expect(find.text('Chapter Questions'), findsOneWidget);
    expect(find.text('Group-II'), findsOneWidget);
    expect(find.text('Group-III'), findsOneWidget);
    expect(find.text('Paper-wise'), findsNothing);
    expect(find.byType(AdminQuestionListScreen), findsNothing);
  });

  testWidgets('Group-II Paper I ends at a content-topic bank', (tester) async {
    final course = syllabus.getCourseById('group-ii')!;
    final paper = course.papers.firstWhere(
      (item) => item.hasCanonicalPaperIContent,
    );
    final area = paper.majorStudyAreas.first;
    final topic = area.contentTopics.first;
    final service = _FakeQuestions([
      _question(
        id: 'in-topic',
        courseId: 'group-ii',
        paperId: paper.id,
        text: 'Inside content topic',
        majorStudyAreaId: area.id,
        contentTopicId: topic.id,
      ),
      _question(
        id: 'other-paper',
        courseId: 'group-ii',
        paperId: 'group-ii-paper-ii',
        text: 'Outside content topic',
        partId: 'other-part',
        topicId: 'other-topic',
      ),
    ]);

    await tester.pumpWidget(browser(service));
    await tester.pumpAndSettle();
    await tapKey(tester, const ValueKey('chapter-questions-course-group-ii'));
    await tapKey(tester, ValueKey('chapter-questions-paper-${paper.id}'));
    expect(find.text('Major Study Areas'), findsOneWidget);
    expect(area.contentTopics, hasLength(1));
    expect(
      normalizeChapterFolderName(area.displayName),
      normalizeChapterFolderName(topic.displayName),
    );
    await tapKey(tester, ValueKey('chapter-questions-area-${area.id}'));

    expect(find.text('Content Topics'), findsNothing);
    expect(find.byType(AdminQuestionListScreen), findsOneWidget);
    final list = tester.widget<AdminQuestionListScreen>(
      find.byType(AdminQuestionListScreen),
    );
    expect(list.chapterContext?.majorStudyAreaId, area.id);
    expect(list.chapterContext?.contentTopicId, topic.id);
    expect(find.text('Inside content topic'), findsOneWidget);
    expect(find.text('Outside content topic'), findsNothing);
    expect(service.loadedCourseId, 'group-ii');
    expect(
      find.byKey(const ValueKey('chapter-question-bank-context')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('question-list-course')), findsNothing);
    expect(find.byKey(const ValueKey('question-list-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('question-list-import')), findsOneWidget);
    expect(find.text('Lessons'), findsNothing);
  });

  testWidgets('skipped Paper I wrapper still locks create and import', (
    tester,
  ) async {
    final course = syllabus.getCourseById('group-ii')!;
    final paper = course.papers.firstWhere(
      (item) => item.hasCanonicalPaperIContent,
    );
    final area = paper.majorStudyAreas.first;
    final topic = area.contentTopics.single;

    await tester.pumpWidget(browser(_FakeQuestions(const [])));
    await tester.pumpAndSettle();
    await tapKey(tester, const ValueKey('chapter-questions-course-group-ii'));
    await tapKey(tester, ValueKey('chapter-questions-paper-${paper.id}'));
    await tapKey(tester, ValueKey('chapter-questions-area-${area.id}'));
    await tester.tap(find.byKey(const ValueKey('question-list-create')));
    await tester.pumpAndSettle();

    final form = tester.widget<AdminQuestionFormScreen>(
      find.byType(AdminQuestionFormScreen),
    );
    expect(form.chapterContext?.majorStudyAreaId, area.id);
    expect(form.chapterContext?.contentTopicId, topic.id);
    expect(find.text('Content Topics'), findsNothing);

    Navigator.of(tester.element(find.byType(AdminQuestionFormScreen))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('question-list-import')));
    await tester.pumpAndSettle();

    final import = tester.widget<AdminQuestionImportScreen>(
      find.byType(AdminQuestionImportScreen),
    );
    expect(import.chapterContext?.majorStudyAreaId, area.id);
    expect(import.chapterContext?.contentTopicId, topic.id);
    expect(find.byType(AdminQuestionImportEntryScreen), findsNothing);
  });

  testWidgets('global Paper I import skips a same-name content topic', (
    tester,
  ) async {
    final course = syllabus.getCourseById('group-ii')!;
    final paper = course.papers.firstWhere(
      (item) => item.hasCanonicalPaperIContent,
    );
    final area = paper.majorStudyAreas.first;
    final topic = area.contentTopics.single;

    await tester.pumpWidget(
      const MaterialApp(home: AdminQuestionImportEntryScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-entry-chapter')));
    await tester.pumpAndSettle();
    await tapKey(tester, const ValueKey('chapter-questions-course-group-ii'));
    await tapKey(tester, ValueKey('chapter-questions-paper-${paper.id}'));
    await tapKey(tester, ValueKey('chapter-questions-area-${area.id}'));

    expect(find.text('Content Topics'), findsNothing);
    final import = tester.widget<AdminQuestionImportScreen>(
      find.byType(AdminQuestionImportScreen),
    );
    expect(import.chapterContext?.majorStudyAreaId, area.id);
    expect(import.chapterContext?.contentTopicId, topic.id);
  });

  testWidgets('Paper I keeps a real content-topic choice', (tester) async {
    const multi = SyllabusMajorStudyArea(
      id: 'multi-area',
      officialName: 'Society',
      displayName: 'Society',
      contentTopics: [
        SyllabusContentTopic(
          id: 'topic-caste',
          officialName: 'Caste',
          displayName: 'Caste',
        ),
        SyllabusContentTopic(
          id: 'topic-tribe',
          officialName: 'Tribe',
          displayName: 'Tribe',
        ),
      ],
    );
    const renamed = SyllabusMajorStudyArea(
      id: 'renamed-area',
      officialName: 'Geography',
      displayName: 'Geography',
      contentTopics: [
        SyllabusContentTopic(
          id: 'topic-rivers',
          officialName: 'Rivers',
          displayName: 'Rivers of India',
        ),
      ],
    );
    const spaced = SyllabusMajorStudyArea(
      id: 'spaced-area',
      officialName: 'Current Affairs',
      displayName: 'Current Affairs',
      contentTopics: [
        SyllabusContentTopic(
          id: 'topic-current',
          officialName: 'Current Affairs',
          displayName: '  current   affairs ',
        ),
      ],
    );
    final catalog = SyllabusService.testing([
      SyllabusCourse(
        id: 'group-ii',
        name: 'Group-II',
        subtitle: '',
        totalMarks: 1,
        isEnrolled: true,
        isAvailable: true,
        icon: 'school',
        papers: [
          SyllabusPaper(
            id: 'group-ii-paper-i',
            title: 'Paper I',
            majorStudyAreas: const [multi, renamed, spaced],
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => AdminChapterQuestionsBrowserScreen(
                syllabusService: catalog,
                location: const AdminChapterQuestionContext(
                  courseId: 'group-ii',
                  paperId: 'group-ii-paper-i',
                ),
                embeddedInShell: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tapKey(tester, const ValueKey('chapter-questions-area-multi-area'));
    expect(find.text('Content Topics'), findsOneWidget);
    expect(find.text('Caste'), findsOneWidget);
    expect(find.text('Tribe'), findsOneWidget);
    expect(find.byType(AdminQuestionListScreen), findsNothing);
    Navigator.of(
      tester.element(find.byType(AdminChapterQuestionsBrowserScreen).last),
    ).pop();
    await tester.pumpAndSettle();

    await tapKey(tester, const ValueKey('chapter-questions-area-renamed-area'));
    expect(find.text('Content Topics'), findsOneWidget);
    expect(find.text('Rivers of India'), findsOneWidget);
    expect(find.byType(AdminQuestionListScreen), findsNothing);
    Navigator.of(
      tester.element(find.byType(AdminChapterQuestionsBrowserScreen).last),
    ).pop();
    await tester.pumpAndSettle();

    await tapKey(tester, const ValueKey('chapter-questions-area-spaced-area'));
    final list = tester.widget<AdminQuestionListScreen>(
      find.byType(AdminQuestionListScreen),
    );
    expect(list.chapterContext?.majorStudyAreaId, 'spaced-area');
    expect(list.chapterContext?.contentTopicId, 'topic-current');
    expect(find.text('Content Topics'), findsNothing);
  });

  testWidgets('Group-II Papers II–IV end at a topic bank', (tester) async {
    final course = syllabus.getCourseById('group-ii')!;
    final paper = course.papers.firstWhere(
      (item) =>
          !item.hasCanonicalPaperIContent &&
          item.parts.any(
            (part) => part.topics.any((topic) => topic.lessons.isNotEmpty),
          ),
    );
    final part = paper.parts.firstWhere(
      (item) => item.topics.any((topic) => topic.lessons.isNotEmpty),
    );
    final topic = part.topics.firstWhere((item) => item.lessons.isNotEmpty);
    final lesson = topic.lessons.first;

    await tester.pumpWidget(browser(_FakeQuestions(const [])));
    await tester.pumpAndSettle();
    await tapKey(tester, const ValueKey('chapter-questions-course-group-ii'));
    await tapKey(tester, ValueKey('chapter-questions-paper-${paper.id}'));
    expect(find.text('Parts'), findsOneWidget);
    await tapKey(tester, ValueKey('chapter-questions-part-${part.id}'));
    expect(find.text('Topics'), findsOneWidget);
    expect(find.text('Lessons'), findsNothing);
    await tapKey(tester, ValueKey('chapter-questions-topic-${topic.id}'));

    final list = tester.widget<AdminQuestionListScreen>(
      find.byType(AdminQuestionListScreen),
    );
    expect(list.chapterContext?.courseId, 'group-ii');
    expect(list.chapterContext?.paperId, paper.id);
    expect(list.chapterContext?.partId, part.id);
    expect(list.chapterContext?.topicId, topic.id);
    expect(list.chapterContext?.lessonId, isNull);
    expect(list.chapterContext?.syllabusUnitId, isNull);
    expect(find.text('Lessons'), findsNothing);
    expect(lesson.id, isNotEmpty);
  });

  testWidgets('Group-III Paper I ends at a syllabus unit', (tester) async {
    final paper = syllabus
        .getCourseById('group-iii')!
        .papers
        .firstWhere((item) => item.hasDirectSyllabusUnits);
    final unit = paper.syllabusUnits.first;

    await tester.pumpWidget(browser(_FakeQuestions(const [])));
    await tester.pumpAndSettle();
    await tapKey(tester, const ValueKey('chapter-questions-course-group-iii'));
    await tapKey(tester, ValueKey('chapter-questions-paper-${paper.id}'));
    expect(find.text('Syllabus Units'), findsOneWidget);
    expect(find.text('Major Study Areas'), findsNothing);
    await tapKey(tester, ValueKey('chapter-questions-unit-${unit.id}'));

    final list = tester.widget<AdminQuestionListScreen>(
      find.byType(AdminQuestionListScreen),
    );
    expect(list.chapterContext?.courseId, 'group-iii');
    expect(list.chapterContext?.paperId, paper.id);
    expect(list.chapterContext?.syllabusUnitId, unit.id);
    expect(list.chapterContext?.partId, isNull);
    expect(list.chapterContext?.lessonId, isNull);
  });

  testWidgets('Group-III part papers end at a part syllabus unit', (
    tester,
  ) async {
    final paper = syllabus
        .getCourseById('group-iii')!
        .papers
        .firstWhere(
          (item) => !item.hasDirectSyllabusUnits && item.hasPartSyllabusUnits,
        );
    final part = paper.parts.firstWhere(
      (item) => item.syllabusUnits.isNotEmpty,
    );
    final unit = part.syllabusUnits.first;

    await tester.pumpWidget(browser(_FakeQuestions(const [])));
    await tester.pumpAndSettle();
    await tapKey(tester, const ValueKey('chapter-questions-course-group-iii'));
    await tapKey(tester, ValueKey('chapter-questions-paper-${paper.id}'));
    expect(find.text('Parts'), findsOneWidget);
    await tapKey(tester, ValueKey('chapter-questions-part-${part.id}'));
    await tapKey(tester, ValueKey('chapter-questions-unit-${unit.id}'));

    final list = tester.widget<AdminQuestionListScreen>(
      find.byType(AdminQuestionListScreen),
    );
    expect(list.chapterContext?.partId, part.id);
    expect(list.chapterContext?.syllabusUnitId, unit.id);
    expect(list.chapterContext?.topicId, isNull);
  });

  testWidgets('Create Question from a chapter bank locks that context', (
    tester,
  ) async {
    final course = syllabus.getCourseById('group-ii')!;
    final paper = course.papers.firstWhere(
      (item) => item.hasCanonicalPaperIContent,
    );
    final area = paper.majorStudyAreas.first;
    final topic = area.contentTopics.first;
    final location = AdminChapterQuestionContext(
      courseId: 'group-ii',
      paperId: paper.id,
      majorStudyAreaId: area.id,
      contentTopicId: topic.id,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminQuestionListScreen(
          service: _FakeQuestions(const []),
          chapterContext: location,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('question-list-create')));
    await tester.pumpAndSettle();

    expect(find.byType(AdminQuestionFormScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chapter-question-create-context')),
      findsOneWidget,
    );
    expect(find.textContaining(topic.displayName), findsWidgets);
    expect(find.byKey(const ValueKey('question-course')), findsNothing);
    expect(find.text('Lesson'), findsNothing);
  });

  testWidgets('a topic bank shows legacy lesson questions together', (
    tester,
  ) async {
    final course = syllabus.getCourseById('group-ii')!;
    final paper = course.papers.firstWhere(
      (item) => !item.hasCanonicalPaperIContent && item.parts.isNotEmpty,
    );
    final part = paper.parts.first;
    final topic = part.topics.first;
    final other = part.topics.length > 1 ? part.topics[1] : part.topics.first;
    final location = AdminChapterQuestionContext(
      courseId: 'group-ii',
      paperId: paper.id,
      partId: part.id,
      topicId: topic.id,
    );
    final questions = [
      for (final lessonId in ['legacy-a', 'legacy-b', 'legacy-c'])
        _question(
          id: 'q-$lessonId',
          courseId: 'group-ii',
          paperId: paper.id,
          text: 'Legacy $lessonId',
          partId: part.id,
          topicId: topic.id,
          lessonId: lessonId,
        ),
      _question(
        id: 'q-other',
        courseId: 'group-ii',
        paperId: paper.id,
        text: 'Other topic question',
        partId: part.id,
        topicId: other.id == topic.id ? 'different-topic' : other.id,
        lessonId: 'legacy-other',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: AdminQuestionListScreen(
          service: _FakeQuestions(questions),
          chapterContext: location,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Legacy legacy-a'), findsOneWidget);
    expect(find.text('Legacy legacy-b'), findsOneWidget);
    expect(find.text('Legacy legacy-c'), findsOneWidget);
    expect(find.text('Other topic question'), findsNothing);
    expect(find.text('Lessons'), findsNothing);
    expect(
      find.byKey(const ValueKey('question-list-result-count')),
      findsOneWidget,
    );
    expect(find.text('3 of 3'), findsOneWidget);
  });

  testWidgets('editing a legacy question keeps its lessonId off the form', (
    tester,
  ) async {
    Question? submitted;
    final existing = _question(
      id: 'q-legacy-edit',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      text: 'Legacy editable question',
      partId: 'group-ii-paper-ii-part-01',
      topicId: 'group-ii-paper-ii-part-01-topic-01',
      lessonId: 'group-ii-paper-ii-part-01-topic-01-lesson-01',
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: 'Legacy editable question',
          options: [
            QuestionOption(text: 'A'),
            QuestionOption(text: 'B'),
            QuestionOption(text: 'C'),
            QuestionOption(text: 'D'),
          ],
          explanation: 'Because',
        ),
        te: QuestionLocalizedContent(
          question: 'ప్రశ్న',
          options: [
            QuestionOption(text: 'ఎ'),
            QuestionOption(text: 'బి'),
            QuestionOption(text: 'సి'),
            QuestionOption(text: 'డి'),
          ],
          explanation: 'వివరణ',
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminQuestionForm(
            courses: const [_groupIi],
            initialQuestion: existing,
            onSubmit: (question) async => submitted = question,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lesson'), findsNothing);
    final submit = find.byKey(const ValueKey('submit-question'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(submitted?.id, 'q-legacy-edit');
    expect(
      submitted?.syllabus?.lessonId,
      'group-ii-paper-ii-part-01-topic-01-lesson-01',
    );
    expect(submitted?.syllabus?.topicId, 'group-ii-paper-ii-part-01-topic-01');
  });

  testWidgets('topic bank import opens the scoped chapter workspace', (
    tester,
  ) async {
    final course = syllabus.getCourseById('group-ii')!;
    final paper = course.papers.firstWhere(
      (item) => !item.hasCanonicalPaperIContent && item.parts.isNotEmpty,
    );
    final part = paper.parts.first;
    final topic = part.topics.first;

    await tester.pumpWidget(browser(_FakeQuestions(const [])));
    await tester.pumpAndSettle();
    await tapKey(tester, const ValueKey('chapter-questions-course-group-ii'));
    await tapKey(tester, ValueKey('chapter-questions-paper-${paper.id}'));
    await tapKey(tester, ValueKey('chapter-questions-part-${part.id}'));
    await tapKey(tester, ValueKey('chapter-questions-topic-${topic.id}'));
    await tester.tap(find.byKey(const ValueKey('question-list-import')));
    await tester.pumpAndSettle();

    expect(find.byType(AdminQuestionImportScreen), findsOneWidget);
    expect(find.byType(AdminQuestionImportEntryScreen), findsNothing);
    expect(
      find.byKey(const ValueKey('chapter-import-locked-context')),
      findsOneWidget,
    );
    expect(find.text(topic.resolvedDisplayName), findsWidgets);
    expect(find.byKey(const ValueKey('import-json')), findsOneWidget);
  });

  testWidgets(
    'global chapter import walks the hierarchy before the workspace',
    (tester) async {
      final course = syllabus.getCourseById('group-ii')!;
      final paper = course.papers.firstWhere(
        (item) => !item.hasCanonicalPaperIContent && item.parts.isNotEmpty,
      );
      final part = paper.parts.first;
      final topic = part.topics.first;

      await tester.pumpWidget(
        const MaterialApp(home: AdminQuestionImportEntryScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('import-entry-chapter')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminChapterQuestionsBrowserScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('import-json')), findsNothing);
      expect(
        find.byKey(const ValueKey('import-entry-test-series')),
        findsNothing,
      );

      await tapKey(tester, const ValueKey('chapter-questions-course-group-ii'));
      await tapKey(tester, ValueKey('chapter-questions-paper-${paper.id}'));
      await tapKey(tester, ValueKey('chapter-questions-part-${part.id}'));
      await tapKey(tester, ValueKey('chapter-questions-topic-${topic.id}'));

      expect(find.byType(AdminQuestionImportScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chapter-import-locked-context')),
        findsOneWidget,
      );
      expect(find.text('Test Series Questions'), findsNothing);
    },
  );

  testWidgets('an existing chapter question in the bank can still be edited', (
    tester,
  ) async {
    Question? opened;
    final existing = _question(
      id: 'q-existing',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      text: 'Existing chapter question',
      majorStudyAreaId: 'area',
      contentTopicId: 'topic',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          onGenerateRoute: (settings) {
            if (settings.name == AdminRoutes.questionEdit) {
              opened = settings.arguments as Question?;
              return MaterialPageRoute<void>(
                builder: (_) => const Text('edit-opened'),
              );
            }
            return MaterialPageRoute<void>(
              builder: (_) => AdminQuestionListScreen(
                service: _FakeQuestions([existing]),
                chapterContext: const AdminChapterQuestionContext(
                  courseId: 'group-ii',
                  paperId: 'group-ii-paper-i',
                  majorStudyAreaId: 'area',
                  contentTopicId: 'topic',
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Existing chapter question'), findsOneWidget);
    final edit = find.byKey(const ValueKey('question-edit-q-existing'));
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(find.text('edit-opened'), findsOneWidget);
    expect(opened?.id, 'q-existing');
  });

  test(
    'scoped chapter import locks the topic and keeps a harmless lessonId',
    () async {
      final course = syllabus.getCourseById('group-ii')!;
      final paper = course.papers.firstWhere(
        (item) =>
            !item.hasCanonicalPaperIContent &&
            item.parts.any(
              (part) => part.topics.any((topic) => topic.lessons.isNotEmpty),
            ),
      );
      final part = paper.parts.firstWhere(
        (item) => item.topics.any((topic) => topic.lessons.isNotEmpty),
      );
      final topic = part.topics.firstWhere((item) => item.lessons.isNotEmpty);
      final lesson = topic.lessons.first;
      final validator = QuestionImportValidator(
        chapterContext: AdminChapterQuestionContext(
          courseId: 'group-ii',
          paperId: paper.id,
          partId: part.id,
          topicId: topic.id,
        ),
      );

      final kept = await validator.validate(
        QuestionImportParser.parseJson(
          jsonEncode({
            'questions': [_importRecord(lessonId: lesson.id)],
          }),
        ),
      );
      expect(kept.errors, isEmpty);
      expect(kept.validatedQuestions.single.courseId, 'group-ii');
      expect(kept.validatedQuestions.single.paperId, paper.id);
      expect(kept.validatedQuestions.single.partId, part.id);
      expect(kept.validatedQuestions.single.syllabus?.topicId, topic.id);
      expect(kept.validatedQuestions.single.lessonId, lesson.id);

      final omitted = await validator.validate(
        QuestionImportParser.parseJson(
          jsonEncode({
            'questions': [_importRecord()],
          }),
        ),
      );
      expect(omitted.errors, isEmpty);
      expect(omitted.validatedQuestions.single.lessonId, isNull);
      expect(omitted.validatedQuestions.single.syllabus?.topicId, topic.id);

      final escaped = await validator.validate(
        QuestionImportParser.parseJson(
          jsonEncode({
            'questions': [
              _importRecord(courseId: 'group-iii', topicId: 'other-topic'),
            ],
          }),
        ),
      );
      expect(escaped.canImport, isFalse);
      expect(
        escaped.errors.map((issue) => issue.field),
        containsAll(['courseId', 'topicId']),
      );
    },
  );

  test(
    'scoped chapter import writes contentArea=chapter without a JSON field',
    () async {
      final course = syllabus.getCourseById('group-ii')!;
      final paper = course.papers.firstWhere(
        (item) => item.hasCanonicalPaperIContent,
      );
      final area = paper.majorStudyAreas.first;
      final topic = area.contentTopics.first;
      final location = AdminChapterQuestionContext(
        courseId: 'group-ii',
        paperId: paper.id,
        majorStudyAreaId: area.id,
        contentTopicId: topic.id,
      );
      final created = <Map<String, dynamic>>[];
      final service = QuestionImportService(
        chapterContext: location,
        questionRepository: QuestionCloudRepository.withHandlers(
          createBatch: ({required items}) async {
            created.addAll([for (final item in items) item.data]);
          },
          idGenerator: () => 'imported-${created.length + 1}',
        ),
      );

      final omitted = await service.validateAndImportJson(
        jsonEncode({
          'questions': [_importRecord()],
        }),
      );
      expect(omitted.succeeded, isTrue);
      expect(_importRecord().containsKey('contentArea'), isFalse);
      expect(created.single['contentArea'], 'chapter');
      _expectImportMatchesChapterQuery(created.single, location);

      final explicit = await service.validateAndImportJson(
        jsonEncode({
          'questions': [
            _importRecord()..['contentArea'] = 'chapter',
          ],
        }),
      );
      expect(explicit.succeeded, isTrue);
      expect(created[1]['contentArea'], 'chapter');

      final conflict = await service.validateJson(
        jsonEncode({
          'questions': [
            _importRecord()
              ..['contentArea'] = 'testSeries'
              ..['testSeriesCategory'] = 'part',
          ],
        }),
      );
      expect(conflict.canImport, isFalse);
      expect(
        conflict.errors.any((issue) => issue.field == 'contentArea'),
        isTrue,
      );
      expect(created, hasLength(2));
    },
  );

  test('Test Series browser type is unchanged by the chapter browser', () {
    expect(
      const AdminTestSeriesQuestionsBrowserScreen().scope.contentArea,
      'testSeries',
    );
  });
}

void _expectImportMatchesChapterQuery(
  Map<String, dynamic> data,
  AdminChapterQuestionContext location,
) {
  final query = AdminChapterQuestionQuery.fromContext(
    location,
    status: QuestionPublicationStatus.draft,
  );
  for (final filter in query.equalityFilters) {
    expect(data[filter.field], filter.value, reason: filter.field);
  }
  expect(
    query.equalityFilters.any((filter) => filter.field == 'lessonId'),
    isFalse,
  );
}
