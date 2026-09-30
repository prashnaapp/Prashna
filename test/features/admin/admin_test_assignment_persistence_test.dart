import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_content_callable_client.dart';
import 'package:telangana_prep/features/admin/data/admin_test_series_question_query.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_form_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_test_service.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';

void main() {
  for (final category in TestCategoryType.values.where(
    (category) => category != TestCategoryType.paperTests,
  )) {
    test(
      'metadata save keeps server questionIds for ${category.name}',
      () async {
        final serverIds = ['q-1', 'q-3', 'q-4', 'q-5'];
        final staleIds = ['q-1', 'q-2', 'q-3', 'q-4', 'q-5'];
        final written = await _saveMetadata(
          server: _test(
            category,
            questionIds: serverIds,
            marks: 4,
            duration: 4,
          ),
          form: _test(
            category,
            title: 'Renamed',
            questionIds: staleIds,
            questionCount: 5,
            marks: 99,
            duration: 90,
          ),
        );

        expect(written['title'], 'Renamed');
        expect(written['questionIds'], serverIds);
        expect(written['questionCount'], 4);
        expect(written['totalMarks'], 4);
        expect(written['durationMinutes'], 4);
      },
    );

    test('metadata save does not drop a question added in Manage Questions '
        'for ${category.name}', () async {
      final written = await _saveMetadata(
        server: _test(
          category,
          questionIds: ['q-1', 'q-2', 'q-3', 'q-4', 'q-5'],
          marks: 5,
          duration: 5,
        ),
        form: _test(
          category,
          title: 'Still five',
          questionIds: ['q-1', 'q-2', 'q-3', 'q-4'],
          questionCount: 4,
          marks: 4,
          duration: 4,
        ),
      );

      expect(written['title'], 'Still five');
      expect(written['questionIds'], ['q-1', 'q-2', 'q-3', 'q-4', 'q-5']);
      expect(written['questionCount'], 5);
    });
  }

  test('assignment update still writes the requested questionIds', () async {
    Map<String, dynamic>? written;
    final questions = [
      for (final id in ['q-1', 'q-3', 'q-4', 'q-5']) _question(id),
    ];
    final service = _service(
      server: _test(
        TestCategoryType.partTests,
        questionIds: ['q-1', 'q-2', 'q-3', 'q-4', 'q-5'],
      ),
      questions: questions,
      onWrite: (data) => written = data,
    );

    await service.updateTest(
      _test(
        TestCategoryType.partTests,
        questionIds: ['q-1', 'q-3', 'q-4', 'q-5'],
        questionCount: 4,
      ),
    );

    expect(written?['questionIds'], ['q-1', 'q-3', 'q-4', 'q-5']);
  });

  testWidgets(
    'returning from Manage Questions shows the saved assignment count',
    (tester) async {
      final service = _ScreenService(
        _test(
          TestCategoryType.partTests,
          questionIds: ['q-1', 'q-2', 'q-3', 'q-4', 'q-5'],
        ),
      );
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: AdminTestFormScreen(test: service.server, service: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assigned Questions: 5'), findsWidgets);
      await tester.tap(
        find.byKey(const ValueKey('test-form-manage-questions')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Changes are saved immediately.'), findsOneWidget);
      expect(find.text('5 / 160 assigned'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('remove-question-q-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('4 / 160 assigned'), findsOneWidget);
      expect(service.server.questionIds, ['q-1', 'q-3', 'q-4', 'q-5']);
      expect(service.preserveAssignments, isFalse);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Assigned Questions: 4'), findsWidgets);
      await tester.enterText(find.byType(TextFormField).first, 'Updated title');
      final save = find.byKey(const ValueKey('submit-test'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(service.preserveAssignments, isTrue);
      expect(service.saved?.title, 'Updated title');
      expect(service.saved?.questionIds, ['q-1', 'q-3', 'q-4', 'q-5']);
    },
  );
}

Future<Map<String, dynamic>> _saveMetadata({
  required TestModel server,
  required TestModel form,
}) async {
  Map<String, dynamic>? written;
  final service = _service(
    server: server,
    questions: [for (final id in server.questionIds) _question(id)],
    onWrite: (data) => written = data,
  );
  await service.updateTest(form, preserveAssignments: true);
  return written!;
}

AdminTestService _service({
  required TestModel server,
  required List<Question> questions,
  required void Function(Map<String, dynamic> data) onWrite,
}) {
  return AdminTestService(
    testRepository: TestCloudRepository.withLoader(
      (_) async => const [],
      getById: (_) async => server,
      update: ({required testId, required data}) async => onWrite(data),
    ),
    questionRepository: QuestionCloudRepository.withHandlers(
      getByIds: (ids) async => [
        for (final question in questions)
          if (ids.contains(question.id)) question,
      ],
    ),
  );
}

TestModel _test(
  TestCategoryType category, {
  String title = 'Scoped Test',
  List<String> questionIds = const [],
  int? questionCount,
  int marks = 10,
  int duration = 30,
}) {
  return TestModel(
    id: 'test-1',
    examId: 'group-ii',
    category: category,
    title: title,
    questionCount:
        questionCount ?? (questionIds.isEmpty ? 10 : questionIds.length),
    marks: marks,
    durationMinutes: duration,
    negativeMarking: '0',
    difficulty: 'Medium',
    questionIds: questionIds,
    status: TestPublicationStatus.draft,
    paperId: category == TestCategoryType.partTests ? 'group-ii-paper-i' : null,
    seriesId: category == TestCategoryType.mockTests ? 'Grand Test - I' : null,
    year: category == TestCategoryType.previousYear ? 2016 : null,
  );
}

Question _question(String id) {
  final now = DateTime(2026, 9, 29);
  return Question(
    id: id,
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    question: 'Question $id',
    options: const ['A', 'B'],
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
    contentArea: 'chapter',
  );
}

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

class _ScreenService extends AdminTestService {
  _ScreenService(this.server);

  TestModel server;
  bool? preserveAssignments;
  TestModel? saved;

  @override
  Future<List<Course>> loadCourses() async => const [_course];

  @override
  Future<TestModel?> getTest(String testId) async => server;

  @override
  Future<List<Question>> loadQuestionsByIds(List<String> ids) async => [
    for (final id in ids) _question(id),
  ];

  @override
  Future<QuestionBankPage> loadCompatibleQuestionPage(
    TestModel test, {
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) async {
    return const QuestionBankPage(questions: [], hasMore: false);
  }

  @override
  Future<AdminQuestionAssignmentState> loadQuestionAssignmentState(
    List<String> ids,
  ) async {
    return AdminQuestionAssignmentState(
      owners: {for (final id in server.questionIds) id: server.id},
      legacyTestIds: const {},
    );
  }

  @override
  Future<void> updateTest(
    TestModel test, {
    bool preserveAssignments = false,
  }) async {
    this.preserveAssignments = preserveAssignments;
    saved = test;
    if (!preserveAssignments) {
      server = TestModel(
        id: server.id,
        examId: server.examId,
        category: server.category,
        title: test.title,
        questionCount: test.questionIds.length,
        marks: test.marks,
        durationMinutes: test.durationMinutes,
        negativeMarking: server.negativeMarking,
        difficulty: server.difficulty,
        questionIds: test.questionIds,
        status: server.status,
        paperId: server.paperId,
      );
    }
  }
}
