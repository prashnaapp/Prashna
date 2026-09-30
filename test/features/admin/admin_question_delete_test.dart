import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_content_callable_client.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_list_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
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
    required String id,
    QuestionPublicationStatus? status,
    bool isActive = false,
  }) {
    final now = DateTime(2026, 8, 9);
    return Question(
      id: id,
      courseId: 'group-ii',
      paperId: 'paper-1',
      sectionId: 'section-1',
      topicId: 'topic-1',
      question: 'Delete candidate $id',
      options: const ['A', 'B', 'C', 'D'],
      correctOption: 'A',
      explanation: 'Because',
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
      isActive: isActive,
    );
  }

  test('canDeleteQuestion allows only draft/archived unassigned questions', () {
    const empty = AdminQuestionAssignmentState(owners: {}, legacyTestIds: {});
    final draft = buildQuestion(
      id: 'draft',
      status: QuestionPublicationStatus.draft,
    );
    final archived = buildQuestion(
      id: 'archived',
      status: QuestionPublicationStatus.archived,
    );
    final published = buildQuestion(
      id: 'published',
      status: QuestionPublicationStatus.published,
      isActive: true,
    );

    expect(AdminQuestionService.canDeleteQuestion(draft, empty), isTrue);
    expect(AdminQuestionService.canDeleteQuestion(archived, empty), isTrue);
    expect(AdminQuestionService.canDeleteQuestion(published, empty), isFalse);

    final owned = AdminQuestionAssignmentState(
      owners: {'draft': 'test-1'},
      legacyTestIds: {},
    );
    expect(AdminQuestionService.canDeleteQuestion(draft, owned), isFalse);

    final legacy = AdminQuestionAssignmentState(
      owners: {},
      legacyTestIds: {
        'archived': ['legacy-test'],
      },
    );
    expect(AdminQuestionService.canDeleteQuestion(archived, legacy), isFalse);
  });

  testWidgets('cancel delete performs no backend call', (tester) async {
    final service = _DeleteFakeService(
      courses: const [course],
      questions: [
        buildQuestion(id: 'q-cancel', status: QuestionPublicationStatus.draft),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      MaterialApp(home: AdminQuestionListScreen(service: service)),
    );
    await tester.pumpAndSettle();

    final deleteAction = find.byKey(const ValueKey('question-delete-q-cancel'));
    await tester.ensureVisible(deleteAction);
    await tester.pumpAndSettle();
    await tester.tap(deleteAction);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(service.deleteCalls, 0);
    expect(find.text('Delete candidate q-cancel'), findsOneWidget);
  });

  testWidgets('successful delete removes the row', (tester) async {
    final service = _DeleteFakeService(
      courses: const [course],
      questions: [
        buildQuestion(id: 'q-delete', status: QuestionPublicationStatus.draft),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      MaterialApp(home: AdminQuestionListScreen(service: service)),
    );
    await tester.pumpAndSettle();

    final deleteAction = find.byKey(const ValueKey('question-delete-q-delete'));
    await tester.ensureVisible(deleteAction);
    await tester.pumpAndSettle();
    await tester.tap(deleteAction);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('question-delete-confirm')));
    await tester.pumpAndSettle();

    expect(service.deleteCalls, 1);
    expect(find.text('Delete candidate q-delete'), findsNothing);
    expect(find.text('Question deleted.'), findsOneWidget);
  });

  testWidgets('failed delete preserves the row', (tester) async {
    final service = _DeleteFakeService(
      courses: const [course],
      questions: [
        buildQuestion(id: 'q-fail', status: QuestionPublicationStatus.draft),
      ],
      failDelete: true,
    );

    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      MaterialApp(home: AdminQuestionListScreen(service: service)),
    );
    await tester.pumpAndSettle();

    final deleteAction = find.byKey(const ValueKey('question-delete-q-fail'));
    await tester.ensureVisible(deleteAction);
    await tester.pumpAndSettle();
    await tester.tap(deleteAction);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('question-delete-confirm')));
    await tester.pumpAndSettle();

    expect(service.deleteCalls, 1);
    expect(find.text('Delete candidate q-fail'), findsOneWidget);
    expect(find.textContaining('Could not delete question'), findsOneWidget);
  });

  testWidgets('assigned draft does not show delete', (tester) async {
    final service = _DeleteFakeService(
      courses: const [course],
      questions: [
        buildQuestion(
          id: 'q-assigned',
          status: QuestionPublicationStatus.draft,
        ),
      ],
      assignmentState: const AdminQuestionAssignmentState(
        owners: {'q-assigned': 'test-1'},
        legacyTestIds: {},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: AdminQuestionListScreen(service: service)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('question-delete-q-assigned')),
      findsNothing,
    );
  });
}

class _DeleteFakeService extends AdminQuestionService {
  _DeleteFakeService({
    required this.courses,
    required List<Question> questions,
    this.assignmentState = const AdminQuestionAssignmentState(
      owners: {},
      legacyTestIds: {},
    ),
    this.failDelete = false,
  }) : questions = List<Question>.from(questions),
       super();

  final List<Course> courses;
  final List<Question> questions;
  final AdminQuestionAssignmentState assignmentState;
  final bool failDelete;
  int deleteCalls = 0;

  @override
  Future<List<Course>> loadCourses() async => courses;

  @override
  Future<List<Question>> loadQuestions(String courseId) async =>
      List<Question>.from(questions);

  @override
  Future<AdminQuestionAssignmentState> loadQuestionAssignmentState(
    List<String> questionIds,
  ) async {
    return assignmentState;
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    deleteCalls++;
    if (failDelete) {
      throw const FormatException('Server rejected delete.');
    }
    questions.removeWhere((question) => question.id == questionId);
  }
}
