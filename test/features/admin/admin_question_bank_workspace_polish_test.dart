import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_list_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';

const _course = Course(
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

Question _buildQuestion({
  String id = 'q-visual-1',
  String text = 'Workspace polish question stem?',
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
    status: QuestionPublicationStatus.draft,
    isActive: true,
  );
}

void main() {
  testWidgets('Question Bank workspace chrome has no Dashboard atmosphere', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminQuestionListScreen(
          service: _FakeService(questions: [_buildQuestion()]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dashboard-atmosphere')), findsNothing);
    expect(
      find.byKey(const ValueKey('question-list-filter-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('question-list-course-context')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('question-list-result-count')),
      findsOneWidget,
    );
    expect(find.text('Create Question'), findsWidgets);
    expect(find.text('+ Create Question'), findsNothing);
    expect(find.byKey(const ValueKey('question-list-create')), findsOneWidget);
    expect(find.byKey(const ValueKey('question-list-import')), findsOneWidget);
    expect(find.byKey(const ValueKey('question-list-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('question-list-course')), findsOneWidget);
    expect(find.byKey(const ValueKey('question-list-status')), findsOneWidget);
    expect(find.byKey(const ValueKey('question-list-paper')), findsOneWidget);
  });

  testWidgets('Clear filters resets search and hides clear control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminQuestionListScreen(
          service: _FakeService(questions: [_buildQuestion()]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('question-list-clear-filters')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('question-list-search')),
      'zzzz-no-match',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('question-list-clear-filters')),
      findsOneWidget,
    );
    expect(find.text('No questions found'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('question-list-clear-filters')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('question-list-clear-filters')),
      findsNothing,
    );
    expect(find.text('Workspace polish question stem?'), findsOneWidget);
  });

  testWidgets('Question Bank uses one main content scroll', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminQuestionListScreen(
          service: _FakeService(questions: [_buildQuestion()]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('question-list-scroll')), findsOneWidget);
    // One continuous content scroll — no nested ListView for header vs rows.
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Question Bank'), findsWidgets);
    expect(find.byKey(const ValueKey('question-list-filter-panel')), findsOneWidget);
    expect(find.text('Workspace polish question stem?'), findsOneWidget);
  });
}

class _FakeService extends AdminQuestionService {
  _FakeService({required this.questions}) : super();

  final List<Question> questions;

  @override
  Future<List<Course>> loadCourses() async => const [_course];

  @override
  Future<List<Question>> loadQuestions(String courseId) async =>
      List<Question>.from(questions);
}
