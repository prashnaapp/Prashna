import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/admin_routes.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_access_denied_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_login_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_import_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_test_series_browser_screen.dart';
import 'package:telangana_prep/features/admin/presentation/shell/admin_dirty_scope.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_ui/admin_hierarchy_header.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_ui/admin_page_header.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_ui/admin_surface.dart';
import 'package:telangana_prep/features/admin/services/admin_test_service.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';

void main() {
  const user = AuthUser(
    uid: 'uid-1',
    email: 'admin@example.com',
    displayName: 'Admin User',
  );

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

  testWidgets('Login premium chrome preserves Sign in action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminLoginScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('admin-login-title')), findsOneWidget);
    expect(find.text('Prashna Admin'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(AdminSurface), findsWidgets);
  });

  testWidgets('Access Denied premium chrome preserves Sign out', (tester) async {
    var signedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AdminAccessDeniedScreen(
          user: user,
          onSignOut: () async => signedOut = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Access denied'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-access-denied-title')), findsOneWidget);
    expect(find.textContaining('admin@example.com'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(signedOut, isFalse);
    expect(find.byKey(const ValueKey('admin-sign-out-clean-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sign-out-confirm')));
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
  });

  testWidgets('Import premium header keeps JSON and validate controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminQuestionImportScreen(embeddedInShell: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdminPageHeader), findsOneWidget);
    expect(find.text('Import Questions'), findsOneWidget);
    expect(find.byKey(const ValueKey('import-json')), findsOneWidget);
    expect(find.byKey(const ValueKey('validate-import')), findsOneWidget);
    expect(find.byKey(const ValueKey('confirm-import')), findsOneWidget);
    expect(find.text('Import as drafts'), findsOneWidget);
    expect(find.textContaining('draft'), findsWidgets);
  });

  testWidgets('Dashboard major nav replaces stack like sidebar', (tester) async {
    final navObserver = _RouteNameObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [navObserver],
        home: AdminDirtyScope(
          controller: AdminDirtyController(),
          child: AdminDashboardScreen(
            user: user,
            onSignOut: () async {},
            embeddedInShell: true,
          ),
        ),
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(body: Text('route:${settings.name}')),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Questions'));
    await tester.pumpAndSettle();

    expect(find.text('route:${AdminRoutes.questions}'), findsOneWidget);
    expect(navObserver.replacedTo, AdminRoutes.questions);
  });

  testWidgets('Embedded Test Series depth uses hierarchy header not AppBar', (
    tester,
  ) async {
    final service = _FakeAdminTestService(courses: const [course]);
    await tester.pumpWidget(
      MaterialApp(
        home: AdminTestSeriesBrowserScreen(
          service: service,
          courseId: 'group-ii',
          mode: AdminTestSeriesMode.categories,
          embeddedInShell: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdminHierarchyHeader), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('admin-hierarchy-back')), findsOneWidget);
    expect(find.text('Paper-wise Tests'), findsOneWidget);
  });
}

class _RouteNameObserver extends NavigatorObserver {
  String? replacedTo;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // pushNamedAndRemoveUntil may present as push after removals.
    replacedTo = route.settings.name ?? replacedTo;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacedTo = newRoute?.settings.name ?? replacedTo;
  }
}

class _FakeAdminTestService extends AdminTestService {
  _FakeAdminTestService({required this.courses})
    : super(
        testRepository: TestCloudRepository.withLoader((_) async => const []),
      );

  final List<Course> courses;

  @override
  Future<List<Course>> loadCourses() async => courses;

  @override
  Future<List<TestModel>> loadTests(String courseId) async => const [];
}
