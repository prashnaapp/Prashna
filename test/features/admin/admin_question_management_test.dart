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
      MaterialApp(
        home: AdminQuestionListScreen(service: service),
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
}

class _FakeAdminQuestionService extends AdminQuestionService {
  _FakeAdminQuestionService({
    required this.courses,
    required this.questions,
  }) : super();

  final List<Course> courses;
  final List<Question> questions;

  @override
  Future<List<Course>> loadCourses() async => courses;

  @override
  Future<List<Question>> loadQuestions(String courseId) async => questions;
}
