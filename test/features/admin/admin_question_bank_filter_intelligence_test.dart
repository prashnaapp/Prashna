import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_list_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';

void main() {
  const groupIi = Course(
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

  const groupIii = Course(
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

  Question paperIQuestion({
    String id = 'q-paper-i',
    String text = 'Paper I current affairs question',
    String majorStudyAreaId = 'group-ii-paper-i-area-01',
    String contentTopicId = 'group-ii-paper-i-area-01-topic-01',
    QuestionPublicationStatus status = QuestionPublicationStatus.published,
  }) {
    final now = DateTime(2026, 9, 7);
    return Question(
      id: id,
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      sectionId: 'current-affairs',
      topicId: contentTopicId,
      question: text,
      options: const ['A', 'B', 'C', 'D'],
      correctOption: 'A',
      explanation: 'Explanation',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      language: 'en',
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      status: status,
      isActive: status == QuestionPublicationStatus.published,
      content: QuestionContent(
        en: QuestionLocalizedContent(
          question: text,
          options: const [
            QuestionOption(text: 'A'),
            QuestionOption(text: 'B'),
            QuestionOption(text: 'C'),
            QuestionOption(text: 'D'),
          ],
          explanation: 'Explanation',
        ),
      ),
      syllabus: QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        majorStudyAreaId: majorStudyAreaId,
        contentTopicId: contentTopicId,
      ),
    );
  }

  Question paperIIQuestion({
    String id = 'q-paper-ii',
    String text = 'Paper II history question',
    String partId = 'group-ii-paper-ii-part-01',
    String topicId = 'group-ii-paper-ii-part-01-topic-01',
    String lessonId = 'group-ii-paper-ii-part-01-topic-01-lesson-01',
    QuestionPublicationStatus status = QuestionPublicationStatus.published,
  }) {
    final now = DateTime(2026, 9, 7);
    return Question(
      id: id,
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      sectionId: 'socio-cultural-history',
      topicId: topicId,
      question: text,
      options: const ['A', 'B', 'C', 'D'],
      correctOption: 'A',
      explanation: 'Explanation',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      language: 'en',
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      status: status,
      isActive: status == QuestionPublicationStatus.published,
      content: QuestionContent(
        en: QuestionLocalizedContent(
          question: text,
          options: const [
            QuestionOption(text: 'A'),
            QuestionOption(text: 'B'),
            QuestionOption(text: 'C'),
            QuestionOption(text: 'D'),
          ],
          explanation: 'Explanation',
        ),
      ),
      syllabus: QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-ii',
        partId: partId,
        topicId: topicId,
        lessonId: lessonId,
      ),
    );
  }

  Future<void> openDropdownAndSelect(
    WidgetTester tester, {
    required Key fieldKey,
    required String optionText,
  }) async {
    final field = find.byKey(fieldKey);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    final option = find.text(optionText).last;
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pumpAndSettle();
  }

  Future<void> pumpList(
    WidgetTester tester, {
    required List<Question> questions,
    List<Course> courses = const [groupIi, groupIii],
  }) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AdminQuestionListScreen(
          service: _FakeFilterQuestionService(
            courses: courses,
            questionsByCourse: {
              for (final course in courses)
                course.courseId: questions
                    .where((q) => q.courseId == course.courseId)
                    .toList(growable: false),
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Paper I filter intelligence', () {
    testWidgets('Paper I shows Major Study Area and Content Topic', (
      tester,
    ) async {
      await pumpList(
        tester,
        questions: [paperIQuestion(), paperIIQuestion()],
      );

      expect(find.text('Major Study Area'), findsNothing);
      expect(find.text('Content Topic'), findsNothing);
      expect(find.text('Part'), findsNothing);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-paper'),
        optionText: 'Paper I',
      );

      expect(
        find.byKey(const ValueKey('question-list-major-study-area')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('question-list-content-topic')),
        findsOneWidget,
      );
      expect(find.text('Major Study Area'), findsOneWidget);
      expect(find.text('Content Topic'), findsOneWidget);
      expect(find.text('Part'), findsNothing);
      expect(find.text('Lesson'), findsNothing);
      expect(find.byKey(const ValueKey('question-list-part')), findsNothing);
      expect(find.byKey(const ValueKey('question-list-topic')), findsNothing);
      expect(find.byKey(const ValueKey('question-list-lesson')), findsNothing);
    });

    testWidgets('Paper I Major Study Area filters by content attribution', (
      tester,
    ) async {
      await pumpList(
        tester,
        questions: [
          paperIQuestion(
            id: 'q-ca',
            text: 'Current Affairs stem',
            majorStudyAreaId: 'group-ii-paper-i-area-01',
            contentTopicId: 'group-ii-paper-i-area-01-topic-01',
          ),
          paperIQuestion(
            id: 'q-ir',
            text: 'International Relations stem',
            majorStudyAreaId: 'group-ii-paper-i-area-02',
            contentTopicId: 'group-ii-paper-i-area-02-topic-01',
          ),
          paperIIQuestion(text: 'Should hide under Paper I'),
        ],
      );

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-paper'),
        optionText: 'Paper I',
      );
      expect(find.text('Current Affairs stem'), findsOneWidget);
      expect(find.text('International Relations stem'), findsOneWidget);
      expect(find.text('Should hide under Paper I'), findsNothing);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-major-study-area'),
        optionText: 'Current Affairs',
      );
      expect(find.text('Current Affairs stem'), findsOneWidget);
      expect(find.text('International Relations stem'), findsNothing);
    });
  });

  group('Papers II–IV filter intelligence', () {
    testWidgets('Paper II shows Part, Topic, and Lesson', (tester) async {
      await pumpList(
        tester,
        questions: [paperIQuestion(), paperIIQuestion()],
      );

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-paper'),
        optionText: 'Paper II',
      );

      expect(find.byKey(const ValueKey('question-list-part')), findsOneWidget);
      expect(find.byKey(const ValueKey('question-list-topic')), findsOneWidget);
      expect(find.byKey(const ValueKey('question-list-lesson')), findsOneWidget);
      expect(find.text('Part'), findsOneWidget);
      expect(find.text('Topic'), findsOneWidget);
      expect(find.text('Lesson'), findsOneWidget);
      expect(find.text('Major Study Area'), findsNothing);
      expect(find.text('Content Topic'), findsNothing);
    });

    testWidgets('Part → Topic → Lesson cascade filters questions', (
      tester,
    ) async {
      await pumpList(
        tester,
        questions: [
          paperIIQuestion(
            id: 'q-match',
            text: 'Indus Valley question',
            topicId: 'group-ii-paper-ii-part-01-topic-01',
            lessonId: 'group-ii-paper-ii-part-01-topic-01-lesson-01',
          ),
          paperIIQuestion(
            id: 'q-other-topic',
            text: 'Other topic question',
            topicId: 'group-ii-paper-ii-part-01-topic-02',
            lessonId: 'group-ii-paper-ii-part-01-topic-02-lesson-01',
          ),
          paperIQuestion(text: 'Paper I should hide'),
        ],
      );

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-paper'),
        optionText: 'Paper II',
      );
      expect(find.text('Indus Valley question'), findsOneWidget);
      expect(find.text('Other topic question'), findsOneWidget);
      expect(find.text('Paper I should hide'), findsNothing);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-part'),
        optionText: 'Socio-Cultural History of India and Telangana',
      );
      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-topic'),
        optionText: 'Ancient India and Early Empires',
      );
      expect(find.text('Indus Valley question'), findsOneWidget);
      expect(find.text('Other topic question'), findsNothing);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-lesson'),
        optionText: 'Indus Valley Society and Culture',
      );
      expect(find.text('Indus Valley question'), findsOneWidget);
    });
  });

  group('Cascading filter clears', () {
    testWidgets('Paper change clears hierarchy children', (tester) async {
      await pumpList(
        tester,
        questions: [paperIQuestion(), paperIIQuestion()],
      );

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-paper'),
        optionText: 'Paper I',
      );
      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-major-study-area'),
        optionText: 'Current Affairs',
      );
      expect(find.text('Current Affairs'), findsWidgets);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-paper'),
        optionText: 'Paper II',
      );

      expect(find.text('Major Study Area'), findsNothing);
      expect(find.text('Content Topic'), findsNothing);
      expect(find.byKey(const ValueKey('question-list-part')), findsOneWidget);
      // MSA selection must not linger as an invisible Paper II filter.
      expect(find.text('Paper I current affairs question'), findsNothing);
      expect(find.text('Paper II history question'), findsOneWidget);
    });

    testWidgets('Course change clears hierarchy filters', (tester) async {
      await pumpList(
        tester,
        questions: [
          paperIQuestion(),
          paperIIQuestion(),
          Question(
            id: 'q-g3',
            courseId: 'group-iii',
            paperId: 'group-iii-paper-i',
            sectionId: 'section-1',
            topicId: 'topic-1',
            question: 'Group III only question',
            options: const ['A', 'B', 'C', 'D'],
            correctOption: 'A',
            explanation: 'Explanation',
            difficulty: QuestionDifficulty.easy,
            questionType: QuestionType.practice,
            language: 'en',
            marks: 1,
            negativeMarks: 0,
            tags: const [],
            estimatedTime: const Duration(seconds: 60),
            createdAt: DateTime(2026, 9, 7),
            updatedAt: DateTime(2026, 9, 7),
            status: QuestionPublicationStatus.published,
            isActive: true,
          ),
        ],
      );

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-paper'),
        optionText: 'Paper II',
      );
      expect(find.text('Paper II history question'), findsOneWidget);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-course'),
        optionText: 'Group-III',
      );

      expect(find.byKey(const ValueKey('question-list-part')), findsNothing);
      expect(find.text('Major Study Area'), findsNothing);
      expect(find.text('Group III only question'), findsOneWidget);
      expect(find.text('Paper II history question'), findsNothing);
    });

    testWidgets('Major Study Area change clears Content Topic', (tester) async {
      await pumpList(
        tester,
        questions: [
          paperIQuestion(
            id: 'q-ca',
            text: 'CA stem',
            majorStudyAreaId: 'group-ii-paper-i-area-01',
            contentTopicId: 'group-ii-paper-i-area-01-topic-01',
          ),
          paperIQuestion(
            id: 'q-ir',
            text: 'IR stem',
            majorStudyAreaId: 'group-ii-paper-i-area-02',
            contentTopicId: 'group-ii-paper-i-area-02-topic-01',
          ),
        ],
      );

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-paper'),
        optionText: 'Paper I',
      );
      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-major-study-area'),
        optionText: 'Current Affairs',
      );
      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-content-topic'),
        optionText: 'Current Affairs',
      );
      expect(find.text('CA stem'), findsOneWidget);
      expect(find.text('IR stem'), findsNothing);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-major-study-area'),
        optionText: 'International Relations',
      );
      expect(find.text('CA stem'), findsNothing);
      expect(find.text('IR stem'), findsOneWidget);
    });
  });

  group('Labels and existing filter semantics', () {
    testWidgets('paper dropdown uses syllabus titles not raw IDs', (
      tester,
    ) async {
      await pumpList(tester, questions: [paperIQuestion()]);

      await tester.tap(find.byKey(const ValueKey('question-list-paper')));
      await tester.pumpAndSettle();

      expect(find.text('Paper I'), findsWidgets);
      expect(find.text('Paper II'), findsWidgets);
      expect(find.text('group-ii-paper-i'), findsNothing);
      expect(find.text('group-ii-paper-ii'), findsNothing);
    });

    testWidgets('search and status filters still work with hierarchy', (
      tester,
    ) async {
      await pumpList(
        tester,
        questions: [
          paperIQuestion(
            id: 'q-pub',
            text: 'Published searchable stem',
            status: QuestionPublicationStatus.published,
          ),
          paperIQuestion(
            id: 'q-draft',
            text: 'Draft searchable stem',
            status: QuestionPublicationStatus.draft,
          ),
          paperIIQuestion(text: 'Other paper stem'),
        ],
      );

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-paper'),
        optionText: 'Paper I',
      );
      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-list-status'),
        optionText: 'Draft',
      );
      expect(find.text('Draft searchable stem'), findsOneWidget);
      expect(find.text('Published searchable stem'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('question-list-search')),
        'Draft searchable',
      );
      await tester.pumpAndSettle();
      expect(find.text('Draft searchable stem'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('question-list-search')),
        'no-match-xyz',
      );
      await tester.pumpAndSettle();
      expect(find.text('Draft searchable stem'), findsNothing);
      expect(find.text('No questions found'), findsOneWidget);
    });
  });
}

class _FakeFilterQuestionService extends AdminQuestionService {
  _FakeFilterQuestionService({
    required this.courses,
    required this.questionsByCourse,
  }) : super();

  final List<Course> courses;
  final Map<String, List<Question>> questionsByCourse;

  @override
  Future<List<Course>> loadCourses() async => courses;

  @override
  Future<List<Question>> loadQuestions(String courseId) async {
    return questionsByCourse[courseId] ?? const [];
  }
}
