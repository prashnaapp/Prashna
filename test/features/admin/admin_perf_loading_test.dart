import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_content_callable_client.dart';
import 'package:telangana_prep/features/admin/data/admin_chapter_question_query.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/admin/data/admin_test_series_question_query.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_assignment_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_test_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';

void main() {
  test('course test list is reused until a test write', () async {
    var reads = 0;
    final service = AdminTestService(
      testRepository: TestCloudRepository.withLoader(
        (_) async => const [],
        loadAdminTests: (_) async {
          reads++;
          return const [];
        },
        idGenerator: () => 'draft-1',
        create: ({required testId, required data}) async {},
      ),
      questionRepository: QuestionCloudRepository.withHandlers(),
    );

    await service.loadTests('group-ii');
    await service.loadTests('group-ii');
    expect(reads, 1);

    await service.createTest(
      const TestModel(
        id: '',
        examId: 'group-ii',
        category: TestCategoryType.partTests,
        title: 'Cached draft',
        questionCount: 10,
        marks: 10,
        durationMinutes: 30,
        negativeMarking: '0',
        difficulty: 'Medium',
        paperId: 'group-ii-paper-i',
      ),
    );
    await service.loadTests('group-ii');
    expect(reads, 2);
  });

  test('hierarchy loads courses and tests together', () async {
    var inFlight = 0;
    var maxInFlight = 0;
    Future<T> overlap<T>(Future<T> Function() body) async {
      inFlight++;
      if (inFlight > maxInFlight) maxInFlight = inFlight;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      try {
        return await body();
      } finally {
        inFlight--;
      }
    }

    final service = _OverlapService(overlap);
    await service.loadHierarchy(courseId: 'group-ii');
    expect(maxInFlight, 2);
  });

  test('located chapter tests use the chapter page query', () async {
    var scans = 0;
    AdminChapterQuestionQuery? query;
    final questions = QuestionCloudRepository.withHandlers(
      loadQuestions: (_) async {
        scans++;
        return const [];
      },
      loadChapterQuestionPage: (spec) async {
        query = spec;
        return const QuestionBankPage(questions: [], hasMore: false);
      },
    );
    final service = AdminTestService(
      questionRepository: questions,
      testRepository: TestCloudRepository.withLoader((_) async => const []),
    );

    await service.loadCompatibleQuestionPage(
      const TestModel(
        id: 'chapter-1',
        examId: 'group-iii',
        category: TestCategoryType.chapterTests,
        title: 'Unit test',
        questionCount: 10,
        marks: 10,
        durationMinutes: 30,
        negativeMarking: '0',
        difficulty: 'Medium',
        paperId: 'group-iii-paper-i',
        syllabusUnitId: 'group-iii-paper-i-unit-01',
      ),
    );

    expect(scans, 0);
    expect(query?.courseId, 'group-iii');
    expect(query?.paperId, 'group-iii-paper-i');
    expect(query?.syllabusUnitId, 'group-iii-paper-i-unit-01');
    expect(
      query?.equalityFilters.map((filter) => filter.field),
      containsAll(['contentArea', 'courseId', 'paperId', 'syllabusUnitId']),
    );
  });

  testWidgets('compatible and assigned reads overlap on first load', (
    tester,
  ) async {
    final service = _DelayedAssignmentService();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestAssignmentScreen(test: _chapterTest, service: service),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(service.maxInFlight, 2);
    await tester.pumpAndSettle();
  });
}

const _chapterTest = TestModel(
  id: 'test-1',
  examId: 'group-ii',
  category: TestCategoryType.chapterTests,
  title: 'Chapter Test',
  questionCount: 1,
  marks: 1,
  durationMinutes: 1,
  negativeMarking: '0',
  difficulty: 'Medium',
  questionIds: ['q-one'],
);

class _OverlapService extends AdminTestService {
  _OverlapService(this._overlap);

  final Future<T> Function<T>(Future<T> Function() body) _overlap;

  @override
  Future<List<Course>> loadCourses() {
    return _overlap(() async => const []);
  }

  @override
  Future<List<TestModel>> loadTests(String courseId) {
    return _overlap(() async => const []);
  }
}

class _DelayedAssignmentService extends AdminTestService {
  int inFlight = 0;
  int maxInFlight = 0;

  Future<T> _track<T>(T value) async {
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    inFlight--;
    return value;
  }

  @override
  Future<TestModel?> getTest(String testId) async => _chapterTest;

  @override
  Future<QuestionBankPage> loadCompatibleQuestionPage(
    TestModel test, {
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) {
    return _track(const QuestionBankPage(questions: [], hasMore: false));
  }

  @override
  Future<List<Question>> loadQuestionsByIds(List<String> ids) {
    return _track(const <Question>[]);
  }

  @override
  Future<AdminQuestionAssignmentState> loadQuestionAssignmentState(
    List<String> ids,
  ) async {
    return const AdminQuestionAssignmentState(owners: {}, legacyTestIds: {});
  }
}
