import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_series_browser_screen.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_managed_test_list.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_test_form.dart';
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
    String id = 'test-1',
    TestPublicationStatus status = TestPublicationStatus.draft,
    String? paperId = 'group-ii-paper-i',
    String? partId,
    String? syllabusUnitId = 'group-ii-paper-i-area-01',
    String? seriesId,
    int? year,
    TestCategoryType category = TestCategoryType.chapterTests,
    List<String> questionIds = const [],
  }) {
    return TestModel(
      id: id,
      examId: 'group-ii',
      category: category,
      title: 'Lifecycle test $id',
      description: 'Scoped test',
      questionCount: questionIds.isEmpty ? 1 : questionIds.length,
      marks: 1,
      durationMinutes: 30,
      negativeMarking: '0',
      difficulty: 'Medium',
      status: status,
      questionIds: questionIds,
      paperId: paperId,
      partId: partId,
      syllabusUnitId: syllabusUnitId,
      seriesId: seriesId,
      year: year,
    );
  }

  group('Lifecycle consistency (Phase 4D)', () {
    testWidgets('managed list: draft shows Publish, archived shows Restore', (
      tester,
    ) async {
      var changeCount = 0;
      final service = _FakeManagedTestService(
        courses: const [course],
        tests: [
          buildTest(id: 'draft-1'),
          buildTest(
            id: 'archived-1',
            status: TestPublicationStatus.archived,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminManagedTestList(
                tests: service.tests,
                service: service,
                onChanged: () async => changeCount++,
                onCreate: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('test-publish-draft-1')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('test-publish-archived-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('test-restore-archived-1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('test-restore-archived-1')));
      await tester.pumpAndSettle();

      expect(service.statuses['archived-1'], TestPublicationStatus.draft);
      expect(changeCount, 1);
    });

    test('updateTest rejects archived → published (same as publishTest)',
        () async {
      final current = buildTest(
        id: 'archived-update',
        status: TestPublicationStatus.archived,
      );
      var updated = false;
      final repo = TestCloudRepository.withLoader(
        (_) async => const [],
        getById: (_) async => current,
        update: ({required testId, required data}) async {
          updated = true;
        },
      );
      final service = AdminTestService(testRepository: repo);

      await expectLater(
        () => service.updateTest(
          buildTest(
            id: 'archived-update',
            status: TestPublicationStatus.published,
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Archived tests cannot be published'),
          ),
        ),
      );
      expect(updated, isFalse);
    });

    test('updateTest allows draft → published when publication-valid', () async {
      final current = buildTest(id: 'draft-update');
      Map<String, dynamic>? updatedData;
      final repo = TestCloudRepository.withLoader(
        (_) async => const [],
        getById: (_) async => current,
        update: ({required testId, required data}) async {
          updatedData = data;
        },
      );
      final service = AdminTestService(testRepository: repo);

      await service.updateTest(
        buildTest(
          id: 'draft-update',
          status: TestPublicationStatus.published,
        ),
      );

      expect(updatedData, isNotNull);
      expect(updatedData!['isPublished'], isTrue);
      expect(updatedData!['status'], 'published');
    });
  });

  group('Hierarchy labels and cascading (Phase 4D)', () {
    testWidgets('AdminTestRow resolves Paper I labels not raw IDs', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminTestRow(
              test: buildTest(),
              onEdit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Paper I'), findsOneWidget);
      expect(find.textContaining('Current Affairs'), findsOneWidget);
      expect(find.text('group-ii-paper-i'), findsNothing);
      expect(find.text('group-ii-paper-i-area-01'), findsNothing);
    });

    testWidgets('course change clears seriesId on unlocked form', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminTestForm(
                courses: const [
                  course,
                  Course(
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
                  ),
                ],
                initialTest: buildTest(
                  id: 'edit-grand',
                  category: TestCategoryType.mockTests,
                  paperId: 'group-ii-paper-i',
                  syllabusUnitId: null,
                  seriesId: 'Grand Test - I',
                ),
                initialCourseId: 'group-ii',
                onSubmit: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grand Test - I'), findsWidgets);

      final courseField = find.byKey(const ValueKey('test-course'));
      await tester.ensureVisible(courseField);
      await tester.tap(courseField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Group-III').last);
      await tester.pumpAndSettle();

      // Series selection must clear with course change.
      expect(find.text('Grand Test - I'), findsNothing);
    });
  });

  group('Previous Papers year continuity (Phase 4D)', () {
    testWidgets('added examination year remains listed after drill and back', (
      tester,
    ) async {
      final service = _FakeManagedTestService(
        courses: const [course],
        tests: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminTestSeriesBrowserScreen(
            service: service,
            courseId: 'group-ii',
            mode: AdminTestSeriesMode.previousPapers,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No examination years yet'), findsOneWidget);

      await tester.tap(find.text('+ Examination year'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2018');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Paper I'), findsOneWidget);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.text('2018'), findsOneWidget);
      expect(find.text('No examination years yet'), findsNothing);
    });
  });
}

class _FakeManagedTestService extends AdminTestService {
  _FakeManagedTestService({
    required this.courses,
    required List<TestModel> tests,
  }) : tests = List<TestModel>.from(tests),
       super();

  final List<Course> courses;
  final List<TestModel> tests;
  final Map<String, TestPublicationStatus> statuses = {};

  @override
  Future<List<Course>> loadCourses() async => courses;

  @override
  Future<List<TestModel>> loadTests(String courseId) async {
    return [
      for (final test in tests)
        if (test.examId == courseId) test,
    ];
  }

  @override
  Future<void> setStatus(String testId, TestPublicationStatus status) async {
    statuses[testId] = status;
    final index = tests.indexWhere((t) => t.id == testId);
    if (index >= 0) {
      final current = tests[index];
      tests[index] = TestModel(
        id: current.id,
        examId: current.examId,
        category: current.category,
        title: current.title,
        description: current.description,
        questionCount: current.questionCount,
        marks: current.marks,
        durationMinutes: current.durationMinutes,
        negativeMarking: current.negativeMarking,
        difficulty: current.difficulty,
        questionIds: current.questionIds,
        status: status,
        paperId: current.paperId,
        partId: current.partId,
        syllabusUnitId: current.syllabusUnitId,
        year: current.year,
        seriesId: current.seriesId,
      );
    }
  }
}
