import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/admin_routes.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_chapter_questions_browser_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_list_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_questions_home_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_series_questions_browser_screen.dart';
import 'package:telangana_prep/features/admin/presentation/shell/admin_nav_destination.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';

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

void main() {
  Widget navApp({required _FakeAdminQuestionService service}) {
    return MaterialApp(
      home: Scaffold(
        body: Navigator(
          initialRoute: '/',
          onGenerateRoute: (settings) {
            final name = settings.name;
            if (name == '/' || name == null) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) =>
                    const AdminQuestionsHomeScreen(embeddedInShell: true),
              );
            }
            if (name == AdminRoutes.chapterQuestions) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => AdminChapterQuestionsBrowserScreen(
                  questionService: service,
                  embeddedInShell: true,
                ),
              );
            }
            if (name == AdminRoutes.testSeriesQuestions) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const AdminTestSeriesQuestionsBrowserScreen(
                  embeddedInShell: true,
                ),
              );
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Text('route:$name'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('Questions landing shows only Chapter and Test Series choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminQuestionsHomeScreen(embeddedInShell: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chapter Questions'), findsOneWidget);
    expect(find.text('Test Series Questions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('questions-choice-chapter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('questions-choice-test-series')),
      findsOneWidget,
    );
    expect(find.text('Question Bank'), findsNothing);
    expect(find.text('Create Question'), findsNothing);
    expect(find.text('Paper-wise'), findsNothing);
    expect(find.text('Grand Tests'), findsNothing);
    expect(find.text('Previous Papers'), findsNothing);
  });

  testWidgets('Chapter Questions opens Group-II and Group-III', (tester) async {
    final service = _FakeAdminQuestionService();
    await tester.pumpWidget(navApp(service: service));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('questions-choice-chapter')));
    await tester.pumpAndSettle();

    expect(find.byType(AdminChapterQuestionsBrowserScreen), findsOneWidget);
    expect(find.byType(AdminQuestionListScreen), findsNothing);
    expect(find.text('Group-II'), findsOneWidget);
    expect(find.text('Group-III'), findsOneWidget);
    expect(service.loadQuestionsCalls, 0);
  });

  testWidgets('Test Series Questions opens canonical Group-II and Group-III', (
    tester,
  ) async {
    final service = _FakeAdminQuestionService();
    await tester.pumpWidget(navApp(service: service));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('questions-choice-test-series')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdminTestSeriesQuestionsBrowserScreen), findsOneWidget);
    expect(find.text('Test Series Questions'), findsWidgets);
    expect(find.text('Group-II'), findsOneWidget);
    expect(find.text('Group-III'), findsOneWidget);

    final courses = SyllabusService.instance.getAvailableCourses();
    expect(
      courses.map((c) => c.id).toList(),
      containsAll(['group-ii', 'group-iii']),
    );
    expect(
      find.byKey(const ValueKey('test-series-questions-course-group-ii')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('test-series-questions-course-group-iii')),
      findsOneWidget,
    );
    expect(service.loadQuestionsCalls, 0);
  });

  testWidgets(
    'course selection shows Paper-wise, Grand Tests, Previous Papers',
    (tester) async {
      final service = _FakeAdminQuestionService();
      await tester.pumpWidget(navApp(service: service));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('questions-choice-test-series')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('test-series-questions-course-group-ii')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paper-wise'), findsOneWidget);
      expect(find.text('Grand Tests'), findsOneWidget);
      expect(find.text('Previous Papers'), findsOneWidget);
      expect(find.text('part'), findsNothing);
      expect(find.text('mock'), findsNothing);
      expect(find.text('previousyear'), findsNothing);
      expect(service.loadQuestionsCalls, 0);
    },
  );

  testWidgets(
    'each category carries courseId and internal testSeriesCategory',
    (tester) async {
      final service = _FakeAdminQuestionService();
      await tester.pumpWidget(navApp(service: service));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('questions-choice-test-series')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('test-series-questions-course-group-iii')),
      );
      await tester.pumpAndSettle();

      Future<void> openCategory({
        required Key tileKey,
        required String wire,
        required String label,
      }) async {
        await tester.tap(find.byKey(tileKey));
        await tester.pumpAndSettle();
        final screen = tester.widget<AdminTestSeriesQuestionsBrowserScreen>(
          find.byType(AdminTestSeriesQuestionsBrowserScreen).last,
        );
        expect(
          screen.scope.contentArea,
          AdminQuestionScope.contentAreaTestSeries,
        );
        expect(screen.scope.courseId, 'group-iii');
        expect(screen.scope.testSeriesCategory, wire);
        expect(find.text('Group-III'), findsWidgets);
        expect(find.text(label), findsWidgets);
        expect(find.text(wire), findsNothing);
        Navigator.of(
          tester.element(
            find.byType(AdminTestSeriesQuestionsBrowserScreen).last,
          ),
        ).pop();
        await tester.pumpAndSettle();
      }

      await openCategory(
        tileKey: const ValueKey('test-series-questions-category-part'),
        wire: 'part',
        label: 'Paper-wise',
      );
      await openCategory(
        tileKey: const ValueKey('test-series-questions-category-mock'),
        wire: 'mock',
        label: 'Grand Tests',
      );
      await openCategory(
        tileKey: const ValueKey('test-series-questions-category-previousyear'),
        wire: 'previousyear',
        label: 'Previous Papers',
      );
      expect(service.loadQuestionsCalls, 0);
    },
  );

  test('sidebar Questions route still maps nested question destinations', () {
    expect(
      AdminNavDestinationX.fromRouteName(AdminRoutes.questions),
      AdminNavDestination.questions,
    );
    expect(
      AdminNavDestinationX.fromRouteName(AdminRoutes.chapterQuestions),
      AdminNavDestination.questions,
    );
    expect(
      AdminNavDestinationX.fromRouteName(AdminRoutes.testSeriesQuestions),
      AdminNavDestination.questions,
    );
  });
}

class _FakeAdminQuestionService extends AdminQuestionService {
  _FakeAdminQuestionService() : super();

  int loadQuestionsCalls = 0;

  @override
  Future<List<Course>> loadCourses() async => const [_course];

  @override
  Future<List<Question>> loadQuestions(String courseId) async {
    loadQuestionsCalls += 1;
    return const [];
  }
}
