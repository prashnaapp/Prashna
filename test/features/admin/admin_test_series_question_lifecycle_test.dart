import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/admin_routes.dart';
import 'package:telangana_prep/features/admin/data/admin_content_callable_client.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/data/admin_test_series_question_query.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_list_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_series_question_bank_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/tests/data/grand_test_series.dart';

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

  Question build({
    required String id,
    required String text,
    QuestionPublicationStatus? status,
    bool isActive = false,
  }) {
    final now = DateTime(2026, 10, 1);
    return Question(
      id: id,
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      question: text,
      options: const ['A', 'B', 'C', 'D'],
      correctOption: 'A',
      explanation: 'Because',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      status: status,
      isActive: isActive,
      contentArea: AdminQuestionScope.contentAreaTestSeries,
      testSeriesCategory: AdminQuestionScope.categoryPart,
    );
  }

  Widget bankApp(
    _LifecycleBankService service, {
    AdminQuestionScope scope = paperScope,
    RouteFactory? onGenerateRoute,
  }) {
    return MaterialApp(
      home: AdminTestSeriesQuestionBankScreen(scope: scope, service: service),
      onGenerateRoute: onGenerateRoute,
    );
  }

  testWidgets('draft Test Series question shows Edit and Publish', (
    tester,
  ) async {
    final service = _LifecycleBankService(
      seeds: [
        build(
          id: 'q-draft',
          text: 'Draft stem',
          status: QuestionPublicationStatus.draft,
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(bankApp(service));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('question-edit-q-draft')), findsOneWidget);
    expect(find.text('Publish'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('question-delete-q-draft')),
      findsOneWidget,
    );
  });

  testWidgets('published Test Series question shows Edit and Archive', (
    tester,
  ) async {
    final service = _LifecycleBankService(
      seeds: [
        build(
          id: 'q-published',
          text: 'Published stem',
          status: QuestionPublicationStatus.published,
          isActive: true,
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(bankApp(service));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('question-edit-q-published')),
      findsOneWidget,
    );
    expect(find.text('Archive'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('question-delete-q-published')),
      findsNothing,
    );
  });

  testWidgets('archived Test Series question shows Edit and Restore', (
    tester,
  ) async {
    final service = _LifecycleBankService(
      seeds: [
        build(
          id: 'q-archived',
          text: 'Archived stem',
          status: QuestionPublicationStatus.archived,
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(bankApp(service));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('question-edit-q-archived')),
      findsOneWidget,
    );
    expect(find.text('Restore'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('question-delete-q-archived')),
      findsOneWidget,
    );
  });

  testWidgets('assigned Test Series question does not show Delete', (
    tester,
  ) async {
    final service = _LifecycleBankService(
      seeds: [
        build(
          id: 'q-assigned',
          text: 'Assigned stem',
          status: QuestionPublicationStatus.draft,
        ),
      ],
      assignmentState: const AdminQuestionAssignmentState(
        owners: {'q-assigned': 'test-1'},
        legacyTestIds: {},
      ),
    );
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(bankApp(service));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('question-delete-q-assigned')),
      findsNothing,
    );
  });

  testWidgets('Edit opens the existing Question edit route', (tester) async {
    final service = _LifecycleBankService(
      seeds: [
        build(
          id: 'q-edit',
          text: 'Edit me',
          status: QuestionPublicationStatus.draft,
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      bankApp(
        service,
        onGenerateRoute: (settings) {
          if (settings.name == AdminRoutes.questionEdit) {
            final arg = settings.arguments;
            expect(arg, isA<Question>());
            expect((arg as Question).id, 'q-edit');
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Edit route opened')),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('question-edit-q-edit')));
    await tester.pumpAndSettle();
    expect(find.text('Edit route opened'), findsOneWidget);
  });

  testWidgets('Publish updates status and refreshes the bank', (tester) async {
    final service = _LifecycleBankService(
      seeds: [
        build(
          id: 'q-pub',
          text: 'Publish me',
          status: QuestionPublicationStatus.draft,
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(bankApp(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(service.statusUpdates, [
      ('q-pub', QuestionPublicationStatus.published),
    ]);
    expect(find.text('Archive'), findsOneWidget);
    expect(service.loadPageCalls, greaterThan(1));
  });

  testWidgets('lifecycle parity holds for grand and previous banks', (
    tester,
  ) async {
    for (final scope in [grandScope, previousScope]) {
      final service = _LifecycleBankService(
        seeds: [
          build(
            id: 'q-grand-prev',
            text: 'Scoped stem',
            status: QuestionPublicationStatus.draft,
          ),
        ],
      );
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(bankApp(service, scope: scope));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('question-edit-q-grand-prev')),
        findsOneWidget,
      );
      expect(find.text('Publish'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('chapter question list row keys remain unchanged', (
    tester,
  ) async {
    final service = _ChapterListFake(
      questions: [
        build(
          id: 'q-chapter',
          text: 'Chapter row',
          status: QuestionPublicationStatus.draft,
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      MaterialApp(home: AdminQuestionListScreen(service: service)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('question-edit-q-chapter')),
      findsOneWidget,
    );
    expect(find.text('Publish'), findsOneWidget);
  });
}

class _LifecycleBankService extends AdminQuestionService {
  _LifecycleBankService({
    required this.seeds,
    this.assignmentState = const AdminQuestionAssignmentState(
      owners: {},
      legacyTestIds: {},
    ),
  }) : super();

  final List<Question> seeds;
  AdminQuestionAssignmentState assignmentState;
  final List<(String, QuestionPublicationStatus)> statusUpdates = [];
  int loadPageCalls = 0;

  @override
  Future<QuestionBankPage> loadTestSeriesQuestionPage(
    AdminQuestionScope scope, {
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) async {
    loadPageCalls += 1;
    final questions = List<Question>.from(seeds);
    return QuestionBankPage(
      questions: questions,
      hasMore: false,
      cursorDocumentId: questions.isEmpty ? null : questions.last.id,
    );
  }

  @override
  Future<AdminQuestionAssignmentState> loadQuestionAssignmentState(
    List<String> questionIds,
  ) async {
    return assignmentState;
  }

  @override
  Future<void> setStatus(
    String questionId,
    QuestionPublicationStatus status,
  ) async {
    statusUpdates.add((questionId, status));
    final index = seeds.indexWhere((question) => question.id == questionId);
    if (index < 0) return;
    final current = seeds[index];
    seeds[index] = Question(
      id: current.id,
      courseId: current.courseId,
      paperId: current.paperId,
      question: current.question,
      options: current.options,
      correctOption: current.correctOption,
      explanation: current.explanation,
      difficulty: current.difficulty,
      questionType: current.questionType,
      marks: current.marks,
      negativeMarks: current.negativeMarks,
      tags: current.tags,
      estimatedTime: current.estimatedTime,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      status: status,
      isActive: status == QuestionPublicationStatus.published,
      contentArea: current.contentArea,
      testSeriesCategory: current.testSeriesCategory,
      content: current.content,
      syllabus: current.syllabus,
    );
  }
}

class _ChapterListFake extends AdminQuestionService {
  _ChapterListFake({required this.questions}) : super();

  static const _course = Course(
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

  final List<Question> questions;

  @override
  Future<List<Course>> loadCourses() async => const [_course];

  @override
  Future<List<Question>> loadQuestions(String courseId) async => questions;

  @override
  Future<AdminQuestionAssignmentState> loadQuestionAssignmentState(
    List<String> questionIds,
  ) async {
    return const AdminQuestionAssignmentState(owners: {}, legacyTestIds: {});
  }
}
