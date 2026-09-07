import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/admin_routes.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_list_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_question_form.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';

void main() {
  const course = Course(
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

  Question buildQuestion({
    String id = '',
    String text = 'What is the capital of Telangana?',
    QuestionPublicationStatus? status,
    bool isActive = true,
  }) {
    final now = DateTime(2026, 8, 9);
    return Question(
      id: id,
      courseId: 'group-ii',
      paperId: 'paper-1',
      sectionId: 'section-1',
      topicId: 'topic-1',
      question: text,
      options: const ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar'],
      correctOption: 'A',
      explanation: 'Explanation',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      language: 'en',
      marks: 1,
      negativeMarks: 0,
      tags: const ['Telangana'],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      status: status,
      isActive: isActive,
    );
  }

  final question = buildQuestion(id: 'q-existing');

  Widget app(Question initial, Future<void> Function(Question) onSubmit) {
    return MaterialApp(
      home: Scaffold(
        body: AdminQuestionForm(
          courses: const [course],
          initialQuestion: initial,
          onSubmit: onSubmit,
        ),
      ),
    );
  }

  Widget listApp(
    _FakeAdminQuestionService service, {
    RouteFactory? onGenerateRoute,
  }) {
    return MaterialApp(
      home: AdminQuestionListScreen(service: service),
      onGenerateRoute: onGenerateRoute,
    );
  }

  testWidgets('1: empty question is rejected before submit', (tester) async {
    var submitted = false;
    await tester.pumpWidget(
      app(buildQuestion(text: ''), (_) async => submitted = true),
    );

    await tester.tap(find.byKey(const ValueKey('submit-question')));
    await tester.pump();

    expect(find.text('Question text is required.'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('2: valid form submits canonical Question', (tester) async {
    Question? submitted;
    await tester.pumpWidget(
      app(buildQuestion(), (question) async => submitted = question),
    );

    await tester.tap(find.byKey(const ValueKey('submit-question')));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.courseId, 'group-ii');
    expect(submitted!.correctOption, 'A');
    expect(submitted!.options, hasLength(4));
  });

  testWidgets('3: edit form submits an existing question ID', (tester) async {
    Question? submitted;
    final initial = buildQuestion(id: 'q-edit');
    await tester.pumpWidget(
      app(initial, (question) async => submitted = question),
    );

    await tester.tap(find.byKey(const ValueKey('submit-question')));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.id, 'q-edit');
  });

  testWidgets('4: create action is visible and opens the create route', (
    tester,
  ) async {
    final service = _FakeAdminQuestionService(
      courses: const [course],
      questions: [question],
    );

    await tester.pumpWidget(
      listApp(
        service,
        onGenerateRoute: (settings) {
          if (settings.name == AdminRoutes.questionCreate) {
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(
                body: Text('Create route opened'),
              ),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('+ Create Question'), findsOneWidget);
    await tester.tap(find.text('+ Create Question'));
    await tester.pumpAndSettle();

    expect(find.text('Create route opened'), findsOneWidget);
  });

  testWidgets('5: published question shows Archive action and status chip', (
    tester,
  ) async {
    final published = buildQuestion(
      id: 'q-published',
      status: QuestionPublicationStatus.published,
      isActive: true,
    );
    final service = _FakeAdminQuestionService(
      courses: const [course],
      questions: [published],
    );

    await tester.pumpWidget(listApp(service));
    await tester.pumpAndSettle();

    expect(find.text('Published'), findsWidgets);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Restore'), findsNothing);
    expect(find.text('Publish'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(
      find.byKey(const ValueKey('question-edit-q-published')),
      findsOneWidget,
    );
  });

  testWidgets('6: archive requires confirmation then sets archived status', (
    tester,
  ) async {
    final published = buildQuestion(
      id: 'q-to-archive',
      status: QuestionPublicationStatus.published,
      isActive: true,
    );
    final service = _FakeAdminQuestionService(
      courses: const [course],
      questions: [published],
    );

    await tester.pumpWidget(listApp(service));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Archive Question?'), findsOneWidget);
    expect(
      find.textContaining('removed from Student Practice and new Tests'),
      findsOneWidget,
    );
    expect(service.statusUpdates, isEmpty);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(service.statusUpdates, isEmpty);
    expect(find.text('Archive'), findsOneWidget);

    await tester.ensureVisible(find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await tester.pumpAndSettle();

    expect(service.statusUpdates, [
      ('q-to-archive', QuestionPublicationStatus.archived),
    ]);
    expect(find.text('Restore'), findsOneWidget);
    expect(find.text('Archived'), findsWidgets);
  });

  testWidgets(
    '7: archived question Restore publishes via existing status path',
    (tester) async {
      final archived = buildQuestion(
        id: 'q-archived',
        status: QuestionPublicationStatus.archived,
        isActive: false,
      );
      final service = _FakeAdminQuestionService(
        courses: const [course],
        questions: [archived],
      );

      await tester.pumpWidget(listApp(service));
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Archive Question?'), findsNothing);

      await tester.ensureVisible(find.text('Restore'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(service.statusUpdates, [
        ('q-archived', QuestionPublicationStatus.published),
      ]);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Published'), findsWidgets);
    },
  );

  testWidgets('8: draft question Publish publishes via existing status path', (
    tester,
  ) async {
    final draft = buildQuestion(
      id: 'q-draft',
      status: QuestionPublicationStatus.draft,
      isActive: false,
    );
    final service = _FakeAdminQuestionService(
      courses: const [course],
      questions: [draft],
    );

    await tester.pumpWidget(listApp(service));
    await tester.pumpAndSettle();

    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Draft'), findsWidgets);

    await tester.ensureVisible(find.text('Publish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(service.statusUpdates, [
      ('q-draft', QuestionPublicationStatus.published),
    ]);
    expect(find.text('Archive'), findsOneWidget);
  });

  testWidgets('9: edit action still opens the edit route', (tester) async {
    final published = buildQuestion(
      id: 'q-edit-row',
      status: QuestionPublicationStatus.published,
      isActive: true,
    );
    final service = _FakeAdminQuestionService(
      courses: const [course],
      questions: [published],
    );

    await tester.pumpWidget(
      listApp(
        service,
        onGenerateRoute: (settings) {
          if (settings.name == AdminRoutes.questionEdit) {
            final arg = settings.arguments;
            expect(arg, isA<Question>());
            expect((arg as Question).id, 'q-edit-row');
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(
                body: Text('Edit route opened'),
              ),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    final edit = find.byKey(const ValueKey('question-edit-q-edit-row'));
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();

    expect(find.text('Edit route opened'), findsOneWidget);
  });

  testWidgets('10: no permanent delete affordance is shown', (tester) async {
    final service = _FakeAdminQuestionService(
      courses: const [course],
      questions: [
        buildQuestion(
          id: 'q-a',
          status: QuestionPublicationStatus.archived,
          isActive: false,
        ),
      ],
    );

    await tester.pumpWidget(listApp(service));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsNothing);
    expect(find.text('Permanently Delete'), findsNothing);
    expect(find.text('Remove'), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('11: Question Bank header and filter controls remain available', (
    tester,
  ) async {
    final service = _FakeAdminQuestionService(
      courses: const [course],
      questions: [question],
    );

    await tester.pumpWidget(listApp(service));
    await tester.pumpAndSettle();

    expect(find.text('Question Bank'), findsWidgets);
    expect(
      find.textContaining('Manage, review, publish, archive'),
      findsOneWidget,
    );
    expect(find.text('+ Create Question'), findsOneWidget);
    expect(find.text('Import Questions'), findsOneWidget);
    expect(find.byKey(const ValueKey('question-list-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('question-list-course')), findsOneWidget);
    expect(find.byKey(const ValueKey('question-list-status')), findsOneWidget);
    expect(find.text('Paper'), findsOneWidget);
    expect(find.text('Part'), findsOneWidget);
    expect(find.text('Topic'), findsOneWidget);
    expect(find.text('Lesson'), findsOneWidget);
    expect(find.text('What is the capital of Telangana?'), findsOneWidget);
  });

  testWidgets('12: empty course shows meaningful empty state', (tester) async {
    final service = _FakeAdminQuestionService(
      courses: const [course],
      questions: const [],
    );

    await tester.pumpWidget(listApp(service));
    await tester.pumpAndSettle();

    expect(find.text('No questions yet'), findsOneWidget);
    expect(find.textContaining('Create your first question'), findsOneWidget);
    expect(find.text('+ Create Question'), findsWidgets);
  });

  testWidgets('13: filtered empty results show adjust-filters guidance', (
    tester,
  ) async {
    final service = _FakeAdminQuestionService(
      courses: const [course],
      questions: [question],
    );

    await tester.pumpWidget(listApp(service));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('question-list-search')),
      'zzzz-no-match',
    );
    await tester.pumpAndSettle();

    expect(find.text('No questions found'), findsOneWidget);
    expect(
      find.textContaining('Try adjusting your filters'),
      findsOneWidget,
    );
  });
}

class _FakeAdminQuestionService extends AdminQuestionService {
  _FakeAdminQuestionService({
    required this.courses,
    required List<Question> questions,
  }) : questions = List<Question>.from(questions),
       super();

  final List<Course> courses;
  final List<Question> questions;
  final List<(String, QuestionPublicationStatus)> statusUpdates = [];

  @override
  Future<List<Course>> loadCourses() async => courses;

  @override
  Future<List<Question>> loadQuestions(String courseId) async =>
      List<Question>.from(questions);

  @override
  Future<void> setStatus(
    String questionId,
    QuestionPublicationStatus status,
  ) async {
    statusUpdates.add((questionId, status));
    final index = questions.indexWhere((q) => q.id == questionId);
    if (index < 0) return;
    final current = questions[index];
    questions[index] = Question(
      id: current.id,
      courseId: current.courseId,
      paperId: current.paperId,
      sectionId: current.sectionId,
      topicId: current.topicId,
      question: current.question,
      options: current.options,
      correctOption: current.correctOption,
      explanation: current.explanation,
      difficulty: current.difficulty,
      questionType: current.questionType,
      language: current.language,
      marks: current.marks,
      negativeMarks: current.negativeMarks,
      tags: current.tags,
      estimatedTime: current.estimatedTime,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      content: current.content,
      syllabus: current.syllabus,
      status: status,
      year: current.year,
      examName: current.examName,
      hint: current.hint,
      aiExplanation: current.aiExplanation,
      isActive: status == QuestionPublicationStatus.published,
      itemFormat: current.itemFormat,
    );
  }
}
