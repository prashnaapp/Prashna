import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/admin_routes.dart';
import 'package:telangana_prep/features/admin/data/admin_test_hierarchy.dart';
import 'package:telangana_prep/features/admin/data/admin_test_scope.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_chapters_browser_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_series_browser_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_test_service.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';

void main() {
  const groupIi = Course(
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

  const groupIii = Course(
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
  );

  TestModel testDoc({
    required String id,
    required String examId,
    required TestCategoryType category,
    required String title,
    String? paperId,
    String? partId,
    String? syllabusUnitId,
    String? seriesId,
    int? year,
  }) {
    return TestModel(
      id: id,
      examId: examId,
      category: category,
      title: title,
      questionCount: 10,
      marks: 10,
      durationMinutes: 30,
      negativeMarking: '0',
      difficulty: 'Medium',
      paperId: paperId,
      partId: partId,
      syllabusUnitId: syllabusUnitId,
      seriesId: seriesId,
      year: year,
    );
  }

  group('AdminTestHierarchy', () {
    test('filters by stored metadata, not titles', () {
      final tests = [
        testDoc(
          id: 'ch-1',
          examId: 'group-ii',
          category: TestCategoryType.chapterTests,
          title: 'Grand Test 1',
          paperId: 'group-ii-paper-i',
          syllabusUnitId: 'group-ii-paper-i-area-01',
        ),
        testDoc(
          id: 'gt-1',
          examId: 'group-ii',
          category: TestCategoryType.mockTests,
          title: 'Current Affairs',
          paperId: 'group-ii-paper-i',
          seriesId: 'Grand Test 1',
        ),
        testDoc(
          id: 'py-1',
          examId: 'group-ii',
          category: TestCategoryType.previousYear,
          title: 'Paper I',
          paperId: 'group-ii-paper-i',
          year: 2016,
        ),
      ];

      expect(
        AdminTestHierarchy.chapters(
          tests: tests,
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
          syllabusUnitId: 'group-ii-paper-i-area-01',
        ).map((test) => test.id),
        ['ch-1'],
      );
      expect(
        AdminTestHierarchy.grandTests(
          tests: tests,
          courseId: 'group-ii',
          seriesId: 'Grand Test 1',
          paperId: 'group-ii-paper-i',
        ).map((test) => test.id),
        ['gt-1'],
      );
      expect(
        AdminTestHierarchy.years(tests: tests, courseId: 'group-ii'),
        [2016],
      );
      expect(
        AdminTestHierarchy.years(tests: tests, courseId: 'group-iii'),
        isEmpty,
      );
    });
  });

  testWidgets('dashboard exposes Chapters and Test Series, not Mock Tests', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardScreen(
          user: const AuthUser(uid: 'admin', displayName: 'Admin'),
          onSignOut: () async {},
        ),
      ),
    );

    expect(find.text('Chapters'), findsOneWidget);
    expect(find.text('Test Series'), findsOneWidget);
    expect(find.text('Mock Tests'), findsNothing);
    expect(
      find.text(
        'Course → Paper → Part (when applicable) → Chapter → Test',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Group-II Chapters: four papers; Paper I has no Parts', (
    tester,
  ) async {
    final syllabus = SyllabusService.instance.getCourseById('group-ii')!;
    final service = _FakeAdminTestService(
      courses: const [groupIi, groupIii],
      tests: const [],
    );

    await tester.pumpWidget(
      MaterialApp(home: AdminChaptersBrowserScreen(service: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Group-II'));
    await tester.pumpAndSettle();

    expect(syllabus.papers, hasLength(4));
    for (final paper in syllabus.papers) {
      expect(
        find.text(AdminTestHierarchy.paperLabel(paper)),
        findsOneWidget,
      );
    }

    await tester.tap(find.text(AdminTestHierarchy.paperLabel(syllabus.papers.first)));
    await tester.pumpAndSettle();

    expect(find.text('Parts'), findsNothing);
    expect(find.text('Chapters'), findsWidgets);
    expect(
      find.text(syllabus.papers.first.syllabusUnits.first.displayName),
      findsOneWidget,
    );
  });

  testWidgets('Group-II Chapters: Paper II uses Parts then chapters', (
    tester,
  ) async {
    final paper = SyllabusService.instance.getPaper(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
    )!;
    final service = _FakeAdminTestService(
      courses: const [groupIi],
      tests: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminChaptersBrowserScreen(
          service: service,
          courseId: 'group-ii',
          paperId: paper.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(paper.hasCanonicalParts, isTrue);
    expect(find.text('Parts'), findsWidgets);
    for (final part in paper.parts) {
      expect(find.text(part.displayName), findsOneWidget);
    }

    await tester.tap(find.text(paper.parts.first.displayName));
    await tester.pumpAndSettle();
    expect(
      find.text(paper.parts.first.syllabusUnits.first.displayName),
      findsOneWidget,
    );
  });

  testWidgets('Group-III Chapters: three papers from syllabus', (tester) async {
    final syllabus = SyllabusService.instance.getCourseById('group-iii')!;
    final service = _FakeAdminTestService(
      courses: const [groupIi, groupIii],
      tests: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminChaptersBrowserScreen(
          service: service,
          courseId: 'group-iii',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(syllabus.papers, hasLength(3));
    for (final paper in syllabus.papers) {
      expect(
        find.text(AdminTestHierarchy.paperLabel(paper)),
        findsOneWidget,
      );
    }
  });

  testWidgets('Test Series shows the three categories and no Mock Tests', (
    tester,
  ) async {
    final service = _FakeAdminTestService(
      courses: const [groupIi, groupIii],
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

    expect(find.text('Paper-wise Tests'), findsOneWidget);
    expect(find.text('Grand Tests'), findsOneWidget);
    expect(find.text('Previous Papers'), findsOneWidget);
    expect(find.text('Mock Tests'), findsNothing);
  });

  testWidgets('Paper-wise Tests: Paper II opens Parts as the next level', (
    tester,
  ) async {
    final paper = SyllabusService.instance.getPaper(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
    )!;
    final service = _FakeAdminTestService(
      courses: const [groupIi],
      tests: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestSeriesBrowserScreen(
          service: service,
          courseId: 'group-ii',
          mode: AdminTestSeriesMode.paperWise,
          paperId: paper.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parts'), findsWidgets);
    expect(find.text('+ Create Test'), findsNothing);
    for (final part in paper.parts) {
      expect(find.text(part.displayName), findsOneWidget);
    }

    await tester.tap(find.text(paper.parts.first.displayName));
    await tester.pumpAndSettle();
    expect(find.text('+ Create Test'), findsOneWidget);
  });

  testWidgets('Grand Tests stay empty until a seriesId exists', (tester) async {
    final service = _FakeAdminTestService(
      courses: const [groupIi],
      tests: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestSeriesBrowserScreen(
          service: service,
          courseId: 'group-ii',
          mode: AdminTestSeriesMode.grandTests,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No Grand Test groups yet'), findsOneWidget);
    expect(find.text('Grand Test 1'), findsNothing);
  });

  testWidgets('Previous Papers list stored years only', (tester) async {
    final service = _FakeAdminTestService(
      courses: const [groupIi],
      tests: [
        testDoc(
          id: 'py-2016',
          examId: 'group-ii',
          category: TestCategoryType.previousYear,
          title: 'Some title',
          paperId: 'group-ii-paper-i',
          year: 2016,
        ),
      ],
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

    expect(find.text('2016'), findsOneWidget);
    expect(find.text('2024'), findsNothing);
  });

  testWidgets('chapter leaf create passes locked scope', (tester) async {
    final unit = SyllabusService.instance
        .getPaper(courseId: 'group-ii', paperId: 'group-ii-paper-i')!
        .syllabusUnits
        .first;
    Object? args;
    final service = _FakeAdminTestService(
      courses: const [groupIi],
      tests: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminChaptersBrowserScreen(
          service: service,
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
          unitId: unit.id,
        ),
        onGenerateRoute: (settings) {
          if (settings.name == AdminRoutes.testCreate) {
            args = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('create opened')),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('+ Create Test'));
    await tester.pumpAndSettle();

    final scope = args as AdminTestScope;
    expect(scope.category, TestCategoryType.chapterTests);
    expect(scope.courseId, 'group-ii');
    expect(scope.paperId, 'group-ii-paper-i');
    expect(scope.syllabusUnitId, unit.id);
    expect(scope.year, isNull);
  });
}

class _FakeAdminTestService extends AdminTestService {
  _FakeAdminTestService({required this.courses, required List<TestModel> tests})
    : _tests = List<TestModel>.from(tests),
      super(
        testRepository: TestCloudRepository.withLoader((_) async => const []),
      );

  final List<Course> courses;
  final List<TestModel> _tests;

  @override
  Future<List<Course>> loadCourses() async => courses;

  @override
  Future<List<TestModel>> loadTests(String courseId) async {
    return [
      for (final test in _tests)
        if (test.examId == courseId) test,
    ];
  }
}
