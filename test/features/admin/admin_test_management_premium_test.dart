import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/admin_routes.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_list_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_series_browser_screen.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_managed_test_list.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_ui/admin_empty_state.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_ui/admin_nav_tile.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_ui/admin_page_header.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_ui/admin_test_row.dart';
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
    String? description,
  }) {
    return TestModel(
      id: id,
      examId: 'group-ii',
      category: TestCategoryType.partTests,
      title: title,
      description: description ?? 'Scoped paper-wise practice',
      questionCount: 10,
      marks: 10,
      durationMinutes: 30,
      negativeMarking: '0.25',
      difficulty: 'Medium',
      status: status,
      paperId: 'group-ii-paper-i',
      partId: 'group-ii-paper-i-part-a',
    );
  }

  testWidgets('Test Series browser renders premium mode tiles', (tester) async {
    final service = _FakeAdminTestService(
      courses: const [course],
      tests: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestSeriesBrowserScreen(
          service: service,
          courseId: 'group-ii',
          mode: AdminTestSeriesMode.categories,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdminNavTile), findsNWidgets(3));
    expect(find.text('Paper-wise Tests'), findsOneWidget);
    expect(find.text('Grand Tests'), findsOneWidget);
    expect(find.text('Previous Papers'), findsOneWidget);
    expect(find.text('Paper → Part → Test'), findsOneWidget);
  });

  testWidgets('Managed test list empty state and header', (tester) async {
    final service = _FakeAdminTestService(
      courses: const [course],
      tests: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdminManagedTestList(
              tests: const [],
              service: service,
              onChanged: () async {},
              onCreate: () {},
              scopeLabel: 'Group-II › Paper-wise Tests',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Managed Tests'), findsOneWidget);
    expect(find.text('Group-II › Paper-wise Tests'), findsOneWidget);
    expect(find.text('+ Create Test'), findsOneWidget);
    expect(find.byType(AdminEmptyState), findsOneWidget);
    expect(find.text('No tests in this folder yet.'), findsOneWidget);
  });

  testWidgets('AdminTestRow shows metadata status and edit', (tester) async {
    var edited = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminTestRow(
            test: buildTest(),
            onEdit: () => edited = true,
            onPublish: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Group-II Practice Test 1'), findsOneWidget);
    expect(find.text('Scoped paper-wise practice'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.textContaining('10 Q'), findsOneWidget);
    expect(find.textContaining('30 min'), findsOneWidget);
    expect(find.text('Paper-wise Tests'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(edited, isTrue);
  });

  testWidgets('flat list premium header and lifecycle still publish', (
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
          if (settings.name == AdminRoutes.testEdit) {
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Edit route')),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdminPageHeader), findsOneWidget);
    expect(find.byType(AdminTestRow), findsOneWidget);
    expect(find.text('Managed Tests'), findsOneWidget);

    await tester.tap(find.byTooltip('Publish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(
      service.statuses['test-group-ii-001'],
      TestPublicationStatus.published,
    );
    expect(find.text('Published'), findsOneWidget);
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
            description: test.description,
            questionCount: test.questionCount,
            marks: test.marks,
            durationMinutes: test.durationMinutes,
            negativeMarking: test.negativeMarking,
            difficulty: test.difficulty,
            questionIds: test.questionIds,
            status: statuses[test.id] ?? test.status,
            paperId: test.paperId,
            partId: test.partId,
          ),
    ];
  }

  @override
  Future<void> setStatus(String testId, TestPublicationStatus status) async {
    statuses[testId] = status;
  }
}
