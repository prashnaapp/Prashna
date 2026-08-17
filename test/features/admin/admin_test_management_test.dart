import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/admin_routes.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_list_screen.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_test_form.dart';
import 'package:telangana_prep/features/admin/services/admin_test_service.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';

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

  TestModel buildTest({
    String id = 'test-group-ii-001',
    String title = 'Group-II Practice Test 1',
    TestPublicationStatus status = TestPublicationStatus.draft,
  }) {
    return TestModel(
      id: id,
      examId: 'group-ii',
      category: TestCategoryType.chapterTests,
      title: title,
      questionCount: 10,
      marks: 10,
      durationMinutes: 30,
      negativeMarking: '0',
      difficulty: 'Medium',
      status: status,
    );
  }

  Widget formApp(TestModel initial, Future<void> Function(TestModel) onSubmit) {
    return MaterialApp(
      home: Scaffold(
        body: AdminTestForm(
          courses: const [course],
          initialTest: initial.id.isEmpty && initial.title.isEmpty
              ? null
              : initial,
          initialCourseId: 'group-ii',
          onSubmit: onSubmit,
        ),
      ),
    );
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    final submit = find.byKey(const ValueKey('submit-test'));
    await tester.dragUntilVisible(
      submit,
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
  }

  testWidgets('1: empty title is rejected before submit', (tester) async {
    var submitted = false;
    await tester.pumpWidget(
      formApp(buildTest(id: '', title: ''), (_) async => submitted = true),
    );

    await tapSubmit(tester);

    expect(submitted, isFalse);
    expect(find.text('Title is required.'), findsOneWidget);
  });

  testWidgets('2: valid form submits canonical TestModel', (tester) async {
    TestModel? submitted;
    await tester.pumpWidget(
      formApp(
        buildTest(id: '', title: 'New Chapter Test'),
        (model) async => submitted = model,
      ),
    );

    // Create flow has no Status field; submit label is "Create draft".
    await tapSubmit(tester);
    expect(find.text('Create draft'), findsOneWidget);
    expect(find.text('Save changes'), findsNothing);

    expect(submitted, isNotNull);
    expect(submitted!.examId, 'group-ii');
    expect(submitted!.title, 'New Chapter Test');
    expect(submitted!.questionCount, 10);
    expect(submitted!.questionIds, isEmpty);
    expect(submitted!.isPublished, isFalse);
  });

  testWidgets('3: edit form submits an existing test ID', (tester) async {
    TestModel? submitted;
    final initial = buildTest(id: 'test-edit');
    await tester.pumpWidget(
      formApp(initial, (model) async => submitted = model),
    );

    final status = find.text('Status');
    await tester.dragUntilVisible(
      status,
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(status, findsOneWidget);
    await tapSubmit(tester);

    expect(submitted, isNotNull);
    expect(submitted!.id, 'test-edit');
  });

  testWidgets('4: create action is visible and opens the create route', (
    tester,
  ) async {
    final service = _FakeAdminTestService(
      courses: const [course],
      tests: [buildTest()],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestListScreen(service: service),
        onGenerateRoute: (settings) {
          if (settings.name == AdminRoutes.testCreate) {
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Create route opened')),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('+ Create Test'), findsOneWidget);
    expect(find.text('Group-II Practice Test 1'), findsOneWidget);
    expect(find.textContaining('Draft'), findsOneWidget);

    await tester.tap(find.text('+ Create Test'));
    await tester.pumpAndSettle();

    expect(find.text('Create route opened'), findsOneWidget);
  });

  testWidgets('5: edit navigation passes through list card', (tester) async {
    TestModel? edited;
    final service = _FakeAdminTestService(
      courses: const [course],
      tests: [buildTest()],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestListScreen(service: service),
        onGenerateRoute: (settings) {
          if (settings.name == AdminRoutes.testEdit) {
            edited = settings.arguments as TestModel?;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Edit route opened')),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit route opened'), findsOneWidget);
    expect(edited?.id, 'test-group-ii-001');
  });

  testWidgets('6: publish action updates status', (tester) async {
    final service = _FakeAdminTestService(
      courses: const [course],
      tests: [buildTest()],
    );

    await tester.pumpWidget(
      MaterialApp(home: AdminTestListScreen(service: service)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Draft'), findsOneWidget);

    await tester.tap(find.byTooltip('Publish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Published'), findsOneWidget);
    expect(
      service.statuses['test-group-ii-001'],
      TestPublicationStatus.published,
    );
  });

  testWidgets('7: unpublish action updates status', (tester) async {
    final service = _FakeAdminTestService(
      courses: const [course],
      tests: [buildTest(status: TestPublicationStatus.published)],
    );

    await tester.pumpWidget(
      MaterialApp(home: AdminTestListScreen(service: service)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Published'), findsOneWidget);

    await tester.tap(find.byTooltip('Unpublish'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Draft'), findsOneWidget);
    expect(
      service.statuses['test-group-ii-001'],
      TestPublicationStatus.draft,
    );
  });
}

class _FakeAdminTestService extends AdminTestService {
  _FakeAdminTestService({required this.courses, required List<TestModel> tests})
    : _tests = tests.map((test) => test).toList(growable: true),
      super(
        testRepository: TestCloudRepository.withLoader((_) async => const []),
      );

  final List<Course> courses;
  final List<TestModel> _tests;
  final Map<String, TestPublicationStatus> statuses = {};

  @override
  Future<List<Course>> loadCourses() async => courses;

  @override
  Future<List<TestModel>> loadTests(String courseId) async {
    return [
      for (final test in _tests)
        if (test.examId == courseId)
          TestModel(
            id: test.id,
            examId: test.examId,
            category: test.category,
            title: test.title,
            questionCount: test.questionCount,
            marks: test.marks,
            durationMinutes: test.durationMinutes,
            negativeMarking: test.negativeMarking,
            difficulty: test.difficulty,
            questionIds: test.questionIds,
            status: statuses[test.id] ?? test.status,
          ),
    ];
  }

  @override
  Future<void> publishTest(String testId) async {
    statuses[testId] = TestPublicationStatus.published;
  }

  @override
  Future<void> unpublishTest(String testId) async {
    statuses[testId] = TestPublicationStatus.draft;
  }

  @override
  Future<void> setStatus(String testId, TestPublicationStatus status) async {
    statuses[testId] = status;
  }
}
